# Preamble for Qwen (Realsig+, TLR, and Constraint-Serialization Bug)

## 1. Realsig Modes
F# historically uses realsig-: all value initialization is lifted to an outer
module to preserve source-order initialization. To allow this module to access
class-declared values, private fields are emitted as internal in IL. IL
visibility therefore reflects the initialization model rather than the source
code.

realsig+ preserves the true source-declared visibility
(private/protected/internal/public) in IL while keeping the same initialization
sequencing. No other closure or initialization semantics change.

## 2. TLR Pipeline
The TLR pipeline (InnerLambdasToTopLevelFuncs.fs) discovers inner lambdas and
nested functions, determines closure environments, and lifts them into IL-shaped
forms.

- Under --optimize-: closures become classes.
- Under --optimize+: closures become generic methods.

TLR collects all freetypars and constraints from the lambda body and its ambient
class environment and attaches them to the generated closure representation.

Under realsig-, closures are homed on the outer module.
Under realsig+, closures are homed on the class where they were discovered.


Your task is to investigate a specific issue in the F# compiler related to realsig+.

Context:
- In realsig+, free class type parameters are copied into the method as new method type parameters.
- Their constraints are also copied.
- However, the copied constraints still reference the original class typar instead of the method’s cloned typar.
- This produces incorrect IL metadata: the method generic parameter constraints refer to the class generic parameter, not the method parameter.

Your goal:
Determine how to fix the the F# compiler to perform “typar substitution inside constraints” for realsig+ code, i believe it already does it for realsig- code in IlxGen/codegen.

Investigate the following:

1. Typar identity
   - Determine whether constraints can be rewritten by matching on typar identity (stamp).
   - Evaluate whether stamp-based substitution is sufficient to express “replace class typar with method typar” inside constraint types.

2. Lambda – homing implications
   - The compiler currently assumes InnerLambdas will be hosted on an outer, non-generic module rather than on the class where the lambda was discovered.
   - As a result, when the Val for an InnerLambda is built:
       * ctps is always empty (because module homing implies no class typars),
       * mtps contains all free typars discovered in the lambda’s method body, including any typars originating from the enclosing class.
   - Under realsig+, InnerLambdas are re-homed onto their enclosing class, but their typar sets were constructed under the module-homing assumption. This mis-homing causes class typars to be misclassified as method typars and leads directly to incorrect VAR/MVAR emission.

3. Constraint representation
   - Confirm that constraints are stored as TTypes containing Typar nodes.
   - Determine whether these TTypes can be walked and rewritten safely using typar substitution.
   - Verify whether the TAST permits constraint rewriting after type checking, or whether constraints must be reconstructed later.

4. Phase correctness
   - Assess whether InnerLambdasToTopLevelFuncs.fs (TLR) is the correct phase to perform typar substitution, given that it has access to free typars and the enclosing class context.
   - Determine whether this phase is too early, meaning constraints must instead be fixed in IlxGen.fs during IL generic parameter emission, where VAR vs MVAR is decided.

5. Identify and implement
   - Implement the minimal correct fix in IlxGen.fs so that, under realsig+, nested closure methods re-homed onto their original class emit correct IL generic parameter constraints.
   - Ensure constraints reference the cloned method typar rather than the original class typar.
   - Determine whether this requires reconstructing constraint TTypes at IL emission time or performing stamp-based substitution using the class?method typar mapping.

Repro:
Compilation:
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig+ --optimize+ --out:artifacts\Temp\RealsigPlusOptimisePlus.exe
for debug compiler use:
artifacts\bin\fsc\Debug\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig+ --optimize+ --out:artifacts\Temp\RealsigPlusOptimisePlus.exe

To evaluate constraint serialization, run the command:

.opencode\Realsig-Rehoming\verifyRealsigPlusConstraintBlobs.cmd "artifacts\Temp\RealsigPlusOptimisePlus.exe"
.opencode\Realsig-Rehoming\verifyRealsigMinusConstraintBlobs.cmd "artifacts\Temp\RealsigMinusOptimisePlus.exe"

view the output

Type: ConcatEnumerator`2
Token: 0x0200000D
  GP: T (index 0)
  GP: U (index 1)
    Constraint token: 0x1B000006
    Constraint Blob:
15 12 2D 01 13 00
    Decoded: genericinst(class UnknownHandleKind(ModuleDefinition)<var(0)> )

Method: takeInner@301
Token: 0x0600002A
  GP: T (index 0)
  GP: U (index 1)
    Constraint token: 0x1B000006
    Constraint Blob:
15 12 2D 01 13 00
    Decoded: genericinst(class UnknownHandleKind(ModuleDefinition)<var(0)> )

notice that takeInner@301 has the exact same blob as ConcatEnumerator`2 this is the bug

Deliverables:
exact IlxGen emission site,
class?method typar mapping,
constraint remap logic,

verification against the dumper output (ConcatEnumerator`2 vs takeInner@301).

============================================================================================
One last addendum:
This is verbatim from your final output before opencode crashed:

DEFINITIVE PROOF. realsig? vs realsig+ differ by exactly the !n vs !!n distinction:
realsig? (works) — line 1069 & 1125:
takeOuter@308<T,(IEnumerable`1<!!T>) U>(class .../ConcatEnumerator`2<!!T,!!U> x, ...)
takeInner@301<T,(IEnumerable`1<!!T>) U>(class .../ConcatEnumerator`2<!!T,!!U> x, ...)
? method's own GPs are !!T,!!U (MVAR, method-local); constraint IEnumerable1<!!T>`` 
references **method's own T; args !!T,!!U (method-local). All !! = CORRECT IL.
Also notice line 950 & 1115: realsig? callers use ConcatEnumerator2<!!0,!!1> — !!0,!!1 
is a **method-generic** reference (the calling context's own T,U`), which is correct 
(the method's own GPs). realsig+ (broken) — from P.dbg.il line 1048 & 1104:
takeOuter@308<T,(IEnumerable`1<!T>) U>(class .../ConcatEnumerator`2<!T,!U> x, ...)
takeInner@301<T,(IEnumerable`1<!T>) U>(class .../ConcatEnumerator`2<!T,!U> x, ...)
? method's own GPs are !T,!U (VAR, class-level) — WRONG. Constraint IEnumerable1<!T>`` 
references class's T. This produces VerificationException.
So the fix is to make the realsig+ path emit the method's own type parameters as !!n 
(MVAR, method-local), exactly as realsig? does. The difference between the two is the 
home of the method: realsig? ? module class (0 typars ? EnclosingTyparCount=0 ? tv=0,1 >= 0 ? et_MVAR). 
realsig+ ? **ConcatEnumerator2 class** (2 typars ? EnclosingTyparCount=2 ? tv=0,1 < 2` ? et_VAR).
Now I have a fully diagnosed bug with a clear fix direction. Let me record this in a 
findings doc and then implement the fix.

=============================================================================================
Yet another final addendum:

## Part 1 — realsig+ re-homing: thread the lost declaring class into TLR (threading only)

- `MakeTopLevelRepresentationDecisions` (`InnerLambdasToTopLevelFuncs.fs:1473`) already walks the
  *same* `CheckedImplFile` that carries the class context; the member body of an F# class lives at
  `TMDefRec.bindings ? ModuleOrNamespaceBinding.Binding (TBind(memberVal, body))`, and `ExprFolder`
  / `FoldExpr` (`TypedTreeOps.ExprOps.fs:518`) descends into that body — so the ambient class is
  *recoverable from the TAST at TLR time*; it is simply never recorded today.

- The local lambdas TLR lifts (e.g. `takeInner`, `genericTakeOuter`) are created in type-checking
  with `Val.DeclaringEntity = ParentNone` (`TypedTree.fs:2974`); the "which class owns this local"
  fact is therefore *not on the Val at all*, and it is not derivable from `Val.Type`/`ValReprInfo`
  or `f.Type` — the only carrier of it is the lexically-enclosing member's binding.

- The real "declaring class" for a local is NOT the local's `DeclaringEntity` (that is `ParentNone`);
  it is the class whose *member* is the nearest enclosing `Parent (tcref :> TyconRef)` binding found
  while walking `ModuleOrNamespaceContents`. The walk must reset that owner at every
  `ModuleOrNamespaceBinding.Module` boundary (a nested module is not a class) and must NOT treat a
  module-level `let` (a `TMDefLet` at Contents level) as class-local.

- `Entity`/`Tycon` and `Val` are both `NoEquality;NoComparison`, so they cannot be F# `Set`/`Map`
  keys: the new helper returns `Zmap<Val, Tycon>` (keyed by the `valOrder` stamp comparer already
  used everywhere in this file, `valOrder = ...` at `ExprConstruction.fs:42`), and class identity is
  tested by comparing `Entity.Stamp` (the way `valOrder` itself works), not `=`.

- The answer cannot be attached to `Val`/`ValOptionalData` *or* any `Expr`/`ParentRef` field, because
  those are pickled (pickled at `TypedTreePickle.fs:2985` via `p_parentref x.TryDeclaringEntity`):
  adding data there would change the pickled format, which the task forbids. Hence it is a pure,
  recomputed-on-demand function of the `CheckedImplFile` and is *threaded as an extra parameter*.

- This is exactly the prior plan's "approach (b)" (`.opencode/Realsig-Rehoming/possible_approach.txt`):
  a self-contained pre-scan in `InnerLambdasToTopLevelFuncs.fs` producing `Zmap<Val, classContext>`,
  consumed later by Pass2/Pass4 (via `RewriteContext`) — no `TypedTree`/picker change, transient
  compiler-only state.

- Part 2's two needs both reduce to this map plus `Tycon.Typars` (`TypedTree.fs:938`): (a) re-home the
  TLR `fHat` onto the mapped class, and (b) split the leading `|classTypars|` typars as class-tyvars
  (`ctps`) from the method-tyvars (`etps`) — mirroring the existing `List.splitAt numParentTypars tps`
  split but keyed on the class from the map instead of `DeclaringEntity` (which is `ParentNone`).

## Implementation notes - using InnerLambdaDeclaringTyconsOf to replace invalid TryDeclaringEntity uses for typar splitting


- The four previously-broken sites (Pass2 ambients, Pass3 fHat typing, Pass4 wrapper tyargs, TransApp call-site tyargs) all need (a) the host class Tycon or (b) its Typars; Tycon (TypedTree.fs:938) exposes both .Typars : Typar list and .IsModuleOrNamespace, so Zmap<Val, Tycon> is a drop-in replacement for the Parent tcref pattern - no new type needed.
- valOrder (ExprConstruction.fs:42) is a Stamp-based IComparer<Val>, so map keys are the same Val object (stamp) that is bound by TBind, referenced as Expr.Val, and resolved via ValRef.Deref - Pass2 passes, Pass4 can read one shared map keyed by the same Val.
- ClearValReprInfo (TypedTreeOps.ExprOps.fs:2379) is f.SetValReprInfo None; f - it is identity on the Val (same stamp), so the shadow let fOrig = ClearValReprInfo fOrig in fRebinding does NOT change the map key: lookups by fOrig before or after the shadow are equivalent and we can compute fHoming/hostingSplit before the shadow.
- BodyReferencesTypeScopedPrivate (the one site to keep using TryDeclaringEntity) matches vref (the ValRef at a reference site, i.e. the private member being invoked) rather than the local Val, so that site is still correct and must not be changed; the invalid sites matched the local Val whose declaring entity is ParentNone.
- HomingKind (HostingClass | HelperClass) is the only thing derived from g.realsig in the file (Pass1 line 378); the typar-splitting sites only need (a) the host class Tycon from the map and (b) its Typars. No other site in the file reads g.realsig, so the map threads through Pass2, Pass3 (via envp.ep_ctps) and Pass4 (via envp.ep_ctps + arityM homing) without new gating.
- The two wrapper/call-site predicate pairs (fHoming = HostingClass && not (isNil ep_ctps) && <has host>) were previously duplicated with TryDeclaringEntity; I collapsed each into a local let hostingSplit = ... (fRebinding, TransApp) so the condition is written once per site - reducing the risk of the two branches diverging.

coding:
When adding code to an F# source code file
always check if the line follwing your insertion point is an and binding.  if it is and you are adding a let binding, make your let binding an and binding also.



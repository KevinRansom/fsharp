# TailCallChecks.fs

**Purpose**
Implements tail-call analysis over the optimized TAST of a file, analogous to the `PostInferenceChecks`
traversal. For functions annotated with the `[<TailCall>]` attribute (`WellKnownValAttributes.TailCallAttribute`),
it walks the recursive scope of the function and emits a warning (`FSComp.SR.chkNotTailRecursive`) if the
function is called in a non-tail-recursive manner, or if a tail-call blocker is present (byref arguments,
`newobj`/`super`/self-init calls, constrained/calls, DllImport, pinned locals, curried leftover args,
non-void return that must generate a trailing `unit`). The `ModuleOrNamespaceContents` are not mutated.

**Namespace(s)**
`module internal FSharp.Compiler.TailCallChecks`

**Public API surface**
- `CheckImplFile: TcGlobals -> Import.ImportMap -> bool (reportErrors) -> ModuleOrNamespaceContents -> unit` — the single public entry; performs the TailCall analysis on the optimized TAST for a file.

**Types declared**
- `TailCallReturnType` — `MustReturnVoid` ("has unit return type and must return void") | `NonVoid`.
- `TailCall` — `Yes of TailCallReturnType | No`, capturing "is this call in a tail position, and what
  must the return be"; static helpers `IsVoidRet`, `YesFromVal`, `YesFromExpr`; member `AtExprLambda`
  (inside a lambda-expression that is itself a value, the return is `NonVoid` — must return `unit`, not void).
- `cenv` — check environment: `stackGuard`, `g`, `amap`, `mustTailCall: Zset<Val>` (values marked
  `[<TailCall>]` in the module), `hasPinnedLocals` (pinned locals block tail calls).
- `PermitByRefExpr` — context for byref permission when traversing (mirrors `PostInferenceChecks`).

**Active patterns / helpers**
- `(|ValUseAtApp|_|) e` — recognizes a value use as the function part of an application (or a bare val).
- `hasTailCallAttrib` — O(1) `attribsHaveValFlag` check with a fallback that matches user-defined shadow
  types of `Microsoft.FSharp.Core.TailCallAttribute` by full name.
- `IsValRefIsDllImport g vref` — detects `[<DllImport>]` values (never tail-callable).
- `CheckForNonTailRecCall cenv expr tailCall` — the core test: for an `Expr.App` whose function is a
  `[<TailCall>]`-marked value, computes `canTailCall` from the value's `ValReprInfo` (curried arg split,
  `GetMemberCallInfo` flags `isNewObj`/`isSuperInit`/`isSelfInit`, `PossibleConstrainedCall`, byref
  args, `mustGenerateUnitAfterCall` from the declared return type vs. required return) and warns otherwise.

**Recursive check family** (`and`-block, each threading a `tailCall: TailCall`)
- `CheckExprNoByrefs`, `CheckCall`, `CheckCallWithReceiver`, `CheckExprLinear`, `CheckExpr`,
  `CheckStructStateMachineExpr`, `CheckObjectExpr`, `CheckFSharpBaseCall`, `CheckILBaseCall`,
  `CheckApplication`, `CheckLambda`, `CheckTyLambda`, `CheckMatch`, `CheckLetRec`
  (`CheckStaticOptimization`), `CheckMethods`, `CheckMethod`, `CheckInterfaceImpl(s)`, `CheckExprOp`,
  `CheckLambdas`, `CheckExprs(NoByRefLike|PermitByRefLike)`,
  `CheckExprPermitByRefLike`, `CheckExprPermitReturnableByRef`,
  `CheckDecisionTree*` (`Targets`/`Target`/`DecisionTree`/`Switch`/`Test`), `CheckBinding(s)`,
  `CheckModuleBinding`, `CheckDefnsInModule`, `CheckDefnInModule`, `CheckModuleSpec`.

**Significant internal logic**
- The traversal tracks "am I in a tail position" via the `TailCall` value threaded through every
  `Check*` function: `Yes(returnType)` at the top of a `[<TailCall>]` function body, degraded to `No` in
  non-tail positions (e.g. under a non-final `let` binding, in a lambda that is stored as a value, in the
  first branch of a sequential before the tail position, etc.), and adjusted by `AtExprLambda` for
  lambda expressions used as values.
- `CheckForNonTailRecCall` recognizes the specific IL-level blockers listed in the source comment
  (newobj/super/self-init, byref args, DllImport, constrained calls, pinned locals, trailing curried args,
  must-generate-unit) — these prevent the IL emitter from using a true tail call, so a `[<TailCall>]`
  contract is violated.
- Recursion through module structure (`CheckDefnsInModule`/`CheckModuleSpec`/`CheckModuleBinding`)
  resets the "must tail call" tracking per module binding, so `[<TailCall>]` marks only apply within the
  mutual recursive scope of the marked function.
- Uses `StackGuard` (from `Internal.Utilities`) to bound recursion depth.

**Cross-references**
- `TailCallChecks.fsi` — public contract (the single `CheckImplFile` entry).
- `PostInferenceChecks.fs` (sibling) — the analogous byref/limit traversal; this module re-threads similar
  `PermitByRefExpr`/`CheckExpr*` structure for the tail-call concern.
- `AttributeChecking.fsi` (sibling) — `WellKnownValAttributes.TallCallAttribute` / `attribsHaveValFlag`
  (via `AttributeChecking`/`CheckBasics`) used by `hasTailCallAttrib`.
- `TypeRelations.fsi` / `TypedTree` (`Expr`, `Val`) — the TAST being traversed.
- `CheckDeclarations.fs` (sibling) — drives the post-check passes (including this one) over the file.

Discoveries.md
==============

## Part 1 — realsig+ re-homing: thread the lost declaring class into TLR (threading only)

- `MakeTopLevelRepresentationDecisions` (`InnerLambdasToTopLevelFuncs.fs:1473`) already walks the
  *same* `CheckedImplFile` that carries the class context; the member body of an F# class lives at
  `TMDefRec.bindings → ModuleOrNamespaceBinding.Binding (TBind(memberVal, body))`, and `ExprFolder`
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

# LowerCalls.fs

**Purpose**: A small TAST rewrite pass that expands under-applied (partially applied) values of statically-known arity into lambda expressions, and beta-reduces (binds) the known arguments. This normalizes call shape so that subsequent optimization (the peephole optimizer in `Optimizer.fs`) sees uniform applications.

**Namespace / module declared**: `FSharp.Compiler.LowerCalls` (internal module; contract in `LowerCalls.fsi`)

**API surface**:
- `InterceptExpr g cont expr -> Expr voption` — the interception function for `RewriteImplFile`:
  - `Expr.Val` of a value with known `ValReprInfo` -> `AdjustValForExpectedValReprInfo` (eta-expand to the expected representation form).
  - `Expr.App (Val v, ...)` with known arity -> if under-applied, adjust `v` and then `MakeApplicationAndBetaReduce` to bind known args; otherwise just rebuild the application.
  - Other applications -> `MakeApplicationAndBetaReduce`.
  - Anything else -> `None` (no intercept).
- `LowerImplFile g assembly -> CheckedImplFile` — runs `InterceptExpr` as the `PreIntercept` of a `RewriteImplFile` over the whole file. Stack guard: `"LowerCallsRewriteStackGuardDepth"`.

**Significant internal logic**:
- The pass only fires for values with `Some` arity information in `ValReprInfo`; values without static arity info are left untouched.
- Adjustment uses `AdjustValForExpectedValReprInfo` (from `TypedTreeOps`) to produce the eta-expanded lambda shape; argument binding goes through `MakeApplicationAndBetaReduce`.
- Rewritten expressions are explicitly expected to be further optimized by `Optimizer.fs`; this pass is not self-sufficient.

**Cross-references**:
- Signature: `LowerCalls.fsi`.
- Depends on `FSharp.Compiler.TypedTree` / `FSharp.Compiler.TypedTreeOps` (`AdjustValForExpectedValReprInfo`, `MakeApplicationAndBetaReduce`, `RewriteImplFile`, `StackGuard`) and `FSharp.Compiler.DiagnosticsLogger`.
- Pipeline sibling: `src/Compiler/Optimize/Optimizer.fs` (subsequent peephole optimization).
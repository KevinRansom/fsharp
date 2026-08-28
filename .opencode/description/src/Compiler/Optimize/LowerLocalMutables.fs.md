# LowerLocalMutables.fs

**Purpose**: Rewrites mutable local variables that *escape* (are captured by inner lambdas or returned out of their scope) into heap-allocated reference cells. Locals that are not captured remain as simple locals. The pass is run over an entire implementation file at once, so escape analysis is whole-file.

**Namespace / module declared**: `FSharp.Compiler.LowerLocalMutables` (internal module; contract in `LowerLocalMutables.fsi`)

**API surface**:
- `TransformImplFile: g: TcGlobals -> amap: ImportMap -> implFile: CheckedImplFile -> CheckedImplFile` (also `DecideImplFile`, `DecideEscapes`, `DecideLambda`, `DecideExpr`, `DecideExprOp`, `DecideBinding`, `DecideBindings` — the analysis steps) — decide and apply the mutable-local-to-ref-cell rewrites.
- `TransformExpr` / `TransformBinding` — rewrite fetches/stores/addr-of for promoted locals; rewrite bindings to allocate the reference cell.

**Environment**:
- `cenv = { g: TcGlobals; amap: ImportMap }` — the local analysis environment.

**Significant internal logic**:
- `DecideEscapes syntacticArgs body` — the core escape rule: a mutable local `v` is promoted iff it is not in the `syntacticArgs` set, `v.IsMutable`, `v.ValReprInfo.IsNone` (i.e. not already a "top-level" value), and not known to be only mutated before first use (`Optimizer.IsKnownOnlyMutableBeforeUse`).
- `DecideLambda` / `DecideExpr` / `DecideExprOp` — walk lambda, object expression, and special `Expr.Op` cases (`While`, `TryFinally`, `IntegerForLoop`, `TryWith`) that contain inner lambda bodies, accumulating the escape set.
- `DecideBinding` / `DecideBindings` — extend the escape set for non-recursive and recursive binding groups.
- `DecideImplFile` — drive an `ExprFolder0` over the file, intercepting binding groups to run the analysis.
- **Rewrite**: for each escaped local, allocate a new `mkLocal` (or `mkCompGenLocal`) of type `mkRefCellTy g localVal.Type`, emit a `mkRefCell` allocation in the binding's RHS, and rewrite:
  - Reads (`Expr.Val`) -> `mkRefCellGet`
  - Writes (`TOp.LValueOp LSet`) -> `mkRefCellSet`
  - Address-of (`TOp.LValueOp LAddrOf`) -> `mkRecdFieldGetAddrViaExprAddr` of the cell's content field
- Emits an `abImplicitHeapAllocation` diagnostic (compiler warning) for each promoted local that is a user-visible name.
- Rewriting is applied through `RewriteImplFile` with `PreIntercept = Some(TransformExpr ...)` and `PreInterceptBinding = Some(TransformBinding ...)`; the stack guard is `"AutoboxRewriteStackGuardDepth"`; quote rewriting is enabled.

**Cross-references**:
- Signature: `LowerLocalMutables.fsi`.
- Depends heavily on `FSharp.Compiler.TypedTree`/`TypedTreeBasics`/`TypedTreeOps`, and calls `Optimizer.IsKnownOnlyMutableBeforeUse` from `src/Compiler/Optimize/Optimizer.fs`.
- Pipeline sibling in `src/Compiler/Optimize/`.
- The resulting "cell" objects (boxed `byref` of `'T`) are what `EraseClosures` / `EraseUnions` later operate on at the ILX level.
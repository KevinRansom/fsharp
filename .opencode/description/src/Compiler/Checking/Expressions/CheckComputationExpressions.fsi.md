# CheckComputationExpressions.fsi

**Purpose**
Public contract (internal module) for computation-expression typechecking. Exposes the single entry point
`TcComputationExpression`, which checks a computation expression given the resolved builder expression, its
type, and the syntactic body.

**Namespace(s)**
`module internal FSharp.Compiler.CheckComputationExpressions`

**Public API surface** (complete)
- `TcComputationExpression : cenv: TcFileState -> env: TcEnv -> overallTy: OverallTy -> tpenv: UnscopedTyparEnv -> mWhole: range * interpExpr: Expr * builderTy: TType * comp: SynExpr -> Expr * UnscopedTyparEnv` — typecheck a computation expression; `interpExpr` is the (already resolved) builder expression, `builderTy` its type, `comp` the syntactic computation body.

**Significant notes**
- The .fsi is deliberately minimal: the entire translation engine (context records, custom-op discovery,
  the syntactic `Return`/`Bind`/... desugaring, query/source handling) is implementation detail of
  `CheckComputationExpressions.fs`. Callers only see the single entry point and its
  `OverallTy`/`UnscopedTyparEnv`-based signature (matching the rest of `CheckExpressions.fsi`).

**Cross-references**
- `CheckComputationExpressions.fs` — the implementation.
- `CheckComputationExpressionsCustomOps.fs` — the sibling module the implementation uses for overloaded
  custom-operation resolution reporting (fixes #11612 / #15206).
- `CheckExpressions.fsi` (sibling) — the `TcExpr`/`OverallTy`/`UnscopedTyparEnv` conventions this
  signature follows; the direct caller of `TcComputationExpression`.
- `CheckBasics.fsi` (Checking dir) — `TcFileState`, `TcEnv`, `UnscopedTyparEnv` types.

# DetupleArgs.fsi

**Purpose**: Signature file for the `FSharp.Compiler.Detuple` module (implementation in `DetupleArgs.fs`). Declares the external contract of the "tuple collapse" pass that eliminates redundant tuple allocations at call sites of inner functions written in uncurried form.

**Namespace / module declared**: `module internal FSharp.Compiler.Detuple` (internal — the surface is compiler-only).

**API declared**:
- `DetupleImplFile: PerFileNamingScope -> CcuThunk -> TcGlobals -> CheckedImplFile -> CheckedImplFile` — transform one implementation file by de-tupling inner-function call arguments.

**Nested module `GlobalUsageAnalysis` contract**:
- `accessor` — opaque (internal) type describing per-use-site tuple projection.
- `Results` record — the call-site usage analysis result for an implementation file:
  - `Uses: Zmap<Val, (accessor list * TType list * Expr list) list>` — per value, the contexts in which it is used (call patterns).
  - `Defns: Zmap<Val, Expr>` — value -> its binding representation.
  - `DecisionTreeBindings: Zset<Val>` — values bound inside a decision tree.
  - `RecursiveBindings: Zmap<Val, bool * Vals>` — value -> (recursive? * the other values in the mutual binding).
  - `TopLevelBindings: Zset<Val>` — values not defined under lambdas.
  - `IterationIsAtTopLevel: bool` — whether the analysis iteration itself was at top level.
- `GetUsageInfoOfImplFile: TcGlobals -> CheckedImplFile -> Results` — run the usage analysis.
- `GetValsBoundInExpr: Expr -> Zset<Val>` — values bound in an expression.

**Notes**:
- Dependencies: `Internal.Utilities.Collections` (Zmap/Zset), `FSharp.Compiler.CompilerGlobalState`, `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypedTree`.
- The detailed algorithm (call-pattern intersection, choice of replacement formals, rebinds/rebuildTuple fixups) is documented in comments of `DetupleArgs.fs`, not in this signature.

**Cross-references**: `DetupleArgs.fs` (implementation); pipeline sibling in `src/Compiler/Optimize/`; driven from `Optimizer.fs`.
# DetupleArgs.fs

**Purpose**: A "tuple collapse" optimization pass that eliminates tuple allocations made at call sites by functions written in uncurried style. Where every call site of a private, non-top-level inner function passes an explicit tuple, the function is rewritten to take the individual tuple fields instead, and the call sites are rewritten to pass the fields directly.

**Namespace / module declared**: `FSharp.Compiler.Detuple` (internal module; contract in `DetupleArgs.fsi`)

**API surface**:
- `DetupleImplFile: PerFileNamingScope -> CcuThunk -> TcGlobals -> CheckedImplFile -> CheckedImplFile` — entry point; runs the whole pass over one implementation file.
- Nested `GlobalUsageAnalysis` module:
  - `GetValsBoundInExpr: Expr -> Zset<Val>` — values bound under an expression.
  - `Results` record — global usage analysis result: `Uses` (per-val list of call contexts `accessor list * TType list * Expr list`), `Defns` (val -> binding expr), `DecisionTreeBindings`, `RecursiveBindings` (val -> `recursive? * others`), `TopLevelBindings`, `IterationIsAtTopLevel`.
  - `GetUsageInfoOfImplFile: TcGlobals -> CheckedImplFile -> Results` — the analysis proper.
  - `accessor` — opaque type describing how a tuple field is projected at a use site.

**Key concepts from the in-code design comments**:
- Top-level F# functions/methods already get de-tupled automatically by choice of representation; this pass targets inner functions only, and only those not given TLR (lambda-lifting) representation.
- The transform (informal): `let rec fOrig p = ...` where all calls are `fOrig (a, b)` becomes `let rec transformedVal p1 p2 = let p = p1, p2 ...` with calls `transformedVal a b`.
- Chosen call-pattern: for each arg, component-wise intersect the known tuple structure across *all* call patterns, extended with `UnknownTS` to the max arity; if a formal's type itself does not expect a tuple, the split is refused.

**Internal structure** (implementation overview):
- Collects per-function call-pattern info in a pre-pass (the rewrite itself does not change call patterns, so a single collection suffices).
- Chooses replacement formals per formal: `SameArg xi` (kept as-is), `NewArgs [...]` (split into individual args; unit arg is a special case).
- Rewrites definition bindings: new formals followed by `rebinds` (`rebuildTuple` / projection bindings) around the fixed-up body.
- Fixups call sites to the de-tupled application.

**Cross-references**:
- Sibling `DetupleArgs.fsi` (signature).
- Runs in the optimization pipeline orchestrated by `src/Compiler/Optimize/Optimizer.fs`, alongside `InnerLambdasToTopLevelFuncs.fs` (TLR decisions) and `LowerCalls.fs` (arity adjustment).
- Operates on `CheckedImplFile` (TypedTree, `FSharp.Compiler.TypedTree`) with utilities from `FSharp.Compiler.TypedTreeOps`, `FSharp.Compiler.TypedTreeBasics`, `Internal.Utilities.Collections` (Zmap/Zset), `FSharp.Compiler.CompilerGlobalState`.
# LowerComputedCollections.fsi

**Purpose**: Signature file for `FSharp.Compiler.LowerComputedCollectionExpressions` (implementation in `LowerComputedCollections.fs`). Declares the contract of the lowering pass that rewrites computed list/array collection expressions into direct builder-based calls.

**Namespace / module declared**: `module internal FSharp.Compiler.LowerComputedCollectionExpressions` (internal, compiler-use only).

**API declared**:
- `LowerComputedListOrArrayExpr: tcVal: ConstraintSolver.TcValF -> g: TcGlobals -> amap: ImportMap -> ilTyForTy: (TType -> ILType) -> overallExpr: Expr -> Expr option` — recognize and lower a computed list or array expression. Returns `None` if the expression is not one of the recognized shapes.

**Dependencies opened**: `FSharp.Compiler.AbstractIL.IL` (`ILType`), `FSharp.Compiler.Import` (`ImportMap`), `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypedTree` (`Expr`).

**Cross-references**: `LowerComputedCollections.fs` (implementation); invoked by `Optimizer.fs`; sibling lowering passes `LowerSequences.fs`, `LowerStateMachines.fs`, `LowerLocalMutables.fs` in `src/Compiler/Optimize/`.
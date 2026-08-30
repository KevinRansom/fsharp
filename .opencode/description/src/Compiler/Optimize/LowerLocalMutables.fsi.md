# LowerLocalMutables.fsi

**Purpose**: Signature file for `FSharp.Compiler.LowerLocalMutables` (implementation in `LowerLocalMutables.fs`). Declares the entry point for rewriting mutable local variables captured by inner lambdas into heap-allocated reference cells.

**Namespace / module declared**: `module internal FSharp.Compiler.LowerLocalMutables` (internal, compiler-use only).

**API declared**:
- `TransformImplFile: g: TcGlobals -> amap: ImportMap -> implFile: CheckedImplFile -> CheckedImplFile` — documented as: "Rewrite mutable locals to reference cells across an entire implementation file."

**Dependencies opened**: `FSharp.Compiler.Import` (`ImportMap`), `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypedTree` (`CheckedImplFile`).

**Cross-references**: `LowerLocalMutables.fs` (implementation; contains the `cenv` type, the `Decide*` analysis functions, and `TransformExpr`/`TransformBinding` writers). Part of the pipeline in `src/Compiler/Optimize/` (orchestrated by `Optimizer.fs`).
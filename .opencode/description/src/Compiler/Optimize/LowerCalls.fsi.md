# LowerCalls.fsi

**Purpose**: Signature file for `FSharp.Compiler.LowerCalls`. Declares the contract of the pass that eta-expands under-applied values of known arity and beta-reduces their known arguments.

**Namespace / module declared**: `module internal FSharp.Compiler.LowerCalls` (internal, compiler-use only).

**API declared**:
- `LowerImplFile: g: TcGlobals -> assembly: CheckedImplFile -> CheckedImplFile` — documented as: "Expands under-applied values of known arity to lambda expressions, and then reduces to bind any known arguments. The results are later optimized by Optimizer.fs."

**Dependencies opened**: `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypedTree` (CheckedImplFile).

**Cross-references**: `LowerCalls.fs` (implementation); `Optimizer.fs` (the downstream optimization stage).
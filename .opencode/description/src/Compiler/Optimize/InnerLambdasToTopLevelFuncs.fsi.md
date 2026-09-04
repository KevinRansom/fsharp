# InnerLambdasToTopLevelFuncs.fsi

**Purpose**: Signature file for the TLR pass (`FSharp.Compiler.InnerLambdasToTopLevelFuncs`, implementation in `InnerLambdasToTopLevelFuncs.fs`). Exposes the single entry point that turns inner lambdas into top-level functions with explicit free-value parameters where beneficial.

**Namespace / module declared**: `module internal FSharp.Compiler.InnerLambdasToTopLevelFuncs` (internal, compiler-use only).

**API declared**:
- `MakeTopLevelRepresentationDecisions: amap: ImportMap -> scope: PerFileNamingScope -> ccu: CcuThunk -> g: TcGlobals -> expr: CheckedImplFile -> CheckedImplFile` — run the TLR decision + rewrite over one typed implementation file.

**Dependencies opened**: `FSharp.Compiler.Import` (ImportMap, CcuThunk), `FSharp.Compiler.CompilerGlobalState` (PerFileNamingScope), `FSharp.Compiler.TypedTree` (CheckedImplFile), `FSharp.Compiler.TcGlobals`.

**Notes**:
- All of the pass's internal machinery (Pass1 DTR/arity decisions, Pass2 required-item analysis, environment-pack choice, Pass4 rewrite) is private to the implementation file; only `MakeTopLevelRepresentationDecisions` is part of the contract.
- Called from the optimization pipeline in `src/Compiler/Optimize/Optimizer.fs`.

**Cross-references**: `InnerLambdasToTopLevelFuncs.fs` (implementation); `Optimizer.fs`; related to TLR-representation `ValReprInfo` consumed by `LowerCalls.fs`, `DetupleArgs.fs`, and the ILX erasure in `EraseClosures.fs`.
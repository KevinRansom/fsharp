# EraseClosures.fsi

**Purpose**: Signature file for `FSharp.Compiler.AbstractIL.ILX.EraseClosures` (implementation in `EraseClosures.fs`). Declares the compact contract of the pass that takes an ILX closure definition and produces the .NET-level types (delegates, closure classes) plus the rewritten method bodies in which indirect closure calls become direct IL calls.

**Namespace / module declared**: `/// Compiler use only.  Erase closures` — `module internal FSharp.Compiler.AbstractIL.ILX.EraseClosures` (internal, compiler-use only).

**API declared** (this .fsi is intentionally minimal — most of the implementation's internals are private to the .fs):
- `type cenv` — the erasure context (opaque to callers); carries `ILGlobals`, the `FSharpFunc` type-ref array, the `FSharpTypeFunc` boxed type, and the attribute-stamping callbacks.
- `newIlxPubCloEnv: ilg: ILGlobals * addMethodGeneratedAttrs: (ILMethodDef -> ILMethodDef) * addFieldGeneratedAttrs: (ILFieldDef -> ILFieldDef) * addFieldNeverAttrs: (ILFieldDef -> ILFieldDef) -> cenv` — build a context.
- `mkILTyFuncTy: cenv -> ILType` — the "type function" boxed type used for polymorphic closures.
- `mkILFuncTy: cenv -> ILType -> ILType -> ILType` — a 1-arg `FSharpFunc` delegate type.
- `mkTyOfLambdas: cenv -> IlxClosureLambdas -> ILType` — delegate type for a closure-lambda chain.
- `mkCallFunc: cenv -> allocLocal: (ILType -> uint16) -> numThisGenParams: int -> ILTailcall -> IlxClosureApps -> ILInstr list` — the main call-site emitter: turn an abstract indirect application (`IlxClosureApps`) into a list of IL instructions. The `allocLocal` callback lets the caller register the temporary locals that `mkCallFunc` may need for multi-arg calls. `numThisGenParams` is the number of generic parameters of the enclosing `this`.
- `convIlxClosureDef: cenv -> encl: string list -> ILTypeDef -> IlxClosureInfo -> ILTypeDef list` — the top-level translation entry: given an ILX closure type def and its info, emit the corresponding (possibly multiple) .NET `ILTypeDef`s (delegate wrapper(s), closure class, etc.).

**Dependencies opened**: `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.AbstractIL.ILX.Types`.

**Cross-references**: `EraseClosures.fs` (implementation; ~800 lines — includes private helpers `mkTyOfApps`, `mkMethSpecForMultiApp`, `mkCallBlockForMultiValueApp`, `convMethodBody`/`convMethodDef`, `mkLdFreeVar`, `mkILCloFldDefs`, etc.); driven from `IlxGen.fs`; related to `EraseUnions.fs` (sibling erasure pass) and `EraseUnions.Types.fs` / `EraseUnions.Emit.fs`; all inside `src/Compiler/CodeGen/`.
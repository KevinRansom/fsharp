# IlxGenSupport.fsi

**Purpose**: Signature file for `FSharp.Compiler.IlxGenSupport` (implementation in `IlxGenSupport.fs`). Declares a small set of shared ILX-generator helpers — mostly attribute construction and name-uniqueification utilities — that are reused by `IlxGen.fs` and the union/closure erasure passes.

**Namespace / module declared**: `/// The ILX generator.` — `module internal FSharp.Compiler.IlxGenSupport` (internal, compiler-use only).

**API declared**:
- `mkLdfldMethodDef: ilMethName: string * iLAccess: ILMemberAccess * isStatic: bool * ilTy: ILType * ilFieldName: string * ilPropType: ILType * retTyAttrs: ILAttributes * customAttrs: ILAttribute list -> ILMethodDef` — build a simple `ldfld` accessor method (the `getter`/`setter` body over a single field).
- `GetDynamicDependencyAttribute: g: TcGlobals -> memberTypes: int32 -> ilType: ILType -> ILAttribute` — build a `[DynamicDependency]` attribute (used by union/struct erasure to preserve trimming of referenced types).
- `GenReadOnlyModReqIfNecessary: g: TcGlobals -> ty: TypedTree.TType -> ilTy: ILType -> ILType` — add the `modreq(ReadOnly)` to `ilTy` when `ty` is a F# record/struct with no mutable members.
- `GenAdditionalAttributesForTy: g: TcGlobals -> ty: TypedTree.TType -> ILAttribute list` — any extra type-level attributes implied by the F# type (e.g. `IsUnmanagedAttribute`, `DynamicallyAccessedMembers`, etc.).
- `GetReadOnlyAttribute` / `GetIsUnmanagedAttribute` — the individual attribute builders.
- `GetNullableAttribute: g: TcGlobals -> nullnessInfos: TypedTree.NullnessInfo list -> ILAttribute` — build the `[System.Diagnostics.CodeAnalysis.Nullable]` attribute from a list of per-element nullness states.
- `GetNullableContextAttribute: g: TcGlobals -> byte -> ILAttribute` — the `[NullableContext]` attribute on a scope.
- `GetNotNullWhenTrueAttribute: g: TcGlobals -> string array -> ILAttribute` — build `[NotNullWhen(true)]` for a set of property names.
- `ChooseUniqueName: baseName: string -> existingNames: Set<string> -> string` — return `baseName` if it does not collide with any name in `existingNames`, otherwise `baseName0`, `baseName1`, `baseName2`, ... until a unique name is found.

**Dependencies opened**: `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.TcGlobals`.

**Cross-references**:
- `IlxGenSupport.fs` — the implementation (~500 lines; also contains `mkFlagsAttribute`, `mkLocalPrivateAttributeWithDefaultConstructor`, `mkLocalPrivateAttributeWithPropertyConstructors`, `mkLocalPrivateAttributeWithByteAndByteArrayConstructors`, `mkLocalPrivateInt32Enum`, `GenReadOnlyIfNecessary`, `GenNullnessIfNecessary`, `GetNullnessFromTType` — helpers for F#-specific attribute emission used by `IlxGen.fs` and the `EraseUnions.*` passes).
- Consumers: `IlxGen.fs` (attribute emission, nullable-attribute generation), `EraseUnions.fs` / `EraseUnions.Emit.fs` (via `GetDynamicDependencyAttribute` etc.).
- All inside `src/Compiler/CodeGen/`.
# ILDeltaHandles.fs

**Purpose**
F# types and utilities for hot-reload delta metadata emission: typed handle DU types wrapping row ids, typed ECMA-335 coded-index unions, token arithmetic (`DeltaTokens`), EnC operation codes, and IL exception-region types — all intentionally delta-owned so the hot-reload pipeline stays isolated from mainline core-IL signature churn (with boundary adapters for crossing into `ilwrite`/`ilbinary` row models).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILDeltaHandles`)

**Structs**
- `EntityToken { TableIndex; RowId }` — generic EncLog/EncMap token with `Token` (`table<<24 | rowId`).
- Row-id handle structs (each a `of rowId: int` DU with a `RowId` member): `ModuleHandle`, `TypeRefHandle`, `TypeDefHandle`, `FieldHandle`, `MethodDefHandle`, `ParamHandle`, `InterfaceImplHandle`, `MemberRefHandle`, `DeclSecurityHandle`, `StandAloneSigHandle`, `EventHandle`, `PropertyHandle`, `ModuleRefHandle`, `TypeSpecHandle`, `AssemblyHandle`, `AssemblyRefHandle`, `FileHandle`, `ExportedTypeHandle`, `ManifestResourceHandle`, `GenericParamHandle`, `MethodSpecHandle`, `GenericParamConstraintHandle`.
- Heap offset/index structs: `StringOffset`, `BlobOffset`, `GuidIndex`, `UserStringOffset` (each with `Value` and `Zero`).
- `IlExceptionRegion { Kind; TryOffset; TryLength; HandlerOffset; HandlerLength; CatchTypeToken; FilterOffset }` — replaces `System.Reflection.Metadata.ExceptionRegion` for delta emission.

**Unions (coded indices, ECMA-335 II.24.2.6)** — all expose `CodedTag`/`RowId` (or `TableIndex`/`RowId`):
- `TypeDefOrRef` (TDR_TypeDef/TypeRef/TypeSpec), `HasCustomAttribute` (22 cases), `MemberRefParent` (5 cases), `HasSemantics` (Event/Property), `CustomAttributeType` (MethodDef/MemberRef), `ResolutionScope` (Module/ModuleRef/AssemblyRef/TypeRef), `MethodDefOrRef`, `HasConstant` (Field/Param/Property), `HasFieldMarshal`, `HasDeclSecurity`, `MemberForwarded`, `Implementation` (File/AssemblyRef/ExportedType), `TypeOrMethodDef`.

**Enums**
- `IlExceptionRegionKind` — Catch=0, Filter=1, Finally=2, Fault=4.
- `EditAndContinueOperation` (struct, equality on `Value`) — Default=0, AddMethod=1, AddField=2, AddParameter=3, AddProperty=4, AddEvent=5; matches CLR EnC/SRM codes.

**Modules**
- `CoreTypeAdapters` — boundary-safe `(codedTag, rowId)` projections (e.g. `typeDefOrRefParts`, `memberRefParentParts`, `methodDefOrRefParts`, `resolutionScopeParts`) so delta code can cross into core row models via primitives.
- `DeltaTokens` — `TableCount = 64`; token primitives `getRowNumber`, `getTableIndex`, `makeToken(TableName, row)`, `makeTokenFromIndex`, `toEntityToken`/`fromEntityToken`; Portable PDB table indices (0x30-0x37: Document, MethodDebugInformation, LocalScope, LocalVariable, LocalConstant, ImportScope, StateMachineMethod, CustomDebugInformation).
- `HandleConversions` — `tryMake*` inverse constructors from `(tableIndex, rowId)` for HasCustomAttribute / ResolutionScope / MemberRefParent / CustomAttributeType / TypeDefOrRef.

**Cross-references**
- `BinaryConstants.fs` (TableName, tag constants), `DeltaMetadataTables.fs`, `DeltaMetadataSerializer.fs`, `DeltaIndexSizing.fs`, `DeltaTableLayout.fs`, `FSharpDeltaMetadataWriter.fs`

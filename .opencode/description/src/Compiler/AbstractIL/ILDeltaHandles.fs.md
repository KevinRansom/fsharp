# ILDeltaHandles.fs

## Pipeline role

Part of the AbstractIL delta metadata (EnC hot-reload) writer infrastructure. This module defines F#-native types and utilities for hot reload delta metadata emission: typed metadata handles, the ECMA-335 coded-index unions (`TypeDefOrRef`, `HasCustomAttribute`, `MemberRefParent`, `HasSemantics`, `CustomAttributeType`, `ResolutionScope`, `MethodDefOrRef`, `HasConstant`, `HasFieldMarshal`, `HasDeclSecurity`, `MemberForwarded`, `Implementation`, `TypeOrMethodDef`), token arithmetic (`DeltaTokens`), EncLog operation codes, exception-region models, and conversion helpers. These are intentionally delta-owned to isolate the hot-reload pipeline from broad mainline signature churn; adapters convert between delta-owned and core-owned representations at boundary crossings (the core IL writer keeps its own row models).

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.ILDeltaHandles` (module `internal`)
- Uses: `System`, `FSharp.Compiler.AbstractIL.BinaryConstants`.

## Types — entity token

- `EntityToken` (`[<Struct>]` record) — `{ TableIndex: int; RowId: int }`, the generic token representation for EncLog/EncMap entries.
  - Static `Create(tableIndex, rowId)`.
  - `Token` — the full 32-bit token value `(TableIndex <<< 24) ||| (RowId &&& 0x00FFFFFF)`.

## Types — handles

All single-case `[<Struct>]` DUs exposing `RowId` (except note): `ModuleHandle`, `TypeRefHandle`, `TypeDefHandle`, `FieldHandle`, `MethodDefHandle`, `ParamHandle`, `InterfaceImplHandle`, `MemberRefHandle`, `DeclSecurityHandle`, `StandAloneSigHandle`, `EventHandle`, `PropertyHandle`, `ModuleRefHandle`, `TypeSpecHandle`, `AssemblyHandle`, `AssemblyRefHandle`, `FileHandle`, `ExportedTypeHandle`, `ManifestResourceHandle`, `GenericParamHandle`, `MethodSpecHandle`, `GenericParamConstraintHandle` (one-of `rowId: int` each).

## Types — heap reference wrappers

- `StringOffset` (`[<Struct>]`) — `StringOffset of offset: int` with `.Value` and `Zero`.
- `BlobOffset` (`[<Struct>]`) — `BlobOffset of offset: int` with `.Value` and `Zero`.
- `GuidIndex` (`[<Struct>]`) — `GuidIndex of index: int` with `.Value` and `Zero`.
- `UserStringOffset` (`[<Struct>]`) — `UserStringOffset of offset: int` with `.Value` and `Zero`.

## Types — coded indices (with `CodedTag` and `RowId` members)

- `TypeDefOrRef` — `TDR_TypeDef of TypeDefHandle | TDR_TypeRef of TypeRefHandle | TDR_TypeSpec of TypeSpecHandle`.
- `HasCustomAttribute` — `HCA_MethodDef | HCA_Field | HCA_TypeRef | HCA_TypeDef | HCA_Param | HCA_InterfaceImpl | HCA_MemberRef | HCA_Module | HCA_DeclSecurity | HCA_Property | HCA_Event | HCA_StandAloneSig | HCA_ModuleRef | HCA_TypeSpec | HCA_Assembly | HCA_AssemblyRef | HCA_File | HCA_ExportedType | HCA_ManifestResource | HCA_GenericParam | HCA_GenericParamConstraint | HCA_MethodSpec` (22 cases). `CodedTag` maps DeclSecurity to `hca_Permission`; GenericParamConstraint/MethodSpec use explicit tags 20/21.
- `MemberRefParent` — `MRP_TypeDef | MRP_TypeRef | MRP_ModuleRef | MRP_MethodDef | MRP_TypeSpec`. `CodedTag` notes that BinaryConstants does not expose the TypeDef tag on main, so the ECMA tag 0 is explicit here.
- `HasSemantics` — `HS_Event of EventHandle | HS_Property of PropertyHandle`.
- `CustomAttributeType` — `CAT_MethodDef | CAT_MemberRef`.
- `ResolutionScope` — `RS_Module | RS_ModuleRef | RS_AssemblyRef | RS_TypeRef`.
- `MethodDefOrRef` — `MDOR_MethodDef | MDOR_MemberRef`.
- `HasConstant` — `HC_Field of FieldHandle | HC_Param of ParamHandle | HC_Property of PropertyHandle` with `TableIndex` (0x04/0x08/0x17) and `RowId`.
- `HasFieldMarshal` — `HFM_Field | HFM_Param` with `TableIndex` (0x04/0x08).
- `HasDeclSecurity` — `HDS_TypeDef | HDS_MethodDef | HDS_Assembly` with `TableIndex` (0x02/0x06/0x20).
- `MemberForwarded` — `MF_Field | MF_MethodDef` with `TableIndex` (0x04/0x06).
- `Implementation` — `IMP_File | IMP_AssemblyRef | IMP_ExportedType` with `TableIndex` (0x26/0x23/0x27).
- `TypeOrMethodDef` — `TOMD_TypeDef | TOMD_MethodDef` with `TableIndex` and `CodedTag`.

## Modules

### CoreTypeAdapters

Boundary-safe conversions to primitives (keeps hot reload isolated without widening the core `ilbinary.fsi` API surface):
- `moduleRowId`, `typeRefRowId`, `typeDefRowId`, `memberRefRowId`, `methodDefRowId`, `typeSpecRowId`, `moduleRefRowId`, `assemblyRefRowId` — unwrap handles to row ids.
- `typeDefOrRefParts`, `memberRefParentParts`, `methodDefOrRefParts`, `resolutionScopeParts` — return `(coded tag, row id)` pairs.

### DeltaTokens

Token arithmetic utilities (replaces `System.Reflection.Metadata.Ecma335.MetadataTokens`):
- `TableCount = 64` — number of ECMA-335 metadata tables (includes reserved slots).
- `getRowNumber token` — lower 24 bits; `getTableIndex token` — upper 8 bits.
- `makeToken (table: TableName) rowNumber` — `(table.Index <<< 24) ||| (rowNumber &&& 0x00FFFFFF)` (internal).
- `makeTokenFromIndex (tableIndex: int) rowNumber` — for PDB tables without `TableName` definitions or external callers.
- `toEntityToken token` / `fromEntityToken entity` — conversions with `EntityToken`.
- Portable PDB table indices: `tableDocument`(0x30), `tableMethodDebugInformation`(0x31), `tableLocalScope`(0x32), `tableLocalVariable`(0x33), `tableLocalConstant`(0x34), `tableImportScope`(0x35), `tableStateMachineMethod`(0x36), `tableCustomDebugInformation`(0x37).

### HandleConversions

- `tryMakeHasCustomAttribute (tableIndex) (rowId)` — table index to `HasCustomAttribute`, `None` for invalid indices (maps 0x06 Method, 0x04 Field, 0x01 TypeRef, 0x02 TypeDef, 0x08 Param, 0x09 InterfaceImpl, 0x0A MemberRef, 0x00 Module, 0x0E DeclSecurity, 0x17 Property, 0x14 Event, 0x11 StandAloneSig, 0x1A ModuleRef, 0x1B TypeSpec, 0x20 Assembly, 0x23 AssemblyRef, 0x26 File, 0x27 ExportedType, 0x28 ManifestResource, 0x2A GenericParam, 0x2C GenericParamConstraint, 0x2B MethodSpec).
- `tryMakeResolutionScope` — 0x00 Module, 0x1A ModuleRef, 0x23 AssemblyRef, 0x01 TypeRef.
- `tryMakeMemberRefParent` — 0x02 TypeDef, 0x01 TypeRef, 0x1A ModuleRef, 0x06 MethodDef, 0x1B TypeSpec.
- `tryMakeCustomAttributeType` — 0x06 MethodDef, 0x0A MemberRef.
- `tryMakeTypeDefOrRef` — 0x02 TypeDef, 0x01 TypeRef, 0x1B TypeSpec.

## Types — Enc operation code

- `EditAndContinueOperation` (`[<Struct; CustomEquality; NoComparison>]` enum-like DU) — `Default`, `AddMethod`, `AddField`, `AddParameter`, `AddProperty`, `AddEvent`, replacing SRM's `EditAndContinueOperation`.
  - `Value` maps to CLR EnC operation codes: Default=0, AddMethod=1, AddField=2, AddParameter=3, AddProperty=4, AddEvent=5.
  - Custom `Equals`/`GetHashCode`/`IEquatable` based on `Value`.

## Types — IL exception regions

- `IlExceptionRegionKind` (enum) — `Catch = 0`, `Filter = 1`, `Finally = 2`, `Fault = 4` (replaces SRM `ExceptionRegionKind`).
- `IlExceptionRegion` (`[<Struct>]` record) — `Kind`, `TryOffset`, `TryLength`, `HandlerOffset`, `HandlerLength`, `CatchTypeToken` (catch type token for Catch; 0 otherwise), `FilterOffset` (filter offset for Filter; 0 otherwise). Replaces SRM `ExceptionRegion` for delta emission.

## Significant internal logic

- The coded-index union model carries both `CodedTag` (the ECMA-335 low-bit tag) and the typed `RowId`; this decouples the serializer from raw integer tag arithmetic.
- All coded-index tag values remain consistent with `BinaryConstants`; where the mainline `BinaryConstants` does not expose a tag (e.g. `MemberRefParent` TypeDef=0), the ECMA-335 value is stated explicitly with a comment.
- `EditAndContinueOperation` values must match the CLR EnC op codes exactly, since the runtime `CMiniMdRW` interprets the EncLog operand values.
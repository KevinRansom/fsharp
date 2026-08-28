# DeltaMetadataTables.fs

**Purpose**
Hot-reload delta table mirror. Collects AbstractIL-metadata table rows (TypeDef, MethodDef, Field, Param, TypeRef, MemberRef, GenericParam, Property/Event + maps, MethodSemantics, Constant, Nested-Class, InterfaceImpl, MethodImpl, AssemblyRef, StandAloneSig, CustomAttribute, EncLog, EncMap, Module) alongside the SRM metadata builder for deltas emitted by hot reload, and accumulates the delta #Strings/#Blob/#GUID/#US heap bytes so deltas can be serialized directly via AbstractIL (`DeltaMetadataSerializer`).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.DeltaMetadataTables`)

**TypeDefs / internal helpers declared**
- `MetadataHeapOffsets` (record) — baseline heap start offsets (`StringHeapStart`, `BlobHeapStart`, `GuidHeapStart`, `UserStringHeapStart`); `Zero`, `OfHeapSizes` static members.
- `RowTableBuilder` (private class) — grows a `ResizeArray<RowElementData[]>`.
- `StringHeapBuilder` (private class) — dedup'd #Strings entries with ordinal lookup; builds lazy null-terminated UTF8 byte array + per-entry offsets.
- `ByteArrayHeapBuilder` (private class) — dedup'd #Blob/#GUID entries (with a custom `byte[]` comparer); emits compressed-unsigned-length-prefixed blob heap format.
- `UserStringHeapBuilder` (private class) — sparse #US allocation at explicit offsets (delta-local), trimmed/cached byte output.
- `DeltaMetadataTables(?heapOffsets: MetadataHeapOffsets)` (class) — the main delta table/heap builder; accepts baseline heap offsets to place delta entries in the cumulative address space.

**Public API surface** (class members)
- Row builders: `AddModuleRow` (module row + GUID handles mvid/encId/encBaseId), `AddTypeDefinitionRow`, `AddNestedClassRow`, `AddInterfaceImplRow`, `AddConstantRow`, `AddMethodImplRow`, `AddMethodRow(row, body: MethodBodyUpdate)`, `AddFieldRow`, `AddParameterRow`, `AddTypeReferenceRow`, `AddMemberReferenceRow`, `AddMethodSpecificationRow`, `AddTypeSpecificationRow`, `AddGenericParamRow`, `AddGenericParamConstraintRow`, `AddAssemblyReferenceRow`, `AddStandaloneSignatureRow`, `AddCustomAttributeRow`, `AddPropertyRow`, `AddEventRow`, `AddPropertyMapRow`, `AddEventMapRow`, `AddMethodSemanticsRow`, `AddEncLogRow(table, rowId, op)`, `AddEncMapRow(table, rowId)`.
- Heap access: `StringHeapBytes`/`StringHeapOffsets`, `BlobHeapBytes`/`BlobHeapOffsets`, `GuidHeapBytes`, `UserStringHeapBytes`, `StringHeapSize`/`BlobHeapSize`/`GuidHeapSize`, `HeapSizes: MetadataHeapSizes`, `TableRows: TableRows` (all 26 tables), `TableRowCounts: int[]` (indexed by table), `HeapOffsets`.
- `AddUserStringLiteral(offset, value)` — places a literal at a delta-local offset derived from an absolute IL offset.
- `AsMetadataHeaps() : IMetadataHeaps` — bridges to the shared heap interface.

**Significant internal logic**
- `rowElement*` helpers build `RowElementData` rows tagged with `RowElementTags` — absolute vs. relative heap handles, coded-index tags via `ILDeltaHandles` DUs (`TypeDefOrRef`, `MethodDefOrRef`, `TypeOrMethodDef`, `HasConstant`, `HasCustomAttribute`, `CustomAttributeType`, `ResolutionScope`, `MemberRefParent`, `HasSemantics`).
- Roslyn parity: TypeDef FieldList/MethodList columns written 0 (members linked via AddField/AddMethod EncLog); #GUID delta stream zero-filled through prior cumulative heap size so handle N sits at byte `(N-1)*16`.
- Debug tracing gated by `FSHARP_HOTRELOAD_TRACE_HEAP_OFFSETS` / `FSHARP_HOTRELOAD_TRACE_METADATA` env vars (`printfn` diagnostics only).
- `forceAddGuidValue` returns cumulative 1-based index = prior entries + delta entry; `AddEncLogRow`/`AddEncMapRow` build ECMA-335 metadata tokens via `DeltaTokens.makeToken`.

**Cross-references**
- `DeltaMetadataTypes.fs` (RowInfo records, `TableRows`, `RowElementData`)
- `DeltaMetadataEncoding.fs` (`RowElementTags`, `CodedIndices`), `DeltaTableLayout.fs`, `DeltaIndexSizing.fs`, `DeltaMetadataSerializer.fs`
- `ILDeltaHandles.fs` (DeltaTokens, handles/DUs), `ILMetadataHeaps.fs`, `IlxDeltaStreams.fs` (`MethodBodyUpdate`), `BinaryConstants.fs`

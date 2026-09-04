# DeltaMetadataTables.fs

## Pipeline role

Part of the AbstractIL delta metadata (EnC hot-reload) writer infrastructure. This file mirrors the subset of the ECMA-335 metadata tables emitted by hot reload deltas: it accumulates delta-local rows as tagged `RowElementData` elements, builds the delta string/blob/GUID/user-string heaps with caching and offset tables, and exposes the heap bytes, heap sizes, table row counts, and the aggregated `TableRows` contract consumed by `DeltaMetadataSerializer`. The tables are populated to allow serializing deltas directly via AbstractIL rather than via an SRM `MetadataBuilder`.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.DeltaMetadataTables` (module `internal`)
- Uses: `System`, `System.Collections.Generic`, `System.IO`, `System.Text`, `Microsoft.FSharp.Collections`, `FSharp.Compiler.AbstractIL.ILBinaryWriter` (`ByteBuffer` indirectly via `IlxDeltaStreams`), `FSharp.Compiler.AbstractIL.BinaryConstants`, `FSharp.Compiler.AbstractIL.ILDeltaHandles`, `FSharp.Compiler.AbstractIL.ILMetadataHeaps`, `FSharp.Compiler.AbstractIL.IlxDeltaStreams`, `FSharp.Compiler.AbstractIL.DeltaMetadataTypes`, and aliases `DeltaMetadataEncoding` as `Encoding`.
- Environment flags consumed: `FSHARP_HOTRELOAD_TRACE_HEAP_OFFSETS` (`traceHeapOffsets` lazy value, `"1"`/`"true"` = on), `FSHARP_HOTRELOAD_TRACE_METADATA` (= `"1"` enables GUID-heap traces).

## Modules

- `traceHeapOffsets` (lazy `bool`) — traces heap-offset decisions during module-row and user-string writes.

## Types

- `MetadataHeapOffsets` (record) — cumulative baseline heap sizes that delta-local offsets are added to:
  - `StringHeapStart: int`, `BlobHeapStart: int`, `GuidHeapStart: int`, `UserStringHeapStart: int`.
  - Static members: `Zero` (all zeros) and `OfHeapSizes(heapSizes: MetadataHeapSizes)` (copies the four heap sizes).

## Private helpers

- `byteArrayComparer: IEqualityComparer<byte[]>` — structural byte-array equality and hash code (for `Dictionary<byte[], int>` blob lookups; hash `17*23 + byte` rolling).
- `writeCompressedUnsigned (writer: BinaryWriter) (value: int)` — ECMA-335 compressed unsigned integer (1/2/4 bytes with the 0x80/0xC0 leading-byte markers); `invalidArg` if too large, though delta blobs entering the heap always use this form.
- `RowTableBuilder` (private class) — accumulates `RowElementData[]` rows; members `Add`, `Entries`, `Count`.
- `StringHeapBuilder` (private class) — shared string heap with ordinal `Dictionary` dedup, lazy build of the `#Strings` bytes (leading null byte, NUL-terminated UTF-8 entries) and an `entryOffsets` table. Members: `AddSharedEntry` (returns 0 for empty), `Bytes`, `EntryOffsets`.
- `ByteArrayHeapBuilder` (private class) — shared blob heap (used for both #Blob and #GUID), with `AddSharedEntry` (0 for null/empty), lazy build writing each entry length-prefixed via `writeCompressedUnsigned`; members `Bytes`, `EntryOffsets`, `Entries`.
- `UserStringHeapBuilder` (private class) — delta `#US` heap. Maintains a growable byte buffer that always reserves the leading null byte (offset 0 valid for delta heaps), dedups by offset in a `HashSet<int>`, encodes values via `encodeUserString` from `IlxDeltaStreams`. Members: `AddEntry(offset, value)`, `NextOffset` (max length used), `Bytes`.

## Class

`DeltaMetadataTables(?heapOffsets: MetadataHeapOffsets)` — the main table mirror.

- Constructor validates that `GuidHeapStart` is a non-negative multiple of 16; computes `priorGuidEntryCount = GuidHeapStart / 16`.
- Holds one `RowTableBuilder` per table: `moduleRows`, `typeDefRows`, `nestedClassRows`, `interfaceImplRows`, `methodImplRows`, `constantRows`, `fieldRows`, `methodRows`, `paramRows`, `typeRefRows`, `memberRefRows`, `methodSpecRows`, `typeSpecRows`, `genericParamRows`, `genericParamConstraintRows`, `assemblyRefRows`, `standAloneSigRows`, `customAttributeRows`, `propertyRows`, `eventRows`, `propertyMapRows`, `eventMapRows`, `methodSemanticsRows`, `encLogRows`, `encMapRows`.
- Private row-element builders (all produce `RowElementData`): `rowElement tag value` (relative) and `rowElementAbsolute tag value`; typed wrappers `rowElementUShort`, `rowElementULong`, `rowElementString`, `rowElementBlob`, `rowElementStringAbsolute`, `rowElementBlobAbsolute`, `rowElementGuidAbsolute`, `rowElementSimpleIndex table`, `rowElementTypeDefOrRef tag`, `rowElementHasSemantics tag`, `rowElementMethodDefOrRef`, `rowElementTypeOrMethodDef`, `rowElementResolutionScope`, `rowElementMemberRefParent`, `rowElementHasCustomAttribute`, `rowElementHasConstant` (Field/Param/Property tags 0/1/2), `rowElementCustomAttributeType`.
- Heap helpers: `addStringValue`, `addUserStringValue` (allocates at `NextOffset`, stores the *absolute* offset for IL operands), `addExistingStringOffset`, `addExistingStringOffsetOption`, `addBlobBytes`, `addExistingBlobOffset`, `forceAddGuidValue` (1-based index in the cumulative GUID heap), `stringElement`/`blobElement` (absolute vs relative), `encodeTypeDefOrRef` (returns `(tdor_* tag, rowId)`), and the lazily cached `build*HeapBytes` functions.

### Row-adding members (public API)

Per ECMA-335 tables:

- `AddModuleRow(name, nameOffsetOpt, generation, moduleId, encId, encBaseId)` — emits the Module row (generation u2, name, MVID, EncId, EncBaseId GUIDs). EnC Module rows use cumulative GUID handles (delta stream zero-padded through prior generations); EncBaseId is handle 0 for generation 1, otherwise appended.
- `AddTypeDefinitionRow(row: TypeDefinitionRowInfo)` — II.22.37; FieldList/MethodList written as 0 (Roslyn EnC parity; members linked via EncLog AddField/AddMethod).
- `AddNestedClassRow(row: NestedClassRowInfo)` — II.22.32.
- `AddInterfaceImplRow(row: InterfaceImplRowInfo)` — II.22.23.
- `AddConstantRow(row: ConstantRowInfo)` — II.22.9; Type code written as little-endian u2 with zero high padding byte; Value blob always enters the delta blob heap.
- `AddMethodImplRow(row: MethodImplRowInfo)` — II.22.27.
- `AddMethodRow(row: MethodDefinitionRowInfo, body: MethodBodyUpdate)` — RVA, ImplFlags (u2), Flags (u2), Name, Signature, ParamList. RVA comes from the method body update (or the row's `CodeRva`) when body code exists.
- `AddFieldRow(row: FieldDefinitionRowInfo)` — II.22.15.
- `AddParameterRow(row: ParameterDefinitionRowInfo)` — II.22.33; validates `RowId > 0` and `SequenceNumber >= 0`.
- `AddTypeReferenceRow(row: TypeReferenceRowInfo)` — ResolutionScope, Name, Namespace.
- `AddMemberReferenceRow(row: MemberReferenceRowInfo)` — MemberRefParent, Name, Signature.
- `AddMethodSpecificationRow(row: MethodSpecificationRowInfo)` — Method (MethodDefOrRef), Signature.
- `AddTypeSpecificationRow(row: TypeSpecificationRowInfo)` — II.22.39: single `#Blob` signature column.
- `AddGenericParamRow(row: GenericParamRowInfo)` — II.22.20: Number, Flags, Owner (TypeOrMethodDef), Name; validates row id and number.
- `AddGenericParamConstraintRow(row: GenericParamConstraintRowInfo)` — II.22.21.
- `AddAssemblyReferenceRow(row: AssemblyReferenceRowInfo)` — Version u2 components (clamped to 0..0xFFFF), Flags, PublicKeyOrToken, Name, Culture, HashValue.
- `AddStandaloneSignatureRow(signatureBytes)` — single blob column; skips null/empty.
- `AddCustomAttributeRow(row: CustomAttributeRowInfo)` — Parent (HasCustomAttribute), Constructor (CustomAttributeType), Value blob.
- `AddPropertyRow(row: PropertyDefinitionRowInfo)` — Attributes, Name, Signature.
- `AddEventRow(row: EventDefinitionRowInfo)` — Attributes, Name, EventType.
- `AddPropertyMapRow(row: PropertyMapRowInfo)` — TypeDef, FirstProperty.
- `AddEventMapRow(row: EventMapRowInfo)` — TypeDef, FirstEvent.
- `AddMethodSemanticsRow(row: MethodSemanticsMetadataUpdate)` — Attributes (u2), Method, Association (HasSemantics, Property/Event by association union case).
- `AddEncLogRow(table: TableName, rowId: int, operation: EditAndContinueOperation)` — II.22.7: token + operation value.
- `AddEncMapRow(table: TableName, rowId: int)` — II.22.6: single token column, sorted by table then row.
- `AddUserStringLiteral(offset: int, value: string)` — adds a literal at the *absolute* offset from IL tokens; converts to delta-relative offset (`offset - UserStringHeapStart`), warning if the offset is stale relative to the baseline.

### Output members

- `StringHeapBytes`, `BlobHeapBytes`, `GuidHeapBytes`, `UserStringHeapBytes` (with byte caches), `StringHeapOffsets`, `BlobHeapOffsets`, `StringHeapSize`, `BlobHeapSize`, `GuidHeapSize`, `HeapSizes` (as `MetadataHeapSizes`), `HeapOffsets`.
- `TableRowCounts: int[]` — array indexed by ECMA-335 table number (`DeltaTokens.TableCount` entries) populated from each row-builder count (Module..ENCMap).
- `TableRows: TableRows` — the aggregated row contract passed to the serializer.
- `AsMetadataHeaps() : IMetadataHeaps` — unified heap access (string/blob/guid/user-string) so both full-assembly and delta emission share an interface; GUID heap index returns a delta-local 1-based index.

## Significant internal logic

- Offsets are *delta-relative* in the built heaps but *cumulative (baseline + delta)* when serialized: string entries use `StringHeapStart + entryOffset`, blob entries use `BlobHeapStart + entryOffset`, GUID columns use entry-count arithmetic (`GuidHeapStart / 16 + index`), and user strings use `UserStringHeapStart + relativeOffset`.
- The `#GUID` delta stream is zero-filled through the prior cumulative heap size (`heapOffsets.GuidHeapStart`) so cumulative module handles stay stable, then this generation's GUIDs are appended.
- The absolute-vs-relative distinction in `RowElementData.IsAbsolute` lets offsets captured from a baseline (already absolute) pass through unchanged while fresh entries are translated.
- User strings are stored by absolute token offset in `userStringLookup` so IL `ldstr` operands and the heap layout cannot drift apart.
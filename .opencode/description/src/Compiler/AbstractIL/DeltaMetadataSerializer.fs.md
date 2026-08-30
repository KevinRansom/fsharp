# DeltaMetadataSerializer.fs

## Pipeline role

Part of the AbstractIL delta metadata (EnC hot-reload) writer infrastructure. This module is the final stage of delta emission: it turns the accumulated `TableRows` + heap bytes (from `DeltaMetadataTables`), the computed index sizes/masks (from `DeltaIndexSizing` / `DeltaTableLayout`), and the token calculators (from `IlxDeltaStreams`) into the binary `#~` tables stream, aligned `#Strings/#US/#GUID/#Blob` heap streams, and the complete metadata root (metadata root header + stream headers + stream data, plus a `#JTD` stream for EnC deltas), mirroring Roslyn's `DeltaMetadataWriter` and SRM `MetadataBuilder`.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.DeltaMetadataSerializer` (module `internal`)
- Uses: `System`, `System.Collections.Generic`, `System.IO`, `System.Text`, `FSharp.Compiler.AbstractIL.ILMetadataHeaps`, `FSharp.Compiler.AbstractIL.BinaryConstants`, `FSharp.Compiler.AbstractIL.ILDeltaHandles`, `FSharp.Compiler.AbstractIL.DeltaMetadataTables`, `FSharp.Compiler.AbstractIL.DeltaMetadataTypes`, `FSharp.Compiler.AbstractIL.DeltaTableLayout`, and `DeltaMetadataEncoding` aliased as `Encoding`.

## Types

- `DeltaHeapStreams` (record) — the aligned heap streams written into the delta metadata, plus their padded lengths (which become stream-header Size values):
  - `Strings`, `StringsLength`, `Blobs`, `BlobsLength`, `Guids`, `GuidsLength`, `UserStrings`, `UserStringsLength`.
- `DeltaTableStream` (record) — the serialized `#~` stream:
  - `Bytes: byte[]`, `UnpaddedSize: int`, `PaddedSize: int`.
- `DeltaMetadataSizes` (record) — the sizing data mirroring Roslyn's `MetadataSizes`:
  - `RowCounts: int[]`, `HeapSizes: MetadataHeapSizes`, `BitMasks: TableBitMasks`, `IndexSizes: DeltaIndexSizing.CodedIndexSizes`, `IsEncDelta: bool`.
- `DeltaTableSerializerInput` (record) — the fully prepared input to `buildTableStream`:
  - `Tables: TableRows`, `MetadataSizes: DeltaMetadataSizes`, `StringHeap`, `StringHeapOffsets`, `BlobHeap`, `BlobHeapOffsets`, `GuidHeap`, `HeapOffsets: MetadataHeapOffsets`.
- `StreamDescriptor` (private record) — `Name`, `Offset`, `Size`, `Bytes` for building the stream headers.

## Functions

- `padTo4 (bytes: byte[]) : byte[]` — private; zero-pads a byte array to a 4-byte boundary.
- `buildHeapStreams (mirror: DeltaMetadataTables) : DeltaHeapStreams` — pulls heap bytes from the mirror and pads each to 4 bytes. Lengths are the padded sizes (stream-header Size values), per Roslyn `DeltaMetadataWriter`/SRM `MetadataBuilder`: stream header Size uses `GetAlignedHeapSize` while cumulative tracking uses unaligned sizes; the header Length fields must match the actual padded byte-array lengths for correct runtime parsing.
- `computeMetadataSizes (tableMirror: DeltaMetadataTables) (externalRowCounts: int[]) : DeltaMetadataSizes` — computes sizing for delta serialization:
  - Normalizes `externalRowCounts` to `DeltaTokens.TableCount` (zeros if length mismatched).
  - Derives `rowCounts` from the mirror; determines `isEncDelta` as "EncLog or EncMap rows present".
  - Calls `DeltaTableLayout.computeBitMasks` and `DeltaIndexSizing.compute`.
- `writeUInt16`/`writeUInt32` — private BinaryWriter helpers.
- `writeHeapIndex (writer) (isBig) (value)` — writes a 2- or 4-byte heap/simple index.
- `writeTaggedIndex (writer) (nbits) (isBig) (tag) (value)` — encodes `(value <<< nbits) ||| tag`, 2 or 4 bytes.
- `tableRowsByIndex (tables: TableRows) : RowElementData[][][]` — private; maps the named `TableRows` fields onto an array indexed by ECMA-335 table number (using `TableNames`), including Nested=41, ENCLog=30, ENCMap=31.
- `isTablePresent (bitmaskLow) (bitmaskHigh) index` — private; reads a bit from the (possibly split) 64-bit Valid mask.
- `writeRowElement (writer) (indexSizes) (input) (element)` — private; the central dispatcher converting a `RowElementData` to bytes:
  - `UShort`/`ULong`: raw 2/4 bytes.
  - `String`: absolute offset written verbatim; or `StringHeapStart + entryOffset` for relative entries (with bounds check); width from `StringsBig`.
  - `Blob`: same pattern with `BlobHeapStart`; width from `BlobsBig`.
  - `Guid`: absolute cumulative index verbatim or `baselineEntries + value` (entry counts, not byte offsets), width from `GuidsBig`.
  - Simple table indices (`SimpleIndexMin..Max`): width from `SimpleIndexBig.[tableIndex]`.
  - Each coded-index family (`TypeDefOrRef`, `TypeOrMethodDef`, `HasConstant`, `HasCustomAttribute`, `HasFieldMarshal`, `HasDeclSecurity`, `MemberRefParent`, `HasSemantics`, `MethodDefOrRef`, `MemberForwarded`, `Implementation`, `CustomAttributeType`, `ResolutionScope`): sub-tag from the range, encoded via `writeTaggedIndex` with the corresponding `CodedIndices.TagBits` and bigness flag.
  - Anything else raises `invalidArg`.
- `align4 value` — private; rounds up to a multiple of 4.
- `buildTableStream (input: DeltaTableSerializerInput) : DeltaTableStream` — serializes the `#~` stream:
  - Header: reserved `0u`, major `2`, minor `0`.
  - HeapSizes byte: `0x01` StringsBig, `0x02` GuidsBig, `0x04` BlobsBig; EnC deltas additionally set `0x20|0x80` (mirroring Roslyn's `MetadataSizes` for `EmitDifference`). Followed by `1` (Reserved2) and the ValidLow/ValidHigh/SortedLow/SortedHigh masks.
  - Row-count list for present tables, then each present table's rows and elements.
  - Returns bytes padded to 4 bytes with separate `UnpaddedSize`/`PaddedSize`.
- `encodeName (writer) (name)` — private; writes a UTF-8 stream name with NUL terminator padded to 4 bytes.
- `streamHeaderSize (name)` — private; `8 + align4(nameLength + 1)`.
- `serializeMetadataRoot (input: DeltaTableSerializerInput) (heaps: DeltaHeapStreams) (tableStream: DeltaTableStream) : byte[]` — writes the complete metadata image:
  - Streams `#-` (tables), `#Strings`, `#US`, `#GUID`, `#Blob`, and `#JTD` (size 0, empty) only for EnC deltas.
  - Header: signature `0x424A5342` ("BSJB"), major `1`, minor `1`, reserved, version length + `"v4.0.30319"` (+ NUL, padded to 4), flags 0, stream count.
  - Stream directory: `(offset, size, name)` triplets; then the stream bytes themselves.
  - Offsets are computed to place streams after the header.

## Significant internal logic

- Sizing parity contract (documented in `buildHeapStreams`): stream-header Size fields use 4-byte-aligned heap sizes while the delta heap offsets (used for cumulative handle arithmetic) use the unaligned sizes, exactly as Roslyn/SRM do.
- EnC deltas are distinguished by the presence of EncLog/EncMap rows; that flag drives (a) the `0x20|0x80` heap-flags bits, (b) the `#JTD` stream, and (c) un-compressed (4-byte) index sizing via `DeltaIndexSizing`.
- All index widths flow from the single `CodedIndexSizes`/bit-mask computation so header, masks, row counts, and row bodies cannot disagree.
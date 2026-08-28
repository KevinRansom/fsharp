# DeltaMetadataSerializer.fs

**Purpose**
Core serializer of the hot-reload delta metadata stream set. Builds aligned heap streams, computes sizing (bit masks, coded-index widths) for a delta table mirror, serializes the `#~` (tables) stream, and assembles the full metadata root (`JB` header + stream directory + `#~`, `#Strings`, `#US`, `#GUID`, `#Blob`, and for EnC deltas an empty `#JTD` stream) into the byte arrays the delta writer appends to a PE file. Mirrors Roslyn's `DeltaMetadataWriter`/`MetadataBuilder` behavior.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.DeltaMetadataSerializer`)

**TypeDefs declared**
- `DeltaHeapStreams` (record) — aligned byte arrays + lengths for Strings/Blobs/Guids/UserStrings heaps.
- `DeltaTableStream` (record) — serialized `#~` stream bytes, `UnpaddedSize`, `PaddedSize`.
- `DeltaMetadataSizes` (record) — sizing data mirroring Roslyn's `MetadataSizes`: `RowCounts`, `HeapSizes`, `BitMasks`, `IndexSizes`, `IsEncDelta`.
- `DeltaTableSerializerInput` (record) — input bundle: `Tables: TableRows`, `MetadataSizes`, heap bytes + offset arrays, `HeapOffsets: MetadataHeapOffsets`.
- `StreamDescriptor` (private record) — stream name/offset/size/bytes for the JB stream directory.

**Public API surface** (module-internal)
- `buildHeapStreams (mirror: DeltaMetadataTables) : DeltaHeapStreams` — 4-byte pads each heap; Length fields are the stream-header (padded) sizes.
- `computeMetadataSizes (tableMirror) (externalRowCounts) : DeltaMetadataSizes` — detects EnC delta (ENCLog/ENCMap rows present), calls `DeltaTableLayout.computeBitMasks` and `DeltaIndexSizing.compute`.
- `buildTableStream (input) : DeltaTableStream` — emits the `#~` stream.
- `serializeMetadataRoot (input) (heaps) (tableStream) : byte[]` — emits the JB-format metadata root.

**Internal helpers**
- `padTo4`, `align4`, `writeUInt16/32`, `writeHeapIndex` (2/4 bytes per bigness), `writeTaggedIndex` (encodes `(value <<< tagBits) ||| tag`).
- `tableRowsByIndex` — maps `TableRows` to an array indexed by ECMA-335 table number (Module, TypeDef, Nested, InterfaceImpl, Constant, MethodImpl, Field, Method, Param, TypeRef, MemberRef, MethodSpec, TypeSpec, GenericParam, GenericParamConstraint, CustomAttribute, AssemblyRef, StandAloneSig, Property, Event, PropertyMap, EventMap, MethodSemantics, ENCLog, ENCMap).
- `writeRowElement` — dispatches on `RowElementTags`: UShort/ULong/Data, string & blob heap offsets (absolute vs. offset-index-relative), GUID as 1-based entry index relative to a baseline (byte offset / 16), simple indexes, and all 13 coded-index ranges.
- JB header: signature `0x424A5342`, version "v4.0.30319", 4-byte-aligned UTF8 stream names.

**Significant internal logic**
- `#~` header: flags byte with 0x01/0x02/0x04 wide-heap bits plus 0x20|0x80 for EnC deltas, valid/sorted 64-bit masks, per-table row counts for present tables, then all row elements.
- EnC deltas include a zero-size `#JTD` stream.
- Note: `traceHeapOffsets` debug printf used for GUID-offset tracing.

**Cross-references**
- `DeltaMetadataTables.fs` (DeltaMetadataTables, TableRows, RowElementData, MetadataHeapOffsets)
- `DeltaMetadataTypes.fs`, `DeltaMetadataEncoding.fs` (`Encoding` alias), `DeltaTableLayout.fs`, `DeltaIndexSizing.fs`
- `ILMetadataHeaps.fs`, `ILDeltaHandles.fs` (DeltaTokens.TableCount), `FSharpDeltaMetadataWriter.fs` (consumer)

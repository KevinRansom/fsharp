# ILBaselineReader.fs

**Purpose**: A **minimal, dependency-free binary reader** for the PE / .NET metadata of a compiled assembly (and the `.#Pdb` stream of a portable PDB). It parses the PE header → COFF header → CLR runtime header → `#~` (or `#-`) metadata root → stream headers (`#Strings`, `#US`, `#Blob`, `#GUID`, `#~`), computes the metadata table row counts and per-table row sizes, and exposes row-level access to the `TypeDef`, `Field`, `MethodDef`, `PropertyMap`/`Property`, `EventMap`/`Event`, and `Module` tables. This is used by `HotReloadBaseline.fs` to build a *baseline* of a previously-compiled assembly that can later be diffed for hot reload.

**Namespace / module declared**: `FSharp.Compiler.CodeGen.ILBaselineReader` (internal module; no .fsi)

**Types declared** (row-data record types):
- `MetadataHeapSizes` — `StringHeapSize`, `UserStringHeapSize`, `BlobHeapSize`, `GuidHeapSize`.
- `MetadataSnapshot` — `HeapSizes`, `TableRowsCounts: int[]`, `GuidHeapStart: int` — a compact, stable snapshot of the metadata for baseline comparison.
- `PortablePdbMetadata` — `ContentId: byte[]`, `TableRowsCounts: int[]`, `EntryPointToken: int option` — the portable-PDB-specific data.
- Row rowdata records: `TypeDefRowData`, `FieldRowData`, `MethodDefRowData`, `PropertyMapRowData`, `PropertyRowData`, `EventMapRowData`, `EventRowData`, `ModuleRowData`.
- `StreamHeader` (private) — `Offset`, `Size`, `Name` of a metadata stream.
- `MetadataContext` (private) — `bytes`, `RowCounts`, and precomputed offsets that `BaselineMetadataReader` uses to locate rows.
- `BaselineMetadataReader` — the user-facing reader (value-type-ish, created via `static member Create(bytes): option`).

**Public / internal API surface**:
- `readUInt64: bytes -> int -> uint64` — `let internal`; reads a little-endian 64-bit value without sign-extending either half.
- `metadataSnapshotFromBytes: bytes -> MetadataSnapshot option` — the top-level "get me a stable snapshot of this assembly's metadata" function. Returns `None` on any parse failure (index / argument out of range, or missing tables).
- `readCodeViewContentIdFromBytes: bytes -> byte[] option` — read the CodeView content id (a 19-byte guid-ish structure under `#Pdb`).
- `readModuleMvidFromBytes: bytes -> Guid option` — read the `Module` table's `Mvid` GUID from the assembly's `#GUID` heap.
- `readPortablePdbMetadata: pdbBytes -> PortablePdbMetadata option` — read the portable PDB's `#Pdb` stream (Content Id + Tables + Entry Point token).
- `BaselineMetadataReader.Create(bytes): BaselineMetadataReader option` — open the reader.
- Reader members: `RowCounts`, `TypeDefCount`, `FieldCount`, `MethodDefCount`, `PropertyMapCount`, `PropertyCount`, `EventMapCount`, `EventCount`; `GetModule()`, `GetTypeDef(int)`, `GetField(int)`, `GetMethodDef(int)`, `GetPropertyMap(int)`, `GetProperty(int)`, `GetEventMap(int)`, `GetEvent(int)`; `GetString(offset)`, `GetBlob(offset)`; and the *range* helpers `GetTypeFieldRange(typeRowId)`, `GetTypeMethodRange(typeRowId)`, `GetPropertyMapRange(propertyMapRowId)`, `GetEventMapRange(eventMapRowId)`.

**Internal machinery (notable)**:
- `readUInt16` / `readInt32` — low-level little-endian readers.
- `tryRvaToOffset` — walk the COFF section headers to map a relative virtual address to an in-file offset.
- `findMetadataRoot` — locate the CLR runtime header (from the PE optional header's `DataDirectory[14]` = CLR header), read its `MetaData RVA`, and convert to an offset.
- `parseStreamHeaders` / `findStream` — parse the `#~` stream header list and find a named stream.
- `parseTablesStream` — read the `valid` / `sorted` bitmasks and the 64 row counts.
- Row-size table: `tableIndexSize`, `codedIndexSize`, and per-table row-size functions (`resolutionScopeSize`, `typeDefOrRefSize`, `hasConstantSize`, `hasCustomAttributeSize`, `hasFieldMarshalSize`, `hasDeclSecuritySize`, `memberRefParentSize`, `hasSemanticsSize`, `methodDefOrRefSize`, `memberForwardedSize`, `implementationSize`, `customAttributeTypeSize`, `typeOrMethodDefSize`) implement the ECMA-335 coded-index-size rules so that `calculateTableRowSizes` can compute the per-table row size and `calculateTableOffsets` the per-table start offset.
- `createMetadataContext` — builds the `MetadataContext` (row counts, per-table sizes, per-table offsets) that every row accessor uses.
- Heap readers: `readStringFromHeap` (with UTF-8 / UTF-16 detection for the `#Strings` heap), `readBlobFromHeap` (big-blob / small-blob decode), `readGuidFromBytes`.
- Per-row decoders: `readTypeDefRow`, `readFieldRow`, `readMethodDefRow`, `readPropertyMapRow`, `readPropertyRow`, `readEventMapRow`, `readEventRow`, `readModuleRow`.
- Portable PDB helpers: `parsePdbStream` (the `#Pdb` stream entry-point token + content id), `parsePdbTablesStream` (the 8 PDB tables row counts), and `readPortablePdbMetadata` (the top-level entry, validating the `0x424A5342` `"BJSB"` signature).
- `TableIndices` — a private module holding the 64 metadata table id constants for the tables this reader cares about.

**Significant internal logic**:
- The whole reader is **defensive**: every entry point (`metadataSnapshotFromBytes`, `readModuleMvidFromBytes`, `readPortablePdbMetadata`, and the `Get*` row accessors) catches `IndexOutOfRangeException` / `ArgumentOutOfRangeException` and returns `None`, so a truncated or malformed assembly simply produces a `None` baseline rather than an exception.
- The `#Strings` heap size is *trimmed* at the trailing NULs (the heap may be padded with NULs that are not part of any string). This is reflected in `MetadataSnapshot.HeapSizes.StringHeapSize`.
- The metadata tables are addressed by `rowId` (1-based), and the reader precomputes `tableOffsets` so that `rowOffset = tableStart + (rowId-1) * rowSize` is an O(1) computation.
- `PropertyMap` / `EventMap` ranges are computed by looking at the next map row's first-entry index to derive the end of the current range (the standard "PropertyMap → Property[] slice" relationship).
- The file deliberately avoids depending on `System.Reflection.Metadata`; it's a self-contained, low-level reader, which means it has no allocation-heavy state and can be run on the hot path of a hot-reload diff.

**Cross-references**:
- `HotReloadBaseline.fs` — the direct consumer; it wraps a `BaselineMetadataReader` in a `MetadataSnapshot` and re-exports `metadataSnapshotFromBytes` / `readModuleMvidFromBytes`.
- `FSharp.Compiler.AbstractIL.IL` — the IL-metadata types (the baseline ultimately feeds the delta writer that walks `ILModuleDef`-shaped data).
- Part of the hot-reload / incremental-build flow in `src/Compiler/CodeGen/` (see also `EraseClosures.fs`, `EraseUnions.*` for the related erasure family).
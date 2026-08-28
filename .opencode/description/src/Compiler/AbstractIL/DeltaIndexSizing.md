# DeltaIndexSizing.fs

**Purpose**
Supports F# hot reload (EnC / Edit-and-Continue) delta metadata emission. Computes whether each ECMA-335 coded/simple metadata index in a delta stream needs 2 or 4 bytes of storage, per ECMA-335 II.24.2.6. Because EnC delta streams are uncompressed, all indices are 4 bytes; the compressed path is retained for parity with the baseline IL writer (ilwrite.fs).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.DeltaIndexSizing`)

**Modules / TypeDefs / Structs declared**
- `CodedIndexSizes` (record) — holds computed "bigness" flags (bool per index type, `SimpleIndexBig: bool[]`) for every simple and coded index type plus heap sizes (`StringsBig`, `GuidsBig`, `BlobsBig`).

**Public API surface** (module-internal)
- `compute (tableRowCounts:int[]) (externalRowCounts:int[]) (heapSizes:MetadataHeapSizes) (isEncDelta:bool) : CodedIndexSizes` — main entry point; determines byte width of each reference type in the metadata tables.
- Minor helpers exist.

**Internal helpers**
- `tableSize`, `totalRowCount` (local + external row counts), `referenceExceedsLimit`
- `codedBigness` — 4 bytes if uncompressed, else checks whether any referenced table overflows `2^(16-tagBits)` rows after the tag
- `isSimpleIndexBig` — big when local+external rows >= 0x10000 (or uncompressed)
- Coded index table/tag definitions inlined: `TypeDefOrRef` (2-bit), `TypeOrMethodDef` (1-bit), `HasConstant` (2-bit), `HasCustomAttribute` (5-bit), `HasFieldMarshal`, `HasDeclSecurity`, `MemberRefParent` (3-bit), `HasSemantics`, `MethodDefOrRef`, `MemberForwarded`, `Implementation`, `CustomAttributeType` (3-bit, tags 0/1/4 reserved), `ResolutionScope` (2-bit)

**Significant internal logic**
- Heap indices are 4 bytes when the assembly is uncompressed or the heap is >= 64KB.
- Coded index bigness: tag uses low N bits; if any member table row count (local + external) reaches `2^(16-N)` a 4-byte index is required.
- EnC deltas always report "big" (uncompressed 4-byte indices).

**Cross-references**
- `BinaryConstants.fs` (TableNames, CodedIndices tag data)
- `ILDeltaHandles.fs` (DeltaTokens.TableCount)
- `ILMetadataHeaps.fs` (MetadataHeapSizes)
- `DeltaMetadataEncoding.fs` (CodedIndices definitions)
- `DeltaMetadataSerializer.fs` (consumes these sizes when emitting rows)

# DeltaIndexSizing.fs

## Pipeline role

Part of the AbstractIL delta metadata (EnC hot-reload) writer infrastructure. This module computes coded index sizing for delta metadata emission: it decides, per ECMA-335 II.24.2.6, whether each metadata index (heap or table reference) must be encoded in 4 bytes ("big") or fits in 2 bytes ("small"), based on row counts in the metadata tables and the sizes of the string/blob/GUID heaps. The same pattern is used by the baseline IL writer (`ilwrite.fs`), but here it is specialized for delta emission. The result is the `CodedIndexSizes` record consumed by `DeltaMetadataSerializer` to pick tag/width encodings.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.DeltaIndexSizing` (module `internal`)
- Uses: `FSharp.Compiler.AbstractIL.BinaryConstants` (for `TableNames`), `FSharp.Compiler.AbstractIL.ILDeltaHandles` (for `DeltaTokens`, `CodedIndices`-related tags), `FSharp.Compiler.AbstractIL.ILMetadataHeaps` (for `MetadataHeapSizes`), `FSharp.Compiler.AbstractIL.DeltaMetadataEncoding` (for `CodedIndices`).

## Types

- `CodedIndexSizes` (record) — holds computed "bigness" flags for all coded index types. When a flag is `true`, the index requires 4 bytes; when `false`, 2 bytes suffice.
  - Fields: `StringsBig`, `GuidsBig`, `BlobsBig` (heap indices), `SimpleIndexBig: bool[]` (per-table simple indices), then one bool per coded index: `TypeDefOrRefBig`, `TypeOrMethodDefBig`, `HasConstantBig`, `HasCustomAttributeBig`, `HasFieldMarshalBig`, `HasDeclSecurityBig`, `MemberRefParentBig`, `HasSemanticsBig`, `MethodDefOrRefBig`, `MemberForwardedBig`, `ImplementationBig`, `CustomAttributeTypeBig`, `ResolutionScopeBig`.

## Functions

- `tableSize (tableRowCounts: int[]) (table: int) : int` — private; returns the row count of a metadata table.
- `totalRowCount (tableRowCounts: int[]) (externalRowCounts: int[]) (table: int) : int` — private; sums the local row count and the external (baseline-provided) row count for a table. If the external array length does not match the table count, external counts are treated as zero.
- `referenceExceedsLimit (tableRowCounts: int[]) (externalRowCounts: int[]) (maxValueExclusive: int) (tables: int[]) : bool` — private; true if any of the given tables reaches the exclusive row-count limit.
- `codedBigness (tagBits: int) (tableRowCounts: int[]) (externalRowCounts: int[]) (isCompressed: bool) (tables: int[]) : bool` — private; determines if a coded index requires 4 bytes. For EnC deltas (uncompressed) it always returns `true`; for compressed metadata the limit is `2^(16 - tagBits)`, and bigness holds if any referenced table reaches that limit.
- `isSimpleIndexBig (tableRowCounts: int[]) (externalRowCounts: int[]) (isCompressed: bool) (tableIndex: int) : bool` — private; `true` for uncompressed delta emission, otherwise `local + external >= 0x10000`.
- `compute (tableRowCounts: int[]) (externalRowCounts: int[]) (heapSizes: MetadataHeapSizes) (isEncDelta: bool) : CodedIndexSizes` — the main entry point computing all bigness flags.
  - Heap indices (`StringsBig`, `BlobsBig`, `GuidsBig`) are big if uncompressed (`isEncDelta`) or the relevant heap is `>= 0x10000`.
  - `SimpleIndexBig` is computed for all `DeltaTokens.TableCount` tables via `Array.init`.
  - Each coded index bigness flag is derived from `CodedIndices.*` definitions (tag bits + referenced tables) in `DeltaMetadataEncoding.fs`, using the local `coded` helper.

## Significant internal logic

- Mirrors ECMA-335 II.24.2.6 index sizing: a coded index combines a low-bit tag (identifying the table) with a row index; if any table in the coded index's set exceeds `2^(16 - tagBits) - 1` rows, the full index needs 4 bytes (compressed) or is always 4 bytes (EnC deltas).
- Encoded tag layouts relied upon here (documented in the trailer comments): `TypeDefOrRef` 2-bit tag; `TypeOrMethodDef` 1-bit; `HasConstant` 2-bit; `HasCustomAttribute` 5-bit (largest coded index, 22 parent types); `HasFieldMarshal` 1-bit; `HasDeclSecurity` 2-bit; `MemberRefParent` 3-bit; `HasSemantics` 1-bit; `MethodDefOrRef` 1-bit; `MemberForwarded` 1-bit; `Implementation` 2-bit; `CustomAttributeType` 3-bit (tags 0, 1, 4 reserved); `ResolutionScope` 2-bit.
- EnC deltas never compress indices, so all references are 4 bytes, matching the DeltaMetadataSerializer expectations.
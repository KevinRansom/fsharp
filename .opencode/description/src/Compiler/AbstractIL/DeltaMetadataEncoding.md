# DeltaMetadataEncoding.fs

**Purpose**
Part of the hot-reload delta metadata encoding support. Defines the row-element tag numbers used in delta table rows and the canonical coded-index table orders that hot-reload metadata sizing (`DeltaIndexSizing`) and serialization (`DeltaMetadataSerializer`) rely on. Kept in a separate hot-reload-owned module so delta serialization can evolve without expanding the baseline `ilwrite.fsi` surface.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.DeltaMetadataEncoding`)

**Modules / TypeDefs declared**
- `RowElementTags` (nested module) — tag literals for row column kinds: `UShort=0`, `ULong=1`, `Data=2`, `DataResources=3`, `Guid=4`, `Blob=5`, `String=6`, `SimpleIndexMin=7`/`SimpleIndexMax=119`, plus per-coded-index ranges (`TypeDefOrRefOrSpec` 120-122, `TypeOrMethodDef` 123-124, `HasConstant` 125-127, `HasCustomAttribute` 128-149, `HasFieldMarshal` 150-151, `HasDeclSecurity` 152-154, `MemberRefParent` 155-159, `HasSemantics` 160-161, `MethodDefOrRef` 162-164, `MemberForwarded` 165-166, `Implementation` 167-169, `CustomAttributeType` 170-173, `ResolutionScope` 174-178) each with a `(tag) -> int` accessor.
- `CodedIndexDefinition` (record) — `{ TagBits: int; Tables: int[] }`.
- `CodedIndices` (nested module) — canonical coded-index definitions (tag bits + table index order) for All 13 coded index types: `TypeDefOrRef`, `TypeOrMethodDef`, `HasConstant`, `HasCustomAttribute` (22 parent tables, 5-bit tag), `HasFieldMarshal`, `HasDeclSecurity`, `MemberRefParent`, `HasSemantics`, `MethodDefOrRef`, `MemberForwarded`, `Implementation`, `CustomAttributeType`, `ResolutionScope`.

**Public API surface** (module-internal)
- `RowElementTags.SimpleIndex/TypeDefOrRefOrSpec/...` tag constructors; `CodedIndices.*` definitions.

**Significant internal logic**
- Tag numbers encode ECMA-335 "coded index" element kinds; each coded index's tag range is a base offset plus the per-table tag.
- `HasCustomAttribute` covers 22 metadata entities (largest coded index).

**Cross-references**
- `BinaryConstants.fs` (TableName, TableNames, tag types like `TypeDefOrRefTag`)
- `DeltaIndexSizing.fs`, `DeltaMetadataSerializer.fs`, `DeltaMetadataTables.fs`, `ILDeltaHandles.fs`

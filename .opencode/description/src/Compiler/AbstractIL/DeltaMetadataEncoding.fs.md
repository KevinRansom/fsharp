# DeltaMetadataEncoding.fs

## Pipeline role

Part of the AbstractIL delta metadata (EnC hot-reload) writer infrastructure. This module defines the tag vocabulary used to encode row elements in delta metadata tables. Each tag value identifies how a cell in a delta table row should be serialized (a raw `UInt16`/`UInt32`, heap data, or a reference to another metadata table). Keeping these tags in a delta-owned module lets delta serialization evolve without expanding `ilwrite.fsi`. It also defines the canonical coded-index table orders used by `DeltaIndexSizing` and the serializer.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.DeltaMetadataEncoding` (module `internal`)
- Uses: `FSharp.Compiler.AbstractIL.BinaryConstants` (for `TableName`, and indirectly tag types such as `TypeDefOrRefTag`, `TypeOrMethodDefTag`, `HasConstantTag`, `HasCustomAttributeTag`, `HasFieldMarshalTag`, `HasDeclSecurityTag`, `MemberRefParentTag`, `HasSemanticsTag`, `MethodDefOrRefTag`, `MemberForwardedTag`, `ImplementationTag`, `CustomAttributeTypeTag`, `ResolutionScopeTag`).

## Modules

### RowElementTags

Literal constants describing the byte-level element kinds that can appear in a delta table row. Values below `SimpleIndexMin` are base kinds; values from `SimpleIndexMin` onward encode specific metadata tables or coded-index tagged variants.

- Base kinds: `UShort = 0`, `ULong = 1`, `Data = 2` (inline data), `DataResources = 3`, `Guid = 4`, `Blob = 5`, `String = 6`.
- Simple table indices: range `SimpleIndexMin = 7` .. `SimpleIndexMax = 119`. Function `SimpleIndex (table: TableName)` returns `SimpleIndexMin + table.Index`.
- Coded indices (tag = the metadata tag value):
  - `TypeDefOrRef`: min `120`, max `122`; `TypeDefOrRefOrSpec (tag)`.
  - `TypeOrMethodDef`: min `123`, max `124`; `TypeOrMethodDef (tag)`.
  - `HasConstant`: min `125`, max `127`; `HasConstant (tag)`.
  - `HasCustomAttribute`: min `128`, max `149`; `HasCustomAttribute (tag)`.
  - `HasFieldMarshal`: min `150`, max `151`; `HasFieldMarshal (tag)`.
  - `HasDeclSecurity`: min `152`, max `154`; `HasDeclSecurity (tag)`.
  - `MemberRefParent`: min `155`, max `159`; `MemberRefParent (tag)`.
  - `HasSemantics`: min `160`, max `161`; `HasSemantics (tag)`.
  - `MethodDefOrRef`: min `162`, max `164`; `MethodDefOrRef (tag)`.
  - `MemberForwarded`: min `165`, max `166`; `MemberForwarded (tag)`.
  - `Implementation`: min `167`, max `169`; `Implementation (tag)`.
  - `CustomAttributeType`: min `170`, max `173`; `CustomAttributeType (tag)`.
  - `ResolutionScope`: min `174`, max `178`; `ResolutionScope (tag)`.

### CodedIndices

Canonical coded-index table definitions for hot reload metadata sizing and serialization. Each is a `CodedIndexDefinition` with a tag-bit count and the ordered list of `TableNames` rows making up the coded index (order defines tag assignment).

- `TypeDefOrRef` — TagBits 2; tables TypeDef, TypeRef, TypeSpec.
- `TypeOrMethodDef` — TagBits 1; tables TypeDef, Method.
- `HasConstant` — TagBits 2; tables Field, Param, Property.
- `HasCustomAttribute` — TagBits 5; 22 tables (Method, Field, TypeRef, TypeDef, Param, InterfaceImpl, MemberRef, Module, Permission, Property, Event, StandAloneSig, ModuleRef, TypeSpec, Assembly, AssemblyRef, File, ExportedType, ManifestResource, GenericParam, GenericParamConstraint, MethodSpec).
- `HasFieldMarshal` — TagBits 1; tables Field, Param.
- `HasDeclSecurity` — TagBits 2; tables TypeDef, Method, Assembly.
- `MemberRefParent` — TagBits 3; tables TypeDef, TypeRef, ModuleRef, Method, TypeSpec.
- `HasSemantics` — TagBits 1; tables Event, Property.
- `MethodDefOrRef` — TagBits 1; tables Method, MemberRef.
- `MemberForwarded` — TagBits 1; tables Field, Method.
- `Implementation` — TagBits 2; tables File, AssemblyRef, ExportedType.
- `CustomAttributeType` — TagBits 3; tables Method, MemberRef (tags 0, 1, 4 unused).
- `ResolutionScope` — TagBits 2; tables Module, ModuleRef, AssemblyRef, TypeRef.

## Types

- `CodedIndexDefinition` (record, in module scope) — `{ TagBits: int; Tables: int[] }`; the number of low-order tag bits plus the row indices of the referenced metadata tables.

## Significant internal logic

- The numeric value space `[0, 179]` partitions into base kinds, simple tables, and the 14 coded index families; the serializer maps each cell's tag back to the corresponding encoding and resolves table references through `DeltaTokens`/`BinaryConstants` symbol tables.
- Comments in each `CodedIndices` entry record the exact ECMA-335 tag-to-table assignment used by `DeltaIndexSizing.fs` to compute bigness and by the serializer to emit fixed-size (4-byte) indices in EnC deltas.
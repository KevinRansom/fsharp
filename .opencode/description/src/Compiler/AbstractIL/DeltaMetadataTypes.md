# DeltaMetadataTypes.fs

**Purpose**
Defines the shared contract types for the hot-reload delta metadata tables: stable, content-based definition keys used to correlate a definition across compiles/generations (baseline vs. fresh compile) independently of row-id churn, plus per-table row-model records (RowInfo) and the `TableRows` aggregate consumed by `DeltaMetadataTables`/`DeltaMetadataSerializer`.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.DeltaMetadataTypes`)

**Records / Unions declared**
- Definition keys: `MethodDefinitionKey` (type, name, generic arity, parameter types, return type), `ParameterDefinitionKey` (method key + sequence number), `FieldDefinitionKey`, `PropertyDefinitionKey` (incl. indexer parameter types), `EventDefinitionKey`.
- `MethodSemanticsAssociation` (union) — `PropertyAssociation of PropertyDefinitionKey * rowId` | `EventAssociation of EventDefinitionKey * rowId`, for getter/setter/add/remove rows.
- `RowElementData` (record) — `{ Tag: int; Value: int; IsAbsolute: bool }`, the minimal shared row-cell type for delta tables.
- Row models (all records): `MethodDefinitionRowInfo` (attrs, name, signature blob, first-param id, CodeRva, `ParentTypeDefRowId` for ADDED methods), `ParameterDefinitionRowInfo`, `FieldDefinitionRowInfo` (incl. `ParentTypeDefRowId` for AddField), `TypeDefinitionRowInfo` (Extends TypeDefOrRef, `EnclosingTypeDefRowId` for nested), `NestedClassRowInfo`, `InterfaceImplRowInfo`, `MethodImplRowInfo`, `ConstantRowInfo` (ELEMENT_TYPE TypeCode), `TypeReferenceRowInfo`, `MemberReferenceRowInfo`, `MethodSpecificationRowInfo`, `TypeSpecificationRowInfo`, `GenericParamRowInfo`, `GenericParamConstraintRowInfo`, `AssemblyReferenceRowInfo`, `CustomAttributeRowInfo`, `PropertyDefinitionRowInfo` (`ParentPropertyMapRowId`), `EventDefinitionRowInfo` (`ParentEventMapRowId`), `PropertyMapRowInfo`, `EventMapRowInfo`, `MethodSemanticsMetadataUpdate`.
- `TableRows` (record) — 26 `RowElementData[][]` fields (Module, TypeDef, NestedClass, InterfaceImpl, Constant, MethodImpl, Field, MethodDef, Param, TypeRef, MemberRef, MethodSpec, TypeSpec, GenericParam, GenericParamConstraint, AssemblyRef, StandAloneSig, CustomAttribute, Property, Event, PropertyMap, EventMap, MethodSemantics, EncLog, EncMap).

**Significant internal logic**
- RowInfo records carry `StringOffset`/`BlobOffset` options so the same heap entry can be reused when it already exists in baseline/delta heaps; `IsAdded` + `Parent*RowId` fields drive EncLog Add* entries (Roslyn/CLR EnC applier parity).
- Key types are deliberately lifted out of the hot-reload baseline bookkeeping (handle caches, token maps) because they are pure structural identities over ILType/string data.

**Cross-references**
- `DeltaMetadataTables.fs` (row builders consume these records), `DeltaMetadataSerializer.fs` (serializes `TableRows`)
- `BinaryConstants.fs` (StringOffset, BlobOffset, attributes enums), `ILDeltaHandles.fs` (TypeDefOrRef, MethodDefOrRef, HasConstant, etc.)
- `il.fs` (ILType used in definition keys)

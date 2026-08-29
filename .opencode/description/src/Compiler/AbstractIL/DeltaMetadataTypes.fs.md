# DeltaMetadataTypes.fs

## Pipeline role

Part of the AbstractIL delta metadata (EnC hot-reload) writer infrastructure. This file defines the data-contract types shared between the delta metadata builder and the delta serializer: stable content-based "definition keys" used to correlate metadata definitions across compiles (baseline vs. fresh), row-info records describing the ECMA-335 metadata table rows that a delta may emit, and the `TableRows` aggregate that is handed to `DeltaMetadataSerializer`. The keys and row models are pure structural identities over `ILType`/string data, carrying no session state, so they live beside the row-info contract types rather than with baseline bookkeeping.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.DeltaMetadataTypes` (module `internal`)
- Uses: `System`, `System.Reflection` (attribute enums such as `MethodAttributes`, `MethodImplAttributes`, `ParameterAttributes`, `FieldAttributes`, `TypeAttributes`, `GenericParameterAttributes`, `AssemblyFlags`, `PropertyAttributes`, `EventAttributes`, `MethodSemanticsAttributes`), `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.AbstractIL.BinaryConstants`, `FSharp.Compiler.AbstractIL.ILDeltaHandles`.

## Types — definition keys

Stable, content-based identifiers used to correlate a definition across compiles/generations (e.g. baseline vs. fresh compile) independently of row-id churn. Lifted from the hot-reload baseline module; these records carry no session state.

- `MethodDefinitionKey` (record) — `DeclaringType: string`, `Name: string`, `GenericArity: int`, `ParameterTypes: ILType list`, `ReturnType: ILType`.
- `ParameterDefinitionKey` (record) — `Method: MethodDefinitionKey`, `SequenceNumber: int`.
- `FieldDefinitionKey` (record) — `DeclaringType: string`, `Name: string`, `FieldType: ILType`.
- `PropertyDefinitionKey` (record) — `DeclaringType: string`, `Name: string`, `PropertyType: ILType`, `IndexParameterTypes: ILType list`.
- `EventDefinitionKey` (record) — `DeclaringType: string`, `Name: string`, `EventType: ILType option`.
- `MethodSemanticsAssociation` (discriminated union) — identifies the property or event a MethodSemantics row (getter/setter/add/remove) is associated with, plus the row id of that PropertyMap/EventMap-owned parent:
  - `PropertyAssociation of PropertyDefinitionKey * rowId: int`
  - `EventAssociation of EventDefinitionKey * rowId: int`

## Types — minimal shared row-element models

- `RowElementData` (record) — `{ Tag: int; Value: int; IsAbsolute: bool }`; a single serialized cell of a delta table row.

## Types — row info models

Each type documents its ECMA-335 table and how the CLR EnC applier links the row.

- `MethodDefinitionRowInfo` (record) — `Key`, `RowId`, `IsAdded`, `ParentTypeDefRowId: int option` (baseline TypeDef that receives an ADDED method; required because CMiniMdRW::ApplyDelta reads the parent TypeDef from the AddMethod EncLog entry), `Attributes: MethodAttributes`, `ImplAttributes: MethodImplAttributes`, `Name`, `NameOffset: StringOffset option`, `Signature: byte[]`, `SignatureOffset: BlobOffset option`, `FirstParameterRowId: int option`, `CodeRva: int option`.
- `ParameterDefinitionRowInfo` (record) — `Key`, `RowId`, `IsAdded`, `Attributes: ParameterAttributes`, `SequenceNumber`, `Name: string option`, `NameOffset`.
- `FieldDefinitionRowInfo` (record) — ECMA-335 II.22.15 (Flags, Name, Signature). `Key`, `RowId`, `IsAdded`, `ParentTypeDefRowId: int` (used for the EncLog "(TypeDef, AddField)" parent entry preceding the Field row, Roslyn-style), `Attributes: FieldAttributes`, `Name`, `NameOffset`, `Signature`, `SignatureOffset`.
- `TypeDefinitionRowInfo` (record) — ECMA-335 II.22.37 (Flags, TypeName, TypeNamespace, Extends, FieldList, MethodList) for ADDED TypeDefs. Fields: `FullName`, `RowId`, `Attributes: TypeAttributes`, `Name`, `NameOffset`, `Namespace`, `NamespaceOffset`, `Extends: TypeDefOrRef option` (None encodes the nil TypeDefOrRef), `EnclosingTypeDefRowId: int option` (drives the NestedClass row). Roslyn parity: FieldList/MethodList columns are always written as 0 — members are linked via AddField/AddMethod EncLog parent entries.
- `NestedClassRowInfo` (record) — ECMA-335 II.22.32 (NestedClass, EnclosingClass): `RowId`, `NestedTypeDefRowId`, `EnclosingTypeDefRowId`. Emitted for added nested types; logged as plain Default EncLog entry.
- `InterfaceImplRowInfo` (record) — ECMA-335 II.22.23 (Class — TypeDef row — and Interface — TypeDefOrRef coded index): `RowId`, `ClassTypeDefRowId`, `Interface: TypeDefOrRef`. Emitted for interfaces of ADDED types; logged as plain Default EncLog entry trailing the log and listed in EncMap as an add.
- `MethodImplRowInfo` (record) — ECMA-335 II.22.27 (Class — TypeDef row; MethodBody, MethodDeclaration — MethodDefOrRef coded indices): `RowId`, `ClassTypeDefRowId`, `MethodBody: MethodDefOrRef`, `MethodDeclaration: MethodDefOrRef`. Emitted for the explicit interface implementations of ADDED types (F# classes implement interfaces explicitly, so every implemented interface slot carries a MethodImpl row).
- `ConstantRowInfo` (record) — ECMA-335 II.22.9 (Type — 1-byte ELEMENT_TYPE plus padding byte — Parent — HasConstant coded index — Value — #Blob offset): `RowId`, `TypeCode: byte`, `Parent: HasConstant`, `Value: byte[]`. Emitted for literal (HasDefault) fields of ADDED types and members (enum members, union Tags holder constants, `[<Literal>]` module values).
- `TypeReferenceRowInfo` (record) — `RowId`, `ResolutionScope: ResolutionScope`, `Name`, `NameOffset`, `Namespace`, `NamespaceOffset`.
- `MemberReferenceRowInfo` (record) — `RowId`, `Parent: MemberRefParent`, `Name`, `NameOffset`, `Signature: byte[]`, `SignatureOffset`.
- `MethodSpecificationRowInfo` (record) — `RowId`, `Method: MethodDefOrRef`, `Signature: byte[]`, `SignatureOffset`.
- `TypeSpecificationRowInfo` (record) — ECMA-335 II.22.39 (single #Blob signature carrying a bare Type, II.23.2.14): `RowId`, `Signature`, `SignatureOffset`. Appended with a plain Default EncLog entry when an edit references a generic instantiation with no matching baseline row.
- `GenericParamRowInfo` (record) — ECMA-335 II.22.20 (Number u2, Flags u2, Owner TypeOrMethodDef, Name #Strings): `RowId`, `Number`, `Attributes: GenericParameterAttributes`, `Owner: TypeOrMethodDef`, `Name`, `NameOffset`. Emitted for generic parameters of ADDED generic methods/types; GenericParam rows of UPDATED methods are baseline rows and never re-emitted.
- `GenericParamConstraintRowInfo` (record) — ECMA-335 II.22.21 (Owner — GenericParam row index — Constraint — TypeDefOrRef coded index): `RowId`, `OwnerGenericParamRowId`, `Constraint: TypeDefOrRef`. Logged as a plain Default EncLog entry after the GenericParam entries and listed in EncMap as an add.
- `AssemblyReferenceRowInfo` (record) — `RowId`, `Version`, `Flags: AssemblyFlags`, `PublicKeyOrToken: byte[]`, `PublicKeyOrTokenOffset`, `Name`, `NameOffset`, `Culture: string option`, `CultureOffset`, `HashValue: byte[]`, `HashValueOffset`.
- `CustomAttributeRowInfo` (record) — `RowId`, `Parent: HasCustomAttribute`, `Constructor: CustomAttributeType`, `Value: byte[]`, `ValueOffset`.
- `PropertyDefinitionRowInfo` (record) — `Key`, `RowId`, `IsAdded`, `ParentPropertyMapRowId: int option` (the AddProperty EncLog entry must carry the parent PropertyMap token; CLR links via AddPropertyToPropertyMap), `Name`, `NameOffset`, `Signature: byte[]`, `SignatureOffset`, `Attributes: PropertyAttributes`.
- `EventDefinitionRowInfo` (record) — `Key`, `RowId`, `IsAdded`, `ParentEventMapRowId: int option` (CLR links via AddEventToEventMap), `Name`, `NameOffset`, `Attributes: EventAttributes`, `EventType: TypeDefOrRef`.
- `PropertyMapRowInfo` (record) — `DeclaringType: string`, `RowId`, `TypeDefRowId`, `FirstPropertyRowId: int option`, `IsAdded: bool`.
- `EventMapRowInfo` (record) — `DeclaringType: string`, `RowId`, `TypeDefRowId`, `FirstEventRowId: int option`, `IsAdded: bool`.
- `MethodSemanticsMetadataUpdate` (record) — `RowId`, `MethodToken: int`, `Attributes: MethodSemanticsAttributes`, `IsAdded: bool`, `AssociationInfo: MethodSemanticsAssociation` (required; provides the property/event key and row id).

## Types — aggregate

- `TableRows` (record) — one `RowElementData[][]` per delta-emittable table, keyed by role:
  `Module`, `TypeDef`, `NestedClass`, `InterfaceImpl`, `Constant`, `MethodImpl`, `Field`, `MethodDef`, `Param`, `TypeRef`, `MemberRef`, `MethodSpec`, `TypeSpec`, `GenericParam`, `GenericParamConstraint`, `AssemblyRef`, `StandAloneSig`, `CustomAttribute`, `Property`, `Event`, `PropertyMap`, `EventMap`, `MethodSemantics`, `EncLog`, `EncMap`.

## Significant internal logic

- The `*Key` records provide row-id-independent identities so that a definition can be matched between a baseline assembly and a fresh compile even when its token/row changed.
- EnC-specific invariants encoded in the row models: ADDED methods/fields/properties/events must record their parent (TypeDef/PropertyMap/EventMap) row id so the EncLog `Add*` parent entries can be emitted; `TypeDefinitionRowInfo` writes FieldList/MethodList as 0 in deltas (Roslyn parity).
- The comment blocks reference Roslyn/C# Enc reference templates for several row kinds (new_class, new_enum, generic_method_add, generic_constraint_add) that establish the expected EncLog/EncMap entry patterns.
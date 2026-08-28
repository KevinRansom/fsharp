# FSharpDeltaMetadataWriter.fs

**Purpose**
Top-level orchestration of hot-reload delta metadata emission. Given the per-generation delta row descriptions (Type/Nested/InterfaceImpl/MethodImpl/Constant/Method/Param/Field/TypeRef/MemberRef/MethodSpec/TypeSpec/GenericParam/GenericParamConstraint/AssemblyRef/Property/Event maps/MethodSemantics/StandAloneSig/CustomAttribute rows, user-string literals, and methodbody updates) plus the baseline heap offsets and external row counts, it builds a `DeltaMetadataTables` mirror, validates primary-key ordering, computes the EncLog/EncMap entries in Roslyn/CLR EnC-applier order, computes sizing (`DeltaTableLayout.computeBitMasks`, `DeltaIndexSizing.compute`), and serializes the delta metadata root + heap streams (`DeltaMetadataSerializer.*`) into a `MetadataDelta` blob ready for the delta writer to install into the baseline PE.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.FSharpDeltaMetadataWriter`)

**TypeDefs declared**
- Type aliases reusing `DeltaMetadataTypes.*`: `MethodDefinitionRowInfo`, `ParameterDefinitionRowInfo`, `FieldDefinitionRowInfo`, `PropertyDefinitionRowInfo`, `EventDefinitionRowInfo`, `MethodSpecificationRowInfo`, `TypeSpecificationRowInfo`, `GenericParamRowInfo`, `GenericParamConstraintRowInfo`, `PropertyMapRowInfo`, `EventMapRowInfo`, `MethodSemanticsMetadataUpdate`; `StandaloneSignatureUpdate = IlxDeltaStreams.StandaloneSignatureUpdate`.
- `MethodMetadataUpdate` (record) — `{ MethodKey: MethodDefinitionKey; MethodToken: int; MethodHandle: MethodDefHandle; Body: MethodBodyUpdate }` — the method-body payload paired with the MethodDef row.
- `MetadataDelta` (record) — the full emission result: `Metadata`, `StringHeap`, `BlobHeap`, `GuidHeap` byte arrays, `EncLog : (TableName * int * EditAndContinueOperation)[]`, `EncMap : (TableName * int)[]`, `TableRowCounts`, `HeapSizes`, `HeapOffsets`, `Tables: TableRows`, `TableBitMasks`, `IndexSizes`, `TableStream: DeltaTableStream`, `GenerationId` (this generation's EncId), `BaseGenerationId` (previous generation's EncId, Empty for generation 1).

**Public API surface**
- `emit (moduleName, moduleNameOffset, generation, encId, encBaseId, moduleId, methodDefinitionRows, parameterDefinitionRows, propertyDefinitionRows, eventDefinitionRows, propertyMapRows, eventMapRows, methodSemanticsRows, standaloneSignatureRows, customAttributeRows, updates, heapOffsets, externalRowCounts) : MetadataDelta` — the minimal entry point (methods + property/event maps + standalone sigs).
- `emitWithReferences (...)` — back-compat: adds field/type-ref/member-ref/method-spec/assembly-ref rows.
- `emitWithUserStrings (...)` — adds user-string literal updates.
- `emitWithTypeDefinitions (...)` — the full entry point: also supports ADDED `TypeDefinitionRowInfo`, `NestedClassRowInfo`, `InterfaceImplRowInfo`, `MethodImplRowInfo`, `ConstantRowInfo`, `TypeSpecificationRowInfo`, `GenericParamRowInfo`, `GenericParamConstraintRowInfo` rows.

**Internal helpers**
- `shouldTraceMetadata / shouldTraceHeaps / shouldTraceMethodRows` — env-var gated tracing (`FSHARP_HOTRELOAD_TRACE_METADATA`, `FSHARP_HOTRELOAD_TRACE_HEAPS`, `FSHARP_HOTRELOAD_TRACE_METHODS`); diagnostic `printfn` output only.
- `sortRowsByRowId tableName getRowId rows` — sort delta rows by row id so the #~ stream is monotone in row order.
- `validatePrimaryKeyOrder tableName getPrimaryKey rows` — verify (for tables the CLR requires sorted — e.g. `GenericParam` by `(owner,row)`, `GenericParamConstraint` by owner) that delta rows are non-decreasing in the primary key, since delta rows are appended, not globally sorted.

**Significant internal logic**
- The empty-delta shortcut: if there is no row payload and no updates, the writer still returns a well-formed (but empty) `MetadataDelta` with computed sizes, so the runtime sees a valid delta header.
- The module builds a fresh `DeltaMetadataTables` mirror (per-generation) seeded with the current `metadataHeaps` and heap start offsets, then emits rows in the order the CLR EnC applier expects:
  - TypeDef rows: `(TypeDef, rowId, Default)` EncLog — added before their member rows.
  - NestedClass rows: `(Nested, rowId, Default)` — Roslyn's reference templates log plain Default.
  - InterfaceImpl rows: `(InterfaceImpl, rowId, Default)`.
  - MethodImpl rows: `(MethodImpl, rowId, Default)`.
  - Constant rows: `(Constant, rowId, Default)` (for ADDED enum / union-tag / `<Literal>` fields).
  - Method rows: `AddMethod(parent TypeDef, rowId)` for **ADDED** methods; `(Method, rowId, Default)` for all; added **before** parameter/property/event maps that reference them.
  - Parameter rows: `AddParameter(owner Method, rowId)` for **ADDED**; `(Param, rowId, Default)` for all; **before** their owning method row in the EncLog (CLR applies AddParameter first, then the Default).
  - Field rows: `AddField(parent TypeDef, rowId)` then `(Field, rowId, Default)` for **ADDED**; **after** their TypeDef row in the EncLog; added to `EncMap`.
  - Property rows: `AddProperty(owner TypeDef, rowId)` for **ADDED** (CLR's AddPropertyToPropertyMap links to PropertyMap); `(Property, rowId, Default)` for all.
  - Event rows: `AddEvent(owner TypeDef, rowId)` for **ADDED**; `(Event, rowId, Default)` for all.
  - PropertyMap / EventMap rows: `(PropertyMap, rowId, Default)` / `(EventMap, rowId, Default)`.
  - MethodSemantics rows: `(MethodSemantics, rowId, Default)`.
  - TypeRef/MemberRef/MethodSpec/TypeSpec/AssemblyRef rows: `(…, rowId, Default)` — appended, not linked.
  - GenericParam rows: `(GenericParam, rowId, Default)` — sorted by `(owner.RowId <<< 1) ||| owner.CodedTag` (typeOrMethodDefKey), validated for primary-key order.
  - GenericParamConstraint rows: `(GenericParamConstraint, rowId, Default)` — sorted by `OwnerGenericParamRowId`, validated.
  - StandAloneSig rows: `(StandAloneSig, rowId, Default)`.
  - CustomAttribute rows: `(CustomAttribute, rowId, Default)` — appended, not globally sorted (enforced by `DeltaTableLayout.computeBitMasks` clearing the `CustomAttribute` sorted bit for EnC deltas).
- `EncMap` entries: the union of every row's `(table, rowId)` added to any table in this generation, sorted by token (table, row) for the CLR EnC applier's binary search.
- After all rows are emitted, the writer calls `DeltaMetadataSerializer.computeMetadataSizes` and `buildTableStream`, `buildHeapStreams`, and `serializeMetadataRoot` to produce the final `MetadataDelta.Metadata` blob.

**Cross-references**
- `DeltaMetadataTables.fs` (mirror + heaps), `DeltaMetadataSerializer.fs` (sizing + stream), `DeltaTableLayout.fs` (bit masks), `DeltaIndexSizing.fs` (index widths), `DeltaMetadataTypes.fs` (row contracts), `DeltaMetadataEncoding.fs` (row-element tags), `ILDeltaHandles.fs` (handles / DUs / EnC operations), `IlxDeltaStreams.fs` (`MethodBodyUpdate`, `StandaloneSignatureUpdate`), `EncMethodDebugInformation.fs` (the PDB side of EnC — method ordinal / local slot / lambda / state machine maps), `BinaryConstants.fs` (`TableName`, `EditAndContinueOperation`)

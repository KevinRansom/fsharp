# FSharpDeltaMetadataWriter.fs

## Pipeline role

Top-level orchestrator of delta (Edit-and-Continue) metadata emission for hot-reload. Consumes the row lists produced by the compiler's change enumerators, builds a `DeltaMetadataTables` mirror, computes EncLog/EncMap, serializes the metadata root via `DeltaMetadataSerializer`, and returns a `MetadataDelta` consumed by the driver. This is the primary call site for the other `Delta*` modules.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.FSharpDeltaMetadataWriter` (module `internal`)
- Uses: `ILMetadataHeaps`, `BinaryConstants`, `ILDeltaHandles`, `IlxDeltaStreams`, `DeltaMetadataTables`, `DeltaMetadataTypes`, `DeltaTableLayout`, `DeltaMetadataSerializer`.

## Trace flags

- Literals `TraceMetadataFlagName = "FSHARP_HOTRELOAD_TRACE_METADATA"`, `TraceHeapsFlagName = "FSHARP_HOTRELOAD_TRACE_HEAPS"`, `TraceMethodsFlagName = "FSHARP_HOTRELOAD_TRACE_METHODS"`; each enabled when the env var equals `"1"`/`"true"` (case-insensitive).
- `isEnvVarTruthy` is a local copy of `EnvironmentHelpers.isEnvVarTruthy` kept in-file to avoid pulling an out-of-scope dependency.
- `shouldTraceMetadata ()`, `shouldTraceHeaps ()`, `shouldTraceMethodRows ()`.

## Types

- Type aliases for all row-info records from `DeltaMetadataTypes`: `MethodDefinitionRowInfo`, `ParameterDefinitionRowInfo`, `FieldDefinitionRowInfo`, `PropertyDefinitionRowInfo`, `EventDefinitionRowInfo`, `MethodSpecificationRowInfo`, `TypeSpecificationRowInfo`, `GenericParamRowInfo`, `GenericParamConstraintRowInfo`, `PropertyMapRowInfo`, `EventMapRowInfo`, plus `MethodSemanticsMetadataUpdate` and `StandaloneSignatureUpdate` (from `IlxDeltaStreams`).
- `MethodMetadataUpdate` (record) — `{ MethodKey: MethodDefinitionKey; MethodToken: int; MethodHandle: MethodDefHandle; Body: MethodBodyUpdate }`.
- `MetadataDelta` (record) — the emission result:
  - `Metadata: byte[]` — serialized metadata root.
  - `StringHeap`, `BlobHeap`, `GuidHeap: byte[]`.
  - `EncLog: (TableName * int * EditAndContinueOperation) array`.
  - `EncMap: (TableName * int) array`.
  - `TableRowCounts: int[]`, `HeapSizes: MetadataHeapSizes`, `HeapOffsets: MetadataHeapOffsets`, `Tables: TableRows`, `TableBitMasks: TableBitMasks`, `IndexSizes: CodedIndexSizes`, `TableStream: DeltaTableStream`.
  - `GenerationId: Guid` (EncId of this generation, next generation's EncBaseId) and `BaseGenerationId: Guid`.

## Helper functions

- `sortRowsByRowId tableName getRowId rows` — sorts and rejects duplicate row ids; the `getRowId` returns the value used for the sort.
- `validatePrimaryKeyOrder tableName getPrimaryKey rows` — checks rows are ordered by primary key (so row ids are allocated in ECMA required order).
- `hasConstantKey (parent: HasConstant)` — coded token `(RowId <<< 2) ||| tag` over `HasConstant` (Field=0, Param=1, Property=2).
- `typeOrMethodDefKey (owner: TypeOrMethodDef)` — coded token `(RowId <<< 1) ||| CodedTag`.
- `hasSemanticsKey` — coded token over `MethodSemanticsAssociation` (Event=2-tag `RowId <<< 1`, Property=`(RowId <<< 1) ||| 1`).

## Entry points

- `emitWithTypeDefinitions ...` — the full-featured emission (takes all row lists plus `heapOffsets` and `externalRowCounts`):
  1. Sorts MethodDef rows; short-circuits (no row payload) to an empty delta (empty heaps, empty EncLog/EncMap, computed row counts from an empty mirror).
  2. Builds the `DeltaMetadataTables` mirror, adding the Module row (generation 1 = EncBaseId `Guid.Empty`, else `encBaseId`).
  3. Validates one-to-one correspondence between MethodDef rows and method updates (both directions, by `MethodDefinitionKey`).
  4. Seeds EncLog/EncMap with the Module row; collects per-table EncLog entry groups for TypeDef, NestedClass, InterfaceImpl, MethodImpl, Constant, Method, Param, Field, GenericParam, GenericParamConstraint, PropertyMap/Property, EventMap/Event, MethodSemantics and plain-Default reference tables (TypeRef, MemberRef, MethodSpec, TypeSpec, AssemblyRef, StandAloneSig, CustomAttribute).
  5. Adds UserString heap literals for `userStringUpdates` (offset = `newToken &&& 0x00FFFFFF`).
  6. Assembles EncLog in the established F# order: Module; TypeDef defaults; Field AddField pairs; Method rows (AddMethod + Default pairs); Param (AddParameter + Default pairs); GenericParam entries; reference tables; PropertyMap/Property pairs; EventMap/Event pairs; MethodSemantics; InterfaceImpl; MethodImpl; NestedClass; Constant; then any unhandled tables sorted by token. (Long comments document Roslyn/CLR parity for each shape, e.g. the parent `Add*` -> child `Default` adjacency rule.)
  7. Sorts EncMap by token; writes EncLog/EncMap rows into the mirror.
  8. Runs `computeMetadataSizes`, then `buildTableStream` and `buildHeapStreams`, then `serializeMetadataRoot`.
  9. Heap sizes: StringHeap uses the unpadded length (SRM trims trailing zeros), UserString/Blob/Guid heaps use padded lengths (SRM does not trim) — matters for EnC offset calculations via `MetadataAggregator`.
  10. Returns the `MetadataDelta` (wired to trace output when flags set).
- `emitWithUserStrings`, `emitWithReferences`, `emit` — back-compat wrappers that fix the newest row categories to `[]` and delegate up the chain (`emit` -> `emitWithReferences` -> `emitWithUserStrings` -> `emitWithTypeDefinitions`).

## Significant internal logic

- EncLog semantics for ADDED members mirror Roslyn `DeltaMetadataWriter.PopulateEncLogTableRows`: an added member is logged as its PARENT row tagged with the `Add*` operation immediately followed by the member's own `Default` row; the CLR EnC applier (CMiniMdRW::ApplyDelta) reads the parent token from the `Add*` entry and attaches the member created by the following entry. Map rows must precede the pairs that reference them, and method rows must precede the parameter pairs that reference them.
- The method EncLog (line 942) and heap-size comments (lines 805-815) document parity decisions verified against a C# hot-reload reference delta generator and the CLR's EnC applier.
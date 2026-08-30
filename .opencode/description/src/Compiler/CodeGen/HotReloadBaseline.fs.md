# HotReloadBaseline.fs

**Purpose**: Produces a *baseline snapshot* of a compiled assembly's IL metadata (plus optional portable PDB data and compiler-generated name information) that downstream hot-reload / incremental-build tooling can diff against the next compilation. The baseline is a stable, serializable structure (`FSharpEmitBaseline`) so that a delta engine can match types, methods, fields, properties, and events between two compilations by token and by name+signature.

**Namespace / module declared**: `FSharp.Compiler.HotReloadBaseline` (internal module; no .fsi)

**Types declared**:
- `SynthesizedNameSnapshotSource` — `Recorded` (the compiler recorded the generated names during this compilation) or `Reconstructed` (names were reconstructed from metadata after the fact).
- `PortablePdbSnapshot = { Bytes; TableRowCounts; EntryPointToken }` — the PDB stream bytes, its table row counts, and the optional entry-point token.
- `TypeDefinitionKey = { RowId; Namespace; Name }` — identity of a TypeDef in the baseline.
- `MethodDefinitionKey = { DeclaringType : TypeDefinitionKey; Name; Signature : byte list }`.
- `FieldDefinitionKey = { DeclaringType : TypeDefinitionKey; Name; Signature : byte list }`.
- `PropertyDefinitionKey = { DeclaringType : TypeDefinitionKey; Name; Signature : byte list }`.
- `EventDefinitionKey = { DeclaringType : TypeDefinitionKey; Name; EventType : int }`.
- `BaselineTokenMaps` — maps each of the five key types above to its stable metadata **token** (the 32-bit metadata token used in IL, composed as `tableId <<< 24 ||| rowId`).
- `FSharpEmitBaseline` — the final baseline structure: `ModuleId : Guid`, `Metadata : ILBaselineReader.MetadataSnapshot`, `PortablePdb : PortablePdbSnapshot option`, `TokenMaps : BaselineTokenMaps`, `SynthesizedNameSnapshot : Map<string, string[]>`, `SynthesizedNameSnapshotSource`, and the two Enc-Debug-Info maps `EncMethodDebugInfos` and `EncClosureNames`.

**API surface** (notable `let internal` values):
- `collectSynthesizedNameSnapshot (ilModule: ILModuleDef)` — walk the emitted IL module and record the compiler-generated names (closure names, etc.) into a bucketed `Map<string, string[]>` keyed by the name's "base" (with the per-instance suffix stripped out).
- `collectRecordedSynthesizedNameSnapshot (_compilerGlobalState) (map: ICompilerGeneratedNameMap) = map.Snapshot` — use the names that the compiler *recorded* during this compilation (preferred over reconstruction when available).
- `tryReadFromAssemblyAndPdbBytes (assemblyBytes) (portablePdbBytes: byte[] option) : FSharpEmitBaseline option` — produce a baseline from raw assembly bytes + optional PDB bytes. Returns `None` if the assembly cannot be parsed.
- `readFromAssemblyAndPdbBytes (assemblyBytes) (portablePdbBytes) : FSharpEmitBaseline` — the same, but raises on error.
- `metadataSnapshotFromBytes = ILBaselineReader.metadataSnapshotFromBytes` — re-exported convenience.
- `readModuleMvid = ILBaselineReader.readModuleMvidFromBytes` — re-exported convenience.
- `deriveEncClosureNamesFromEncDebugInfos ...` — reconstruct the per-method closure-name maps from the Enc debug info.

**Helpers (private)**:
- Token builders `typeDefToken rowId`, `fieldToken rowId`, `methodDefToken rowId`, `eventToken rowId`, `propertyToken rowId` — encode `(tableId <<< 24) ||| rowId` using the standard metadata table ids (0x02 TypeDef, 0x04 Field, 0x06 MethodDef, 0x14 Event, 0x17 Property).
- `buildTypeKeys (reader)` — enumerate `TypeDef` rows into `Map<int rowId, TypeDefinitionKey>`.
- `buildTokenMaps (reader)` — build the full `BaselineTokenMaps` (five `Map`s) from the reader; each map is keyed by the corresponding `*DefinitionKey` struct (which carries the declaring type, name, and raw signature blob) and maps to the metadata token.
- `addSynthesizedName` / `snapshotFromBuckets` / `cleanUpGeneratedTypeName` / `formatOccurrenceChainKey` / `formatGenerationSuffixedClosureName` / `typeDefSimpleNames` / `methodNamesByToken` — the name-snapshot machinery.
- `toPortablePdbSnapshot (expectedContentId) (pdbBytes)` — wrap the PDB bytes plus its table row counts and entry-point token (checking the CodeView content id matches the expected one).
- `createCore` / `collectSynthesizedNameSnapshotFromTokens` — assemble the final `FSharpEmitBaseline`.

**Significant internal logic**:
- The entire baseline is a *pure function of (assembly bytes, PDB bytes?)*: no live compiler state is needed, and the same baseline can be re-constructed from a previously-compiled `.dll`. This is what makes it usable as the input to a diff engine in the hot-reload flow (`FSharpDeltaMetadataWriter` and friends, in `src/Compiler/CodeGen/Legacy/` / the delta-metadata writer).
- Token maps are the stable anchor: a method that is semantically identical between two compilations has the same `DeclaringType + Name + Signature`, hence the same key, hence the same row in the key set; the *token* (which changes if the type/method is re-ordered within the module) is the value that the delta writer uses to address the IL.
- The synthesized-name snapshot captures compiler-generated names (closures, nested locals, etc.) so that the delta writer can keep referencing the *original* generated name when a user-visible API is unchanged — important for tools that match by name.
- `EncMethodDebugInfos` and `EncClosureNames` are the per-method EnC (editable) debug info and the per-method closure-name maps (used to derive `EncClosureNames` when the Enc map was not recorded).

**Cross-references**:
- `ILBaselineReader.fs` (sibling in `src/Compiler/CodeGen/`) — provides `BaselineMetadataReader`, `MetadataSnapshot`, and the low-level `.Net` PE/COFF metadata parsing (the `metadata` and `portablePdb` members of `FSharpEmitBaseline` are built by it).
- `FSharp.Compiler.AbstractIL.IL` and `FSharp.Compiler.AbstractIL.EncMethodDebugInformation` — the IL metadata tree and EnC info types.
- `FSharp.Compiler.CompilerGeneratedNameMapState` / `FSharp.Compiler.GeneratedNames` / `FSharp.Compiler.Syntax.PrettyNaming` — the generated-name bookkeeping used to populate the snapshot.
- Downstream of `IlxGen.fs` (which produces the `ILModuleDef` that feeds `collectSynthesizedNameSnapshot`); feeds the F# delta-metadata writer.
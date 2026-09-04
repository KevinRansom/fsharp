# EncMethodDebugInformation.fsi

**Purpose**
Interface contract for the Edit-and-Continue method debug information blobs. Replicates, byte for byte, the three Portable-PDB CustomDebugInformation blob formats Roslyn persists per method to support Edit and Continue (EnC Local Slot Map, EnC Lambda and Closure Map, EnC State Machine State Map), plus an F#-owned synthesized-name snapshot CDI blob. All multi-byte integers use ECMA-335 compressed unsigned/signed encodings; "syntax offset" slots are opaque caller-defined deterministic integer keys.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.EncMethodDebugInformation`)

**Modules / TypeDefs declared**
- `PortableCustomDebugInfoKinds` (RequireQualifiedAccess module) — CDI kind GUIDs: `encLocalSlotMap` (755F52A8-…-209571E552BD), `encLambdaAndClosureMap` (A643004C-…-30D64F4979DE), `encStateMachineStateMap` (8B78CD68-…-E15884B8AAA3), `fsharpSynthesizedNameSnapshot` (F#-owned).
- `EncLocalSlotInfo` (union, RequireQualifiedAccess) — `Temp` (lowering temp, serialized as 0x00) | `Slot of kind * syntaxOffset * ordinal`.
- `EncClosureInfo` (record) — `{ SyntaxOffset }`.
- `EncLambdaInfo` (record) — `{ SyntaxOffset; ClosureOrdinal }`.
- `EncStateMachineStateInfo` (record) — `{ StateNumber; SyntaxOffset }`.
- `EncMethodDebugInformation` (record + `Empty` static) — `{ MethodOrdinal; LocalSlots; Closures; Lambdas; StateMachineStates }`, mirroring Roslyn's `EditAndContinueMethodDebugInformation`.

**Constants** (literals)
- `StaticClosureOrdinal = -1`, `ThisOnlyClosureOrdinal = -2`, `MinClosureOrdinal = -2`, `UndefinedMethodOrdinal = -1`, `MaxSerializableLocalKind = 0x3E`.

**Public API surface**
- `tryEncodeOccurrenceKey / decodeOccurrenceKey` — pack/unpack a short (depth ≤ 2) ordinal chain into an int key.
- `serializeLocalSlots / deserializeLocalSlots`, `serializeLambdaMap / deserializeLambdaMap`, `serializeStateMachineStates / deserializeStateMachineStates` — byte-for-byte Roslyn-compatible blob (de)serialization.
- `deserialize(slotMapBlob, lambdaMapBlob, stateMachineStateMapBlob)` — combined reconstruction (any blob may be null/empty).
- `readEncMethodDebugInfoFromPortablePdb: byte[] -> Map<int, EncMethodDebugInformation>` — decodes all EnC method-level CDI rows of a Portable PDB, keyed by MethodDef token.
- `serializeSynthesizedNameSnapshot / deserializeSynthesizedNameSnapshot / computeSynthesizedNameSnapshotCustomDebugInfoRows` (rows as `ILPdbWriter.PdbModuleCustomDebugInfo`) and `readSynthesizedNameSnapshotFromPortablePdb`.

**Significant notes on the contract**
- Serialization returns empty array when there is nothing to persist (callers skip the CDI row).
- State-machine entries sorted by syntax offset (stable) for ≤ 256 entries per offset.
- Fail-safe reads: non-PDB/garbage images yield empty maps.

**Cross-references**
- `EncMethodDebugInformation.fs` (implementation), `ilwritepdb.fs` (`ILPdbWriter.PdbModuleCustomDebugInfo`, CDI row emission), `FSharpDeltaMetadataWriter.fs` (hot-reload PDB delta consumption)

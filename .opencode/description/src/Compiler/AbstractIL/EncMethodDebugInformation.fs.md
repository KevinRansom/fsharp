# EncMethodDebugInformation.fs

**Purpose**
Implementation of the Edit-and-Continue method debug information blob encodings (contract in `EncMethodDebugInformation.fsi`). Replicates, byte for byte, the three Portable-PDB `CustomDebugInformation` blob formats Roslyn persists per method for Edit and Continue — the EnC Local Slot Map, the EnC Lambda and Closure Map, and the EnC State Machine State Map — using `System.Reflection.Metadata` `BlobBuilder`/`BlobReader` compressed-unsigned/signed integer I/O, exactly as Roslyn (`EditAndContinueMethodDebugInformation.cs`) does. Also implements the F#-owned synthesized-name snapshot CDI blob and the readers that decode the blobs back out of a Portable PDB image.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.EncMethodDebugInformation`)

**Constants**
- `StaticClosureOrdinal = -1`, `ThisOnlyClosureOrdinal = -2`, `MinClosureOrdinal = -2`, `UndefinedMethodOrdinal = -1`, `SyntaxOffsetBaselineMarker = 0xFF` (private), `MaxSerializableLocalKind = 0x3E`, `MaxOccurrenceSegment = 0xFFFF` / `MaxOccurrenceKey = 0x1FFFFFFD` (private), `SynthesizedNameSnapshotBlobVersion = 1` (private).
- CDI kind GUIDs (from `PortableCustomDebugInfoKinds`): `encLocalSlotMap = 755F52A8-91C5-45BE-B4B8-209571E552BD`, `encLambdaAndClosureMap = A643004C-0240-496F-A783-30D64F4979DE`, `encStateMachineStateMap = 8B78CD68-2EDE-420B-980B-E15884B8AAA3`, `fsharpSynthesizedNameSnapshot = 49DDB47E-9C74-46EC-8626-0350676571EB` (F#-owned, records `FSharpSynthesizedTypeMaps.Snapshot` bucket arrays in allocation-slot order).

**Types defined (mirroring the .fsi)**
- `EncLocalSlotInfo` (union, RequireQualifiedAccess) — `Temp | Slot of kind * syntaxOffset * ordinal`.
- `EncClosureInfo` / `EncLambdaInfo` / `EncStateMachineStateInfo` (records) and `EncMethodDebugInformation` (record + `Empty` static member).

**Public API (per .fsi)**
- `tryEncodeOccurrenceKey` / `decodeOccurrenceKey` — pack/unpack a root-first ordinal chain (depth ≤ 2, 16-bit segments) into / out of a single deterministic int suitable for a "syntax offset" blob slot.
- `synthesize/serializeSynthesizedNameSnapshot` / `deserializeSynthesizedNameSnapshot` / `computeSynthesizedNameSnapshotCustomDebugInfoRows` — the F#-owned synthesized-name snapshot CDI blob helpers; empty snapshot → empty blob → no CDI row.
- `serializeLambdaMap` / `deserializeLambdaMap` — EnC Lambda and Closure Map blob (method ordinal + closures + lambdas); returns empty array when there are no lambdas or closures (Roslyn skips the row in that case).
- `serializeLocalSlots` / `deserializeLocalSlots` — EnC Local Slot Map blob; returns empty when there are no slots.
- `serializeStateMachineStates` / `deserializeStateMachineStates` — EnC State Machine State Map blob; entries sorted by syntax offset (stable) so per-offset relative ordinal is preserved.
- `deserialize (slotMapBlob, lambdaMapBlob, stateMachineStateMapBlob)` — combined reconstruction (mirrors Roslyn's `Create`).
- `readEncMethodDebugInfoFromPortablePdb (pdbBytes) : Map<int, EncMethodDebugInformation>` — decodes all EnC method-level CDI rows of a Portable PDB, keyed by MethodDef token (0x06xxxxxx); fail-safe (non-PDB/garbage → empty map).
- `readSynthesizedNameSnapshotFromPortablePdb (pdbBytes) : Map<string, string[]> option` — reads the F#-owned snapshot; `None` on absent/invalid (callers must fall back to IL reconstruction).

**Internal helpers (notable)**
- `writeUtf8String` / `readUtf8String` — length-prefixed UTF-8 string I/O for the synthesized-name snapshot blob.
- `materializeSynthesizedNameSnapshot` — materializes the (lazily computed) snapshot into a deterministic in-memory form for the blob.
- `invalidData (blobName) (offset)` — diagnostic helper for malformed blob reads.
- `isEmpty (blob)` — `isNull || Length = 0`.

**Significant internal logic**
- All multi-byte integers go through `BlobBuilder.WriteCompressedInteger`/`WriteCompressedSignedInteger` and `BlobReader.ReadCompressedInteger`/`ReadCompressedSignedInteger` — exactly matching Roslyn's encoding.
- `deserialize*` functions enforce Roslyn's validations (ordered-by-offset, ≤ 256 per syntax offset in the state machine state map, etc.) and fail closed on malformed data (`invalidData`).
- The synthesized-name snapshot blob is versioned (`SynthesizedNameSnapshotBlobVersion = 1`) so future layout changes are detectable.

**Cross-references**
- `EncMethodDebugInformation.fsi` (contract), `ilwritepdb.fs` (consumes the `PdbMethodCustomDebugInfo`/`PdbModuleCustomDebugInfo` side-channel rows), `FSharpDeltaMetadataWriter.fs` (reads the baseline PDB's EnC blobs to plan the delta), `ilwrite.fsi` (the `options.methodCustomDebugInfoRows` / `options.moduleCustomDebugInfoRows` side channels)

# IlxDeltaStreams.fs

**Purpose**
Part of the hot-reload delta stream machinery. Accumulates the EnC method-body IL payloads and per-body metadata (local signature tokens, exception regions) into the delta `IL` stream, and provides pure-F# token calculators (replacing SRM's `MetadataBuilder`) for user-string and StandAloneSig tokens so token sizing can't drift between the delta stream builder and the metadata table writer.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.IlxDeltaStreams`)

**TypeDefs declared**
- `UserStringTokenCalculator(heapStartOffset)` — get-or-add user strings; token = `0x70000000 | absoluteOffset`; first literal starts at relative offset 1 (offset 0 reserved).
- `StandaloneSignatureTokenCalculator(baselineRowCount)` — dedup'd StandAloneSig blobs; token = `0x11000000 | rowId` (row numbering continues past baseline count); `GetSignatures() : (int * byte[]) list`.
- `MethodBodyUpdate` (record) — `{ MethodToken; LocalSignatureToken; CodeOffset; CodeLength }`.
- `StandaloneSignatureUpdate` (record) — `{ RowId; Blob }`.
- `IlDeltaStreams` (record) — final payload: `IL: byte[]`, `MethodBodies`, `StandaloneSignatures`.
- `IlDeltaStreamBuilder(initialUserStringHeapSize, initialStandAloneSigRowCount)` (class, also `new()` for baseline-less generation-1/test use).

**Public API surface** (class members)
- `AddMethodBody(methodToken, localSignatureToken, ilBytes, maxStack, initLocals, exceptionRegions: IlExceptionRegion[], remapEntityToken: int -> int) : MethodBodyUpdate` — encodes a fat-format method body.
- `AddStandaloneSignature(signature) : int`, `Build() : IlDeltaStreams` (single-use), `UserStringCalculator`, `MethodBodies`, `StandaloneSignatures`.

**Internal helpers**
- `encodeUserString` — ECMA-335 II.24.2.4 #US encoding (compressed length + UTF16 + trailing marker byte 0xFE/0xFF).
- `alignStream` (padding helper).

**Significant internal logic**
- `AddMethodBody` writes a CorILMethod fat header (flags, 0x30 reserved marker, MaxStack, CodeSize, LocalSignatureToken), 4-byte-aligned IL bytes, then an EHTable data section (MoreSects) when exception regions exist — choosing small EHTable encoding (12-byte entries) when offsets/lengths fit, else fat 24-byte entries; Catch-type tokens are remapped via `remapEntityToken`.
- `Build()` throws on second invocation to prevent mismatched EnC state.

**Cross-references**
- `ILDeltaHandles.fs` (`IlExceptionRegion`, `IlExceptionRegionKind`), `BinaryConstants.fs` (e_CorILMethod_* flags, markerForUnicodeBytes), `FSharpCompilerCore` ByteBuffer (via `FSharp.Compiler.IO`), `DeltaMetadataTables.fs` (consumes `MethodBodyUpdate`)

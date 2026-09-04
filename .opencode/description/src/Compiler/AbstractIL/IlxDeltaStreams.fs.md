# IlxDeltaStreams.fs

## Pipeline role

Part of the AbstractIL delta metadata (EnC hot-reload) writer infrastructure. This module accumulates the methods-of-state streams of a hot reload delta: metadata tables and Edit-and-Continue bookkeeping are handled elsewhere (DeltaMetadataSerializer), while this module accumulates encoded method bodies plus the user-string (`#US`) and standalone-signature (`StandAloneSig` table) tokens. It replaces the SRM `MetadataBuilder` used by Roslyn with pure F# token calculators so token arithmetic cannot drift between the delta stream builder and the metadata table writer. The class name honors that it back-ends ILX-generated method bodies.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.IlxDeltaStreams` (module `internal`)
- Uses: `System`, `System.Collections.Generic`, `System.Text`, `FSharp.Compiler.AbstractIL.BinaryConstants` (for `e_CorILMethod_*` and `e_COR_ILEXCEPTION_CLAUSE_*` flag constants), `FSharp.Compiler.AbstractIL.ILBinaryWriter` (for `ByteBuffer`), `FSharp.Compiler.AbstractIL.ILDeltaHandles`, `FSharp.Compiler.IO`.

## Functions

- `encodeUserString (value: string) : byte[]` — encodes a user string per ECMA-335 II.24.2.4: UTF-16 bytes plus a trailing terminal byte, prefixed with a variable-length compressed length (1 byte if `blobLength <= 0x7F`, 2 bytes if `<= 0x3FFF`, else 4 bytes). Uses `markerForUnicodeBytes` to compute the terminal byte.

## Types

- `UserStringTokenCalculator(heapStartOffset: int)` (class) — user string heap token calculator. Caches strings by ordinal in a `Dictionary<string, int>` and computes tokens of the form `0x70000000 | heap_offset`. The `#US` heap reserves offset 0 for the null/empty entry, so the first emitted literal starts at relative offset 1.
  - Member `GetOrAddUserString(value: string) : int` — returns the cached token or adds the string, computing `absoluteOffset = heapStartOffset + currentOffset` and advancing the offset by the encoded length.
- `StandaloneSignatureTokenCalculator(baselineRowCount: int)` (class) — standalone signature token calculator, tokens of the form `0x11000000 | row_id` (StandaloneSig table = 0x11). Caches structural byte arrays and numbers rows from `baselineRowCount + 1`.
  - Member `AddStandaloneSignature(signature: byte[]) : int` — returns 0 for empty signatures; else the cached/assigned token, storing a copy of the blob.
  - Member `GetSignatures() : (int * byte[]) list` — returns `(rowId, blob)` tuples for serialization.
- `MethodBodyUpdate` (record) — a method body captured for an EnC delta:
  - `MethodToken: int`, `LocalSignatureToken: int`, `CodeOffset: int`, `CodeLength: int`.
- `StandaloneSignatureUpdate` (record) — `RowId: int`, `Blob: byte[]`. A standalone signature (e.g., a local signature) emitted in the delta metadata.
- `IlDeltaStreams` (record) — the emitted payloads produced by `IlDeltaStreamBuilder`:
  - `IL: byte[]`, `MethodBodies: MethodBodyUpdate list`, `StandaloneSignatures: StandaloneSignatureUpdate list`.

## Classes

- `IlDeltaStreamBuilder(initialUserStringHeapSize: int, initialStandAloneSigRowCount: int)` (class) — accumulates metadata, Enc bookkeeping, and encoded method bodies prior to serializing a hot reload delta, using pure F# token calculators instead of an SRM `MetadataBuilder`. Callers retrieve the resulting bytes via `Build`. Constructor seeds the user-string token calculator with the baseline `#US` heap size and the standalone-signature calculator with the baseline StandAloneSig row count (0 for a baseline-less builder). The eventual baseline snapshot type lives in a not-yet-upstreamed ilwrite change, so callers pass the two relevant values directly.
  - Members:
    - `new()` — constructs a baseline-less builder (generation-1 / test scenarios), i.e. `IlDeltaStreamBuilder(0, 0)`.
    - `UserStringCalculator` — exposes the user-string token calculator for advanced scenarios.
    - `MethodBodies` — inspection hook primarily used in unit tests (list of `MethodBodyUpdate`).
    - `StandaloneSignatures` — the standalone signatures added, mapped to `StandaloneSignatureUpdate` values.
    - `AddMethodBody(methodToken: int, localSignatureToken: int, ilBytes: byte[], maxStack: int, initLocals: bool, exceptionRegions: IlExceptionRegion[], remapEntityToken: int -> int)` — appends a fat-format method body to the IL stream. Computes the CorILMethod flags (`FatFormat`, optional `MoreSects`/`InitLocals`), aligns to 4 bytes, emits the fat header (flags, `0x30`, maxStack, code size, local signature token), pads code to 4 bytes, and if exception regions exist emits either a small or fat EH table. Small EH table format is used when the region sizes fit single-byte limits; otherwise the big (fat) format is used. Exception kinds map to `e_COR_ILEXCEPTION_CLAUSE_*`; Catch types are remapped through `remapEntityToken` (0 means no token). Records a `MethodBodyUpdate` and returns it.
    - `AddStandaloneSignature(signature: byte[])` — delegates to the standalone-signature calculator.
    - `Build()` — finalizes the builder and emits the metadata and IL blobs. Guarantees single consumption: subsequent calls throw `invalidOp "IlDeltaStreamBuilder.Build may only be called once per builder instance."`.

## Significant internal logic

- Token calculators are shared between the stream builder and the table writer so offsets agree exactly: user-string tokens embed absolute heap offsets, standalone-signature tokens embed row ids seeded from the baseline row count.
- `alignStream` pads the method-body stream to 4-byte boundaries; method bodies and EH tables are each aligned independently.
- Small vs fat EH encoding is chosen purely on size/fit criteria (small table limit 0xFF for the whole section, and each region's offsets/lengths within 16-bit/8-bit ranges).
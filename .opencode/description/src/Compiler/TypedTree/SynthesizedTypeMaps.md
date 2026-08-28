# SynthesizedTypeMaps.fs

**Purpose**: Provides stable compiler-generated names across hot reload (Edit-and-Continue) sessions. Implements `FSharpSynthesizedTypeMaps`, a per-provider-compile name map implementing `ICompilerGeneratedNameMap` (from `CompilerGeneratedNameMapState.fs`): allocation order is captured as buckets keyed by line-normalized basic name, so a closure whose code moves from line 28 to line 30 still gets its original birth name back (mirroring Roslyn EnC).

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.SynthesizedTypeMaps`).

**Declared types**:
- `FSharpSynthesizedTypeMaps` — thread-safe (`syncLock`) map with `buckets: Dictionary<string, ResizeArray<string>>`, `ordinals: Dictionary<string, int>`, `usesRecordedSnapshot` flag.

**Public API surface** (implements `ICompilerGeneratedNameMap`):
- `GetOrAddName(basicName: string) : string` — reserves the next ordinal in the normalized-key bucket and returns the recorded name if present, else computes `{base}@hotreload[-ordinal]` via `CompilerGeneratedNameSuffix` and records it.
- `BeginSession: unit -> unit` — resets all ordinal cursors to 0 so replay starts from the first slot.
- `Snapshot: seq<struct (string * string[])>` — current stable names grouped by base name, sorted ordinally.
- `LoadSnapshot: seq<struct (string * string[])> -> unit` — restores a snapshot, canonicalizing/sorting names by parsed hot-reload ordinals and filling holes with computed names.
- `LoadRecordedSnapshot: seq<...> -> unit` — restores a snapshot recorded from this allocator's own allocation slots; skips IL-order reconstruction (bucket arrays are ground truth).
- `UsesRecordedSnapshot: bool` (read-only property, internal use).

**Internal helpers**: `makeHotReloadName` (suffix `"hotreload"` or `"hotreload-{ordinal}"`), `canonicalizeSnapshotNames` (normalizes pure hot-reload buckets: sorts by ordinal, fills holes, requires distinct ordinals; also handles generation-suffixed names via `tryGetStableOrdinal`), `validateName` (accepts legacy/basic names like `@_instance` and hot-reload-managed names), `nameMapKeyFromSnapshotName` (basename → `SynthesizedNameMapKey`), helper `nextName (mapOpt) basicName generate` at module level (falls back to caller's generator when no map installed).

**Significant internal logic**: Buckets are keyed by `SynthesizedNameMapKey` (line-normalized basic name from `GeneratedNames.fs`) rather than the raw name at the call site, so IL metadata enumerating synthesized helpers in a different order than allocation still replays identically. The ordinal is encounter order within a bucket; `GetOrAddName` and bucket mutation happen in a single `lock syncLock` critical section. Snapshots loaded via `LoadSnapshot` are validated against their key (`invalidArg "snapshot"` on mismatch), while recorded snapshots only reject null names because occurrence-keyed closure overrides may intentionally move names across buckets.

**Cross-references**: `CompilerGeneratedNameMapState.fs` (interface), `GeneratedNames.fs` (`SynthesizedNameMapKey`, `TryNormalizeHotReloadReplayName`, `TryNormalizeHotReloadGenerationName`), `CompilerGlobalState.fs` (consumers), `Syntax/PrettyNaming` (`GetBasicNameOfPossibleCompilerGeneratedName`).

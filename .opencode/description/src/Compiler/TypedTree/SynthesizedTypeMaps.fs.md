# SynthesizedTypeMaps.fs

## Pipeline role

This file belongs to the TypedTree folder of the F# compiler. It implements `ICompilerGeneratedNameMap` (see `CompilerGeneratedNameMapState.fs`) for hot-reload / Edit-and-Continue scenarios: `FSharpSynthesizedTypeMaps` provides stable compiler-generated names across hot reload sessions. Replay buckets are keyed by the *line-normalized* basic name (`SynthesizedNameMapKey` over `GeneratedNames`); bucket values are the original generation-0 full names, so a matched closure whose code moves from line 28 to line 30 still receives its line-28 birth name — mirroring Roslyn EnC's "identity established at first allocation and replayed exactly". The allocator can load either a canonicalized on-disk snapshot or a recorded snapshot taken from this allocator's own allocation slots, and it can resume replay with `BeginSession`. The module also exposes the `nextName` fallback helper used elsewhere in the codegen pipeline.

## Module and contents

- `module internal FSharp.Compiler.SynthesizedTypeMaps` — internal module.
- Opens `System`, `System.Collections.Generic`, `FSharp.Compiler.CompilerGeneratedNameMapState`, `FSharp.Compiler.GeneratedNames`, `FSharp.Compiler.Syntax.PrettyNaming`.
- `let nextName (mapOpt: ICompilerGeneratedNameMap option) basicName generate` — uses `map.GetOrAddName basicName` when a map is installed, otherwise `generate ()`.

### `type FSharpSynthesizedTypeMaps()`

Implements `ICompilerGeneratedNameMap`. All state is `syncLock`-protected (`obj ()`) so allocation order and bucket updates stay atomic:

- State: `buckets: Dictionary<string, ResizeArray<string>>` (Ordinal) of stable names per normalized map key; `ordinals: Dictionary<string, int>` (per-key allocation cursors); `mutable usesRecordedSnapshot: bool`.
- `makeHotReloadName baseName ordinal` — `CompilerGeneratedNameSuffix baseName "hotreload"` (ordinal 0) or `"hotreload-{ordinal}"`.
- `createBucket`, `computeName basicName index`, `getOrAddBucket mapKey`.
- `tryGetHotReloadOrdinal mapKey name` — replay-name ordinal, when its normalized basic name equals `mapKey`.
- `tryGetStableOrdinal mapKey name` — prefers the replay-name ordinal (as a `[ordinal]` list); else the generation name's occurrence ordinal.
- `canonicalizeSnapshotNames mapKey (names: string[])` — IL metadata can enumerate synthesized helpers in a different order than allocation, so canonicalization:
  - If every name is a replay name (hot-reload ordinals present): sorts by `(ordinal, index)`; if the ordinals are distinct, places each name at its ordinal slot, filling holes with the computed replay name for that slot (holes arise exactly where an allocation's replay name never surfaced in IL; the filler equals what `GetOrAddName` produced for that slot originally). Non-distinct ordinals → plain sorted names.
  - Otherwise if every name parses to a stable ordinal (replay or generation occurrence chain): distinct ordinals → sorted names; else keep original order.
  - Otherwise keep original order.
- `nameMapKeyFromSnapshotName name` — `GetBasicNameOfPossibleCompilerGeneratedName` then `SynthesizedNameMapKey`.
- `validateName mapKey name index` — snapshots may contain legacy/basic synthesized names (e.g. `@_instance`) alongside hot-reload-managed names; both forms are accepted. Raises `invalidArg "snapshot"` if the name's derived normalized key differs from `mapKey`.
- `loadSnapshotCore canonicalize (snapshot: seq<struct (string * string[])>)` — clears buckets/ordinals, sets `usesRecordedSnapshot` (true when *not* canonicalizing); groups by `SynthesizedNameMapKey`; when `canonicalize` validates each name against its key and canonicalizes via `canonicalizeSnapshotNames` (deduplicating); otherwise (recorded snapshot) only null-validates and keeps identity-preserving order. Fills new `buckets`/`ordinals` (ordinal cursors reset to 0).
- `member GetOrAddName(basicName)` — the allocator: normalizes to `mapKey`, reserves the bucket ordinal (encounter order within the normalized bucket — one critical section so concurrent callers cannot observe/produce out-of-order allocations); if `index < bucket.Count` replays the stored generation-0 name, else mints `computeName basicName index` and appends.
- `member BeginSession()` — resets all ordinal cursors to 0 so subsequent edits reuse the original name ordering.
- `member Snapshot: seq<struct (string * string[])>` — the current stable names, grouped by map key and sorted ordinally.
- `member UsesRecordedSnapshot` — whether the loaded snapshot was a recorded (non-canonicalized) snapshot.
- `member LoadSnapshot(snapshot)` — canonicalized load (`loadSnapshotCore true`): replaces existing allocation state.
- `member LoadRecordedSnapshot(snapshot)` — recorded load (`loadSnapshotCore false`): the bucket arrays are ground truth, so IL-order reconstruction canonicalization and key-derived name validation are intentionally skipped (occurrence-keyed closure overrides can intentionally move a final name into a bucket whose allocation key differs from the name's derived key).
- `interface ICompilerGeneratedNameMap` — delegates all four members.
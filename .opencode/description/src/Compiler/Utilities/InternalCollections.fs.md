# InternalCollections.fs

**Purpose**: Small internal collection utilities: an aging lookup table (`AgedLookup`) and a Most-Recently-Used cache (`MruCache`) that keep a small set of key/value associations, aging out old entries and optionally holding older values only by `WeakReference` so the GC can reclaim them. Used by the compiler for memoization of intermediate results where values must be reference types. Public contract in `InternalCollections.fsi`.

**Namespace(s)** declared: `Internal.Utilities.Collections`

**Modules / Types declared**:
- `[<StructuralEquality; NoComparison>] type internal ValueStrength<'T when 'T: not struct>` — `Strong of 'T | Weak of WeakReference<'T>`; a value's current liveness strength.
- `type internal AgedLookup<'Token, 'Key, 'Value when 'Value: not struct>` — the core aging structure (see API). Note the `'Token` parameter: every member takes a token as its first argument, a discipline hook so callers pass an execution-context token (see `CompilationThreadToken` in `illib.fs`).
- `type internal MruCache<'Token, 'Key, 'Value when 'Value: not struct>` — higher-level cache over `AgedLookup` with `areSame`/`areSimilar` key semantics and an optional `isStillValid` check on values.

**Public API surface** (per InternalCollections.fsi):
- `AgedLookup`:
  - `new : keepStrongly * areSimilar:'Key*'Key->bool * ?requiredToKeep:'Value->bool * ?keepMax:int` (`keepMax` defaults to 75).
  - `TryPeekKeyValue : 'Token * 'Key -> ('Key * 'Value) option` — peek without promoting.
  - `TryGetKeyValue : 'Token * 'Key -> ('Key * 'Value) option` — get and promote to most-recent.
  - `TryGet : 'Token * 'Key -> 'Value option`.
  - `Put : 'Token * 'Key * 'Value -> unit`; `Remove : 'Token * 'Key -> unit`; `Clear : 'Token -> unit`.
  - `Resize : 'Token * newKeepStrongly * ?newKeepMax -> unit`.
- `MruCache`:
  - `new : keepStrongly * areSame * ?isStillValid * ?areSimilar * ?requiredToKeep * ?keepMax` (`areSimilar` defaults to `areSame`).
  - `ContainsSimilarKey`, `TryGetAny`, `TryGet` (validates `areSame` + `isStillValid`), `TryGetSimilarAny`, `TryGetSimilar` (validates only `isStillValid`).
  - `Set`, `RemoveAnySimilar`, `Clear`, `Resize`.
  - Concurrency note (fsi doc): thread-safe in the sense that reads are non-mutating snapshots; concurrent access may see different live sets.

**Internal helpers**:
- `TryPeekKeyValueImpl` — linear `areSimilar` scan of the list.
- `Promote` — removes similar entries and appends `(key, value)` at the end (most-recent).
- `RemoveImpl` — filters out all similar entries.
- `FilterAndHold` — drops `Weak` entries whose target has been collected.
- `AssignWithStrength` — the aging core: after renumbering entries by recency, keeps at most `keepMax` entries (dropping the older ones unless `requiredToKeep`), and downgrades entries older than the `keepStrongly` threshold to `Weak(WeakReference v)`.

**Significant internal logic / behavioral notes**:
- Storage is a plain F# list `('Key * ValueStrength<'Value>) list`, **youngest at the end** (per comment: the order is arbitrary; reversing it would make adding O(1) and removing O(N)).
- "Aging": each `Put`/`Get` runs `FilterAndHold` (reap collected weaks) then `AssignWithStrength`, which enforces two thresholds — `keepStrongly` (entries beyond this index become weak references) and `keepMax` (absolute cap; default 75, chosen because some operations are O(N) and the list must not grow unbounded).
- `requiredToKeep : 'Value -> bool` exempts specific values from both weakening and dropping.
- `MruCache.TryGet` requires the *stored* key to `areSame` the queried key **and** the value to pass `isStillValid` — this is what makes it a "similar-key" (subsumption) cache appropriate for compiler memo tables where e.g. a supertype result stands in for a subtype query.
- The `'Token` first-argument convention threads an execution token (e.g. `CompilationThreadToken`) through all operations by discipline.

**Cross-references**: same namespace as `HashMultiMap` and `LruCache` (siblings). `LruCache` is a different, versioned LRU (strong/weak linked lists + dictionary) in the same namespace; `AgedLookup`/`MruCache` here are the older simpler aging design. Token types come from `illib.fs` (`Internal.Utilities.Library`).

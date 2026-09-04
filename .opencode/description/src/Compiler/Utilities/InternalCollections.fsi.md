# InternalCollections.fsi

**Purpose**: Signature file for `InternalCollections.fs` (same directory, namespace `Internal.Utilities.Collections`). Documents the public contract of the two internal aging/MRU cache structures used for small key/value memo tables in the compiler.

**Namespace(s)** declared: `Internal.Utilities.Collections`

**Declared items** (public contract; both types are `internal`):
- `type internal AgedLookup<'Token, 'Key, 'Value when 'Value: not struct>` — "Simple aging lookup table. When a member is accessed it's moved to the top of the list and when there are too many elements the least-recently-accessed element falls off the end."
  - `new : keepStrongly * areSimilar * ?requiredToKeep * ?keepMax`
  - `TryPeekKeyValue : 'Token * 'Key -> ('Key * 'Value) option` (does not re-order)
  - `TryGetKeyValue : 'Token * 'Key -> ('Key * 'Value) option` (promotes to most-recent; returns the *original* key because `areSimilar` may unify distinct keys)
  - `TryGet : 'Token * 'Key -> 'Value option`
  - `Put`, `Remove`, `Clear : 'Token ...`
  - `Resize : 'Token * newKeepStrongly * ?newKeepMax -> unit`
- `type internal MruCache<'Token, 'Key, 'Value when 'Value: not struct>` — "Simple priority caching for a small number of key/value associations... may age-out results that have been Set by the caller." Concurrency caveat documented: thread-safe but concurrent use may see different live sets.
  - `new : keepStrongly * areSame * ?isStillValid * ?areSimilar * ?requiredToKeep * ?keepMax`
  - `Clear`, `ContainsSimilarKey`, `TryGetAny`, `TryGet` (only if still valid), `TryGetSimilarAny`, `TryGetSimilar` (both skip `areSame` checking unless `areSimilar` given), `RemoveAnySimilar`, `Set`, `Resize`.

**Relationship to .fs**: The .fs additionally defines the `ValueStrength<'T>` union (`Strong | Weak of WeakReference`) and the private implementation helpers (`FilterAndHold`, `AssignWithStrength`, `Promote`, `RemoveImpl`, `TryPeekKeyValueImpl`) which drive the weak-reference aging; none of them appear in the .fsi. The .fsi's prose documentation carries the semantic contract (similar keys, aging-out, thread-safety caveat).

**Cross-references**: siblings in the same namespace — `HashMultiMap.md` (multi-binding hash map) and `LruCache.md` (versioned LRU with strong/weak lists); see `illib.fsi.md` for the execution-token types (`'Token`) these caches thread through their APIs.

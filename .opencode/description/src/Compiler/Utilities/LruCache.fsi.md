# LruCache.fsi

**Purpose**: Signature file for `LruCache.fs` (same directory, namespace `Internal.Utilities.Collections`). Documents the public contract of the internal versioned LRU cache with mixed strong/weak reference storage and event-driven observability.

**Namespace(s)** declared: `Internal.Utilities.Collections`

**Declared items** (public contract; both types are `internal`):
- `[<RequireQualifiedAccess>] type internal CacheEvent` — `Evicted | Collected | Weakened | Strengthened | Cleared`.
- `type internal LruCache<'TKey, 'TVersion, 'TValue when 'TKey: equality and 'TVersion: equality and 'TValue: not struct and 'TKey: not null and 'TVersion: not null>` — "A cache where least recently used items are removed when the cache is full. It's also versioned, meaning each key can have multiple versions and only the latest one is kept strongly. Older versions are kept weakly and can be collected by GC."
  - `new : keepStrongly: int * ?keepWeakly: int * ?requiredToKeep: ('TValue -> bool) * ?event: (CacheEvent -> string * 'TKey * 'TVersion -> unit)`
    - `keepStrongly` — "Maximum number of strongly held results to keep in the cache."
    - `keepWeakly` — "Maximum number of weakly held results to keep in the cache." (default 100 in .fs)
    - `requiredToKeep` — "A predicate that determines if a value should be kept strongly (no matter what)."
    - `event` — "An event that is called when an item is evicted, collected, weakened or strengthened."
  - `Clear : unit -> unit` and `Clear : predicate: ('TKey -> bool) -> unit` ("Clear any keys that match the given predicate").
  - `GetAll : key: 'TKey * version: 'TVersion -> 'TValue option * ('TVersion * 'TValue) list` — value + other versions.
  - `GetAll : key: 'TKey -> ('TVersion * 'TValue) seq` — "The strongly held value is first in the list."
  - `GetValues : unit -> (string * 'TVersion * 'TValue) seq` — all live entries with labels.
  - `Count : int` — "Gets the number of items in the cache."
  - `Remove : key: 'TKey -> unit` and `Remove : key: 'TKey * version: 'TVersion -> unit`.
  - `Set` — three overloads: `(key, value)`, `(key, version, value)`, `(key, version, label, value)`.
  - `TryGet : key: 'TKey -> 'TValue option` and `TryGet : key * version -> option`.
  - `DebuggerDisplay : string`.

**Relationship to .fs**: The .fs additionally defines the `ValueLink<'T>` (`Strong | Weak`) union and the internal helpers (`removeCollected`, `cutWeakListIfTooLong`, `cutStrongListIfTooLong`, `pushNodeToTop`, `pushValueToTop`) which drive the LRU mechanics and weak/strong transitions; none appear in the .fsi.

**Cross-references**: see sibling `LruCache.md` for behavioral details; `InternalCollections.md` (`AgedLookup`/`MruCache`) is a related but distinct aging design in the same namespace; `Caches.md` is the higher-level concurrent cache with metrics.

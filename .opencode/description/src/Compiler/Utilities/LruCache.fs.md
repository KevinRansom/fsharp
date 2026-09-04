# LruCache.fs

**Purpose**: A versioned LRU cache with mixed strong/weak reference storage for the compiler (`internal`, namespace `Internal.Utilities.Collections`). Each key may have multiple versions; only the most-recently-used entries within `keepStrongly` are held by strong reference, older ones are downgraded to `WeakReference` (up to `keepWeakly`, default 100), and anything older than that is evicted. Fires `CacheEvent`s (Evicted, Collected, Weakened, Strengthened, Cleared) for observability. Public contract in `LruCache.fsi`.

**Namespace(s)** declared: `Internal.Utilities.Collections`

**Modules / Types declared**:
- `[<RequireQualifiedAccess>] type internal CacheEvent` — `Evicted | Collected | Weakened | Strengthened | Cleared`.
- `[<StructuralEquality; NoComparison>] type internal ValueLink<'T when 'T: not struct>` — `Strong of 'T | Weak of WeakReference<'T>`; the value's current reference strength.
- `[<DebuggerDisplay("{DebuggerDisplay}")>] type internal LruCache<'TKey, 'TVersion, 'TValue when 'TKey/'TVersion: equality and not null, 'TValue: not struct>` — the cache proper.

**Public API surface** (per LruCache.fsi):
- `new : keepStrongly * ?keepWeakly (100) * ?requiredToKeep : 'TValue->bool * ?event: CacheEvent * label * key * version -> unit`
- `Set` — 3 overloads: `(key, version, label, value)`, `(key, version, value)` (label = `"[no label]"`), `(key, value)` (version = default).
- `TryGet` — `(key, version) -> 'TValue option` and `(key) -> 'TValue option`.
- `GetAll` — `(key, version) -> 'TValue option * ('TVersion * 'TValue) list`; and `(key) -> ('TVersion * 'TValue) seq` (strong-first ordering).
- `GetValues : unit -> (string * 'TVersion * 'TValue) seq` — live (non-collected) entries.
- `Remove` — `(key)` and `(key, version)`.
- `Clear` — `unit` and `Clear : ('TKey -> bool) -> unit` (predicate-filtered; fires `Cleared`).
- `Count : int` — via `GetValues() |> Seq.length`.
- `DebuggerDisplay: string` — e.g. `"Cache(S:3 W:12)"`.

**Internal helpers**:
- `strongList` / `weakList` — two `LinkedList<'TKey * 'TVersion * string * ValueLink<'TValue>>` (most-recent at head).
- `removeCollected` — walks `weakList`, removing nodes whose `Weak` target has been GC'd (firing `Collected`).
- `cutWeakListIfTooLong` — evicts from the older end of `weakList` until it is `<= keepWeakly`.
- `cutStrongListIfTooLong` — demotes older `Strong` entries to `Weak` until `strongList.Count <= keepStrongly`, skipping those marked `requiredToKeep`; then calls `cutWeakListIfTooLong`.
- `pushNodeToTop` / `pushValueToTop` — re-insert at head of `strongList` (asserting it is a `Strong`).

**Significant internal logic / behavioral notes**:
- Storage layout: `Dictionary<'TKey, Dictionary<'TVersion, LinkedListNode<_>>>` plus the two LRU linked lists. The dictionary gives O(1) (key, version) lookup; the lists provide recency order.
- **Versioned semantics**: setting a *new* version of a key demotes all *other* versions of that key to weak (unless `requiredToKeep` marks them), implementing "new version wins, old versions GC-able."
- **Strengthening on hit**: `TryGet` on a `Weak` entry whose target is still alive re-promotes it to `Strong` (fires `Strengthened`) and re-inserts at the head of `strongList`; if the target is gone, it's removed from the dict and list (fires `Collected`).
- **Eviction order**: overflow first demotes strong → weak (respecting `requiredToKeep`); if the weak list overflows `keepWeakly`, oldest weaks are dropped.
- **Concurrency**: no locks; callers are expected to serialize external access. The cache is used in compiler single-context paths (type-checking pipelines, etc.).
- `Set` on an existing (key, version) overwrites the value in place and re-promotes to the head (no event fired for simple overwrite; `Strengthened` only on weak→strong promotion).
- `GetValues` iterates `strongList @ weakList`, projecting out still-live values with their labels and versions — useful for diagnostics.
- `Clear predicate` removes all nodes for matching keys and fires `CacheEvent.Cleared` per node.

**Cross-references**:
- Same namespace as `HashMultiMap` and `AgedLookup`/`MruCache` (see `InternalCollections.md`); `LruCache` is the more sophisticated versioned design.
- Distinct from `Caches.Cache` (sibling `Caches.md`), which is a general-purpose concurrent LRU with metrics; `LruCache` here is versioned, weak-aware, and event-driven but not thread-safe.
- `CacheEvent` and `ValueLink` are internal to this file.

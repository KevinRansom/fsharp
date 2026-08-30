# Caches.fs

**Purpose**: A thread-safe, instrumented cache with LRU-style eviction for the compiler (`internal`). Backed by a `ConcurrentDictionary` plus a `LinkedList` eviction queue, with eviction processing done in a background `MailboxProcessor`, synchronously, or not at all. Integrates with the compiler's `System.Diagnostics.Metrics` telemetry (via `Activity.fs`'s `Metrics.Meter`) and exposes optional `Evicted`/`EvictionFailed` events for tests. Public contract in `Caches.fsi`.

**Namespace(s)** declared: `FSharp.Compiler.Caches`

**Modules / Types declared**:
- `module CacheMetrics` — metrics counters (`adds`, `updates`, `hits`, `misses`, `evictions`, `evictionFails`, `creations`, `disposals`) tagged with the cache name; `Stats` type aggregating per-name totals and a hit ratio; `ListenToAll` (a `MeterListener` for tests / `--times`), `StatsToString`, `CaptureStatsAndWriteToConsole`.
- `[<RequireQualifiedAccess>] type EvictionMode` (internal) — `NoEviction | Immediate | MailboxProcessor`.
- `[<Struct; RequireQualifiedAccess; NoComparison; NoEquality>] type CacheOptions<'Key>` (internal) — record: `TotalCapacity`, `HeadroomPercentage`, `EvictionMode`, `Comparer`.
- `module CacheOptions` (internal) — `getDefault : IEqualityComparer<'Key> -> CacheOptions<'Key>` (capacity 1024, headroom 50%, default eviction mode from env), `getReferenceIdentity`, `withNoEviction`.
- `[<Sealed; NoComparison; NoEquality>] type CachedEntity<'Key, 'Value>` — mutable cell holding a key, value, and its own `LinkedListNode` (the entity and node reference each other, so the type must be a class). Created with `static member Create`.
- `[<Struct>] type EvictionQueueMessage<'Entity, 'Target>` — `Add of entity * target | Update of entity` (the message queue for eviction processing).
- `[<Sealed>] type Cache<'Key, 'Value when 'Key: not null> internal` — the cache implementation (see API).

**Public API surface** (per Caches.fsi):
- `constructor: options: CacheOptions<'Key> * ?name: string -> Cache<'Key, 'Value>`
- `TryGetValue : key * outref<'Value> -> bool` — hit promotes entry to most-recent.
- `TryAdd : key * value -> bool`
- `GetOrAdd : key * (key -> value) -> value` — computes on miss, registers for eviction.
- `AddOrUpdate : key * value -> unit` — updates value in place (keeps same LRU position).
- `Evicted : IEvent<unit>` and `EvictionFailed : IEvent<unit>` (testing only).
- `IDisposable` — cancels/disposes the eviction processor.
- `CacheMetrics.Meter` (exposed for OpenTelemetry export in tests), `ListenToAll`, `StatsToString`, `CaptureStatsAndWriteToConsole`, `getTotalsByName`, `getRatioByName` (internal).

**Internal helpers**:
- `rebuildStore` — when eviction keeps failing (dead keys whose identity is stale/rehashed), the whole `ConcurrentDictionary` is rebuilt from the eviction queue to drop dead entries.
- `startEvictionProcessor` — the `MailboxProcessor` loop that serially applies eviction messages.

**Significant internal logic / behavioral notes**:
- Capacity split: `capacity = TotalCapacity - headroom`, where headroom is `HeadroomPercentage%` of total. Eviction removes an entry once the LRU (eviction) list exceeds `capacity`; the store itself is never resized, the headroom gives slack so eviction doesn't lag.
- `Add` path: if `store !== target` was captured when the message was queued (store was rebuilt in the meantime), the message handler re-inserts the entity into the new store; otherwise the entity is already present.
- `Update` path: just moves the node to the end of the eviction queue (most-recently-used).
- If an eviction attempt fails (`store.TryRemove` misses), `EvictionFailed` fires and `deadKeysCount` increments; when it exceeds `headroom/2`, `rebuildStore` is called.
- `CacheOptions.forceImmediate` reads the `FSharp_CacheEvictionImmediate` env var to force `EvictionMode.Immediate` (useful for tests/determinism).
- `CachedEntity` is intentionally a *class* (not a struct) because the `LinkedListNode` holds a strong reference back to the entity and vice versa (circular), and structs would break that.
- `Dispose` is idempotent (via `Interlocked.Exchange` on a `disposed` flag) and there is also a finalizer that calls `Dispose` if the caller never did — ensuring the eviction `MailboxProcessor` is cancelled.

**Cross-references**:
- `FSharp.Compiler.Diagnostics.Metrics` (see sibling `Activity.md` / `Activity.fsi.md`) supplies the shared `Meter` and `printTable` used by `CacheMetrics`.
- Distinct from sibling `LruCache.md`, which is a simpler, un-instrumented LRU with weak/strong references; `Caches.Cache` is the higher-level concurrent version.

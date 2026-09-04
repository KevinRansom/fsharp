# Caches.fsi

**Purpose**: Signature file for `Caches.fs` (same directory, namespace `FSharp.Compiler.Caches`). Documents the public contract of the internal thread-safe, instrumented cache; exposes the `EvictionMode` union, the `CacheOptions<'Key>` struct, and the `Cache<'Key, 'Value>` type.

**Namespace(s)** declared: `FSharp.Compiler.Caches`

**Declared items** (public contract; note the module's members and most types are marked `internal` in the .fsi itself — the contract is "internal use"):
- `module CacheMetrics` — `Meter : Meter` (exposed for OpenTelemetry export in tests, see doc comment re: `FSHARP_OTEL_EXPORT`), and internal members `getTotalsByName`, `getRatioByName`, `ListenToAll`, `StatsToString`, `CaptureStatsAndWriteToConsole`.
- `[<RequireQualifiedAccess; NoComparison>] type internal EvictionMode` union:
  - `NoEviction` — "cache is effectively a ConcurrentDictionary."
  - `Immediate` — "Evict items immediately on the caller's thread."
  - `MailboxProcessor` — "Evict items in the background using a MailboxProcessor."
- `[<Struct; RequireQualifiedAccess; NoComparison; NoEquality>] type internal CacheOptions<'Key>` record: `TotalCapacity`, `HeadroomPercentage`, `EvictionMode`, `Comparer`.
- `module internal CacheOptions` — `getDefault`, `getReferenceIdentity` (requires `'Key: not struct`), `withNoEviction`.
- `[<Sealed; NoComparison; NoEquality>] type internal Cache<'Key, 'Value when 'Key: not null>`:
  - `new: options: CacheOptions<'Key> * ?name: string`
  - `TryGetValue : key * outref<'Value> -> bool`
  - `TryAdd : key * value -> bool`
  - `GetOrAdd : key * (key -> value) -> value`
  - `AddOrUpdate : key * value -> unit`
  - `Evicted : IEvent<unit>` (for testing only)
  - `EvictionFailed : IEvent<unit>` (for testing only)
  - `IDisposable`

**Relationship to .fs**: The .fs additionally defines the `CachedEntity<'Key, 'Value>` type (class holding a key, value, and its own `LinkedListNode`), the `EvictionQueueMessage<'Entity, 'Target>` struct, the `CacheMetrics` counter set and `Stats` type, the `CacheMetrics.ListenToAll` `MeterListener` machinery, and the whole eviction-processing loop (`MailboxProcessor` or synchronous) — none of which are part of the .fsi.

**Cross-references**: `Activity.fsi.md` (sibling) supplies the shared `Metrics.Meter`; `LruCache.md` is a separate, simpler LRU.

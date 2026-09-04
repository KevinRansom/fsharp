# AsyncMemoize.fs

**Purpose**: Provides `AsyncMemoize`, a thread-safe memoization/LRU cache for async computations, so the same computation (e.g. reference resolution for a key) runs at most once even when requested concurrently. It tracks in-flight requests, optionally cancels un-awaited work, never caches failing results, and exposes statistics/events for tracing.

**Namespace(s)**: `Internal.Utilities.Collections`

**Modules / TypeDefs / Classes / Records / Unions declared**:
- `AsyncLazyState<'t>` (private union): state machine — `Initial`, `Running`, `Completed`, `Faulted`
- `AsyncLazy<'t>` (class): a single async computation executed once; request-counting, cancellation, exception handling
- `<AutoOpen> module internal Utils`: `shortPath` — returns a path with only the last directory component
- `JobEvent` (internal union): event log entries (`Requested`, `Started`, `Finished`, `Failed`, `Evicted`, ...) with `AllEvents`
- `ICacheKey<'TKey,'TVersion>` (internal interface): `GetKey`/`GetVersion`/`GetLabel`
- `Extensions` (extension class): `WithExtraVersion` — wraps a key with an extra version component
- `KeyData<'TKey,'TVersion>` (private record): `Label`, `Key`, `Version`
- `Job<'t>` (type def): `AsyncLazy<Result<'t,exn> * CapturingDiagnosticsLogger>`
- `AsyncMemoize<'TKey,'TVersion,'TValue>` (internal class): the main cache over an `LruCache`
- `AsyncMemoizeDisabled<'TKey,'TVersion,'TValue>` (internal class): drop-in replacement that disables caching entirely

**Public API surface** (internal to compiler):
- `new(?keepStrongly, ?keepWeakly, ?name, ?cancelUnawaitedJobs, ?cancelDuplicateRunningJobs)`
- `Get(key: ICacheKey<_,_>, computation: Async<'TValue>) : Async<'TValue>` — main entry
- `TryGet(key, versionPredicate) : 'TValue option`; `Clear()`, `Clear predicate`
- `Event` / `OnEvent` of `JobEvent * (string * 'TKey * 'TVersion)`; `Count`; `DebuggerDisplay`
- Minor helpers: `AsyncLazy.Request/CancelIfUnawaited/State/TryResult`

**Notable internal helpers**:
- `AsyncLazy.withStateUpdate` — the only state mutator, lock-protected
- `detachable` — awaits a `Task` so cancellation of the caller detaches from the work task
- `onComplete` — transitions `Running -> Completed|Faulted` (re-runnable when `cacheException=false`)
- Job wrapping in `Get`: `Async.TryCancelled`, `CapturingDiagnosticsLogger` (committed via `CommitDelayedDiagnostics`), `CompilationGlobalsScope`
- `DebuggerDisplay` builds a stats string (Running count, hits%, avg ms, event counts)

**Significant internal logic**:
- LRU cache of 100 strong + 200 weak jobs by default; results cached as `Result.Ok` only — failures are restarted next time (`cacheException = false`)
- Concurrent requests for the same key share one running job via `AsyncLazy`'s request counting (`count + 1`)
- `cancelUnawaitedJobs=true` cancels the job when the last awaiting request is cancelled; `cancelDuplicateRunningJobs` cancels same-key jobs of other versions

**Cross-references**: DiagnosticsLogger.fs (CapturingDiagnosticsLogger), BuildGraph.fs (similar single-execution async node), LruCache (internal utils).

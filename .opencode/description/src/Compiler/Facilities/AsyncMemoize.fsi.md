# AsyncMemoize.fsi

**Purpose**: The signature/contract for `AsyncMemoize.fs`. Declares the public shape of the async memoization cache: the `ICacheKey` abstraction, the internal `AsyncMemoize`/`AsyncMemoizeDisabled` classes, and the `JobEvent` event vocabulary.

**Namespace(s)**: `Internal.Utilities.Collections`

**Modules / TypeDefs / Classes / Unions declared**:
- `<AutoOpen> module internal Utils`: `shortPath: string -> string`
- `JobEvent` (internal union): `Requested | Started | Restarted | Finished | Canceled | Evicted | Collected | Weakened | Strengthened | Failed | Cleared`
- `ICacheKey<'TKey,'TVersion>` (internal): `GetKey`, `GetLabel`, `GetVersion`
- `Extensions` (class): `WithExtraVersion: ICacheKey<'a,'b> * 'c -> ICacheKey<'a,'b*'c>` (extension member)
- `AsyncMemoize<'TKey,'TVersion,'TValue>` (internal): memoization cache, "strongly holds at most one result per key"
- `AsyncMemoizeDisabled<'TKey,'TVersion,'TValue>` (internal): no-caching passthrough (`Get` returns the computation as-is)

**Contract (API surface)**:
- `AsyncMemoize.new(?keepStrongly:int, ?keepWeakly:int, ?name:string, ?cancelUnawaitedJobs:bool, ?cancelDuplicateRunningJobs:bool)`
  - `keepStrongly`/`keepWeakly` — max strong/weak cached results
  - `cancelUnawaitedJobs` — cancels a job when all awaiters cancel; if false, unawaited job runs to completion and result is cached
  - `cancelDuplicateRunningJobs` — cancel other same-key jobs when a new job starts
- `Get: ICacheKey * Async<'TValue> -> Async<'TValue>`; `TryGet: 'TKey * ('TVersion -> bool) -> 'TValue option`
- `Clear` (two overloads), `Event: IEvent<JobEvent * (string * 'TKey * 'TVersion)>`, `OnEvent`, `Count: int`
- `AsyncMemoizeDisabled.Get: _key * computation -> computation` (identity)

**Notes**: Type constraints `equality and not null` on key/version; all declarations are `internal` — this is compiler-internal memoization infrastructure, not part of the FSharp.Compiler.Service public API.

**Cross-references**: Implements AsyncMemoize.fs; consumed by service layer caches; conceptually related to BuildGraph.fsi.

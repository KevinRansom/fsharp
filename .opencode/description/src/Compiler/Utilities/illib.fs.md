# illib.fs

**Purpose**: The compiler's pervasive in-house utility library ("IL library" / internal utilities), namespace `Internal.Utilities.Library`. It supplies the foundational pieces used everywhere in the F# compiler: thread-safe lazy values (`InterruptibleLazy`, `LazyWithContext`), lock/token execution-context discipline (`Lock`/token types), a large set of list/array/string/map helper modules, memoization tables, unique stamp generators, and immutable name/multi-map collections. Public contract in `illib.fsi` (1383 lines of .fs; the .fsi mirrors it closely).

**Namespace(s)** declared: `Internal.Utilities.Library`

**Modules / Types declared** (one-line descriptions; extensive list — key items highlighted):
- `type InterruptibleLazy<'T>` (`[<Class>]`) — thread-safe lazy value that double-checks under a `Monitor` lock, nulling the factory after first computation (`IsValueCreated` tests that); `static member FromValue`, `Force`.
- `module InterruptibleLazy` — `force`.
- `[<AutoOpen>] module internal PervasiveAutoOpens` — pervasive little helpers: `>>>&` (unsigned shift), `notlazy`, `|InterruptibleLazy|` active pattern, `|RecoverableException|_|` (distinguishes `OperationCanceledException` as non-fatal), `isNil`/`isNilOrSingleton`/`isSingleton`, `===` physical equality, `LOH_SIZE_THRESHOLD_BYTES` (80,000), `String` extension members (`StartsWithOrdinal`, `EndsWithOrdinal`, `IndexOfOrdinal`), `getHole`, `reportTime` (bridges to `FSharp.Compiler.Diagnostics.Activity.Profiling.startAndMeasureEnvironmentStats`), `foldOn`, `notFound`, and `Async.RunSynchronouslyImmediate` (async run that blocks the caller thread even if continuations run elsewhere).
- `[<AbstractClass>] type DelayInitArrayMap<'T, 'TDictKey, 'TDictValue>` — lazily computes an array, then a derived dictionary from it (both memoized under a lock); subclass supplies `CreateDictionary`.
- `[<AbstractClass>] type internal DelayInitValue<'T>` — in-place single-computation store (avoids an extra closure object); `Compute` called at most once under lock; exceptions are not cached.
- `module internal Order` — `orderBy`, `orderOn`, `toFunction` comparer factories.
- `module internal Array` — `mapq` (returns input if mapping didn't change anything), `lengthsEqAndForall2`, `order`, `existsOne`, `existsTrue`, `findFirstIndexWhereTrue` (binary-search-ish for first true element), `revInPlace`, `mapAsync`, `replace`, `areEqual` (fast elementwise), `heads`, `isSubArray`, `startsWith`, `endsWith`, `prepend`.
- `module internal Option` — `mapFold`, `attempt`.
- `module internal ValueTuple` — `map1Of2` for value tuples.
- `module internal List` — a very large helper set: `sortWithOrder`, `splitAfter`, `existsi`, `findi`, `splitChoose`, `mapq`/`checkq` (identity-preserving maps), `frontAndBack`/`tryFrontAndBack`, `tryRemove`, `zip4`/`unzip4`, `iter3`, `takeUntil`, `order`, `assoc`/`memAssoc`/`memq`, `mapNth`, `count`, `headAndTail`, `mapHeadTail`, `collectFold`, `collect2`, the full `*Squared` family (`toArraySquared`, `iterSquared`, `collectSquared`, `mapSquared`, `mapFoldSquared`, `forallSquared`, `mapiSquared`, `existsSquared`, `mapiFoldSquared`), `duplicates`, `allEqual`, `isSingleton`, `prependIfSome`, `vMapFold` (value-tuple-based fast map/fold).
- `module internal ResizeArray` — `chunkBySize`, `mapToSmallArrayChunks` (split into arrays under the LOH threshold to avoid stop-the-world GC).
- `module internal Span` — inline `exists` over `Span<'T>`.
- `module internal String` — `make`, `get`, `sub`, `contains`, `order`, `lowercase`/`uppercase`, `isLeadingIdentifierCharacterUpperCase` (with unicameral-script handling), `capitalize`/`uncapitalize`, `dropPrefix`/`dropSuffix`, `toCharArray`, `lowerCaseFirstChar`, `extractTrailingIndex`, `split`, `|StartsWith|_|`, `|Contains|_|`, `getLines`.
- `module internal Dictionary` — `newWithSize`, `ofList`.
- `[<Extension; Class>] type internal DictionaryExtensions` — `BagAdd`, `BagExistsValueForKey`.
- `[<Extension; Class>] type internal ConcurrentDictionaryExtensions` — `GetOrAddLazy` (factory runs once per key, cached behind a `Lazy`).
- `module internal Lazy` — `force`.
- **Lock/token discipline types**: `type internal ExecutionToken` (marker interface); `[<Sealed>] type internal CompilationThreadToken` (full access to TAST/TcImports, may invoke type providers); `[<Sealed>] type internal AnyCallerThreadToken`; `type internal LockToken` (base for per-lock token subtypes); `[<AutoOpen>] module internal LockAutoOpens` — `RequireCompilationThread`, `DoesNotRequireCompilerThreadTokenAndCouldPossiblyBeMadeConcurrent`, `AssumeCompilationThreadWithoutEvidence`, `AnyCallerThread`, `AssumeLockWithoutEvidence`; `type internal Lock<'LockTokenType when 'LockTokenType :> LockToken>` — `AcquireLock : ('LockTokenType -> 'a) -> 'a`.
- `module internal Map` — `tryFindMulti`.
- `[<Struct>] type internal ResultOrException<'TResult>` — `Result of 'T | Exception of exn`; `module ResultOrException` — `success`, `raze`, `|?>`, `ForceRaise`, `otherwise`.
- `type internal UniqueStampGenerator<'T>` — assigns auto-incrementing ints to first-seen values via `ConcurrentDictionary` + `Lazy`; `Encode`, `Table`.
- `type internal MemoizationTable<'T, 'U>` — wraps `FSharp.Compiler.Caches.Cache` (with `CacheOptions.withNoEviction`) with `Lazy` values; `Apply` (optionally gated by `canMemoize`).
- `type internal StampedDictionary<'T, 'U>` — concurrent dict assigning auto-increment stamps per key; `Add`, `UpdateIfExists` (atomic `TryUpdate` keeping the stamp), `GetAll`.
- `exception UndefinedException`; `type internal LazyWithContextFailure` — wrapper carrying an exception; `static member Undefined`.
- `[<Sealed>] type internal LazyWithContext<'T, 'Ctxt>` — lock-protected lazy that requires a context token on every force (so errors can be attributed to a user location); `Create`, `NotLazy`, `IsDelayed`, `IsForced`, `Force`, `UnsynchronizedForce`; uses `Thread.MemoryBarrier` for ARM64 correctness and re-raises the *original* exception via `findOriginalException`.
- `module internal Tables` — `memoize f` (concurrent intern table).
- `type internal IPartialEqualityComparer<'T>` + `module internal IPartialEqualityComparer` — `On` (projection), `partialDistinctBy` (distinct that skips elements outside the equality relation).
- **Name-map collections**: `type NameMap<'T> = Map<string, 'T>`; `type NameMultiMap<'T> = Map<string, 'T list>`; `type MultiMap<'T, 'U when 'T: comparison> = Map<'T, 'U list>`; `module internal NameMap` (range/forall/exists/layer/union/subfold2/mapFold/partition/...); `module internal NameMultiMap` (find/add/range/chooseRange/initBy/ofList,...); `module internal MultiMap`.
- `type internal LayeredMap<'Key, 'Value when 'Key: comparison> = Map<'Key, 'Value>`.
- `[<AutoOpen>] module internal MapAutoOpens` — extensions on `Map`: `static Empty`, `AddMany`, `AddOrModify`.
- `[<Sealed>] type internal LayeredMultiMap<'Key, 'Value>` — immutable multi-map over a `Map<'Key, 'Value list>`; `Add`, `AddMany`, `TryFind`, `TryGetValue`, `Item`, `Values`, `static Empty`.

**Public API surface**: essentially every item above is the public (internal-to-assembly) surface; see illib.fsi for exact signatures. The most-used across the compiler: `List.*`/`Array.*` helpers, `NameMap`/`NameMultiMap`/`MultiMap`, `LazyWithContext`, `InterruptibleLazy`, `CompilationThreadToken` discipline, `MapAutoOpens` extensions, `ResultOrException`.

**Internal helpers / active patterns**: `|InterruptibleLazy|`, `|RecoverableException|_|`, `|StartsWith|_|`, `|Contains|_|`; `PervasiveAutoOpens.===`; `getHole`.

**Significant internal logic / behavioral notes**:
- `LazyWithContext.UnsynchronizedForce` records a `LazyWithContextFailure` placeholder *before* computing, so concurrent forcees don't recompute; on exception, the recorded failure is retained and re-raised on subsequent forces (original exception recovered via the `findOriginalException` mapper). Memory barriers are explicitly noted as required on weakly-ordered (ARM64) architectures.
- `PervasiveAutoOpens.reportTime` ties into the activity profiling of sibling `Activity.fs` (`Activity.Profiling.startAndMeasureEnvironmentStats`).
- `MemoizationTable` depends on sibling `Caches.Cache` with `NoEviction` mode (entries never collected).
- `Lock<'Token>` pattern: each static lock declares its own token type (subtype of `LockToken`), and `AcquireLock` fakes the token via `AssumeLockWithoutEvidence`; this "type-level documentation" pattern enforces (by review, not type-checking) which thread may call which code — see `RequireCompilationThread` etc.
- `ResizeArray.mapToSmallArrayChunks` chunks to stay below `LOH_SIZE_THRESHOLD_BYTES` to reduce stop-the-world GC pressure.

**Cross-references**: uses `FSharp.Compiler.Caches` (see `Caches.md`), `FSharp.Compiler.Diagnostics.Activity` (see `Activity.md`); distinct from sibling `lib.fs` (`Internal.Utilities.Library.Extras`), which adds list-set, pair/tuple, cache-slot and graph helpers in the same namespace family.

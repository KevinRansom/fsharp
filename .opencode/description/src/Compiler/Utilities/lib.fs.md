# lib.fs

**Purpose**: The original F# compiler "library of libraries" (`module internal Internal.Utilities.Library.Extras`) — a grab-bag of small helpers used pervasively by the compiler: bit extraction, comparers, generalized association lists, list-as-set operations, tuple projection/map/fold helpers over 2-6 arities, Zmap/Zset rebinds, string builders, a mutable imperative graph, memoization caches (incl. lock-free version-stamped memo), a `MaybeLazy` type, a `DisposablesTracker`, parallel-array helpers, and a `ConditionalWeakTable`-based `WeakMap`. Public contract in `lib.fsi`.

**Namespace(s)** declared: module path `Internal.Utilities.Library.Extras` (internal module)

**Modules / Types declared** (one-line descriptions):
- `module Bits` — byte-extraction helpers `b0..b3`, `pown32`/`pown64` (mask of low n bits), `mask32`/`mask64`.
- `module Bool` / `module Int32` / `module Int64` — cached `FastGenericComparer` orders.
- `module Pair` — `order` building a structural-pair `IComparer`.
- `type NameSet = Zset<string>` + `module NameSet` (`ofList`); `module NameMap` (`domain`, `domainL`).
- `type IntMap<'T> = Zmap<int, 'T>` + `module IntMap` — standard add/find/tryFind/remove/mem/iter/map/fold.
- `module ListAssoc` — `find`/`tryFind` over key-value lists with custom match predicate.
- `module ListSet` — list-as-set operations: `contains`, `insert`, `unionFavourRight`/`unionFavourLeft`, `findIndex`, `remove`, `subtract` (quadratic), `isSubsetOf`/`isSupersetOf`/`equals`, `intersect`, `setify`, `hasDuplicates`.
- Tuple helpers (top-level vals): `mapFoldFst`/`mapFoldSnd`, `pair`, projections `p13`..`p55`, `mapNOfM` family (`map1Of2`..`map6Of6`), `foldPair`/`fold1Of2`/`foldTriple`/`foldQuadruple`, `mapPair`/`mapTriple`/`mapQuadruple`.
- `module Zmap` — `force` (tryFind or failwith), `mapKey` (update-or-remove via option).
- `module Zset` — `ofList`, `fixpoint` (iterate a set function until it stabilizes).
- `buildString` / `writeViaBuffer` — `StringBuilder`-based output helpers; `type StringBuilder with` — `AppendString` (unit-returning Append).
- Imperative graph: `type GraphNode<'Data, 'Id>` record (`nodeId`, `nodeData`, mutable `nodeNeighbours`); `type Graph<'Data, 'Id when 'Id: comparison>` — `GetNodeData`, `IterateCycles`.
- Null-slot tricks: `type NonNullSlot<'T> = 'T`, `nullableSlotEmpty`/`nullableSlotFull` — "unsafe trick" of using `null` as an empty marker for mutable fields.
- Compiler memo caches: `type cache<'T> = { mutable cacheVal: NonNullSlot<'T> }`, `newCache`, `inline cached`, `inline cacheOptByref`, `inline cacheOptByrefByVersion` (version-stamped, lock-free safe for concurrently-appended tables), `inline cacheOptRef`, `inline tryGetCacheValue`.
- `#if DUMPER` `type Dumper` — debugger dump helper.
- `[<RequireQualifiedAccess>] type MaybeLazy<'T>` — `Strict of 'T | Lazy of InterruptibleLazy<'T>` with `Value`/`Force` (note: `InterruptibleLazy` is defined in sibling `illib.fs`).
- `inline vsnd` — second field accessor on struct tuples.
- `type DisposablesTracker` — `Register (IDisposable | null)`, disposes all in LIFO on `Dispose`, swallowing per-item exceptions.
- `[<RequireQualifiedAccess>] module ArrayParallel` — `iter`/`iteri`/`map`/`mapi` over parallel-for with `MaxDegreeOfParallelism = min(ProcessorCount, length)`, flattening single-exception `AggregateException`.
- `[<RequireQualifiedAccess>] module ListParallel` — `map`.
- `[<RequireQualifiedAccess>] module Async` — `map`.
- `module internal WeakMap` — `getOrCreate` (a `ConditionalWeakTable`-backed per-key lazily-computed value, cached factory to avoid per-lookup lambda alloc), `cacheConditionally`.

**Public API surface**: exactly the items above; see lib.fsi for signatures. Minor helpers exist in abundance (tuple projection family) and are mostly one-liners.

**Internal helpers / notable items**:
- `foldPair`/`foldTriple`/`foldQuadruple` fold two/three/four functions over a tuple accumulator chain — used heavily for multi-value compiler state.
- `ListSet` is O(n) or quadratic and documented as such; it operates with *custom* equality predicates (`f`), which is its raison d'être in the compiler (syntactic-ish equality over ASTs).
- `Graph.IterateCycles` walks the graph and invokes `f` with each discovered cycle (path to a repeated node).
- `cacheOptByrefByVersion` (see .fsi doc): tags the cached value with the data version observed at computation; a reader whose current version doesn't match recomputes. Callers must read `version` with acquire semantics before `f`. `'cache` must be a reference type so publication is one atomic store (a struct option could tear under concurrent reads).

**Significant internal logic / behavioral notes**:
- `ListSet.unionFavourLeft` = `l1 @ (subtract l2 l1)`; `unionFavourRight` = `foldBack insert l1 l2` — both preserve "left/right wins" semantics for equal elements.
- `setify` keeps first occurrence front-to-back: dedup with `insert` and reverse.
- `ArrayParallel` bounds parallelism at `min(ProcessorCount, arr.Length)` to avoid thread over-subscription for small arrays, and unwraps an `AggregateException` with exactly one inner to the inner exception.
- `WeakMap.getOrCreate` pre-builds the `ConditionalWeakTable.CreateValueCallback` once (factory cache) to avoid per-call lambda allocation.
- The "null as empty" `NonNullSlot` trick relies on the host type never using `null` as a legitimate representation; documented as unsafe.

**Cross-references**:
- `illib.fs` lives in the parent module path `Internal.Utilities.Library` and this file is `Internal.Utilities.Library.Extras` — they coexist and share usage (e.g. `NameSet`/`NameMap` here vs. `NameMap<'T>` module in illib).
- `MaybeLazy` references `InterruptibleLazy` from `illib.fs` (see `illib.md`).
- Sibling `lib.fsi.md` is its signature file.

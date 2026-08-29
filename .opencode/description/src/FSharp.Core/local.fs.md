# local.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Contains two layers: the private exception-raising helpers used across FSharp.Core, and the internal high-performance list/array/seq/random implementations (`Microsoft.FSharp.Primitives.Basics`) that the public `List`, `Array`, `Seq` and `Random` modules delegate to.

## Namespace: Microsoft.FSharp.Core — module DetailedExceptions
`[<AutoOpen>] module internal DetailedExceptions` — `invalid*` helpers that raise with formatted, localized messages (used pervasively by array/list/seq code).

- `invalidArgFmt arg format paramArray` — raises `ArgumentException(msg, arg)`.
- `invalidArgOutOfRangeFmt arg format paramArray` — raises `ArgumentOutOfRangeException`.
- `invalidOpFmt format paramArray` — raises `InvalidOperationException`.
- `invalidArgDifferentListLength arg1 arg2 diff` — reports two lists differing by `diff` elements.
- `invalidArg3ListsDifferent ...` — three-list length mismatch report.
- `invalidOpListNotEnoughElements index` — index beyond list length.
- `invalidOpExceededSeqLength fnName diff len` — "tried to skip N past end of seq".
- `invalidArgInputMustBeNonNegative arg count` / `invalidArgInputMustBePositive arg count`.
- `invalidArgOutOfRange arg index text bound` — index outside a named range.
- `invalidArgDifferentArrayLength` / `invalidArg3ArraysDifferent` — array-length mismatch reports.

## Namespace: Microsoft.FSharp.Primitives.Basics — module List
Stack-safe, mutation-based list builders. The key trick: `freshConsNoTail` allocates a cons cell with a null tail via IL and `setFreshConsTail` writes the real tail. Allowed only inside fslib, where careful mutation of private cons cells is legal; the finished list is nil-terminated so it is immutable to users.

### Low-level primitives
- `arrayZeroCreate n` — IL `newarr` without bounds-checking overhead.
- `freshConsNoTail h` / `setFreshConsTail cons t` — two-phase cons construction.
- `ofSeq` — fast-paths `'T list` and `'T array` inputs; otherwise enumerator-driven builder.

### Deduplication / grouping
- `distinctWithComparer` / `distinctByWithComparer` (+ `*ToFreshConsTail` loops) — `HashSet`-backed single-pass dedup with the user comparer.
- `countBy` — materializes a prebuilt `Dictionary` into a list of `(key, count)`.
- `groupBy` — `Dictionary<'SafeKey, 'T list array>`: index 0 holds the result list head, index 1 the current last cons so groups can be appended without reversal; correct lengths handled per group.

### Mapping family
- `map`, `mapi`, `map2`, `mapi2`, `map3` — fresh-tail builder loops; 2/3-list variants raise length mismatches.
- `mapFold` — state-accumulating map producing result list and final state.
- `indexed`, `scan` — index/state-stamped builders.
- `collect` — concatenates mapped sublists by appending each into the growing chain (dummy-head trick, returns `.Tail`).
- `allPairs` — cross product via two nested fresh-tail builders.
- `filter`, `choose`, `partition`, `pairwise`, `unzip`, `unzip3`, `zip`, `zip3` — all fresh-tail builder based; `zip`/`zip3` guard lengths.
- `rev` — accumulator reversal with `[h2;h1]` fast path.
- `concat` — chain of appends over the flattened items.

### Slicing / splitting
- `take`, `takeWhile`, `truncate`, `splitAt`, `skip`-style bounds are enforced with `invalidOpListNotEnoughElements`.
- `windowed`, `chunkBySize`, `splitInto` — sliding-window and chunk builders (windowed validates positive `windowSize`, chunk sizes validations in the public layer).
- `transpose` — repeatedly splits each row list into heads/tails (`transposeGetHeads`) and stacks them, with length-mismatch checks.

### Construction
- `init`, `unfold`, `toArray` (length precomputed, IL `newarr`), `ofArray` (reverse accumulation).
- `tryLastV` — `ValueOption` last element (fast tail-recursive).

## Module: Basics.Array
Internal array helpers used by `Array` and `List` modules.

- `fastComparerForArraySort` — `FastGenericComparerCanBeNull`; used as the nullable fast comparer.
- `zeroCreateUnchecked`, `init` (with negative-length check), `subUnchecked` (loop for count<64, `Array.Copy` otherwise).
- `findBack`/`tryFindBack`/`findIndexBack`/`tryFindIndexBack` — reverse-index loops.
- `permute` — validates the index map is a permutation (marks visited slots, ensures every position covered) and builds the permuted array.
- `mapFold` / `mapFoldBack` / `scanSubRight` — adapted-closure array folds/scans.
- **Sorting:**
  - `unstableSortInPlaceBy` / `unstableSortInPlace` — `Array.Sort` with the fast generic comparer.
  - `stableSortWithKeysAndComparer` — permutation sort: sorts `places` by key with `Array.Sort<_,_>(keys, places, cFast)`, then reassembles sorted runs; equal-key chunks are re-sorted in-place by original position indices to guarantee stability.
  - `stableSortWithKeys` / `stableSortInPlaceBy` — key-projection stable sorts.
  - `stableSortInPlace` — optimized: for value types without identity the comparer may be `null`, using plain `Array.Sort` (unstable is fine); otherwise keys = cloned array and the stable algorithm runs.
  - `stableSortInPlaceWith` — user comparer adapted and wrapped into `IComparer<'T>`.
- `splitInto` — distributes elements into `count` nearly-equal contiguous chunks (first `len % count` chunks get one extra element).

## Module: Basics.Seq
- `tryLastV` — fast `ValueOption` last element with pattern matching for `array`, `IList`, `list` inputs; otherwise single-pass enumerator loop.

## Module: Basics.Random
Randomness helpers used by the public `List`/`Array`/`Seq` random operations.

- `executeRandomizer randomizer` — validates the `unit -> float` randomizer returns a value in `[0.0, 1.0)`, else `ArgumentOutOfRangeException`.
- `next randomizer minValue maxValue` — scaled int in `[min, max)`.
- `shuffleArrayInPlaceWith / shuffleArrayInPlaceBy` — in-place Fisher–Yates (Knuth shuffle) over `[0, n-2]`.
- `getMaxSetSizeForSampling count` — threshold deciding between pool-based and rejection-based sampling; formula (min 21) growing with the count, adapted from CPython `random.py` (PSF license).

## Key design notes
- The fresh-cons builders avoid repeated list reversal and give O(n) single-pass construction for filters/maps/zippers while keeping results indistinguishable from immutable lists.
- `toArray`/`ofArray` optimize conversions inside FSharp.Core (IL allocations, no checks).
- Stable sorting latency: stable sorts go through a permutation array + chunk restabilization; the fast path avoids it entirely for identity-less value keys.
- All exceptions produced here are localized `ArgumentException`/`ArgumentOutOfRangeException`/`InvalidOperationException` with descriptive suffixes.
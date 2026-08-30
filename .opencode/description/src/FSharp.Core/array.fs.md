# array.fs

## Pipeline role

A source file of FSharp.Core, the standard library shipped with the F# compiler (the FSharp.Core assembly loaded at runtime by compiled programs and referenced when the compiler itself compiles against the core library). It implements the full `Array` module (F# built-in one-dimensional array operations) plus the parallel companion module `Array.Parallel`.

## Namespaces

- `Microsoft.FSharp.Collections` — host namespace for the `Array` module and for the `Array.Parallel` submodule.

## Module: `Array`

Declared as:

```fsharp
[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]
[<RequireQualifiedAccess>]
module Array
```

- `ModuleSuffix` maps the source name `Array` to the runtime type name `ArrayModule` (avoiding a clash with the CLR `System.Array` type).
- `RequireQualifiedAccess` forces callers to write `Array.foo`, keeping the module out of `open`-based name spaces.

### Construction and querying

- `length (array: 'T array) : int` — returns the number of elements.
- `last` and `tryLast` — respectively raise `ArgumentException` or return `None` for an empty array.
- `init count initializer` — allocates an array and delegates element generation to `Microsoft.FSharp.Primitives.Basics.Array.init` after validating `count` (negative counts raise `ArgumentException`).
- `zeroCreate count` — allocates a zero-initialized array of length `count` (delegates to `Basics.Array.zeroCreate`; negative count raises `ArgumentException`).
- `create count value` — builds an array of length `count` filled with `value`.
- `singleton value` — builds a single-element array.
- `copy`, `append`, `sub`, `concat` / `collect` — copy, combine, slice and flatten helpers (slice bounds validated against the source).
- `get` / `item` / `tryItem` — indexed element access with `indexNotFound` used for the out-of-range exception path.
- `blit src srcIndex dst dstIndex count` — element bulk copy with bounds checking on both ranges.
- `fill array start count value` — overwrites a range of an array.

### Per-element mapping / iteration

- `map`, `mapi`, `map2`, `mapi2`, `mapFold`, `mapFoldBack` — elementwise transformation, with index- and element-pair variants.
- `iter`, `iteri`, `iter2`, `iteri2` — side-effecting iteration variants.
- `indexed` — pairs each element with its index.
- `exists`, `forall`, `exists2`, `forall2` — predicate checks over one or two arrays.
- `find`, `findIndex`, `findBack`, `findIndexBack`, `tryFind`, `tryFindIndex`, `tryFindBack`, `tryFindIndexBack`, `tryPick`, `pick` — search operations returning the matching element, its index, or (for the `try`/`option` forms) `None`.
- `contains value` — equality-based membership test.

### Filtering and partitioning

- `filter predicate` — keeps matching elements. Implemented as an imperative single allocation pass that accumulates a bitmask: a 32-bit mask word per element is set, compacted with `mask` bit counts (reusing `System.Numerics.BitOperations`-style counting logic), then matched positions are copied into a result array. This avoids the O(n) worst-case growth of a naive builder while preserving order.
- `partition predicate` — splits into `(matching, nonMatching)` arrays.
- `choose chooser` — maps with `option` results, keeping the `Some` values.
- `where` — alias behavior matching `filter`.

### Aggregation

- `fold`, `foldBack`, `fold2`, `foldBack2` — ordered accumulation threading an accumulator through the array (backwards variants process from the right).
- `reduce`, `reduceBack` — fold without an initial value; raise `ArgumentException` on empty input.
- `sum`, `sumBy` — use the `(+)/Zero` static member constraint (SRTP), inlined.
- `average`, `averageBy` — use the `(+)/DivideByInt` static member constraint; raise `ArgumentException` on empty inputs.
- `min`, `max`, `minBy`, `maxBy` — comparison-based extrema.
- `countBy projection` and `groupBy projection` — hash-based grouping.
- `compareWith comparer` — lexicographic comparison of two arrays.
- `allPairs array1 array2` — the cartesian product of two arrays of pairs.
- `scan`, `scanBack` — produce the prefix (suffix) accumulation array including the starting value. The forwards `scan` adapts the user function via `OptimizedClosures.FSharpFunc` and uses a recursive inner helper `scanSubLeft` to compute each prefix cell; `scanBack` delegates to `Basics.Array.scanBack`.
- `pairwise` — builds the array of adjacent pairs.

### Sorting

- `sort`, `sortBy`, `sortWith`, `sortInPlace`, `sortInPlaceBy`, `sortInPlaceWith` — `.NET` `Array.Sort`-backed ordering (in-place forms mutate; returning forms copy first). In-place comparer variants use an early-exit comparison check before invoking the underlying sort.
- `sortDescending`, `sortByDescending` — descending variants reusing `Operators.compare` in reverse.
- `sortInPlaceDescending`, `sortInPlaceByDescending` — in-place descending counterparts.

### Conversions and miscellany

- `toList`, `toSeq` — conversions to other collection shapes.
- `unzip`, `unzip3`, `zip`, `zip3` — pair/triple element de/re-construction; `zip` variants validate equal lengths.
- `splitAt`, `chunkBySize`, `splitInto`, `windowed` — structural slicing of arrays.
- `transpose` — matrix transpose over arrays of arrays (result indexed as `[column, row]`).
- `tryExactlyOne` / `exactlyOne` — single-element array accessors.
- `isEmpty`, `head`, `tryHead`, `tail`, `empty` — minimal accessors.
- `unfold generator` — builds an array by repeatedly applying a generator until `None`.
- `resize count array` — in-place size change preserving the front elements.

### Module: `Array.Parallel`

Declared within the same file (compiled as `Microsoft.FSharp.Collections.Array.ArrayModule.Parallel` with `ModuleSuffix`).

- Uses `System.Threading.Tasks.Parallel.For` plus `System.Threading.Tasks.Parallel` static partitioners for: `iter`, `iteri`, `map`, `mapi`, `map2`, `collect`, `choose`, `groupBy`, `partition`, `partitionWith`, `init`, `zip`, `filter`, `sort`-family, `sum`, `sumBy`, `average`, `averageBy`, `min`, `max`, and aggregations.
- `exists`, `forall`, `tryFind`, `tryFindIndex`, `tryPick` run the predicate over ranges with `Parallel.For` and stop early: matching ranges call `pState.Stop()`; the first found index is remembered via `LowestBreakIteration`, so the lowest winning index wins deterministically ("if any application returns true the overall result is true and testing of other elements in all threads is stopped at system's earliest convenience").
- `reduce`, `reduceBy` reduce each thread partition then combine the partial results, hence the documented requirement that the reduction function be commutative.
- `sort` / `sortBy` / `sortWith` and in-place variants are unstable sorts run in parallel (documented as such, recommending `Seq.sort` for stable behavior).

## Key design notes

- Many small but hot operations (`length`, `zeroCreate`, `init`, `scanBack`) forward to `Microsoft.FSharp.Primitives.Basics.Array` primitives, which mirror `Array2D`/`Array3D` internals and avoid duplicated runtime code.
- `checkNonNull` guard helpers throw `ArgumentNullException` for null inputs across the public surface; `indexNotFound` throws the documented `KeyNotFoundException`-style message on failed lookups/indices.
- The parallel search implementations deliberately reuse a single `Parallel.For` loop over chunked ranges and record the minimum winning iteration so results are deterministic despite concurrent evaluation.

## Notable behavior

- The mask-based `filter` produces a single compact result allocation while iterating once, making it O(n) time with bounded GC pressure and order-preserving.
- `scan` / `scanSubLeft` use `OptimizedClosures.FSharpFunc` inlining to avoid closure boxing per element.
- All in-place sort variants document instability and O(n log n) worst-case behavior; parallel sorts additionally document that equal elements may reorder.
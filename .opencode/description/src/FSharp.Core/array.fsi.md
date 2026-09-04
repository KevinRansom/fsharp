# array.fsi

## Pipeline role

The signature file for `array.fs`, part of FSharp.Core, the standard library shipped with the F# compiler. It declares the public API surface of the `Array` module and its `Array.Parallel` submodule, with full XML documentation and `CompiledName` attributes used by the generated FSharp.Core.xml reference documentation.

## Namespaces

- `Microsoft.FSharp.Collections` — namespace enclosing the `Array` module.

## Module: `Array`

Module docs: "Contains operations for working with arrays." Links to the F# Language Guide topic "Arrays". Module declaration matches the implementation (`CompilationRepresentation.ModuleSuffix`, `RequireQualifiedAccess`).

### Public `val` surface (F# `Array` functions)

All declarations carry `[<CompiledName("...")>]` attributes and XML doc examples. Key members (CompiledName in parentheses where notable):

- Construction / shaping: `zeroCreate`, `create`, `init`, `empty`, `singleton`, `zeroCreate`; `append`, `concat`, `copy`, `sub`, `blit`, `fill`, `chunkBySize`, `splitInto`, `splitAt`, `windowed`, `transpose`, `resize`.
- Elements / accessors: `length`, `get`, `item`, `tryItem`, `head`, `tryHead`, `tail`, `last`, `tryLast`, `isEmpty`, `exactlyOne`, `tryExactlyOne`, `indexed`.
- Iteration: `iter` (Iterate), `iteri` (IterateIndexed), `iter2`, `iteri2`, `map` (Map), `mapi` (MapIndexed), `map2`, `mapi2`, `mapFold`, `mapFoldBack`.
- Predicates / search: `exists`, `exists2`, `forall`, `forall2`, `contains`, `find`, `findBack`, `findIndex`, `findIndexBack`, `tryFind`, `tryFindBack`, `tryFindIndex`, `tryFindIndexBack`, `tryPick`, `pick`, `replace` (present as an overload in some signatures; in this surface via `tryFind`-family).
- Filter / partition: `filter` (Filter), `where`, `partition`, `choose`, `collect`.
- Aggregations: `fold`, `foldBack`, `fold2`, `foldBack2`, `reduce`, `reduceBack`, `scan`, `scanBack`, `sum`, `sumBy`, `average`, `averageBy`, `min`, `max`, `minBy`, `maxBy`, `countBy`, `groupBy`, `compareWith`, `allPairs`.
- Sorting: `sort` (Sort), `sortBy`, `sortWith`, `sortDescending`, `sortByDescending`, and in-place variants `sortInPlace` (SortInPlace), `sortInPlaceBy` (SortInPlaceBy), `sortInPlaceWith` (SortInPlaceWith), `sortInPlaceDescending`, `sortInPlaceByDescending`.
- Conversions / composition: `toList`, `toSeq`, `zip`, `zip3`, `unzip`, `unzip3`, `pairwise`, `unfold`.
- Inlined SRTP members: `sum`, `sumBy`, `average`, `averageBy`, `min`, `max`, `minBy`, `maxBy` use `^T` static member constraints (`(+)`, `Zero`, `DivideByInt`, comparison).

### Module: `Array.Parallel`

A submodule with module docs describing operations performed in parallel (documented as using `System.Threading.Tasks.Parallel.For`). Public members:

- Predicates: `forall` (ForAll), `exists` (Exists) — stop other threads as soon as a result is determined.
- Search: `tryFind` (TryFind), `tryFindIndex` (TryFindIndex), `tryPick` (TryPick).
- Aggregations: `reduce` (Reduce, inline), `reduceBy` (ReduceBy), `max` (Max, inline), `maxBy` (MaxBy, inline), `min` (Min, inline), `minBy` (MinBy, inline), `sum`/`sumBy`/`average`/`averageBy` (inline SRTP).
- Transformation: `choose` (Choose), `collect` (Collect), `map` (Map), `mapi` (MapIndexed), `groupBy` (GroupBy), `iter` (Iterate), `iteri` (IterateIndexed), `init` (Initialize), `partition` (Partition), `partitionWith` (PartitionWith, inline), `filter` (Filter), `zip` (Zip).
- Sorting: `sort` (Sort), `sortBy` (SortBy), `sortWith` (SortWith), `sortInPlaceBy` (SortInPlaceBy), `sortInPlaceWith` (SortInPlaceWith), `sortInPlace` (SortInPlace), `sortDescending` (SortDescending), `sortByDescending` (SortByDescending).

Documentation notes:  parallel `reduce`/`reduceBy` require commutative reductions; parallel sorts are unstable; `partitionWith` partitioner must be thread-safe.

## Key design notes

- Every function is documented with `param`/`returns`/`exception`/`example` XML blocks; exception docs list `ArgumentNullException` for null inputs and `ArgumentException` for empties in folding/aggregation and for wrong dimensions in `blit`/`zip`/`sub`/`fill`.
- Compiled names (`ForAll`, `Exists`, `TryFind`, `Reduce`, `MapIndexed`, `SortInPlaceBy`, ...) define the .NET-facing method names so F# source names remain idiomatic while the metadata stays CLR-friendly.

## Notable behavior

- SRTP inlines carry explicit `when ^T : (static member (+)...)` constraints, allowing `byte`/`float`/user-defined numeric-like types to participate in `sum`/`average` without boxing.
- The Parallel section documents non-deterministic application order except where the lowest index wins (`exists`/`forall`/`tryFindIndex`).
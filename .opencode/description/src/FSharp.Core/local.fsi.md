# local.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Signature for the two internal namespaces in `local.fs`: the `DetailedExceptions` error helpers and the `Microsoft.FSharp.Primitives.Basics` optimized implementations.

## Namespace: Microsoft.FSharp.Core — module DetailedExceptions
`[<AutoOpen>] module internal DetailedExceptions` — all functions are `internal` (not public API); every one is generic in `'T` because they always throw.

- `invalidArgFmt: arg -> format -> objnull array -> 'T` — `ArgumentException`.
- `invalidOpFmt: format -> objnull array -> 'T` — `InvalidOperationException`.
- `invalidArgDifferentListLength: arg1 -> arg2 -> diff -> 'T`.
- `invalidArg3ListsDifferent: arg1 -> arg2 -> arg3 -> len1 -> len2 -> len3 -> 'T`.
- `invalidOpListNotEnoughElements: index -> 'T`.
- `invalidOpExceededSeqLength: fnName -> diff -> len -> 'T`.
- `invalidArgInputMustBeNonNegative: arg -> count -> 'T`.
- `invalidArgInputMustBePositive: arg -> count -> 'T`.
- `invalidArgOutOfRange: arg -> index -> text -> bound -> 'T` — `ArgumentOutOfRangeException`.
- `invalidArgDifferentArrayLength: arg1 -> len1 -> arg2 -> len2 -> 'T`.
- `invalidArg3ArraysDifferent: arg1 -> arg2 -> arg3 -> len1 -> len2 -> len3 -> 'T`.

## Namespace: Microsoft.FSharp.Primitives.Basics — module List (internal)
Exposed internal list algorithms consumed by the public List/Seq modules:
- `allPairs`, `choose`, `countBy` (from a prebuilt `Dictionary<'T1,int>`), `pairwise`, `groupBy` (comparer + safeKey/key functions), `distinctWithComparer`, `distinctByWithComparer`.
- `init`, `filter`, `collect`, `partition`, `map`, `map2`, `map3`, `scan`, `mapi`, `mapi2`, `indexed`, `mapFold`.
- `forall`, `exists`, `rev`, `concat`, `unfold`, `unzip`, `unzip3`.
- `windowed`, `chunkBySize`, `splitInto`, `zip`, `zip3`, `ofArray`, `take`, `takeWhile`, `toArray`, `ofSeq`, `splitAt`, `transpose`, `truncate`, `tryLastV` (`ValueOption`).

## Module: Basics.Array (internal)
- `zeroCreateUnchecked`, `init`, `splitInto`.
- `findBack`, `tryFindBack`, `findIndexBack`, `tryFindIndexBack`.
- `mapFold`, `mapFoldBack`, `permute`, `scanSubRight`, `subUnchecked`.
- Sorting: `unstableSortInPlaceBy`, `unstableSortInPlace`, `stableSortInPlaceBy`, `stableSortInPlaceWith`, `stableSortInPlace`.

## Module: Basics.Seq (internal)
- `tryLastV: 'T seq -> 'T ValueOption`.

## Module: Basics.Random (internal)
- `next: randomizer: (unit -> float) -> minValue -> maxValue -> int`.
- `getMaxSetSizeForSampling: count -> int`.
- `shuffleArrayInPlaceWith: random: Random -> array: 'T[] -> unit`.
- `shuffleArrayInPlaceBy: randomizer: (unit -> float) -> array: 'T[] -> unit`.

## Notable behavior
- Everything in this signature is `internal` to FSharp.Core; only the higher-level public modules (`List`, `Array`, `Seq`, `Random`) in the same assembly use these members.
- `DetailedExceptions` is `[<AutoOpen>]` so its helpers are visible throughout the library without qualification.
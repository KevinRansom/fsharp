# seq.fs

## Overview

This file (namespace `Microsoft.FSharp.Collections`) is the **complete implementation of the `Seq` module** — the standard library of operations over `seq<'T>` (i.e. `System.Collections.Generic.IEnumerable<'T>`). The actual iteration/lazy plumbing relies on `Microsoft.FSharp.Core.CompilerServices.RuntimeHelpers`-style helpers (`mkSeq`, `cast`, `Singleton`, `Empty`, `dispose`, `noReset`, `notStarted`, `alreadyFinished`, `check`) and `Microsoft.FSharp.Primitives.Basics` for list/array conversions and shuffling. There are two main internal layers: an `Internal` module of enumerator utilities and a `Generator` module that drives lazy sequence-expression evaluation.

## `module Internal`

- `arrayBuilderStartingSize : int` literal (`4`).
- `type ArrayBuilder<'T>` (`[<Struct; NoEquality; NoComparison>]`) — record `{ mutable currentCount: int; mutable currentArray: 'T array }`; `addToBuilder` (grow-doubling append) and `builderToArray` (trim to exact length) as `inline` functions.
- `module IEnumerator` — low-level enumerator utilities:
  - `tryItem` / `nth` (with "seq was short by N element(s)" error), `map`, `mapi`, `map2`, `mapi2`, `map3` (all using `OptimizedClosures.FSharpFunc.Adapt`), `choose`, `filter`, `unfold`, `upto` (lazy indexed sequence with `Lazy` caches for `Seq.init`/`Seq.initInfinite`), and `type ArrayEnumerator<'T>` with `ofArray`.
  - `type MapEnumeratorState` (`NotStarted | InProcess | Finished`) and abstract `type MapEnumerator<'T>` base class providing state-checked `Current` access and an abstract `DoMoveNext: byref<'T> -> bool` + `Dispose`.

- `module Generator` — the internal representation driving sequence expressions:
  - `type Step<'T> = Stop | Yield of 'T | Goto of Generator<'T>` and `type Generator<'T> = { abstract Apply: unit -> Step<'T>; abstract Disposer: (unit -> unit) option }`.
  - `disposeG`, `appG` (applies and, on `Stop`, disposes + `Stop`).
  - `type GenerateThen<'T>(g, cont)` — implements generator **binding with right-association** (`bindG (bindG G1 cont1) cont2 --> bindG G1 (cont1 o cont2)`), which keeps recursive/yielding constructs linear instead of quadratic. `bindG` is exposed.
  - `type EnumeratorWrappingLazyGenerator<'T>(g)` — an `IEnumerator<'T>` that tracks a current generator in a mutable cell; on `Goto` it swaps the generator and continues (so long/infinite generation chains are driven through a single enumerator). On completion it senses `Stop` and disposes. Disposal only occurs if not finished.
  - `type LazyGeneratorWrappingEnumerator<'T>(e)` — wraps an enumerator as a generator (`Yield` per `MoveNext`, `Stop` at end, `Disposer = Some e.Dispose`).
  - `EnumerateFromGenerator` / `GenerateFromEnumerator` — optimized converters that peel off a matching wrapper (unwrapping `LazyGeneratorWrappingEnumerator`/`EnumeratorWrappingLazyGenerator`) to avoid nested wrappers.

## `type CachedSeq<'T>(cleanup, res: seq<'T>)` (`[<Sealed>]`)

A `seq<'T>` wrapper (implements `IEnumerable<'T>`, non-generic `IEnumerable`, and `IDisposable`) that delegates `GetEnumerator` to the wrapped sequence and runs `cleanup` on `Dispose`/`Clear`. Used by `Seq.cache`.

## `module Seq` (`[<RequireQualifiedAccess>]` + `ModuleSuffix`)

Public operations; each has `[<CompiledName(...)>]`. Construction/looping primitives use internal helpers `mkDelayedSeq`, `mkUnfoldSeq`, `revamp`/`revamp2`/`revamp3` (wrap a transforming enumerator function into an `IEnumerable`, capturing enumerators lazily). Notable grouped operations:

- **Construction**: `delay`, `unfold`, `empty` (via LINQ `Enumerable.Empty`), `init`, `initInfinite`, `singleton`, `replicate` (LINQ `Repeat`), `ofList`, `ofArray` (fresh object so the array can't be mutated via a backdoor cast), `cast` (from non-generic `IEnumerable`).
- **Basic scanning**: `iter`, `iteri`, `iter2`, `iteri2`, `exists`, `forall`, `exists2`, `forall2`, `contains`, `item`, `tryItem`, `nth` (`Get`), `take`, `skip`, `head`, `tryHead`, `tail`, `last`, `tryLast`, `exactlyOne`, `tryExactlyOne`, `isEmpty`, `length` (with fast paths for array/list/`ICollection<'T>`).
- **Transforms**: `filter`/`where`, `map`, `mapi`, `map2`, `mapi2`, `map3`, `choose`, `indexed`, `zip`, `zip3`, `cast`, `collect` (map+concat), `concat` (via `RuntimeHelpers.mkConcatSeq`), `append` (right-associated generator bind over the two sources), `pairwise`, `scan`, `scanBack`, `windowed` (rotating buffer; fast-path for small windows), `chunkBySize`, `splitInto`, `transpose`, `mapFold`/`mapFoldBack` (via arrays), `rev` (Reverse), `permute`.
- **Search**: `tryPick`, `pick`, `tryFind`, `find`, `findBack`, `tryFindBack`, `findIndex`, `tryFindIndex`, `findIndexBack`, `tryFindIndexBack` (back variants via `toArray` + array functions).
- **Folds/aggregates**: `fold`, `fold2`, `reduce`, `foldBack` (`foldArraySubRight` over materialized array), `foldBack2`, `reduceBack`, `sum`, `sumBy`, `average`, `averageBy`, `min`, `minBy`, `max`, `maxBy` (all SRTP-based `inline`), `countBy`, `groupBy` (inline SRTP-erased impls with `groupByImpl`/`groupByValueType`/`groupByRefType`, using `Dictionary`; the ref-type variant wraps keys in `RuntimeHelpers.StructBox` to handle null-represented keys), `distinct`, `distinctBy` (via `HashSet`).
- **Take/skip variants**: `takeWhile`, `skipWhile`, `truncate`, `windowed`, `except` (HashSet of excluded items, preserving first-seen order).
- **Sorting**: `sortBy`, `sort`, `sortWith`, `sortByDescending`, `sortDescending` (all materialize to array, `stableSortInPlace*`, then expose as a delayed seq).
- **Positional editing** (lazy, via `seq { }` with index tracking and bounds validation): `removeAt`, `removeManyAt`, `updateAt`, `insertAt`, `insertManyAt`.
- **Randomization** (delegating to `Microsoft.FSharp.Primitives.Basics.Random`, with `ThreadSafeRandom.Shared` for the default): `randomShuffleWith`/`By`/`Shuffle`, `randomChoiceWith`/`By`/`Choice`, `randomChoicesWith`/`By`/`Choices`, `randomSampleWith`/`By`/`Sample` (partial-shuffle vs HashSet-rejection sampling depending on set size).
- **Other**: `compareWith` (lexicographic via pair-walk + `OptimizedClosures`), `cache` (thread-safe, caches prefix; `CachedSeq` with `lock prefix` for one-step-at-a-time progress and a `cleanup` that disposes the underlying enumerator), `allPairs` (cartesian product via cached `source2`), `readonly` (`Seq.ReadOnly`).

Most higher-order functions avoid direct lambda application overhead by adapting with `OptimizedClosures.FSharpFunc<...>.Adapt(...)` then `.Invoke(...)` with fully generic arities (2–4).

# list.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Public API signature for the `List` module (implemented in `list.fs`) — the standard collection of linked-list operations.

## Namespaces
- `Microsoft.FSharp.Collections`

## Module: List
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module List`

Full public surface (each `val` carries XML docs, parameter descriptions and examples; grouped here semantically):

### Creation & conversion
- `allPairs: list1 -> list2 -> ('T1 * 'T2) list` — Cartesian product.
- `append: list1 -> list2 -> 'T list` — concatenation.
- `empty<'T> : 'T list` — the empty list.
- `init: length -> (int -> 'T) -> 'T list` — indexed generation; throws on negative length.
- `replicate: count -> 'T -> 'T list` — repeated value.
- `singleton: 'T -> 'T list`.
- `unfold: generator: ('State -> ('T * 'State) option) -> state -> 'T list`.
- `ofArray` / `toArray` / `ofSeq` / `toSeq` — conversions.

### Accessors
- `head` / `tryHead` / `tail` / `last` / `tryLast` / `isEmpty` / `length`.
- `item: index -> list -> 'T` / `tryItem` / `nth` (same as item).
- `exactlyOne` / `tryExactlyOne`.
- `front`-analogues `find`/`findBack`/`findIndex`/`findIndexBack` and their `try*` variants; `pick`/`tryPick`.
- `contains: value -> list -> bool when 'T : equality`.
- `exists` / `exists2`, `forall` / `forall2`.

### Transformation
- `map`, `mapi`, `map2`, `mapi2`, `map3`, `indexed`, `collect`, `choose`.
- `iter`, `iteri`, `iter2`, `iteri2`.
- `mapFold`, `mapFoldBack`, `fold`, `fold2`, `foldBack`, `foldBack2`, `reduce`, `reduceBack`.
- `scan`, `scanBack`, `filter` / `where`, `partition`, `partitionWith` (via `Choice`).
- `distinct`, `distinctBy`, `countBy`, `groupBy`, `except`.
- `pairwise`, `zip`/`zip3`, `unzip`/`unzip3`, `transpose`, `permute`.

### Slicing & structure
- `splitAt`, `take`, `takeWhile`, `skip`, `skipWhile`, `truncate`, `windowed`, `chunkBySize`, `splitInto`, `choose`.

### Aggregates (inline, operator-constrained)
- `sum`, `sumBy`, `average`, `averageBy` (srqt-types), `max`, `maxBy`, `min`, `minBy`.

### Sorting & comparison
- `sort`, `sortBy`, `sortWith`, `sortByDescending`, `sortDescending`.
- `compareWith: ('T -> 'T -> int) -> list1 -> list2 -> int`.

### Indexed mutations
- `removeAt`, `removeManyAt`, `updateAt`, `insertAt`, `insertManyAt`.

### Random operations
- `randomShuffle` (+ `randomShuffleWith: Random -> ...`, `randomShuffleBy: (unit -> float) -> ...`).
- `randomChoice` (+ `...With`, `...By`).
- `randomChoices` (with/without replacement variants `...With`, `...By`).
- `randomSample` (+ `...With`, `...By`) — without replacement.

## Notable behavior
- `partitionWith` splits a list into two lists via a `Choice`-returning partitioner (a single traversal).
- The `randomSample` family preserves list order of selected elements and throws if `count > length` (`notEnoughElements`).
- All signatures with `when 'T : equality` / `when 'Key : comparison` etc. reflect structural or comparison constraints satisfied by the caller.
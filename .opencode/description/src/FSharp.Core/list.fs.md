# list.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler; implements the `List` module of operations over the immutable F# linked list (`'T list`, `FSharpList`).

## Namespaces
- `Microsoft.FSharp.Collections` (module)
- Usages from `Microsoft.FSharp.Primitives.Basics.List` (internal implementation helpers), `Microsoft.FSharp.Core.CompilerServices` (ListCollector), `System.Collections.Generic` (Dictionary/HashSet).

## Module: List
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module List`

### Internal helpers
- `checkNonNull argName arg` — inline null check (`nullArg`).
- `indexNotFound ()` — raises `KeyNotFoundException` with the localized key-not-found message.
- `countByImpl comparer projection getKey list` — dictionary-based counting shared by the value-type/ref-type specializations.
- `countByValueType projection list` — counts using `HashIdentity.Structural<'Key>` directly with the raw key.
- `countByRefType projection list` — wraps keys in `RuntimeHelpers.StructBox<'Key>` (to guard against `null`-representing key types) and uses `StructBox<'Key>.Comparer`; then hands off to `Basics.List.countBy`.
- `groupByImpl / groupByValueType / groupByRefType` — same structural/StructBox split applied to `Basics.List.groupBy`.
- `foldArraySubRight f arr start fin acc` — right fold over an array via a `for` loop; stack-safe.
- `scanArraySubRight f arr start fin initState` — right scan building the result list; stack-safe.
- `foldBack2UsingArrays f list1 list2 acc` — right fold of two lists over arrays; checks equal lengths.
- `forall2aux` / `exists2aux` — tail-recursive two-list quantifiers over adapted closures.

### Basic accessors
- `length` — `list.Length` (O(n)) — `CompiledName "Length"`.
- `last` — via `Basics.List.tryLastV`; raises `ArgumentException` when empty.
- `tryLast` — `ValueOption`-based, mapped to `option`.
- `rev`, `concat` — delegated to `Basics.List`.
- `head` / `tryHead` / `tail` / `isEmpty` — standard cons-cell accessors.
- `item index list` (`CompiledName "Item"`) — recursive index lookup; raises for out-of-range.
- `tryItem` — safe index lookup.
- `nth` — alias of `item` (`CompiledName "Get"`).
- `find` / `tryFind` (recursive, predicate walk), `findBack` / `tryFindBack` (via `toArray` + `Basics.Array.*`).
- `findIndex` / `tryFindIndex` / `findIndexBack` / `tryFindIndexBack` — index variants (back variants over arrays).
- `pick` / `tryPick` — first `Some` of a chooser, else not-found/`None`.
- `exactlyOne` / `tryExactlyOne` — single/triple-pattern on the cons list.
- `contains` — inline structural equality walk.
- `singleton` — `[ value ]`.

### Construction / conversion
- `empty<'T>` — `[]: 'T list`.
- `init`, `replicate` (validates non-negative count, builds with an accumulator), `unfold`, `ofArray`, `toArray`, `ofSeq` (= `Seq.toList`), `toSeq` (= `Seq.ofList`).
- `append` — `list1 @ list2`.

### Maps / iteration
- `map`, `mapi`, `indexed`, `map2`, `mapi2`, `map3`, `mapFold`, `mapFoldBack` (right version reversed-list fold, adapted closures).
- `iter`, `iteri` — `inline`, `[<InlineIfLambda>]` actions over a `for ... in list` loop.
- `iter2`, `iteri2` — dual-list iteration with different-length guards (`invalidArgDifferentListLength`).
- `choose`, `collect` — via `Basics.List`.
- `filter` / `where` — via `Basics.List.filter`.

### Folds and scans
- `fold` — imperative accumulator loop over the list with adapted closure.
- `fold2`, `foldBack`, `scan`, `scanBack`, `foldBack2`, `reduce`, `reduceBack`.
- Stack safety: `foldBack`, `scanBack`, `reduceBack`, `foldBack2` convert the list to an array and fold with an index loop rather than building deep call stacks, avoiding stack overflow on large lists. Small-list fast paths (1–4 elements) avoid the array allocation.

### Counting / grouping / deduplication
- `countBy` — dispatches on `typeof<'Key>.IsValueType` to value type (direct) vs reference type (StructBox) paths.
- `groupBy` — same dispatch, results via `Basics.List.groupBy`.
- `distinct`, `distinctBy` — via `Basics.List.distinctWithComparer`/`distinctByWithComparer` with `HashIdentity.Structural`.
- `except` — admits items into a `HashSet` then filters; ref-counts via structural identity.

### Pairing / splitting / slicing
- `pairwise`, `zip`, `zip3`, `unzip`, `unzip3` — via `Basics.List`.
- `partition` — via `Basics.List.partition`.
- `partitionWith` — inline partitioner into two `ListCollector`s, closed via `ListCollector.Close()`.
- `splitAt`, `take`, `takeWhile`, `skip`, `skipWhile`, `truncate`, `windowed`, `chunkBySize`, `splitInto`, `allPairs`, `transpose`.
- `permute` — via `toArray` + `Basics.Array.permute` + `ofArray`.

### Aggregation (inline numeric)
- `sum`/`sumBy` — `GenericZero` + `Checked.(+)`.
- `average`/`averageBy` — `GenericZero` + `Checked.(+)` + `DivideByInt`.
- `max`/`maxBy`/`min`/`minBy` — inline loops maintaining best element (and its projection).

### Sorting
- `sortWith`, `sortBy`, `sort` — convert to array, `Basics.Array.stableSortInPlace*`, convert back; short-circuit singleton/empty lists.
- `sortByDescending` / `sortDescending` — inline reversed comparers that still use the stable `sortWith`.

### Comparison / membership
- `compareWith` — inline lexicographic loop: compare heads, recurse on tie, shorter list is smaller.
- `forall`, `forall2`, `exists`, `exists2` — quantifiers (two-list ones with different-length errors).

### Indexed mutation (immutable "update" family)
- `removeAt` / `removeManyAt` / `updateAt` / `insertAt` / `insertManyAt` — all walk the prefix with a `ListCollector`, mutate a local cursor, and rebuild the suffix; `AddManyAndClose` finishes the list. Insert operations validate index bounds via `invalidArg`.

### Random operations
- `randomShuffleWith` / `randomShuffleBy` / `randomShuffle` — Fisher–Yates via `Basics.Random.shuffleArrayInPlace*` after `toArray`; the default uses `ThreadSafeRandom.Shared`.
- `randomChoiceWith` / `randomChoiceBy` / `randomChoice` — uniform single pick by index (`random.Next(0, len)` or `Basics.Random.next`).
- `randomChoicesWith` / `randomChoicesBy` / `randomChoices` — count picks *with* replacement.
- `randomSampleWith` / `randomSampleBy` / `randomSample` — sampling *without* replacement: for small input (≤ the set-size threshold) uses the Floyd-style pool with in-place swap of the last element; for large input, rejection-samples unique indices via a `HashSet`.

## Key design notes
- Heavily delegates to `Microsoft.FSharp.Primitives.Basics.List`, keeping the visible module as a thin, well-documented layer with extra validation and polymorphism dispatch.
- `countBy`/`groupBy` use a `StructBox` indirection for reference keys so that keys equal to `null` hash correctly with structural semantics.
- Folds/back-folds are stack-safe via array intermediate representation; forward folds are imperative loops.
- The random family isolates a `Random` object and a `unit -> float` randomizer abstraction for deterministic seeding.
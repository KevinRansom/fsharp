# TaggedCollections.fs

**Purpose**: F# compiler-internal implementation of "tagged" Set and Map collections (`Internal.Utilities.Collections.Tagged`), i.e. F#-semantic `Set`/`Map` (AVL-style balanced binary trees) parameterized by an explicit key comparer (`'ComparerTag :> IComparer<'T>`). This lets the compiler build sets/maps whose key ordering is defined by a type-dependent or custom comparer (e.g. symbol tables keyed by names with compiler-specific comparison semantics) while keeping the same `FSharp.Collections.Set/Map`-style value semantics. The file is a large, self-contained reimplementation of FSharp.Core's `Set`/`Map` with the comparer threaded through every tree operation.

**Namespace(s)**: `Internal.Utilities.Collections.Tagged`

**Modules / Types declared**:

- `type internal SetTree<'T>(k)` / `type internal SetTreeNode<'T>(v, left, right, h)` — the persistent balanced tree nodes (singleton + internal node with height), `[<AllowNullLiteral>]` (null = empty).
- `[<...ModuleSuffix>] module SetTree` — tree algorithms: `empty`, `isEmpty`, `count`, `height`, `mk`, `rebalance`, `add`, `balance`, `split`, `spliceOutSuccessor`, `remove`, `contains`, `iter`, `fold` (left-to-right, documented as differing from `Map.fold`), `forall`, `exists`, `subset`, `filter`, `diff`, `union` (divide-and-conquer via `split`), `intersection`, `partition`, `minimumElement( Opt)`, `maximumElement(Opt)`, `SetIterator<'T>` (imperative left-to-right enumerator with `collapseLHS`), `toSeq`, `compareStacks`/`compare`, `choose`, `toList`, `copyToArray`/`toArray`, `ofSeq`, `ofArray`.
- `type internal Set<'T, 'ComparerTag> when 'ComparerTag :> IComparer<'T>` — the public-internal immutable set; static ops `(-)`, `(+)/Union`, `Intersection`, `Difference`, `Equality`, `Compare`, `Empty`, `Singleton`, `Create`; instance ops `Add`, `Remove`, `Count`, `Contains`, `Iterate`, `Fold`, `IsEmpty`, `Partition`, `Filter`, `Exists`, `ForAll`, `Choose`, `MinimumElement`, `MaximumElement`, `IsSubsetOf`, `IsSupersetOf`, `ToList`, `ToArray`; implements `ICollection<'T>` (read-only), `IEnumerable<'T>`, `IEnumerable`, `IComparable`; `Equals/GetHashCode`.
- `type internal Set<'T> = Set<'T, IComparer<'T>>` — default-comparer alias.
- `type internal MapTree<'Key,'Value>` / `type internal MapTreeNode<'Key,'Value>` — map tree nodes.
- `module MapTree` — same algorithm set for maps: `size`, `height`, `mk`, `rebalance`, `add`, `tryGetValue`/`find`/`tryFind`, `partition`, `filter`, `spliceOutSuccessor`, `remove`, `mem`, `iter`, `tryPick`, `exists`, `forall`, `map`, `mapi`, `foldBack` (right-to-left, documented as differing from `Set.fold`), `foldSection` (range-fold over keys in `[lo,hi]`), `foldMap`, `toList`/`toArray`, `ofList`/`ofSeq`, `MapIterator` + `toSeq`.
- `type internal Map<'Key,'Value,'ComparerTag> when 'ComparerTag :> IComparer<'Key>` — instance ops `Add`, `IsEmpty`, `Item` (get only), `First`, `Exists`, `Filter`, `ForAll`, `Fold`, `FoldSection`, `FoldAndMap`, `Iterate`, `MapRange`, `Map`, `Partition`, `Count`, `ContainsKey`, `Remove`, `TryFind`, `ToList`, `ToArray`; statics `Empty`, `FromList`, `Create`; `IEnumerable<KeyValuePair<_,_>>`, `IComparable`; `Equals/GetHashCode`.
- `type internal Map<'Key,'Value> = Map<'Key,'Value, IComparer<'Key>>` — default alias.

**Public API surface** (see the member lists above; the .fsi mirrors it with doc comments). Notable semantics:

- Set `fold` is left-to-right; Map `Fold` is right-to-left (documented difference).
- `Map.FoldSection lo hi f` folds only bindings with keys in the closed range `[lo, hi]`.
- `Map.FoldAndMap` folds while simultaneously mapping values.
- `Map.First f` returns the first `Some` from `f` in tree order.
- `Set.Intersection/Union/Difference`, `Set.Equality/Compare` are statics (also operators `+`, `-`).

**Internal helpers**: `rebalance` (tolerance-2 height balancing with left/right rotation), `spliceOutSuccessor`, `collapseLHS` (iterator fringe collapse), `indexNotFound`/KeyNotFoundException semantics, `OptimizedClosures.FSharpFunc.Adapt` to avoid delegate re-boxing in the `*Opt` map-tree functions.

**Significant internal logic**:

- Persistent AVL-like trees: `add`/`remove`/`union` share nodes with predecessors; `union` uses split-the-larger-tree divide-and-conquer (split by the larger tree's root key, union disjoint subproblems, `balance` the results) — a known efficient two-tree union.
- Comparer is threaded explicitly through every operation (`add comparer`, `mem comparer`, `union comparer`, `foldSection comparer ...`) — never captured — which is what makes the `'ComparerTag` design sound: two sets/maps with different comparers can coexist and equality (`Set.Equality`) compares using one set's comparer with the same-type check.
- `Equals`/`IComparable` enforce exact generic-comparer-tag match before comparing (comment references issue 4884: different comparers could permute elements, so cross-comparer comparison is forbidden).
- `GetHashCode` is computed by combining `Unchecked.hash` of each element in tree order — only well-defined because a fixed comparer is bound into the value.

**Cross-references**: `TaggedCollections.fsi` (same directory) is the contract. `zmap.fs`/`zset.fs` are thin functional facades over exactly these types (`Zmap = Tagged.Map`, `Zset = Tagged.Set`). Uses `NullHelpers`-family `objEqualsArg` from the `Internal.Utilities.Library` namespace for `Equals` signatures.

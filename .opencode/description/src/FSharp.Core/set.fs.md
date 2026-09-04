# set.fs

## Overview

This file (namespace `Microsoft.FSharp.Collections`) implements the **functional Set type** (`FSharpSet<'T>` for `'T: comparison`) as a **balanced (AVL-style) binary tree**, plus the `Set` module of operations. The tree is immutable and uses `null` to represent the empty tree. Rebalancing keeps the heights of subtrees within a constant tolerance so lookups/insertions/deletions are O(log n). There are also extensive `TRACE_SETS_AND_MAPS` hooks (off by default) for empirically measuring tree/node statistics.

## Tree representation (`SetTree<'T>`)

- `type internal SetTree<'T>(k, h)` (`[<NoEquality; NoComparison; AllowNullLiteral>]`) — base class holding `Key` and `Height`; `SetTree(k)` is a leaf (singleton).
- `type internal SetTreeNode<'T>(v, left, right, h)` (`[<Sealed; AllowNullLiteral>]`) — internal node with `Left`/`Right`.

## `module internal SetTree`

Core balanced-tree algorithms over an `IComparer<'T>`:

- `empty = null`; `isEmpty`, `height`, `mk` (build a node from validated heights), and `rebalance` (single or double rotation: comparison of `t1h` vs `t2h` against `tolerance = 2` with the standard AVL balancing cases).
- `count`, `add` (insert or return unchanged on equal key), `balance` (join `t1 < k < t2` into a balanced tree), `split pivot t` (partition into `< pivot`, `pivot in t?`, `> pivot`), `remove` (with `spliceOutSuccessor` to replace an internal node by its in-order successor), `mem` (member test), `tryGet` (returns `ValueOption`).
- Iteration/folds: `iter`, `foldBack`/`fold` (via `OptimizedClosures.FSharpFunc` adapter), `forall`, `exists`, `subset`, `properSubset`.
- Set algebra: `filter`, `diff` (removes all keys of `b` from `a`), `union` (divide-and-conquer via `split` on the taller tree's pivot), `intersection` (chooses `intersectionAux` vs `intersectionAuxFromSmall` based on which tree is larger), `partition` (`partitionAux`/`partition1`), and `partitionWith` (splits one `SetTree<'T>` into two sets of possibly-different types via a `'T -> Choice<'T1,'T2>` partitioner; traverses descending so inserts are largest-first).
- Extremes: `minimumElement(Aux/Opt)`, `maximumElement(Aux/Opt)`, `minimumElement`/`maximumElement` (raise `SR.setContainsNoElements` on empty).
- Stack-based traversal helper `SetIterator<'T>` (`{ mutable stack: SetTree<'T> list; mutable started: bool }`) with `mkIterator`, `current`, `moveNext` (imperative left-to-right in-order enumeration), and `collapseLHS`; `mkIEnumerator` adapts it to `IEnumerator<'T>` with `Reset` reinstantiated from the original tree.
- Comparison: `compareStacks` (expensive lexicographic comparison of two sets by walking both in-order via explicit stacks) wrapped by `compare`.
- Conversions: `choose` (= `minimumElement`), `toList`, `copyToArray`, `toArray`, `ofSeq`, `ofArray`, `mkFromEnumerator`.

## `type Set<'T>` (`[<Sealed; CompiledName("FSharpSet`1")>]`)

The public immutable set, `'T : comparison`. Under `NETSTANDARD2_1_OR_GREATER || NET` decorated with `[<CollectionBuilder(typeof<Set>, "Create")>]` for collection-expression support. Fields: `comparer` and `tree` (both `[<NonSerialized>]`, mutated only during deserialization) and `serializedData` (used for the permanent serialization format). Static `empty` per type instantiation via `LanguagePrimitives.FastGenericComparer<'T>` (no allocation per empty set). Serialization hooks `OnSerializing`/`OnDeserialized` serialize the tree as an array.

Members:
- `Add`, `Remove`, `Count`, `Contains`, `Iterate`, `Fold`, `IsEmpty`, `Partition`, internal `PartitionWith`, `Filter`, `Map`, `Exists`, `ForAll`.
- Operators: `static (-)` = difference, `static (+)` = union, static `Intersection(a,b)`, static `Union(sets)`, `Intersection(sets)`.
- Static `Equality`/`Compare` (via `SetTree.compare`); `Choose`, `MinimumElement`, `MaximumElement`; `IsSubsetOf`/`IsSupersetOf`/`IsProperSubsetOf`/`IsProperSupersetOf`; `ToList`/`ToArray`; `Empty` static; `Singleton` static; ctor `new(elements: seq<'T>)`; static `Create(elements)` and `FromArray(arr)`; `ToString` produces `"set [e1; e2; ...]"` (truncated at 4, via `anyToStringShowingNull`).
- Equality/hashing: `ComputeHashCode` (shift-combine hash), `GetHashCode`, `Equals`, `IComparable.CompareTo`, and `IStructuralEquatable` (`Equals`/`GetHashCode` honoring a supplied comparer).
- Interfaces: `ICollection<'T>` (read-only — `Add`/`Clear`/`Remove` throw `NotSupportedException`, `Contains`, `CopyTo`, `IsReadOnly = true`, `Count`), `IReadOnlyCollection<'T>`, `IEnumerable<'T>`, `IEnumerable`.

For `NETSTANDARD2_1_OR_GREATER || NET`, a companion `Set` static class (`FSharpSet`, `[<Sealed; AbstractClass>]`, hidden compiler-message 1204) provides `Create(ReadOnlySpan<'T>)` for collection expressions.

## `type SetDebugView<'T>` (`[<Sealed>]`)

Debugger proxy exposing `Items` (first 1000 elements as an array, `RootHidden`). Referenced by `[<DebuggerTypeProxy(typedefof<SetDebugView<_>>)>]` on `Set<_>`.

## `module Set` (`[<RequireQualifiedAccess>]` + `ModuleSuffix`)

Public module operations delegating to the type's members or `SetTree`: `isEmpty`, `contains`, `add`, `singleton`, `remove`, `union`, `unionMany`, `intersect`, `intersectMany`, `iter`, `empty`, `forall`, `exists`, `filter`, `partition`, `partitionWith`, `fold`, `foldBack`, `map`, `count`, `ofList`, `ofArray`, `toList`, `toArray`, `toSeq`, `ofSeq`, `difference`, `isSubset`, `isSuperset`, `isProperSubset`, `isProperSuperset`, `minElement`, `maxElement`. Each has a `[<CompiledName(...)>]`.

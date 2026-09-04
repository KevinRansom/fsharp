# map.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler; implements the immutable `Map<'Key,'Value>` type (AVL binary tree) and the `Map` module in `Microsoft.FSharp.Collections`.

## Namespaces
- `Microsoft.FSharp.Collections`

## Tree node types (internal)
- `MapTree<'Key,'Value>(k, v, h)` — base node with `Height`, `Key`, `Value`; represents a leaf (single binding) when `h = 1`. `[<NoEquality; NoComparison>] [<AllowNullLiteral>]`; `empty` is represented by `null`.
- `MapTreeNode<'Key,'Value>(k, v, left, right, h)` — internal node inheriting MapTree, adding `Left`/`Right`.

## Module: MapTree (internal)
The AVL tree engine.

### Core invariants
- `empty = null`; `isEmpty` = null test.
- `height` — 0 for empty.
- `tolerance = 2` — allowed height imbalance between subtrees.
- `mk l k v r` — construct a node with computed height (max subtree height + 1); leaf node if both children empty.
- `rebalance t1 k v t2` — single/double rotations: if right is heavier than left (`t2h > t1h + tolerance`) rotate left, or for "combination" balance rotate about left child's right child (AVL RL); symmetric for left-heavy (LR). Returns `mk` node otherwise.

### Structural operations
- `size` / `sizeAux` — element count (leaf = 1).
- `add comparer k v m` — insert; rebuilds path preserving balance (`rebalance`); replaces value on equal key (creating a new node).
- `tryGetValue comparer k (v: byref<_>) m` — descend left/right by comparer; writes value into `byref`; leaf fast-path.
- `find` / `tryFind` — via tryGetValue; `find` throws `KeyNotFoundException` (no-inline helper `throwKeyNotFound`).
- `spliceOutSuccessor m` — extracts the smallest key/value of a right subtree (leftmost path unwinding), returning `(k, v, tree')`.
- `remove comparer k m` — deletion via splice-out + `rebalance`.
- `change comparer k (u: 'Value option -> 'Value option) m` — the same "upsert" operation used by `Map.Change`: applies `u` to the existing binding (`None` if absent); `Some v` inserts, `None` deletes; rebuilds/rebalances.
- `mem` — membership test.
- `leftmost`/`rightmost` — min/max key-value; throws `KeyNotFoundException` on empty.

### Higher-order tree walks (all adapted via `OptimizedClosures.FSharpFunc`)
- `partition`/`partitionAux`/`partition1` — split into two maps by predicate (traverses right, root, left into accumulating maps).
- `filter`/`filterAux`/`filter1` — keep predicate-satisfying bindings (in-order traversal).
- `iterOpt`/`iter` — in-order apply.
- `tryPickOpt`/`tryPick` — first `Some` in in-order traversal.
- `existsOpt`/`exists`, `forallOpt`/`forall` — short-circuit quantifiers.
- `map` / `mapiOpt`/`mapi` — value transforms preserving keys/heights.
- `fold` (left, in-order) / `foldBack` (right via reversed order).
- `foldSectionOpt`/`foldSection` — folds only bindings within `[lo, hi]` key range, skipping whole subtrees outside the range using comparer checks.

### Conversions
- `toList` (in-order accumulation), `toArray` (= toList → `Array.ofList`).
- `ofList`, `ofArray` (single-pass adds), `ofSeq` (fast paths for array/list, otherwise enumerator driven).
- `copyToArray m arr i` — writes `KeyValuePair`s into an array.

### Iteration support (stack-based, no recursion on enumerator)
- `MapIterator<'Key,'Value>` record: `stack: MapTree list` + `started` flag.
- `collapseLHS stack` — expands the stack into a "left spine"; invariant is that the stack's top is always a leaf or empty/list; used by all enumerator ops.
- `mkIterator` / `current` / `moveNext` / `mkIEnumerator` — in-order enumerator with `InvalidOperationException` guards for not-started / already-finished, `Reset`, `Dispose`; `Current` yields `KeyValuePair<_,_>`.

### Debug/tracing
- Under `TRACE_SETS_AND_MAPS`, `report()` prints statistics every million operations (`numOnes`, `numNodes`, `numAdds`, `numRemoves`, `numUnions`, `numLookups`, average sizes, largest map and its stack trace).

## Type: Map<'Key,'Value>
`[<Sealed>] [<CompiledName("FSharpMap`2")>] [<DebuggerTypeProxy(MapDebugView)>] type Map<'Key,'Value when 'Key: comparison>(comparer: IComparer<'Key>, tree: MapTree<_,_>)`

- Storage: `comparer`, `tree` (mutable only during deserialization), `serializedData: KeyValuePair[]` for serialization round-trip.
- `OnSerializing` — snapshots the tree to array of `KeyValuePair`; `OnDeserialized` — rebuilds with `FastGenericComparer<'Key>` and clears serializedData.
- Static `empty` — per-instantiation static (one shared empty map per key/value instantiation), created with `FastGenericComparer`.
- `static Empty`, `static Create(ie)`, `new(elements: seq<_>)`, `static ofList`.
- `internal Comparer`, `internal Tree`.

### Members
- `Add`, `Change`, `IsEmpty`, `Item` (get = `MapTree.find`), `TryPick`, `Exists`, `Filter`, `ForAll`, `Fold` (= `foldBack`), `FoldSection`, `Iterate`, `MapRange` (value-only map), `Map` (key-and-value map), `Partition`, `Count` (= `MapTree.size`), `ContainsKey`, `Remove`, `TryGetValue (byref)`, `TryFind`, `ToList`, `ToArray`, `Keys` (KeyCollection), `Values` (ValueCollection), `MinKeyValue`, `MaxKeyValue`.

### Equality / hashing
- `ComputeHashCode` / `GetHashCode` — combine of `hash key` and `Unchecked.hash value` with `(x <<< 1) + y + 631`.
- `Equals` — enumerator walk comparing keys with structural `=` and values with `Unchecked.equals`.
- `IStructuralEquatable` — both methods use the supplied comparer.

### Interface surface
- `IEnumerable<KeyValuePair<_,_>>` and `IEnumerable` — via `MapTree.mkIEnumerator`.
- `IDictionary<_,_>` — read-only: `Item.set`, `Add`, `Remove` raise `NotSupportedException` (`mapCannotBeMutated`); getters delegate.
- `ICollection<KeyValuePair<_,_>>` — read-only (`IsReadOnly = true`), `CopyTo` via `MapTree.copyToArray`, `Contains` = key match with `Unchecked.equals` value.
- `IComparable` — `Seq.compareWith` over key pairs (comparer for keys, `Unchecked.compare` for values); `invalidArg` if not a Map.
- `IReadOnlyCollection<...>`, `IReadOnlyDictionary<...>` — count/item/keys/values/try-get delegation.
- `ToString` — prints first up-to-4 bindings as `map [k1; k2; k3; ... ]` (truncates with `...`).

## Helper types
- `MapDebugView<'Key,'Value>` — debug proxy showing up to 10000 items.
- `KeyValuePairDebugFriendly<'Key,'Value>` — debug display (`{keyValue.Key} = {keyValue.Value}`).
- `KeyCollection<'Key,'Value>` / `ValueCollection<'Key,'Value>` — read-only `ICollection` wrappers: Add/Clear/Remove raise `NotSupportedException`; Contains/CopyTo/count/enumeration delegate to the parent map.

## Module: Map
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Map` — simple delegation wrappers:
- `isEmpty`, `add`, `change`, `find`, `tryFind`, `remove`, `containsKey`, `iter`, `tryPick`, `pick` (KeyNotFound on None), `exists`, `filter`, `partition`, `forall`, `map`, `fold`, `foldBack`, `toSeq`, `findKey`, `tryFindKey`, `ofList`, `ofSeq`, `ofArray`, `toList`, `toArray`, `empty`, `count`, `keys`, `values`, `minKeyValue`, `maxKeyValue`.

## Key design notes
- Null representation of empty trees + the two-way cast between `MapTree` and `MapTreeNode` (`asNode`) make leaf handling uniform and cheap.
- `change` is the shared engine powering `Add` (u = always insert), `Remove` (u = always None), and `Map.Change` (user function).
- All traversals are recursive (in-order), which is fine for typical tree depths; the enumerator is iterative to avoid per-element stack growth.
- `Map` members are documented as thread-safe because the type is immutable (aside from serialization hooks).
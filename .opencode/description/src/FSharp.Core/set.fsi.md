# set.fsi

## Overview

Signature file (namespace `Microsoft.FSharp.Collections`) declaring the public API of the **immutable F# Set type** (`FSharpSet<'T>` for `'T: comparison`) built on balanced binary trees, plus the `Set` module. All members are documented with XML summaries/examples and complexity notes, and are thread-safe.

## `type Set<'T>` (`[<Sealed; CompiledName("FSharpSet`1")>]`), line 20

`'T : comparison`, `[<EqualityConditionalOn>]`. Under `NETSTANDARD2_1_OR_GREATER || NET` decorated with `[<CollectionBuilder(typeof<Set>, "Create")>]`.

- `new: elements: seq<'T> -> Set<'T>` — O(n log n).
- `Add: value -> Set<'T>` (O(log n)), `Remove: value -> Set<'T>` (O(log n)), `Count: int` (O(n)), `Contains: value -> bool` (O(log n)), `IsEmpty: bool` (O(1)).
- Operators `static (-)` (difference), `static (+)` (union).
- Membership tests: `IsSubsetOf`, `IsProperSubsetOf`, `IsSupersetOf`, `IsProperSupersetOf`.
- `MinimumElement: 'T`, `MaximumElement: 'T`.
- Interfaces: `ICollection<'T>`, `IEnumerable<'T>`, `System.Collections.IEnumerable`, `IComparable`, `System.Collections.IStructuralEquatable`, `IReadOnlyCollection<'T>`.

For `NETSTANDARD2_1_OR_GREATER || NET`, an additional `Set` static class (hidden, `[<CompilerMessage(..., 1204, IsHidden=true)>]`, `CompiledName("FSharpSet")`) exposes `static Create([<ScopedRef>] items: ReadOnlySpan<'T>) -> Set<'T>` for compiler/collection-expression use.

## `module Set` (`[<RequireQualifiedAccess>]` + `ModuleSuffix`), line 290

Public operations; each with a `[<CompiledName(...)>]` and docs:

- `empty<'T> : Set<'T>` (`[<GeneralizableValue>]`, `Empty`);
- `singleton` (`Singleton`), `add` (`Add`), `remove` (`Remove`);
- `contains` (`Contains`), `count` (`Count`), `isEmpty` (`IsEmpty`);
- `exists` (`Exists`), `forall` (`ForAll`), `filter` (`Filter`), `iter` (`Iterate`), `map` (`Map`);
- `fold`/`foldBack` (`Fold`/`FoldBack`, require `'T: comparison`), `partition` (`Partition`), `partitionWith` (`PartitionWith`, `'T -> Choice<'T1,'T2>`);
- `isSubset`/`isProperSubset`/`isSuperset`/`isProperSuperset`;
- `intersect` (`Intersect`), `intersectMany` (`IntersectMany`), `union` (`Union`), `unionMany` (`UnionMany`), `difference` (`Difference`);
- `minElement` (`MinElement`), `maxElement` (`MaxElement`);
- conversions: `ofList`/`toList`, `ofArray`/`toArray`, `ofSeq`/`toSeq`.

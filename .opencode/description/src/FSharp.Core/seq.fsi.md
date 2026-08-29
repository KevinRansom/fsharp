# seq.fsi

## Overview

Signature file (namespace `Microsoft.FSharp.Collections`) declaring the complete public API of the **`Seq` module** for `seq<'T>` (= `System.Collections.Generic.IEnumerable<'T>`). The `module Seq` is marked `[<RequireQualifiedAccess>]` and `[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`. Every `val` carries a `[<CompiledName(...)>]` attribute fixing the .NET method name and full XML documentation (summary, remarks on complexity, parameters, exceptions, and runnable `<code lang="fsharp">` examples). The signatures mirror the implementation in `seq.fs`.

## Complete member list (by compiled name)

- **Construction / creation**: `AllPairs`, `Append`, `Cache`, `Cast`, `ChunkBySize`, `Collect`, `Concat`, `Delay`, `Empty`, `Except`, `Initialize`, `InitializeInfinite`, `OfArray`, `OfList`, `ReadOnly`, `Replicate`, `Singleton`, `Transpose`, `Unfold`.
- **Iteration / scanning**: `Iterate` (iter), `IterateIndexed` (iteri), `Iterate2` (iter2), `IterateIndexed2` (iteri2), `Exists`, `Exists2`, `ForAll`, `ForAll2`, `Contains`.
- **Access / element lookup**: `Item` (element at index, throws), `TryItem`, `Get` (nth), `Head`, `TryHead`, `Tail`, `Last`, `TryLast`, `ExactlyOne`, `TryExactlyOne`, `IsEmpty`, `Length`.
- **Transforms**: `Filter` / `Where`, `Map`, `Map2`, `Map3`, `MapIndexed` (mapi), `MapIndexed2` (mapi2), `MapFold`, `MapFoldBack`, `Choose`, `Indexed`, `Pairwise`, `Scan`, `ScanBack`, `Windowed`, `SplitInto`, `Zip`, `Zip3`, `Permute`, `Reverse`.
- **Take / skip**: `Take`, `TakeWhile`, `Skip`, `SkipWhile`, `Truncate`.
- **Search**: `Find`, `FindBack`, `FindIndex`, `FindIndexBack`, `TryFind`, `TryFindBack`, `TryFindIndex`, `TryFindIndexBack`, `Pick`, `TryPick`.
- **Folding / reduction**: `Fold`, `Fold2`, `FoldBack`, `FoldBack2`, `Reduce`, `ReduceBack`, `Sum`, `SumBy`, `Average`, `AverageBy`, `Min`, `MinBy`, `Max`, `MaxBy` (SRTP `inline` signatures, e.g. `Average` requires `+`, `DivideByInt`, `Zero`).
- **Grouping / ordering**: `GroupBy`, `CountBy`, `Distinct`, `DistinctBy`, `Sort`, `SortWith`, `SortBy`, `SortDescending`, `SortByDescending`, `CompareWith`.
- **Conversions**: `ToArray`, `ToList`.
- **Positional editing** (bounds-checked lazy sequences): `RemoveAt`, `RemoveManyAt`, `UpdateAt`, `InsertAt`, `InsertManyAt`.
- **Randomization**: `RandomShuffle(With/By)`, `RandomChoice(With/By)`, `RandomChoices(With/By)`, `RandomSample(With/By)`.

The SRTP-heavy members (`Average`, `AverageBy`, `Sum`, `SumBy`, `Min`, `MinBy`, `Max`, `MaxBy`, `Contains`) carry explicit `when` constraints on generic operators in the signature.

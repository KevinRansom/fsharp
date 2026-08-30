# ImmutableArray.fsi

**Purpose**: Signature file for `ImmutableArray.fs` (same directory). Documents the public contract of the F# combinator layer over `System.Collections.Immutable.ImmutableArray<'T>`, which the compiler uses in place of the usual list/seq combinators where immutable, zero-allocation-per-element behavior matters.

**Namespace(s)** declared: module path `Internal.Utilities.Library.Block` (declared `[<AutoOpen>]` and `internal`).

**Declared items** (public contract):
- `[<RequireQualifiedAccess>] module ImmutableArrayBuilder` — `create : size -> ImmutableArray<'T>.Builder` (thin wrapper over `ImmutableArray.CreateBuilder`).
- `[<RequireQualifiedAccess>] module ImmutableArray` — the full combinator set:
  - `empty<'T> : ImmutableArray<'T>` (`[<GeneralizableValue>]`)
  - `init : n * (int -> 'T) -> ImmutableArray<'T>`
  - `iter`, `iteri`
  - `iter2`, `iteri2`
  - `map`, `mapi`
  - `concat : ImmutableArray<ImmutableArray<'T>> -> ImmutableArray<'T>`
  - `forall`, `forall2`
  - `tryFind`, `tryFindIndex`, `tryPick`
  - `ofSeq : 'T seq -> ImmutableArray<'T>`
  - `append`, `createOne`
  - `filter`
  - `exists`
  - `choose`
  - `isEmpty`
  - `fold : ('State -> 'T -> 'State) * 'State * ImmutableArray<'T> -> 'State`

**Relationship to .fs**: The .fs provides the implementations using `ImmutableArray`'s builder API and `OptimizedClosures.FSharpFunc.Adapt` for fast closures; the .fsi is the compile-time contract. Notable difference: the .fsi declares the top-level module `[<AutoOpen>]` and `internal`, while the .fs declares just the bare module path `Internal.Utilities.Library.Block`. No other public types are declared in either file.

**Cross-references**: see sibling `ImmutableArray.md`.

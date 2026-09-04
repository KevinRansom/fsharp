# collections.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Public API signature for the identity/comparison helper modules (implementations in `collections.fs`).

## Namespaces
- `Microsoft.FSharp.Collections`

## Module: ComparisonIdentity
"Common notions of value ordering" implementing `IComparer<'T>` for sorted structures.

- `Structural<'T> : IComparer<'T> when 'T: comparison` — structural `Operators.compare` semantics.
- `NonStructural< ^T> : IComparer< ^T> when ^T: (static member (<)) and ^T: (static member (>))` — uses `NonStructuralComparison.Compare` and the type's own operators.
- `FromFunction: comparer: ('T -> 'T -> int) -> IComparer<'T>` — comparer driven by a user function.

## Module: HashIdentity
"Common notions of value identity" implementing `IEqualityComparer<'T>` for `Dictionary` and other collections.

- `Structural<'T> : IEqualityComparer<'T> when 'T: equality` — structural `(=)` and `hash`.
- `NonStructural<'T> : IEqualityComparer< ^T > when ^T: equality and ^T: (static member (=):...)` — user-defined `op_Equality`/hashing via `NonStructuralComparison`.
- `LimitedStructural<'T> : limit: int -> IEqualityComparer<'T> when 'T: equality` — structural with a cap on hashing operations (useful for tree keys).
- `Reference<'T> : IEqualityComparer<'T> when 'T: not struct` — physical/reference identity via `LanguagePrimitives.PhysicalEquality` / `PhysicalHash`.
- `FromFunctions<'T> : hasher: ('T -> int) -> equality: ('T -> 'T -> bool) -> IEqualityComparer<'T>` — user-supplied hasher/equality.

## Notable documentation behavior
- Each member documents the underlying `Microsoft.FSharp.Core.Operators.*` or `NonStructuralComparison.*` machinery it delegates to.
- Examples illustrate how arrays compare (structurally) vs by reference in dictionaries.
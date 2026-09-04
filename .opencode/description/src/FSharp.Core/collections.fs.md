# collections.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler; provides the default identity/comparison semantics used when constructing F# collections like `Set`, `Map` and the set/map internals.

## Namespaces
- `Microsoft.FSharp.Collections`

## Module: HashIdentity
Provides `IEqualityComparer<'T>` objects for dictionaries and hash-based collections.

- `Structural<'T : equality>` — inline; returns `LanguagePrimitives.FastGenericEqualityComparer<'T>`, giving structural equality and structural hashing.
- `LimitedStructural<'T : equality> limit` — inline; returns `LanguagePrimitives.FastLimitedGenericEqualityComparer<'T>(limit)`, capping the number of hashing/equality operations (used for tree-shaped keys).
- `Reference<'T : not struct>` — `IEqualityComparer<'T>` based on physical identity: `GetHashCode` = `PhysicalHash`, `Equals` = `PhysicalEquality`.
- `NonStructural<'T : equality and (static member (=):...) >` — inline; equality/hashing via `NonStructuralComparison.hash` and `NonStructuralComparison.(=)`, respecting user-supplied `op_Equality` (e.g. `System.DateTime`).
- `FromFunctions hasher equality` — adapter wrapping user functions; the equality function is adapted with `OptimizedClosures.FSharpFunc<_,_,_>` for fast uncurried invocation.

## Module: ComparisonIdentity
Provides `IComparer<'T>` objects for ordered collections (e.g. `FSharpSet`, `FSharpMap`).

- `Structural<'T : comparison>` — inline; returns `LanguagePrimitives.FastGenericComparer<'T>`, i.e. structural `compare`.
- `NonStructural< ^T : (static member (<)) and (static member (>))>` — inline; `Compare` = `NonStructuralComparison.compare`, honouring user-overloaded comparison operators.
- `FromFunction comparer` — wraps a user comparison function; adapted via `FSharpFunc<'T,'T,int>` for fast invocation.

## Key design notes
- All comparers/equality comparers are structurally correct for F# immutable types (tuples, records, unions, options) and containers.
- `NonStructural` variants are for types with custom operator overloads.
- This is the identity layer on which `Set`/`Map` modules build via `FSharpSet`/`FSharpMap` constructors taking `IComparer<'T>`.
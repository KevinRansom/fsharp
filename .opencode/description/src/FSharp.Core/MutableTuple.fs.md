# MutableTuple.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Defines the `AnonymousObject` family of internal types used when translating F# LINQ queries that carry F# tuples/records: during query translation the compiler replaces tuples/records with these anonymous, immutable, tuple-like objects that LINQ providers (LINQ to SQL/Entities) handle correctly.

## Namespaces
- `Microsoft.FSharp.Linq.RuntimeHelpers`

## Notes on terminology
- Despite the filename and the original "mutable tuple" phrasing, these types are *immutable* "anonymous tuple-like types". The correspondence between constructor arguments and properties is fed to the `Expression.New` "members" argument in `Linq.fs`. The same (now-misleading) terminology runs through `Query.fs`.

## Types: AnonymousObject<'T1 ... 'TN>
Eight sealed generic variants, arities 1 through 8 (`AnonymousObject<'T1>`, `'T1,'T2`, ... , `'T1,...'T8>`), each:

- Constructor takes one `Item<i>` argument per type parameter.
- Read-only property `Item1`...`ItemN` exposing each stored value.
- Override `Equals(obj)` — pattern-matches the other object to the same `AnonymousObject` arity and compares each `Item` field-wise with `EqualityComparer<_>.Default`; returns `false` for non-matching types.
- Override `GetHashCode()` — combines the per-field `EqualityComparer<_>.Default` hash codes using the F#-style combine `((h <<< 5) + h) ^^^ next`, accumulating through all items.

## Key design notes
- All types are `[<Sealed>]` and documented as `[<exclude>]` ("shouldn't be used directly from user code").
- Equality/hashing is field-wise over the class's own equality semantics for each element type, mirroring the structural equality of the tuple/record they stand in for.
- Arity 2 uses the two-element combine inline; arity 1 hash is just the single item's hash.
- These objects plus `Expression.New` wiring in `Linq.fs` and `Query.fs` allow F# query expressions to interoperate with LINQ providers that require anonymous-type shape.
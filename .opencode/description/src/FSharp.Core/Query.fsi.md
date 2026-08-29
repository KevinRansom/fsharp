# Query.fsi

## Overview

This is the signature (interface) file for `Query.fs`, in namespace `Microsoft.FSharp.Linq`. It declares the public surface for F# query expressions: the `QuerySource` type, the `QueryBuilder` with all its query operators (each decorated with `[<CustomOperation(...)>]` attributes that drive the F# query syntax), and the `QueryRunExtensions` modules for `Run` overload resolution. It carries substantial XML documentation.

## `QuerySource<'T, 'Q>`

- `[<NoComparison; NoEquality; Sealed>]` type with:
  - `new: seq<'T> -> QuerySource<'T,'Q>`.
  - `member Source: seq<'T>` (the underlying sequence).
- Doc text: "A partial input or result in an F# query. This type is used to support the F# query syntax."

## `QueryBuilder`

`[<Class>]` type, `new: unit -> QueryBuilder`, used as `query { ... }`.

**CE-support members** (documented as "used to support the F# query syntax"):
- `Source: source:IQueryable<'T> -> QuerySource<'T,'Q>` and `Source: source:IEnumerable<'T> -> QuerySource<'T,IEnumerable>` (overloads implicitly wrap query inputs).
- `For: source * body -> QuerySource<'Result,'Q>` (project each element to a sequence and combine).
- `Zero: unit -> QuerySource<'T,'Q>` (empty sequence).
- `Yield: value:'T -> QuerySource<'T,'Q>` (singleton sequence).
- `YieldFrom: computation -> QuerySource<'T,'Q>`.
- `Quote: Quotations.Expr<'T> -> Quotations.Expr<'T>` (marks the query as a quotation passed to Run).
- `Run: Quotations.Expr<QuerySource<'T,IQueryable>> -> IQueryable<'T>` — runs the quotation as a query using LINQ `IQueryable` rules; internal `RunQueryAsQueryable`, `RunQueryAsEnumerable`, `RunQueryAsValue` variants.

**Query operators** (each is a `[<CustomOperation("name", ...)]` member; selectors are `[<ProjectionParameter>]`):
- Terminal / value results: `contains`, `count`, `last`, `lastOrDefault`, `exactlyOne`, `exactlyOneOrDefault`, `headOrDefault`, `head`, `nth`, `exists`, `find`, `all`, `minBy`, `maxBy`, `sumBy`, `averageBy`, plus nullable aggregates `minByNullable`, `maxByNullable`, `sumByNullable`, `averageByNullable` (ignoring null values).
- Sequence-shaping: `select` (AllowIntoPattern), `where` (MaintainsVariableSpace + AllowIntoPattern), `distinct`, `skip`, `skipWhile`, `take`, `takeWhile`.
- Grouping/sorting/joining: `groupBy`, `groupValBy`, `sortBy`/`sortByDescending`, `thenBy`/`thenByDescending` (only after a sort), `sortByNullable`/`sortByNullableDescending`, `thenByNullable`/`thenByNullableDescending`, `join`, `groupJoin`, `leftOuterJoin` (with `IsLikeJoin`/`IsLikeGroupJoin` and `JoinConditionWord = "on"`). A `zip` operator exists only under the `#if SUPPORT_ZIP_IN_QUERIES` compilation flag.

Aggregate value operators use statically-resolved type parameters (e.g. `^Value` with `static member (+)`, `Zero`, `DivideByInt` and `default` type hints) for `sumBy`/`averageBy`.

## `namespace Microsoft.FSharp.Linq.QueryRunExtensions`

Two `[<AutoOpen>]` modules providing extension `Run` members on `QueryBuilder` so that the correct runner is selected by overload resolution:
- `module LowPriority` — `member Run: Expr<'T> -> 'T` (compiled name `RunQueryAsValue`); runs any value-typed query.
- `module HighPriority` — `member Run: Expr<QuerySource<'T, IEnumerable>> -> seq<'T>` (compiled name `RunQueryAsEnumerable`); runs enumerable-typed queries.

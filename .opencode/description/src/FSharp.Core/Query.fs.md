# Query.fs

## Overview

This file (primarily namespace `Microsoft.FSharp.Linq`) implements F#'s **query expression** support: the `QuerySource` type, the `QueryBuilder` (computational-expression builder used by `query { ... }`), the extension modules that select `Run` overloads, and the internal `Query` module that translates F# quotation-based query expressions into LINQ `Queryable`/`Enumerable` calls (and eventually into a runnable result). It demonstrates heavy use of quotation manipulation and reflection.

## `QuerySource<'T, 'Q>` and `Helpers`

- `type QuerySource<'T, 'Q> (source: seq<'T>)` — a `[<NoComparison; NoEquality; Sealed>]` wrapper around an underlying `seq<'T>`, with member `Source`. `'Q` is a "tag" type parameter distinguishing an `IEnumerable`-backed source from an `IQueryable`-backed one (only used at the type level).
- `module Helpers` (AutoOpen) — small helpers: `plus` (checked `(+)`), `checkNonNull`, and `checkThenBySource` (requires the input to be an `IOrderedEnumerable` so `thenBy` is only usable after a sort).

## Builder plumbing: `ForwardDeclarations`

`module ForwardDeclarations` declares an interface `IQueryMethods` with `Execute: Expr<'T> -> 'U` and `EliminateNestedQueries: Expr -> Expr`, and a mutable global `Query` value. This forward-declaration lets `QueryBuilder` reference the translation functions (via `methodhandleof`) before the `Query` module defines them later in the file; at the bottom of the file the real implementation is installed.

## `type QueryBuilder()`

The computational-expression builder. Methods fall into two groups:

**CE plumbing** (used by the desugaring of `query { ... }`):
- `For`, `Zero`, `Yield`, `YieldFrom`, and `Quote` (marks the body as a quotation `Expr<'T> -> Expr<'T>`).
- `Source` overloads: for `IQueryable<'T>` (produces `QuerySource<'T,'Q>` with queryable tag) and for `IEnumerable<'T>` (produces `QuerySource<'T, IEnumerable>`).
- `RunQueryAsValue`, `RunQueryAsEnumerable` (calls `Adapters.CleanupLeaf` + `LeafExpressionConverter.EvaluateQuotation`), `RunQueryAsQueryable`, and `Run` (= `RunQueryAsQueryable`).

**Query operators** (each a custom operation used inside query expressions). Most are thin wrappers over `Enumerable.*`; those that must translate selectors to LINQ delegate/expression trees are implemented inline in `Query`:

- Equality/ordering/membership: `Contains`, `Last`, `LastOrDefault`, `ExactlyOne`, `ExactlyOneOrDefault`, `Count`, `Distinct`, `Exists`, `All`, `Head`, `HeadOrDefault`, `Nth`, `Find`.
- Sequence shaping: `Select`, `Where`, `Skip`, `SkipWhile`, `Take`, `TakeWhile`.
- Aggregates: `MinBy`, `MaxBy`, `MinByNullable`, `MaxByNullable`, `SumByNullable`, `AverageByNullable` (these iterate with `LanguagePrimitives.GenericZero`, `plus`, `DivideByInt`, skipping nullables), `SumBy`, `AverageBy`.
- Grouping/sorting/joining: `GroupBy`, `SortBy`, `SortByDescending`, `ThenBy`, `ThenByDescending`, `SortByNullable`, `SortByNullableDescending`, `ThenByNullable`, `ThenByNullableDescending`, `GroupValBy`, `Join`, `GroupJoin`, `LeftOuterJoin` (uses `GroupJoin` + `DefaultIfEmpty`).

## Query run extensions

`namespace Microsoft.FSharp.Linq.QueryRunExtensions` provides two `[<AutoOpen>]` modules defining extension `Run` members on `QueryBuilder`, so overload resolution picks the right runner by the query's target type:
- `LowPriority.Run (q: Expr<'T>) = RunQueryAsValue` (compiled name `RunQueryAsValue`).
- `HighPriority.Run (q: Expr<QuerySource<'T, IEnumerable>>) = RunQueryAsEnumerable`.

## `module Query` (`[<CompilationRepresentation(ModuleSuffix)>]`)

The quotation-to-LINQ translation engine (internal). Key ideas:

- **Quotation pattern helpers** to match builder calls: `SpecificCall1/2/3` (match `f x`, `f x y`, `f x y z`), `LambdaNoDetupling`/`LambdasNoDetupling` (reverse the compiler's tuple-parameter encoding of `fun (x,y) -> ...`), `(|Getter|_|)`, `(|GenericArgs|)`, `MacroReduction`, `LetExprReduction`. Concrete `(|CallSortBy|_|)`, `(|CallWhere|_|)`, `(|CallJoin|_|)`, `(|CallMinBy|_|)`, `(|CallAverageBy|_|)`, etc., recognize each `QueryBuilder` operator call in a quotation.
- **"Make" vs "Call" functions**: for each LINQ operator the module defines a `MakeXxx` (build an `Expr` for the queryable/enumerable translation, `isIQ` selecting `Queryable.*` vs `Enumerable.*`) and a `CallXxx` (invoke the same translation dynamically at runtime). These are constructed once from `methodhandleof`-captured generic method definitions and `CallGenericStaticMethod`/`MakeGenericStaticMethod` (plus instance variants) so they can be bound to arbitrary type arguments. Helpers like `MakeOrCallContainsOrElementAt`, `MakeOrCallMinByOrMaxBy`, `MakeOrCallAnyOrAllOrFirstFind`, `MakeOrCallAverageByOrSumByGeneric`, and `MakeOrCallSimpleOp` factor the common shape.
- **Type/selector helpers**: `MakeQueryFuncTy`/`MakeQueryFunc2Ty`, `FuncExprToDelegateExpr`/`FuncExprToLinqFunc2[Expression]` (convert F# function quotation bodies to `System.Func` / `Expression<Func<...>>`), `MakeImplicitExpressionConversion` (wraps delegates for provider compatibility), `ConvVar`, `asExpr`. Type-test utilities `IsQuerySourceTy`, `IsIQueryableTy`, `IsIEnumerableTy`, `qTyIsIQueryable` (the `IEnumerable` tag is treated as enumerable; any other tag as queryable).
- **`MakeSelect`** — builds a select, eliminating degenerate `select (fun x -> x)` nodes except at the outermost level (`CanEliminate.Yes/No`).
- **`RewriteExpr` / `MacroExpand` / `EliminateNestedQueries`** — recursively expand `let`s and reflected-definition "macro" calls that LINQ cannot handle, and flatten nested query sources.
- **`EvalNonNestedInner` / `EvalNonNestedOuter`** — evaluate the outer (non-nested) operators of a query by translating each recognized `CallXxx` into either a LINQ expression tree or a dynamic invocation, and ultimately **`QueryExecute`** evaluates the resulting quotation. Finally, at module load it installs the real implementations into `ForwardDeclarations.Query` (`Execute = QueryExecute`, `EliminateNestedQueries`), closing the forward-declaration loop.

In short, `Query.fs` turns the high-level F# `query { ... }` syntax (captured as a quotation) into equivalent LINQ `Queryable`/`Enumerable` operations, running them either lazily as `IQueryable` or eagerly as sequences/values.

# QueryExtensions.fs

## Overview

This file (namespace `Microsoft.FSharp.Linq.RuntimeHelpers`) provides **runtime helpers for translating F# query expressions into LINQ**. Its central task is adapting queries that `yield`/`select` **immutable** F# values (records and immutable tuples) into the **mutable/`IQueryable`-compatible** "anonymous object" shapes that LINQ providers can consume, and vice versa. It contains the `Grouping` type and the internal `Adapters` module.

## `type Grouping<'K, 'T>(key, values)`

A simple `IGrouping<'K, 'T>` implementation used to "reconstruct a grouping after applying a mutable→immutable mapping transformation on a result of a query". It implements `IGrouping<'K,'T>` (with `Key`), and both `System.Collections.IEnumerable` and `Generic.IEnumerable<'T>` (delegating `GetEnumerator` to `values`).

## `module internal Adapters`

Core translation helpers:

- `memoize` — memoizes a `Type -> 'b` function using a `ConcurrentDictionary<Type, 'b>` (structural key identity).
- `isPartiallyImmutableRecord` — memoized predicate: true for record types where **not all** fields are writable (immutable records, for which LINQ `MemberInit` can't work directly).
- `MemberInitializationHelperMeth` and `NewAnonymousObjectHelperMeth` — captured `MethodInfo` handles for `LeafExpressionConverter.MemberInitializationHelper` and `NewAnonymousObjectHelper` (used to wrap object/anonymous constructions so the quotation-to-LINQ converter can translate them).

**Quotation pattern recognizers:**

- `(|LeftSequentialSeries|)` — flattens nested `Sequential` expressions into a list.
- `(|PropSetList|_|)` — matches a list of `PropertySet` assignments on a given variable (plus unit/null literals), ending by returning that variable.
- `(|ObjectConstruction|_|)` — matches the `let v = new O() in v.Prop1 <- e; ...; v` shape of F# object-construction expressions.
- `(|NewAnonymousObject|_|)` — matches `new AnonymousObject<...>(<e1>, ...)` constructions.
- `(|RecordFieldGetSimplification|_|)` — simplifies `PropGet(NewRecord(...), field)` back to the direct field expression.

**Anonymous-object / tuple mapping:**

- `tupleTypes` — maps .NET tuple types (`System.Tuple<_>` and F# tuples of arity 2–8) to the corresponding `AnonymousObject<...>` types; `anonObjectTypes`, `tupleToAnonTypeMap`, `anonToTupleTypeMap` derived maps.
- `OneNewAnonymousObject` — builds a single `AnonymousObject<...>` `Expr` for ≤8 arguments; `NewAnonymousObject` (recursive) nests tuples for more than 7 arguments.
- `AnonymousObjectGet` — builds a nested property-get chain (`.Item1`..`.Item7`) to extract the `i`-th anonymous object element.
- `RewriteTupleType` — rewrites a tuple type into its anonymous-object equivalent, recursively transforming type arguments via a `conv` function.

**Conversion description (`ConversionDescription`) and type rewriting:**

- A discriminated union `ConversionDescription` records how immutable productions became mutable ones so the process can be inverted: `TupleConv`, `RecordConv`, `GroupingConv`, `SeqConv`, `NoConv`.
- `ConvImmutableTypeToMutableType` — given a conversion description and a type involving immutable tuples/records, produces the equivalent anonymous-object/`IGrouping`/`seq`/`IQueryable` type (records first flatten to tuples via `FSharpType.MakeTupleType`; keeps `IGrouping<_,_>` and preserves `seq` vs `IQueryable` element types).

**Expression rewriting:**

- `IsNewAnonymousObjectHelperQ` — tests whether an expression is a call to `LeafExpressionConverter.NewAnonymousObjectHelper`.
- `CleanupLeaf` — rewrites leaf expressions bottom-up, wrapping object constructions in `MemberInitializationHelper` (so they become `Expression.MemberInit`) and anonymous constructions in `NewAnonymousObjectHelper` (so they become `Expression.New` with member arguments); skips already-wrapped node.
- `SimplifyConsumingExpr` — bottom-up simplification of consumers: replaces `TupleGet(NewTuple els, i)` with `els.[i]` and record-field gets over `NewRecord` with the direct field (`RecordFieldGetSimplification`).
- `ProduceMoreMutables` — given the expression part of a `yield`/`select`, replaces immutable tuple/record constructions with equivalent anonymous-object expressions, returning the expression plus its `ConversionDescription` (`TupleConv`/`RecordConv`).
- `MakeSeqConv` — wraps a non-`NoConv` conversion as `SeqConv`. (The file's header indicates the analogous `GroupingConv`/consuming of mapped results are used where `CleanupLeaf` and the sequence/grouping conversions are applied by the query translator in `Query.fs`.)

In sum, `QueryExtensions.fs` is the "structuring" half of F#-query-to-LINQ translation: it makes immutable F# values consumable by LINQ by converting them to mutable anonymous-object shapes and records how to convert back.

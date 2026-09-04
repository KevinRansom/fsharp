# option.fs

## Overview

This file implements the `Option` and `ValueOption` modules (namespace `Microsoft.FSharp.Core`). `Option` is `[<ModuleSuffix>]`; `ValueOption` is the analogous module for the `voption<'T>` (struct option) type. All functions are `inline` and generally pattern-match directly on the option representation (`None`/`Some`, or `ValueNone`/`ValueSome`). Most higher-order functions mark their function arguments with `[<InlineIfLambda>]` for inlining.

## Module `Option`

Functions on `'T option` (with their `[<CompiledName>]`):

- `get` (`GetValue`) — returns the value or raises `ArgumentException` (`SR.optionValueWasNone`) for `None`.
- `isSome` (`IsSome`), `isNone` (`IsNone`) — boolean tests.
- `defaultValue value option` (`DefaultValue`) — returns the value or the supplied default for `None`.
- `defaultWith defThunk option` (`DefaultWith`) — lazy default; only evaluates the thunk on `None`.
- `orElse ifNone option` (`OrElse`) — returns `option` if `Some`, else the alternate `ifNone`.
- `orElseWith ifNoneThunk option` (`OrElseWith`) — lazy alternate option.
- `count` (`Count`) — `0` for `None`, `1` for `Some`.
- `fold folder state option` (`Fold`) — `None -> state | Some x -> folder state x`.
- `foldBack folder option state` (`FoldBack`) — `None -> state | Some x -> folder x state`.
- `exists`, `forall`, `contains`, `iter` — predicate/action combinators.
- `map` (`Map`), `map2` (`Map2`), `map3` (`Map3`) — transform one/two/three options, returning `None` if any is `None`.
- `bind` (`Bind`) — monadic bind; `None -> None | Some x -> binder x`.
- `flatten` (`Flatten`) — `'T option option -> 'T option` (equivalent to `bind id`).
- `filter` (`Filter`) — keeps the value only if the predicate holds.
- `toArray` (`ToArray`), `toList` (`ToList`) — length 0 or 1 collection.
- `toNullable` (`ToNullable`), `ofNullable` (`OfNullable`) — conversions with `System.Nullable`.
- `ofObj` (`OfObj`) — `'T | null -> 'T option` when `'T : not struct and 'T : not null`; also carries `[<WarnOnWithoutNullArgument>]`.
- `toObj` (`ToObj`) — `'T option -> 'T | null` when `'T : not struct`.
- `ofValueOption` (`OfValueOption`), `toValueOption` (`ToValueOption`) — conversions with `voption`.

## Module `ValueOption`

Mirrors `Option` for `'T voption`, using `ValueNone`/`ValueSome`. It provides the analogous functions: `get`, `isSome`, `isNone`, `defaultValue`, `defaultWith` (deliberately **not** using `InlineIfLambda`, as benchmarked slightly slower), `orElse`, `orElseWith`, `count`, `fold`, `foldBack`, `exists`, `forall`, `contains`, `iter`, `map`, `map2`, `map3`, `bind`, `flatten`, `filter`, `toArray`, `toList`, `toNullable`, `ofNullable`, `ofObj`, `toObj`.

Additionally it has the cross-conversion functions:
- `ofOption` (`OfOption`) — `'T option -> 'T voption`.
- `toOption` (`ToOption`) — `'T voption -> 'T option`.

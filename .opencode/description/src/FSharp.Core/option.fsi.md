# option.fsi

## Overview

This is the public API signature for the `Option` and `ValueOption` modules (namespace `Microsoft.FSharp.Core`, category "Options"). `Option` is `[<ModuleSuffix>]`; `ValueOption` is not. All bindings are `inline` with `[<CompiledName>]` and are documented with XML remarks and examples.

## Module `Option`

Exposed API on `'T option`:

- `isSome : option: 'T option -> bool` (`IsSome`)
- `isNone : option: 'T option -> bool` (`IsNone`)
- `defaultValue : value: 'T -> option: 'T option -> 'T` (`DefaultValue`) — identical to `defaultArg` with swapped args.
- `defaultWith : defThunk: (unit -> 'T) -> option: 'T option -> 'T` (`DefaultWith`)
- `orElse : ifNone: 'T option -> option: 'T option -> 'T option` (`OrElse`)
- `orElseWith : ifNoneThunk: (unit -> 'T option) -> option: 'T option -> 'T option` (`OrElseWith`)
- `get : option: 'T option -> 'T` (`GetValue`) — throws `ArgumentException` on `None`.
- `count : option: 'T option -> int` (`Count`)
- `fold<'T,'State> : folder: ('State -> 'T -> 'State) -> state: 'State -> option: 'T option -> 'State` (`Fold`)
- `foldBack<'T,'State> : folder: ('T -> 'State -> 'State) -> option: 'T option -> state: 'State -> 'State` (`FoldBack`)
- `exists : predicate: ('T -> bool) -> option: 'T option -> bool` (`Exists`)
- `forall : predicate: ('T -> bool) -> option: 'T option -> bool` (`ForAll`)
- `contains : value: 'T -> option: 'T option -> bool when 'T: equality` (`Contains`)
- `iter : action: ('T -> unit) -> option: 'T option -> unit` (`Iterate`)
- `map : mapping: ('T -> 'U) -> option: 'T option -> 'U option` (`Map`)
- `map2 : mapping: ('T1 -> 'T2 -> 'U) -> option1 -> option2 -> 'U option` (`Map2`)
- `map3 : mapping: (3 args) -> option1/2/3 -> 'U option` (`Map3`)
- `bind : binder: ('T -> 'U option) -> option: 'T option -> 'U option` (`Bind`)
- `flatten : option: 'T option option -> 'T option` (`Flatten`)
- `filter : predicate: ('T -> bool) -> option: 'T option -> 'T option` (`Filter`)
- `toArray : option: 'T option -> 'T array` (`ToArray`)
- `toList : option: 'T option -> 'T list` (`ToList`)
- `toNullable : option: 'T option -> Nullable<'T>` (`ToNullable`)
- `ofNullable : value: Nullable<'T> -> 'T option` (`OfNullable`)
- `ofObj : value: 'T | null -> 'T option when 'T: not null and 'T: not struct` (`OfObj`, with `[<WarnOnWithoutNullArgument>]`)
- `toObj : value: 'T option -> 'T | null when 'T: not struct` (`ToObj`)
- `ofValueOption : voption: 'T voption -> 'T option` (`OfValueOption`)
- `toValueOption : option: 'T option -> 'T voption` (`ToValueOption`)

## Module `ValueOption`

The analogue for `'T voption`, exposing the same functions adapted for `ValueNone`/`ValueSome`, plus:

- `ofOption : option: 'T option -> 'T voption` (`OfOption`)
- `toOption : voption: 'T voption -> 'T option` (`ToOption`)

The full set: `isSome`, `isNone`, `defaultValue`, `defaultWith`, `orElse`, `orElseWith`, `get`, `count`, `fold`, `foldBack`, `exists`, `forall`, `contains`, `iter`, `map`, `map2`, `map3`, `bind`, `flatten`, `filter`, `toArray`, `toList`, `toNullable`, `ofNullable`, `ofObj`, `toObj`.

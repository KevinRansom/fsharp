# string.fsi

## Overview

Signature file (namespace `Microsoft.FSharp.Core`) declaring the public **`String` module** — "Functional programming operators for string processing" (documentation category: **Strings and Text**). `[<RequireQualifiedAccess>]` with `ModuleSuffix`; each `val` has a `[<CompiledName(...)>]` and full XML documentation with runnable examples.

## Values / signatures

- `length: str: string -> int` (`Length`) — 0 for null.
- `concat: sep: string -> strings: seq<string> -> string` (`Concat`) — joins with separator; throws `ArgumentNullException` if `strings` is null.
- `iter: action: (char -> unit) -> str: string -> unit` (`Iterate`).
- `iteri: action: (int -> char -> unit) -> str: string -> unit` (`IterateIndexed`).
- `map: mapping: (char -> char) -> str: string -> string` (`Map`).
- `mapi: mapping: (int -> char -> char) -> str: string -> string` (`MapIndexed`).
- `filter: predicate: (char -> bool) -> str: string -> string` (`Filter`) — empty string if input is null.
- `collect: mapping: (char -> string) -> str: string -> string` (`Collect`) — map each char to a string and concatenate.
- `init: count: int -> initializer: (int -> string) -> string` (`Initialize`) — throws `ArgumentException` if `count` < 0.
- `replicate: count: int -> str: string -> string` (`Replicate`) — throws `ArgumentException` if `count` < 0.
- `forall: predicate: (char -> bool) -> str: string -> bool` (`ForAll`).
- `exists: predicate: (char -> bool) -> str: string -> bool` (`Exists`).

# string.fs

## Overview

This file (namespace `Microsoft.FSharp.Core`) implements the **`String` module** — the standard set of operations on .NET `System.String`. The module is `[<RequireQualifiedAccess>]` with `ModuleSuffix`. It uses `Microsoft.FSharp.Primitives.Basics.Array.zeroCreateUnchecked` in places to avoid a dependency on `array.fs` (which is not yet in scope at this point in the build). Each function has a `[<CompiledName(...)>]`.

A notable constant is defined:

- `[<Literal>] LOH_CHAR_THRESHOLD = 40_000` — the Large Object Heap threshold in chars (LOH size threshold bytes (80_000) / `sizeof<char>`), used to decide whether to avoid large allocations.

## Functions

- `length str` (`Length`) — `0` if null, else `str.Length`.
- `concat sep (strings: seq<string>)` (`Concat`) — joins; fast paths for `string array` and `string list` (using `String.Join(sep, arr, 0, arr.Length)`), falling back to `String.Join(sep, strings)`.
- `iter action str` (`Iterate`) — applies `action` to each `char` (skips `null`/empty).
- `iteri action str` (`IterateIndexed`) — indexed variant via `OptimizedClosures.FSharpFunc.Adapt`.
- `map mapping str` (`Map`) — transforms each char in place in a char array, returns new `String`.
- `mapi mapping str` (`MapIndexed`) — indexed map.
- `filter predicate str` (`Filter`) — keeps matching chars. For long strings (`len > LOH_CHAR_THRESHOLD`) it uses a `StringBuilder` (avoiding LOH allocations / "stop the world" collections); otherwise builds a `char` array and returns a substring view via `String(target, 0, i)`.
- `collect mapping str` (`Collect`) — concatenates `mapping c` for each char using a `StringBuilder` seeded with the input length.
- `init count initializer` (`Initialize`) — builds a string of `count` segments from `initializer : int -> string` (validates count non-negative).
- `replicate count str` (`Replicate`) — repeats a string; special cases: empty/zero → empty; length-1 → `String(ch, count)`; count≤4 → `String.Concat`; otherwise an O(log n) doubling copy into a `char` array.
- `forall predicate str` (`ForAll`) — true if all chars satisfy the predicate (true for null/empty).
- `exists predicate str` (`Exists`) — true if any char satisfies the predicate (false for null/empty).

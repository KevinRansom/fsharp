# result.fs

## Overview

This file (namespace `Microsoft.FSharp.Core`) implements the **`Result` module** — the standard set of operations for the `Result<'T, 'Error>` two-case discriminated union (`Ok`/`Error`). All functions are `inline` with `[<InlineIfLambda>]` on the higher-order function arguments so call sites can be optimized during compilation (inlining the lambda at the use site).

The module is annotated with `[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`, so in compiled assembly it appears as `ResultModule`, and each function carries a `[<CompiledName(...)>]` attribute giving the .NET-facing method name (e.g. `Map`, `Bind`).

## Functions

- `map` (`Map`) — `(Ok x) -> Ok (mapping x)`; `Error` passes through unchanged.
- `mapError` (`MapError`) — `(Error e) -> Error (mapping e)`; `Ok` passes through.
- `bind` (`Bind`) — `(Ok x) -> binder x`; `Error` passes through.
- `isOk` (`IsOk`) / `isError` (`IsError`) — boolean tests on the union case.
- `defaultValue value result` (`DefaultValue`) — the contained value on `Ok`, otherwise `value`.
- `defaultWith defThunk result` (`DefaultWith`) — the contained value on `Ok`, otherwise `defThunk error`.
- `count result` (`Count`) — `0` for `Error`, `1` for `Ok`.
- `fold folder state result` (`Fold`) — `(Ok x) -> folder state x`; `state` passes through on `Error`.
- `foldBack folder result state` (`FoldBack`) — `(Ok x) -> folder x state`; `state` passes through on `Error`.
- `exists predicate result` (`Exists`) — `(Ok x) -> predicate x`; `false` on `Error`.
- `forall predicate result` (`ForAll`) — `(Ok x) -> predicate x`; `true` on `Error`.
- `contains value result` (`Contains`) — whether the `Ok` value equals `value` (equality via `=`); `false` on `Error`.
- `iter action result` (`Iterate`) — `(Ok x) -> action x`; `()` on `Error`.
- `toArray result` (`ToArray`) — `[| x |]` on `Ok`, empty array on `Error`.
- `toList result` (`ToList`) — `[x]` on `Ok`, empty list on `Error`.
- `toOption result` (`ToOption`) — `Some x` on `Ok`, `None` on `Error`.
- `toValueOption result` (`ToValueOption`) — `ValueSome x` on `Ok`, `ValueNone` on `Error`.

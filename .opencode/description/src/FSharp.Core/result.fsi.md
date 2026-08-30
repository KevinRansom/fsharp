# result.fsi

## Overview

Signature file (namespace `Microsoft.FSharp.Core`) declaring the public **`Result` module** ("Choices and Results" documentation category). It documents the exact types and behavior of every operation on `Result<'T, 'TError>` (the `Ok`/`Error` two-case union). `open Microsoft.FSharp.Collections` brings in `'T array`, `'T list`, etc. Each value carries a `[<CompiledName(...)>]` attribute fixing the .NET method name, and all are `inline` for optimization at the call site (the `.fs` adds `[<InlineIfLambda>]` to the higher-order arguments).

The module is annotated `[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`, so the compiled type is `ResultModule`.

## Values / signatures

- `map: ('T -> 'U) -> Result<'T,'TError> -> Result<'U,'TError>` (`Map`) — transform the `Ok` value.
- `mapError: ('TError -> 'U) -> Result<'T,'TError> -> Result<'T,'U>` (`MapError`) — transform the `Error` value.
- `bind: ('T -> Result<'U,'TError>) -> Result<'T,'TError> -> Result<'U,'TError>` (`Bind`).
- `isOk: ... -> bool` (`IsOk`); `isError: ... -> bool` (`IsError`).
- `defaultValue: value -> Result<'T,'Error> -> 'T` (`DefaultValue`).
- `defaultWith: defThunk:('Error -> 'T) -> Result<'T,'Error> -> 'T` (`DefaultWith`) — `defThunk` only evaluated when the result is `Error`.
- `count: Result<'T,'Error> -> int` (`Count`) — 0/1.
- `fold<'T,'Error,'State>: ('State->'T->'State) -> state -> result -> 'State` (`Fold`).
- `foldBack<'T,'Error,'State>: ('T->'State->'State) -> result -> state -> 'State` (`FoldBack`).
- `exists: ('T->bool) -> result -> bool` (`Exists`); `forall: ('T->bool) -> result -> bool` (`ForAll`).
- `contains: value:'T -> result -> bool` (`Contains`, requires `'T: equality`).
- `iter: ('T->unit) -> result -> unit` (`Iterate`).
- `toArray: result -> 'T array` (`ToArray`); `toList: result -> 'T list` (`ToList`); `toOption: result -> 'T option` (`ToOption`); `toValueOption: result -> 'T voption` (`ToValueOption`).

Every signature includes extensive XML documentation with prose descriptions and runnable `<code lang="fsharp">` examples.

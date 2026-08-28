# CompilerGlobalState.fsi

**Purpose**: Compilation interface (contract) for `FSharp.Compiler.CompilerGlobalState`, the global name/environment state for type checking. Hides implementation details (e.g. the `ICompilerGeneratedNameMap` injection used for hot-reload name replay) and re-exports only the stable API: name generators, per-file naming scopes, and the `Unique`/`newUnique`/`newStamp` facilities.

**Namespace(s)**: `FSharp.Compiler` — declared `module internal FSharp.Compiler.CompilerGlobalState` (the .fsi exposes the module as internal even though the .fs module is public).

**Declared types (signatures)**:
- `NiceNameGenerator` — `new: unit -> NiceNameGenerator`; `FreshCompilerGeneratedName: string * range -> string`; `ResetCompilerGeneratedNameState: unit -> unit`.
- `StableNiceNameGenerator` — `GetUniqueCompilerGeneratedName: string * range * int64 -> string`; `ResetCompilerGeneratedNameState: unit -> unit`; memoizes stable names by the unique key.
- `PerFileNamingScope` (`[<Sealed>]`) — `Fresh: name: string * m: range -> string`; instance only obtainable via `CompilerGlobalState.NewFileScope` so names are bucketed by the right file (determinism under parallel optimization, dotnet/fsharp#19732).
- `CompilerGlobalState` — members `IlxGenNiceNameGenerator`, `NiceNameGenerator`, `StableNameGenerator`, `NewFileScope: range -> PerFileNamingScope`, `ResetCompilerGeneratedNameState: unit -> unit`.

**Public API surface**:
- `type Unique = int64`
- `val newUnique: unit -> int64` (concurrency-safe)
- `val newStamp: unit -> int64` — stamps for val_specs/tycon_specs (concurrency-safe)

**Notable contract notes**: Constructors are plain `new: unit` (no name-map parameter visible); the `.fs` implementations accept an optional `ICompilerGeneratedNameMap` accessor that defaults to `fun () -> None`. Resetting requires no concurrent name generation (quiescence).

**Cross-references**: `CompilerGlobalState.fs` (implementation), `CompilerGeneratedNameMapState.fs`, `GeneratedNames.fs`.

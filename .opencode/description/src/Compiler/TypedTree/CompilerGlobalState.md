# CompilerGlobalState.fs

**Purpose**: Defines the global environment for all type checking. Provides concurrency-safe global compiler-generated name generators (`NiceNameGenerator`, `StableNiceNameGenerator`), per-file naming scopes for deterministic name allocation (dotnet/fsharp#19732), and the global `Unique`/stamp counters used to stamp type constructors and values. Name generation honors an optional `ICompilerGeneratedNameMap` (hot-reload replay, see `CompilerGeneratedNameMapState.fs`) which must win over per-file occurrence buckets.

**Namespace(s)**: `FSharp.Compiler` (module public in .fs; exposed as `internal FSharp.Compiler.CompilerGlobalState` in the .fsi).

**Declared types**:
- `NiceNameGenerator` — concurrency-safe generator of compiler-generated names, including the `StartLine` of the range at first generation; per-(basicName, fileIndex) `ConcurrentDictionary` occurrence counters; `FreshCompilerGeneratedNameOfBasicName`, `FreshCompilerGeneratedName`, `FreshCompilerGeneratedNameInScope`, `ResetCompilerGeneratedNameState`.
- `StableNiceNameGenerator` — like the above but memoized by a `uniq: int64` key (`ConcurrentDictionary<string * int64, Lazy<string>>`) so the same unique value always yields the same name; wraps an inner `NiceNameGenerator`.
- `PerFileNamingScope` (`[<Sealed>]`, internal constructor) — binds name allocation to one file's `FileIndex`; `Fresh(name, range)`.
- `CompilerGlobalState` — holds `globalNng`, `globalStableNameGenerator`, `ilxgenGlobalNng` and the name-map accessor bound to `this`; exposes `NiceNameGenerator`, `StableNameGenerator`, `IlxGenNiceNameGenerator`, `NewFileScope`, `ResetCompilerGeneratedNameState`.

**Public API surface**:
- `type Unique = int64`
- `newUnique: unit -> int64` — fresh unique stamp (Interlocked increment of private `uniqueCount`).
- `newStamp: unit -> int64` — fresh stamp for val_specs, tycon_specs etc. (Interlocked increment of private `stampCount`).

**Internal details**: Generated names are `CompilerGeneratedNameSuffix basicName (string StartLine (+ "-" + n for repeats))`; both generators consult `getCompilerGeneratedNameMap()` first so an installed replay map overrides per-file bucketing, keeping line-based per-file naming untouched for normal compilation. `ResetCompilerGeneratedNameState` clears all counters for warm-in-process re-emit (Edit-and-Continue) scenarios.

**Cross-references**: `CompilerGlobalState.fsi` (contract), `CompilerGeneratedNameMapState.fs`, `fsharp/syntax/PrettyNaming` (`GetBasicNameOfPossibleCompilerGeneratedName`); used globally across the checker (`Checker.fs`) and ILX codegen.

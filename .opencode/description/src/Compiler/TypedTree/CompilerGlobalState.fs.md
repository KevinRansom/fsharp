# CompilerGlobalState.fs

## Pipeline role

This file belongs to the TypedTree folder of the F# compiler. It defines the global environment used during type checking: the generators of compiler-generated (`NiceNameGenerator`) and stable (`StableNiceNameGenerator`) names, the per-file naming scopes, the unique `Unique` stamp generator, the `Stamp` generator for `Val`/`Tycon` specs, and the `CompilerGlobalState` aggregate that hosts the three shared name generators for a compilation thread. The name generators are concurrency-safe even though in practice they are used from the compilation thread — the global instances live in `tast.fs`, and global objects are kept safe in case future compilations host multiple concurrent instances. Instances carry a reader for the optional synthesized-name map installed via `CompilerGeneratedNameMapState` (the hot-reload/E&c path), so generated names replay deterministically when a map is present.

## Headers, opens

- Header: `module FSharp.Compiler.CompilerGlobalState`, with the standard Microsoft copyright/`License.txt` notice.
- Opens `System`, `System.Collections.Concurrent`, `System.Threading`, `Internal.Utilities.Library`, `FSharp.Compiler.CompilerGeneratedNameMapState`, `FSharp.Compiler.Syntax.PrettyNaming`, `FSharp.Compiler.Text`.

## `type NiceNameGenerator`

Generator of compiler-generated names. Each name includes the `StartLine` of the range passed in at first generation. Concurrency-safe; a global instance is allocated in `tast.fs`. Constructor takes `getCompilerGeneratedNameMap: unit -> ICompilerGeneratedNameMap option`.

- Instance state: `basicNameCounts = ConcurrentDictionary<struct (string * int), int ref>(…)` (per `(basicName, fileIndex)` occurrence counters, sized `max ProcessorCount 1` with 127 buckets); cached `basicNameCountsAddDelegate` (`Func<_,int ref>` returning `ref 0`).
- `incrementBucket basicName fileIndex` — `GetOrAdd` the counter then `Interlocked.Increment`.
- `increment basicName (m: range)` — increments the bucket for `m.FileIndex`.
- `mkName basicName (m: range) count` — `CompilerGeneratedNameSuffix basicName (string m.StartLine + (match (count - 1) with 0 -> "" | n -> "-" + string n))`, i.e. `<basic><line>` then `<basic><line>-<n>` for the 2nd+ occurrence on that line.
- `member FreshCompilerGeneratedNameOfBasicName (basicName, m)` — when a map is installed, delegates to `map.GetOrAddName basicName`; otherwise increments and builds the occurrence name.
- `member FreshCompilerGeneratedName (name, m)` — via `GetBasicNameOfPossibleCompilerGeneratedName name`.
- `member FreshCompilerGeneratedNameInScope (scopeFileIndex, name, m)` — the map wins (exactly as in `FreshCompilerGeneratedNameOfBasicName`: with a session map installed, every allocation path replays the baseline's stable names, otherwise per-file names would drift under edits); else increments the per-(basicName, `scopeFileIndex`) bucket. This preserves the deterministic per-file bucketing from dotnet/fsharp#19732 in normal compilation.
- `new ()` — `NiceNameGenerator(fun () -> None)` (no map).
- `member ResetCompilerGeneratedNameState()` — clears `basicNameCounts` so a subsequent codegen run assigns the same occurrence names a fresh process would (callers must quiesce codegen).

## `type StableNiceNameGenerator`

Like `NiceNameGenerator` but also stable under re-generation: it marks names with a source location, and given the same unique value returns precisely the same name (`StableNiceNameGenerator(fun () -> None)` ctor variant adds a `getCompilerGeneratedNameMap` argument by `new ()`). Also concurrency-safe, used from the compilation thread.

- Instance state: `niceNames = ConcurrentDictionary<string * int64, Lazy<string>>(…)` (per `(basicName, uniq)` memoization); `innerGenerator = NiceNameGenerator(getCompilerGeneratedNameMap)`.
- `member GetUniqueCompilerGeneratedName (name, m, uniq)` — `basicName = GetBasicNameOfPossibleCompilerGeneratedName name`; key `(basicName, uniq)`; `niceNames.GetOrAddLazy(key, fun (basicName, _) -> innerGenerator.FreshCompilerGeneratedNameOfBasicName(basicName, m))` — stable names are memoized by `uniq`.
- `member ResetCompilerGeneratedNameState()` — clears `niceNames` and the inner occurrence counters.

## `type PerFileNamingScope`

`[<Sealed>]`, internal ctor `internal (nng: NiceNameGenerator, fileIndex: int)`:

- `member Fresh (name, m)` — `nng.FreshCompilerGeneratedNameInScope(fileIndex, name, m)`.

## `type internal CompilerGlobalState`

`type internal CompilerGlobalState () as this` — aggregate of the compile's shared name generators:

- `let getCompilerGeneratedNameMap = getCompilerGeneratedNameMapAccessor (this :> obj)` — the optional synthesized-name-map reader for this instance (resolves the side-channel slot once, so each generated name is one `None` check, not a weak-table probe + lock).
- `globalNng = NiceNameGenerator(getCompilerGeneratedNameMap)` — global generator of compiler-generated names.
- `globalStableNameGenerator = StableNiceNameGenerator(getCompilerGeneratedNameMap)` — global stable names.
- `ilxgenGlobalNng = NiceNameGenerator(getCompilerGeneratedNameMap)` — name generator used by IlxGen (static fields, some generated arguments, etc.).
- Members: `NiceNameGenerator = globalNng`; `StableNameGenerator = globalStableNameGenerator`; `IlxGenNiceNameGenerator = ilxgenGlobalNng`.
- `member NewFileScope (fileRange: range)` — `PerFileNamingScope(globalNng, fileRange.FileIndex)`.
- `member ResetCompilerGeneratedNameState()` — resets all three generators (global, stable, ilxgen) so successive in-process codegen runs over the same source produce identical generated names (fresh-process layout); needed by Edit-and-Continue scenarios re-emitting from a warm checker. Callers must quiesce codegen.

## Global unique/stamp generators (concurrency-safe mutable state)

- `type Unique = int64` — unique name generator for stamps attached to lambdas and object expressions.
- `let mutable private uniqueCount = 0L`; `let newUnique() = Interlocked.Increment &uniqueCount`.
- `let mutable private stampCount = 0L`; `let newStamp() = Interlocked.Increment &stampCount` — unique stamps for `val_spec`s, `tycon_spec`s, etc.

## Relation to `CompilerGlobalState.fsi`

The `.fsi` exposes the same surface (`NiceNameGenerator`, `StableNiceNameGenerator`, `PerFileNamingScope`, `CompilerGlobalState`, `Unique`, `newUnique`, `newStamp`); the `.fs` additionally brings in the `CompilerGeneratedNameMapState` plumbing and the full generator internals (occurrence counters, memoization, name construction).
# IncrementalBuild.fsi

**Purpose**: Internal contract for the incremental compilation pipeline: the `IncrementalBuilder` (manages the incremental build graph of an F# project), the per-slot result type `PartialCheckResults`, the cached-state records `TcInfo`/`TcInfoExtras`, the global `FrameworkImportsCache`, and test-support entry points.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## Types declared

- **`FrameworkImportsCacheKey`** (union, internal) — key of the framework-imports cache: resolved path list, assembly name, target-framework dirs, F# binaries dir, lang version, check-nulls; implements `ICacheKey<string, _>`.
- **`FrameworkImportsCache`** (internal) — `new: size -> _`; `Get: TcConfig -> Async<TcGlobals * TcImports * AssemblyResolution list * UnresolvedAssemblyReference list>`; `Clear`; `Downsize`.
- **`IncrementalBuilderEventTesting`** (internal module) — `IBEvent` (`IBEParsed`/`IBETypechecked`/`IBECreated`), `GetMostRecentIncrementalBuildEvents: int -> IBEvent list`, `GetCurrentIncrementalBuildEventNum` — for unit tests.
- **`TcInfo`** (record, internal) — "the minimum amount of state in order to continue type-checking following files": `tcState`, `tcEnvAtEndOfFile`, `moduleNamesDict`, `topAttribs`, `latestCcuSigForFile`, `tcDiagnosticsRev`, `tcDependencyFiles`, `sigNameOpt`; `TcDiagnostics`.
- **`TcInfoExtras`** (record, internal) — optional richness: `tcResolutions`, `tcSymbolUses`, `tcOpenDeclarations`, `latestImplFile`, `itemKeyStore: ItemKeyStore option`, `semanticClassificationKeyStore: SemanticClassificationKeyStore option`; `TcSymbolUses`.
- **`PartialCheckResults`** (sealed, internal) — state at a file slot: `TcImports`/`TcGlobals`/`TcConfig`/`TimeStamp`/`ProjectTimeStamp`; `TryPeekTcInfo`, `TryPeekTcInfoWithExtras`, `GetOrComputeTcInfo`, `GetOrComputeTcInfoWithExtras` (may double-check under partial type checking), `GetOrComputeItemKeyStoreIfEnabled`, `GetOrComputeSemanticClassificationIfEnabled`.
- **`RawFSharpAssemblyDataBackedByLanguageService`** (sealed) — implements `IRawFSharpAssemblyData` from a checked (tcConfig, tcGlobals, ccu, outfile, topAttrs, assemblyName, ilAssemRef).
- **`IncrementalBuilder`** (class, internal) — see below.
- **`module IncrementalBuild`** (internal) — `LocallyInjectCancellationFault: unit -> IDisposable` (unit testing).

## IncrementalBuilder — members (contract)

- State: `TcConfig`, `SourceFiles`.
- Events: `BeforeFileChecked`, `FileParsed`, `FileChecked`, `ProjectChecked`, `ImportsInvalidatedByTypeProvider` (only when type providers compiled in).
- Invalidation: `IsReferencesInvalidated: bool`, `AllDependenciesDeprecated: string[]`, `NotifyFileChanged: fileName * timeStamp -> Async<unit>`.
- Driving: `PopulatePartialCheckingResults: unit -> Async<unit>` — run the background build.
- Quick lookups (no compute): `GetCheckResultsBeforeFileInProjectEvenIfStale`, `GetCheckResultsForFileInProjectEvenIfStale`, `AreCheckResultsBeforeFileInProjectReady`.
- Up-to-date-checked lookups: `TryGetCheckResultsBeforeFileInProject`.
- Blocking compute: `GetCheckResultsBeforeFileInProject`, `GetFullCheckResultsBeforeFileInProject`, `GetCheckResultsAfterFileInProject`, `GetFullCheckResultsAfterFileInProject`, `GetCheckResultsAfterLastFileInProject`.
- Final: `GetCheckResultsAndImplementationsForProject` / `GetFullCheckResultsAndImplementationsForProject` → `Async<PartialCheckResults * ILAssemblyRef * ProjectAssemblyDataResult * CheckedImplFile list option>`; `GetLogicalTimeStampForProject: TimeStampCache -> DateTime`; `ContainsFile`; `GetParseResultsForFile`.
- Creation: `static member TryCreateIncrementalBuilderForProjectOptions` (large parameter list: legacy reference resolver, binaries dir, framework cache, script load closure, source files, command-line args, project references, directory, script rules, keep-contents/symbol-uses flags, metadata-snapshot hook, name suggestions, item-key-store/classification flag, partial checking, dependency provider, parallel reference resolution, identifier capture, `getSource`, `useChangeNotifications`) → `Async<IncrementalBuilder option * FSharpDiagnostic[]>`.

## Public API surface

- Nothing public — the whole fsi is internal; consumers are `BackgroundCompiler.fs`, `service.fs` (`FSharpChecker` internals), and unit tests.

## Significant internal logic (contract notes)

- The `EvenIfStale`/`Ready`/blocking tiering documents the cost/liveness contract: stale-peek is free, `Ready` is relatively quick, the unqualified `Get...` may be long-running (parses + checks up to the slot).
- `TcInfoExtras` being separate from `TcInfo` is the mechanism for partial type checking: the cheap state is always cached, the rich state is computed on demand (possibly a second check).
- `itemKeyStore`/`semanticClassificationKeyStore` are optional (None when the feature flags are off) — see `ItemKey.fsi` and `SemanticClassificationKey.fsi`.
- `GetCheckResultsAndImplementationsForProject` is the full-build endpoint (IL + assembly data + optional typed impl files) used for `GetAssemblyData` and compile scenarios.

## Cross-references

- Used by: `BackgroundCompiler.fs` (`incrementalBuildersCache`, `ParseAndCheckFileInProject`, `GetAssemblyData`, `GetCachedCheckFileResult`), `TransparentCompiler.fs` (snapshot mode), `FSharpCheckerResults.fs` (`FSharpCheckFileResults.Make/CheckOneFile` take a builder).
- Feeds: `ItemKey.fs` / `SemanticClassificationKey.fs` (stores inside `TcInfoExtras`), `FrameworkImportsCache` is shared across builders.
- Events mirror those surfaced by `FSharpChecker` (`BeforeBackgroundFileCheck`/`FileParsed`/`FileChecked`/`ProjectChecked`, see `service.fsi`).

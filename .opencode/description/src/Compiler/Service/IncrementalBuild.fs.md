# IncrementalBuild.fs

**Purpose**: Implements the incremental compilation pipeline for a project: a dependency-graph-based state machine that parses and type-checks files in order, caches partial check states per "file slot", supports up-to-date checking, type-provider invalidation, and produces the final checked assembly (IL assembly ref + assembly data + typed impl files). This is the engine driven by `BackgroundCompiler` and (in snapshot mode) `TransparentCompiler`.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## Modules / Types declared

- **`module IncrementalBuild`** (AutoOpen) — `LocallyInjectCancellationFault` test hook.
- **`module IncrementalBuilderEventTesting`** — `FixedLengthMRU<'T>` (400-slot ring), `IBEvent` (`IBEParsed`/`IBETypechecked`/`IBECreated`), `GetMostRecentIncrementalBuildEvents`, `GetCurrentIncrementalBuildEventNum` — unit-test visibility into pipeline events.
- **`module Tc` = CheckExpressions** alias.
- **`FSharpFile`** (internal record, ~line 97) — `{ Range; Source: FSharpSource; Flags: bool * bool; ... }` — one source file of the build.
- **`module IncrementalBuildSyntaxTree`** (~line 105) — parse helpers (parsing a file with diagnostics, `parseFile`-style helpers, `TryParseInput`).
- **`TcInfo`** (record, ~line 188) — the irreducible per-file check state: `tcState`, `tcEnvAtEndOfFile`, `moduleNamesDict`, `topAttribs`, `latestCcuSigForFile`, `tcDiagnosticsRev` (last-file-first), `tcDependencyFiles`, `sigNameOpt`; `TcDiagnostics` property.
- **`TcInfoExtras`** (record, ~line 213) — optional richness: `tcResolutions`, `tcSymbolUses`, `tcOpenDeclarations`, `latestImplFile`, `itemKeyStore: ItemKeyStore option`, `semanticClassificationKeyStore: SemanticClassificationKeyStore option` (the latter two only when `enableBackgroundItemKeyStoreAndSemanticClassification` is true).
- **`BoundModel`** (private class, ~line 236) — memoized evaluation of the build graph: holds the per-slot `TcInfo`/extras for the bound (parsed + checked) prefix.
- **`FrameworkImportsCacheKey`** (union, ~line 490) + **`FrameworkImportsCache`** (~line 503) — global static cache of the framework/reference `TcGlobals * TcImports` keyed by resolved paths, assembly name, TF directories, binaries dir, lang version, check-nulls; `Get`, `Clear`, `Downsize`.
- **`PartialCheckResults`** (~line 592) — per-slot results: `TcImports`/`TcGlobals`/`TcConfig`, time stamps, `TryPeekTcInfo(WithExtras)`, `GetOrComputeTcInfo`, `GetOrComputeTcInfoWithExtras` (may trigger a second check under partial checking), `GetOrComputeItemKeyStoreIfEnabled`, `GetOrComputeSemanticClassificationIfEnabled`.
- **`module Utilities`** — small shared helpers (hashing, file reading, etc.).
- **`RawFSharpAssemblyDataBackedByLanguageService`** (~line 637) — `IRawFSharpAssemblyData` implementation backed by the checked assembly (used for `GetAssemblyData`/assembly info queries).
- **`module IncrementalBuilderHelpers`** (~line 677) — build-graph node helpers (parse/check node constructors, dependency management).
- **`IncrementalBuilderInitialState`** (~line 896) — immutable inputs: tcConfig, source files, project references, script closure, reference-resolution state, etc.
- **`Slot`** (~line 975) — one file slot in the build (index, file, state).
- **`IncrementalBuilderState`** (~line 988) — mutable state: list of slots, per-slot parse/check memoization, invalidation flags; plus `IncrementalBuilderStateHelpers` and extension members.
- **`IncrementalBuilder`** (~line 1147) — the public (to the service) entry object: `TcConfig`, `SourceFiles`, events `BeforeFileChecked`/`FileParsed`/`FileChecked`/`ProjectChecked` (+ `ImportsInvalidatedByTypeProvider` when type providers enabled), `IsReferencesInvalidated`, `AllDependenciesDeprecated`, `PopulatePartialCheckingResults`, stale/ready/forced `GetCheckResultsBeforeFileInProject` family (`...EvenIfStale`, `AreCheckResultsBefore...Ready`, `TryGet...`, `Get...`, `GetFull...`, `GetCheckResultsAfterFileInProject`, `GetCheckResultsAfterLastFileInProject`, `GetCheckResultsAndImplementationsForProject` (+`Full`), `GetLogicalTimeStampForProject`, `ContainsFile`, `GetParseResultsForFile`, `NotifyFileChanged`; static `TryCreateIncrementalBuilderForProjectOptions` (huge constructor that resolves references, builds framework imports, creates the initial state).

## Public API surface

- Nothing public in the fsi beyond what's internal; exposed to the service: `IncrementalBuilder`, `FrameworkImportsCache`, `PartialCheckResults`, `TcInfo`, `TcInfoExtras`, `RawFSharpAssemblyDataBackedByLanguageService`, and the testing module.

## Internal helpers / active patterns

- Build-graph evaluation via `Internal.Utilities.BuildGraph` (`GraphNode`, `BuildGraph`) — slots chain as dependent nodes so changes invalidate only subsequent slots.
- Events + `MRU` for test observability; `IncrementalBuilderEventTesting.LocallyInjectCancellationFault` for fault-injection tests.
- `DiagnosticsScope`, `FxResolver`, reference resolution (`ResolveReferences`-style) in the creation path.

## Significant internal logic

- **Slot-based incremental checking**: each file is a slot; checking file N requires TcState through slot N-1. Up-to-date is judged by file time stamps + reference invalidation — `TryGetCheckResultsBeforeFileInProject` is quick, `GetCheckResultsBeforeFileInProject` is the blocking compute path.
- **Partial type checking**: when `enablePartialTypeChecking` is set, background work stores only `TcInfo`; `GetOrComputeTcInfoWithExtras`/`GetOrComputeItemKeyStoreIfEnabled`/`GetOrComputeSemanticClassificationIfEnabled` may re-check to materialize resolutions/symbol-uses/stores. `PartialCheckResults` documents this "second type-check" cost explicitly.
- **Framework imports caching**: `FrameworkImportsCache` globalizes the resolution of framework references across projects (strong-size default 8), keyed by `FrameworkImportsCacheKey`.
- **Invalidation**: `NotifyFileChanged`/reference change/time-stamp comparison sets a slot and successors stale; `IsReferencesInvalidated` and `AllDependenciesDeprecated` report it; type providers can raise `ImportsInvalidatedByTypeProvider`.
- **Finalization**: `GetCheckResultsAndImplementationsForProject` runs the full pipeline including optimization/IL (`RawFSharpAssemblyDataBackedByLanguageService`, `ProjectAssemblyDataResult`, optional `CheckedImplFile list` when `generateTypedImplFiles`).

## Cross-references

- Contract: `IncrementalBuild.fsi`.
- Driven by: `BackgroundCompiler.fs` (`incrementalBuildersCache`, `ParseAndCheckFileInProject`, `GetAssemblyData`), and snapshot-mode checking in `TransparentCompiler.fs`.
- Produces `FSharpCheckFileResults` via `FSharpCheckerResults.CheckOneFile` (see `FSharpCheckerResults.fs`).
- File content via `FSharpSource` (see `FSharpSource.fs`); stores via `ItemKey.fs` / `SemanticClassificationKey.fs`; diagnostics via `FSharp.Compiler.Diagnostics`/`DiagnosticsLogger`.

# service.fs

**Purpose**: The main implementation file of FSharp.Compiler.Service. Implements `FSharpChecker` — the central API surface for tooling (Language Server, Visual F#, FSI) — delegating parse/check work to a background compiler (default `BackgroundCompiler`, optionally the experimental `TransparentCompiler`), plus a small `CompileHelpers` module for `Compile` and a static `CompilerEnvironment` helper class.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis` (checker + compile helpers), `FSharp.Compiler` (`CompilerEnvironment`)

## Classes / Modules / Types declared

- **`type IsResultObsolete`** — a boxed `unit -> bool` callback indicating a requested result has gone obsolete (used to cancel stale work).
- **`module CompileHelpers`** — `mkCompilationDiagnosticsHandlers` (builds a `DiagnosticsLogger` + `IDiagnosticsLoggerProvider` collecting `FSharpDiagnostic`s with name suggestions), `tryCompile` (runs `f exiter` under `UseBuildPhase BuildPhase.Parse` and captures/converts a terminating exception), `compileFromArgs` (invokes the Driver's `CompileFromCommandLineArguments` and returns `FSharpDiagnostic[] * exn option`).
- **`type FSharpChecker`** (sealed, non-serializable) — the one-instance-per-process language service. Notable fields: `backgroundCompiler: IBackgroundCompiler` (`BackgroundCompiler` or `TransparentCompiler` depending on `useTransparentCompiler`), `braceMatchCache` (an MruCache safe for concurrent access), static lazy `globalInstance`.
- **`type CompilerEnvironment`** — static-file utility class: default compiler bin folder, default references for orphan sources, conditional defines for editing (`COMPILED`/`INTERACTIVE` + `EDITING`), whether a subcategory of diagnostic is checker-supported, the debugger language ID GUID, `IsScriptFile`/`IsCompilable`/`MustBeSingleFileProject` based on file extension.

## Public API surface (FSharpChecker)

- Creation: `Create` (many optional parameters — project cache size, `keepAssemblyContents`, `keepAllBackgroundResolutions`, `legacyReferenceResolver`, `tryGetMetadataSnapshot`, `suggestNamesForErrors`, `keepAllBackgroundSymbolUses`, `enableBackgroundItemKeyStoreAndSemanticClassification`, `enablePartialTypeChecking`, `parallelReferenceResolution`, `captureIdentifiersWhenParsing`, experimental `documentSource`/`useTransparentCompiler`/`transparentCompilerCacheSizes`); validates that `keepAssemblyContents` and `enablePartialTypeChecking` are not both set. Static `Instance` (obsolete), `ActualParseFileCount`, `ActualCheckFileCount` (test statistics).
- Parse/check: `MatchBraces` (cached), `ParseFile` (+ snapshot overload), obsolete `ParseFileInProject`, `CheckFileInProject`, obsolete `CheckFileInProjectAllowingStaleCachedResults`, `ParseAndCheckFileInProject` (+ snapshot), `ParseAndCheckProject` (+ snapshot), `GetBackgroundParseResultsForFileInProject`, `GetBackgroundCheckResultsForFileInProject`, `TryGetRecentCheckResultsForFile` (both forms).
- Find-references / classification: `FindBackgroundReferencesInFile` (has a `fastCheck` path that pre-filters against `ParseTree.Identifiers` when `captureIdentifiersWhenParsing` is on), `GetBackgroundSemanticClassificationForFile` (both forms).
- Script/options: `GetProjectOptionsFromScript`, `GetProjectSnapshotFromScript`, `GetProjectOptionsFromCommandLineArgs` (appends `--define:COMPILED`/`INTERACTIVE` and `EDITING`), `GetParsingOptionsFromCommandLineArgs` (builds a `TcConfigBuilder`), `GetParsingOptionsFromProjectOptions`.
- Lifecycle/caching: `InvalidateAll` (clears brace cache, background caches, `ClearAllILModuleReaderCache`), `InvalidateConfiguration`, `ClearCache` (both forms), `ClearLanguageServiceRootCachesAndCollectAndFinalizeAllTransients` (+ `GC.Collect`, `FxResolver.ClearStaticCaches`), `NotifyProjectCleaned` (obsolete), `NotifyFileChanged` (custom document sources, which suppress file-system watching).
- Events (forwarded from the background compiler, raised on background threads): `BeforeBackgroundFileCheck`, `FileParsed`, `FileChecked`, `ProjectChecked`.
- Tokenizers: `TokenizeLine` (stateful `FSharpTokenizerLexState`), `TokenizeFile`.
- Compile: `Compile(argv, ?userOpName)` → wraps `CompileHelpers.compileFromArgs`.
- Internal: `TransparentCompiler`, `Caches`, `FrameworkImportsCache`, `ReferenceResolver`.

## Public API surface (CompilerEnvironment)

- All static members listed above; `GetConditionalDefinesForEditing` is documented as fast because the colorizer uses it.

## Internal helpers

- `AreSimilarForParsing`/`AreSameForParsing` (from `BackgroundCompiler` module helpers) for the brace-match MruCache.
- `inferParallelReferenceResolution` — env-var override of the parallel-reference-resolution flag.
- `globalInstance` lazy — backs static `Instance`.

## Significant internal logic

- `FSharpChecker` is a facade: nearly every member forwards to `backgroundCompiler : IBackgroundCompiler`. Only `MatchBraces`, `GetParsingOptionsFromCommandLineArgs`, `Compile`, cache invalidation, and tokenization have local logic.
- When `documentSource` is `Custom`, `useChangeNotifications` is true: the checker stops watching the file system and requires `NotifyFileChanged`.
- The `TransparentCompiler` code path shares all other construction parameters.
- `GetProjectOptionsFromCommandLineArgs` deliberately uses `LoadedTimeStamp = DateTime.MaxValue` so as not to force a reload of project state.

## Cross-references

- Implementation of the contract in `service.fsi`.
- Depends on: `BackgroundCompiler.fs` / `TransparentCompiler.fs` (`IBackgroundCompiler`), `FSharpCheckerResults.fs` (options/result types), Driver's `CompileFromCommandLineArguments` (`FSharp.Compiler.Driver`, i.e. `Driver/fsc.fs`), `FxResolver`, `FSharpEnvironment`.
- `CompilerEnvironment.GetConditionalDefinesForEditing` delegates to `SourceFileImpl` in `FSharpParseFileResults.fs`.

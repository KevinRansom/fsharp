# BackgroundCompiler.fs

**Purpose**: The default background-compiler engine behind `FSharpChecker`. Owns the set of MruCaches (script closure, framework TcImports, parse results, check results, incremental builders), runs compilation work on background threads, and exposes the `IBackgroundCompiler` API used by the public service — parse, check, find-references, semantic classification, script/project-options derivation.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## TypeDefs / Classes / Modules declared

- **Type aliases** — `SourceTextHash = int64`, `CacheStamp = int64`, `FileName`/`FilePath`/`ProjectPath = string`, `FileVersion = int`; `FSharpProjectSnapshot` alias to `ProjectSnapshot.FSharpProjectSnapshot`.
- **`IBackgroundCompiler`** (internal interface) — the full background-work contract: `CheckFileInProject`, `CheckFileInProjectAllowingStaleCachedResults`, `ClearCache` (options/identifiers), `ClearCaches`, `DownsizeCaches`, `FindReferencesInFile` (2 forms), `GetAssemblyData` (2 forms), `GetBackgroundCheckResultsForFileInProject`, `GetBackgroundParseResultsForFileInProject`, `GetCachedCheckFileResult`, `GetProjectOptionsFromScript`, `GetProjectSnapshotFromScript`, `GetSemanticClassificationForFile` (2 forms), `InvalidateConfiguration` (2 forms), `NotifyFileChanged`, `NotifyProjectCleaned`, `ParseAndCheckFileInProject` (2 forms), `ParseAndCheckProject` (2 forms), `ParseFile` (2 forms), `TryGetRecentCheckResultsForFile` (2 forms), events `BeforeBackgroundFileCheck`/`FileParsed`/`FileChecked`/`ProjectChecked`, `FrameworkImportsCache`.
- **`CheckFileCacheKey`** — `FileName * SourceTextHash * FSharpProjectOptions`.
- **`CheckFileCacheValue`** — `FSharpParseFileResults * FSharpCheckFileResults * SourceTextHash * DateTime`.
- **`module EnvMisc`** (AutoOpen) — env-var-tunable cache sizes: `braceMatchCacheSize` (`FCS_BraceMatchCacheSize`, def 5), `parseFileCacheSize` (2), `checkFileInProjectCacheSize` (10), `projectCacheSizeDefault` (3), `frameworkTcImportsCacheStrongSize` (8).
- **`module Helpers`** (AutoOpen) — key-equivalence predicates: `AreSameForChecking2`, `AreSubsumable2`, `AreSameForParsing`, `AreSimilarForParsing`, `AreSameForChecking3`, `AreSubsumable3`; `NamesContainAttribute` (checks if a set of names contains an attribute symbol's name without the `Attribute` suffix, following the declaring entity).
- **`BackgroundCompiler`** (internal class, implements `IBackgroundCompiler`) — static counters `ActualCheckFileCount`/`ActualParseFileCount`; four `Event`s; `scriptClosureCache` (MruCache of `LoadClosure` per options), `frameworkTcImportsCache`, `parseCacheLock` (`Lock<ParseCacheLockToken>`), `parseFileCache`, `checkFileInProjectCache` (values are `GraphNode<CheckFileCacheValue>`), `incrementalBuildersCache` (MruCache of `GraphNode<IncrementalBuilder option * FSharpDiagnostic[]>` per options), plus all IBackgroundCompiler implementations.

## Public API surface

- None directly — everything is internal; the public surface is reached through `FSharpChecker` in `service.fs`, which forwards one-to-one to `IBackgroundCompiler`.

## Internal helpers / active patterns

- `MruCache` (from `Internal.Utilities.BuildGraph`/`Collections`) with per-thread or any-thread tokens for caching.
- `AreSame*/AreSubsumable*` predicates distinguish "same result reuse" from "subsumable for resource accounting".
- `UseBackgroundThread`-style plumbing / async work scheduling, `GraphNode` shared values for check results, `Cancellable` for cooperative cancellation.
- `FSharpCheckerResults.ParseAndCheckFile.parseFile` for the actual parse; `IncrementalBuilder` for per-project pipelines.

## Significant internal logic

- **Check pipeline**: `ParseAndCheckFileInProject` ensures the project's `IncrementalBuilder` exists (creating via `IncrementalBuild` in a background thread, stored in `incrementalBuildersCache` keyed by options), then `GetCheckResultsBeforeFileInProject` computes TcState up to the file, and `FSharpCheckFileResults.CheckOneFile` produces the `FSharpCheckFileResults` — cached as `CheckFileCacheValue` per (file, hash, options).
- **Partial type checking**: when `enablePartialTypeChecking` is on, background checks record only the core `TcInfo` (see `IncrementalBuild.fs`), and rich results (resolutions, symbol uses, item key store, semantic classification) are computed on demand — potentially triggering a second check (`GetOrComputeTcInfoWithExtras`).
- **Script handling**: `GetProjectOptionsFromScript`/`GetProjectSnapshotFromScript` compute the `#load` closure (cached in `scriptClosureCache`) and build options/snapshots; `useScriptResolutionRules` flows into both.
- **Find references**: `FindReferencesInFile` fetches cached check results (computing if needed) and uses either symbol-uses scanning or the `ItemKeyStore` (when `enableBackgroundItemKeyStoreAndSemanticClassification` is true and `keepAllBackgroundSymbolUses`).
- **Semantic classification**: `GetSemanticClassificationForFile` returns a `SemanticClassificationView` backed by the `SemanticClassificationKeyStore` produced during the check (see `SemanticClassificationKey.fs`).
- **Events** `BeforeBackgroundFileCheck`/`FileParsed`/`FileChecked`/`ProjectChecked` are raised around each pipeline stage so hosts can coordinate with foreground work.
- `ClearCaches` invalidates the MruCaches and the framework imports cache; `DownsizeCaches` shrinks them.

## Cross-references

- Contract: `BackgroundCompiler.fsi`.
- Sibling implementation: `TransparentCompiler.fs` (implements the same `IBackgroundCompiler`); `FSharpChecker` in `service.fs` picks between them.
- Drives: `IncrementalBuild.fs` (`IncrementalBuilder`, `FrameworkImportsCache`, `PartialCheckResults`), `FSharpCheckerResults.fs` (parse/check results types and `ParseAndCheckFile`), `FSharpProjectSnapshot.fs` (snapshot model + `snapshotToOptions`), `ItemKey.fs` / `SemanticClassificationKey.fs` (stores), `ExternalSymbol.fs` (FindDecl results).
- Caches: `MruCache`, `GraphNode` from `Internal.Utilities`; environment knobs in `EnvMisc`.

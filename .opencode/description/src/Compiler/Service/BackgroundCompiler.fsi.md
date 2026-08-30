# BackgroundCompiler.fsi

**Purpose**: Internal contract for the background-compiler API (`IBackgroundCompiler`) that both `BackgroundCompiler.fs` and `TransparentCompiler.fs` implement. Defines the exact surface `FSharpChecker` can call against either implementation, plus type aliases and a few internal helper modules.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## TypeDefs declared

- Aliases: `SourceTextHash = int64`, `CacheStamp = int64`, `FileName = string`, `FilePath = string`, `ProjectPath = string`, `FileVersion = int`.
- `FSharpProjectSnapshot = ProjectSnapshot.FSharpProjectSnapshot` (re-export alias).

## Interface declared

- **`IBackgroundCompiler`** (internal, abstract) — members (each with `?userOpName` in the .fs shape):
  - Check: `CheckFileInProject`, `CheckFileInProjectAllowingStaleCachedResults` (stale-tolerant, returns `option`).
  - Cache control: `ClearCache` (options seq / identifiers seq), `ClearCaches`, `DownsizeCaches`.
  - Queries: `FindReferencesInFile` (options / snapshot), `GetAssemblyData` (options / snapshot) → `ProjectAssemblyDataResult`, `GetBackgroundCheckResultsForFileInProject`, `GetBackgroundParseResultsForFileInProject`, `GetCachedCheckFileResult` (builder-scoped).
  - Scripts: `GetProjectOptionsFromScript`, `GetProjectSnapshotFromScript`.
  - Classification: `GetSemanticClassificationForFile` (options / snapshot) → `SemanticClassificationView option`.
  - Invalidation: `InvalidateConfiguration` (options / snapshot), `NotifyFileChanged`, `NotifyProjectCleaned`.
  - Parse-and-check: `ParseAndCheckFileInProject` (fileVersion form / snapshot form), `ParseAndCheckProject` (options / snapshot), `ParseFile` (ISourceText form / snapshot form).
  - Recent results: `TryGetRecentCheckResultsForFile` (options → `(parse * check * SourceTextHash) option`; snapshot → `(parse * check) option`).
  - Events: `BeforeBackgroundFileCheck`, `FileChecked`, `FileParsed`, `ProjectChecked`.
  - `FrameworkImportsCache`.

## Internal modules

- **`EnvMisc`** (AutoOpen) — cache-size defaults (`braceMatchCacheSize`, `parseFileCacheSize`, `checkFileInProjectCacheSize`, `projectCacheSizeDefault`, `frameworkTcImportsCacheStrongSize`); all overridable via `FCS_*` environment variables in the implementation.
- **`Helpers`** (AutoOpen) — key-equivalence predicates: `AreSameForChecking2`, `AreSubsumable2`, `AreSameForParsing`, `AreSimilarForParsing`, `AreSameForChecking3`, `AreSubsumable3`, and `NamesContainAttribute` (attribute-symbol name matching for fast find-references).

## Class declared

- **`BackgroundCompiler`** (internal) — `interface IBackgroundCompiler`; constructor takes the full option set (legacy reference resolver, cache sizes, flags, `getSource`, `useChangeNotifications`); static `ActualCheckFileCount`, `ActualParseFileCount` for tests.

## Public API surface

- None — the entire surface is internal. `FSharpChecker` (in `service.fsi`) is the public façade; this interface is what it delegates to.

## Significant internal logic (contract notes)

- **Two implementations**: `BackgroundCompiler.fs` and `TransparentCompiler.fs` both implement `IBackgroundCompiler`; `FSharpChecker` selects via `useTransparentCompiler`. The snapshot-based overloads are the newer workspace-era API.
- **Stale-result policy**: `CheckFileInProjectAllowingStaleCachedResults` returns `option` — `None` when the antecedent context isn't ready yet (caller can retry or wait for `FileChecked`).
- **Async boundary**: all long-running members return `Async`; events fire on background threads.
- **`GetCachedCheckFileResult`** is builder-scoped (takes an `IncrementalBuilder`) — an optimization for callers that already own a pipeline (e.g. `FSharpCheckProjectResults`).

## Cross-references

- Implemented by: `BackgroundCompiler.fs`, `TransparentCompiler.fs`.
- Consumers: `service.fs` (`FSharpChecker`), `FSharpWorkspaceQuery.fs` (via `FSharpChecker`), `TransparentCompiler.fsi`.
- Data types: `FSharpParseFileResults`/`FSharpCheckFileAnswer`/`FSharpCheckFileResults`/`FSharpProjectOptions` (`FSharpCheckerResults.fsi`), `FSharpProjectSnapshot` (`FSharpProjectSnapshot.fs`), `SemanticClassificationView` (`SemanticClassificationKey.fsi`).
- `FrameworkImportsCache` and `IncrementalBuilder` — `IncrementalBuild.fsi`.

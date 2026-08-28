# FSharpWorkspace.fs

**Purpose**: The entry point of the newer "workspace" model in FCS, where multiple projects share state in a single dependency graph. `FSharpWorkspace` is mutable-but-thread-safe, accepts incremental updates (projects, files) and exposes query access; it owns the `FSharpChecker` instance used to do the actual compilation work.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis.Workspace`

## Classes declared

- **`FSharpWorkspace`** (experimental) — holds:
  - `depGraph: IThreadSafeDependencyGraph<_, _>` (a `LockOperatedDependencyGraph` from `Internal.Utilities.DependencyGraph`),
  - `files: FSharpWorkspaceFiles`,
  - `projects: FSharpWorkspaceProjects(depGraph, files)`,
  - `query: FSharpWorkspaceQuery(depGraph, checker)`.
  - Public members: `Checker: FSharpChecker`, `Files`, `Projects`, `Query`. `DepGraph` is internal (exposed to sibling modules in the same file).

## Public API surface

- `new()` — parameterless constructor that creates a `FSharpChecker` with an aggressive feature set: `keepAllBackgroundResolutions = true`, `keepAllBackgroundSymbolUses = true`, `enableBackgroundItemKeyStoreAndSemanticClassification = true`, `enablePartialTypeChecking = true`, `parallelReferenceResolution = true`, `captureIdentifiersWhenParsing = true`, and `useTransparentCompiler = true`.
- `new(checker: FSharpChecker)` — reuse an existing checker.
- `Checker`, `Files` (Open/Edit/Close/OfProject), `Projects` (AddOrUpdate overloads, Update), `Query` (GetProjectSnapshot, GetParseAndCheckResultsForFile, GetDiagnosticsForFile, GetSemanticClassification, GetSource).

## Internal helpers

- `DepGraph` internal member shared across the workspace trio (state/query files), keeping a single lock-operated graph.

## Significant internal logic

- All cross-file state lives in the single dependency graph; `FSharpWorkspaceProjects.AddOrUpdate` and `Files.Open/Edit/Close` mutate it transactionally (see `FSharpWorkspaceState.fs`), and `FSharpWorkspaceQuery` reads from it (see `FSharpWorkspaceQuery.fs`).
- Choosing `useTransparentCompiler = true` in the default ctor shows the workspace is the primary driver of the new transparent background compiler path.
- The workspace is `Experimental`-attributed — API likely to change.

## Cross-references

- `FSharpWorkspaceState.fs` — `FSharpWorkspaceFiles`, `FSharpWorkspaceProjects` and the graph type vocabulary.
- `FSharpWorkspaceQuery.fs` — `FSharpWorkspaceQuery`, `FSharpDiagnosticReport`.
- Projects are compiled through `FSharpChecker` (see `service.fs`) → `TransparentCompiler`/`BackgroundCompiler` (see `BackgroundCompiler.fs`) → `IncrementalBuild` (see `IncrementalBuild.fs`).
- Data model: `FSharpProjectSnapshot`/`ProjectConfig` in `FSharpProjectSnapshot.fs`.

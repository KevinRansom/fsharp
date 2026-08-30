# FSharpWorkspaceQuery.fs

**Purpose**: Read-side of the F# workspace model: given a thread-safe dependency graph and an `FSharpChecker`, answer file- and project-scoped queries (snapshot lookup, parse+check results, diagnostics, semantic classification, raw source). Designed as the seam for LSP/server features.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis.Workspace` (module `FSharp.Compiler.CodeAnalysis.Workspace.FSharpWorkspaceQuery`)

## Types declared

- **`FSharpDiagnosticReport`** (experimental, internal ctor) — `Diagnostics: FSharpDiagnostic[]` plus `ResultId: string`, a unique id per document version so a client can clear superseded diagnostics.
- **`FSharpWorkspaceQuery`** (experimental, internal ctor) — takes `depGraph: IThreadSafeDependencyGraph<_, _>` and `checker: FSharpChecker`; keeps an `Interlocked` `resultIdCounter`.

## Public API surface

- `GetProjectSnapshot(projectIdentifier) : FSharpProjectSnapshot option` — from the graph; `KeyNotFoundException` → `None`.
- `GetProjectSnapshotForFile(file: Uri) : FSharpProjectSnapshot option` — first project containing the file (TODO in code: proper project selection may come from LSP project context).
- `GetParseAndCheckResultsForFile(file) : Async<(FSharpParseFileResults option * FSharpCheckFileResults option)>` — via `checker.ParseAndCheckFileInProject(path, snapshot)`; `Aborted` answer → parse result present, check result `None`.
- `GetCheckResultsForFile(file)` — `GetParseAndCheckResultsForFile >>> snd`.
- `GetDiagnosticsForFile(file)` — returns an `FSharpDiagnosticReport`; check diagnostics if available else parse diagnostics (TODO: split parse vs check).
- `GetSemanticClassification(file)` — checker's `GetBackgroundSemanticClassificationForFile` on the containing snapshot.
- `GetSource(file) : Task<ISourceTextNew option>` — reads the source file snapshot from the graph.
- Internal: `Checker`, `getDiagnosticResultId`.

## Internal helpers / active patterns

- Per-call `Activity.start` spans with `Activity.Tags.project`/`fileName` tags — instrumentation hook (OpenTelemetry-style) on every query method.

## Significant internal logic

- Result IDs are monotonically increasing integers formatted as strings — deliberately simple ("important that the result id is unique every time in order to be able to clear previous diagnostics").
- `GetProjectSnapshotForFile` currently picks the first containing project — a known limitation documented in the source TODOs.
- `Aborted` check answers are mapped to `Some parseResult, None` so callers still get parse diagnostics.

## Cross-references

- Graph operations come from `WorkspaceDependencyGraphExtensions` in `FSharpWorkspaceState.fs` (`GetProjectsContaining`, `GetSourceFile`, `GetProjectSnapshot`).
- Delegates compilation to `FSharpChecker` (see `service.fs`/`service.fsi`) — specifically the snapshot overloads of `ParseAndCheckFileInProject` and `GetBackgroundSemanticClassificationForFile`.
- Instantiated by `FSharpWorkspace` (see `FSharpWorkspace.fs`); semantic classification payload types from `SemanticClassification.fsi`.

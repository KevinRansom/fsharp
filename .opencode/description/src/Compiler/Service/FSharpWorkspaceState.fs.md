# FSharpWorkspaceState.fs

**Purpose**: Write/state side of the F# workspace model. Defines the node vocabulary of the workspace dependency graph, the extension-method layer that constrains what can be added to it, and the two public-facing state managers — `FSharpWorkspaceFiles` (Open/Edit/Close) and `FSharpWorkspaceProjects` (AddOrUpdate/Update) — which keep the graph consistent as projects and files change.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis.Workspace` (module `FSharp.Compiler.CodeAnalysis.Workspace.FSharpWorkspaceState`)

## Modules / Types declared

- **`module WorkspaceGraphTypes`** (internal)
  - `ProjectWithoutFiles = ProjectConfig * FSharpReferencedProjectSnapshot list`
  - `WorkspaceNodeKey` — `SourceFile path`, `ReferenceOnDisk path`, `ProjectConfig id`, `ProjectWithoutFiles id`, `ProjectSnapshot id`.
  - `WorkspaceNodeValue` — matching value nodes: `SourceFile of FSharpFileSnapshot`, `ReferenceOnDisk`, `ProjectConfig`, `ProjectWithoutFiles`, `ProjectSnapshot of FSharpProjectSnapshot`.
  - `module WorkspaceNode` — pattern "unpackers" (`projectConfig`, `projectSnapshot`, `sourceFile`, ... and `*Key` variants) used by the graph extensions to safely `Unpack` typed values.
- **`module WorkspaceDependencyGraphExtensions`** (internal, `[<AutoOpen>]`) — `WorkspaceDependencyGraphTypeExtensions` with extension methods: `AddOrUpdateFile`, `AddFiles`, `AddReferencesOnDisk`, `AddProjectConfig`, `AddProjectWithoutFiles`, `AddSourceFiles`, `AddProjectSnapshot`, `AddProjectReference`, `RemoveProjectReference`, `GetProjectSnapshot`, `GetProjectReferencesOf`, `GetProjectsThatReference`, `GetProjectsContaining`, `GetSourceFile`, `GetFilesOf`, `ReplaceSourceFiles`. All unsafe unpacking happens here.
- **`FSharpWorkspaceFiles`** (experimental, internal ctor) — `openFiles: ConcurrentDictionary<string, string>`; `Open`/`Edit` upsert in-memory content and update the graph's `SourceFile` node (`FSharpFileSnapshot.CreateFromString`); `Close` removes from `openFiles` and re-binds the node from the file system (unsaved changes are undone); `OfProject(projectIdentifier)`; internal `GetFileContentIfOpen`.
- **`FSharpWorkspaceProjects`** (experimental, internal ctor) — `outputPathMap: ConcurrentDictionary<string, FSharpProjectIdentifier>` (output path → project id, used to detect project references). Overloads of `Update` and `AddOrUpdate` (`ProjectConfig + sourceFilePaths`, `... + Uri seq`, `projectPath + outputPath + compilerArgs` [splits args into `-r:` references, `.fs/.fsi/.fsx` source files, and other options], and the 5-arg form). Internal: `Debug_DumpGraphOnEveryChange` / `Debug_DumpMermaid(path)` for graph visualization, `files`.

## Public API surface

- `FSharpWorkspaceFiles.Open/Edit/Close/OfProject`, `FSharpWorkspaceProjects.AddOrUpdate` (4 overloads) and `Update` — all marked `[<Experimental>]`.

## Internal helpers / active patterns

- The `WorkspaceNode.*` unpacker functions — one per node flavor — keep generic graph code type-safe.
- `Activity.start` spans with project/source-file tags on every mutation.
- `depGraph.Transact` — atomic multi-step updates (add project node, reconcile references, add dependent references).

## Significant internal logic

- **Layered node derivation**: `ReferenceOnDisk`/`SourceFile` → `ProjectConfig` (with resolved on-disk references) → `ProjectWithoutFiles` (wrapping referenced-project snapshots into `FSharpReferencedProjectSnapshot.FSharpReference`) → `ProjectSnapshot` (adds source files, builds `FSharpProjectSnapshot`). Re-adding the same project identifier updates the chain and the graph invalidates only what changed.
- **Project reference reconciliation** in `AddOrUpdate`: set-difference between existing and newly-discovered references (matched by output path via `outputPathMap`) drives `RemoveProjectReference`/`AddProjectReference`; projects that *reference this project's output* also get a reference edge added.
- **`ReplaceSourceFiles`** removes old file dependencies of the `ProjectSnapshot` node and re-adds the new set — used by `Update` (keeping existing in-memory snapshots for files still present).
- File content preference: `createFileSnapshot` uses the in-memory `openFiles` content if the file is open, otherwise `FSharpFileSnapshot.CreateFromFileSystem`.
- Debug hook: optional Mermaid dump of the graph on every change (reference nodes collapsed to `"..."`).

## Cross-references

- Node data types: `FSharpFileSnapshot`, `ReferenceOnDisk`, `ProjectConfig`, `FSharpProjectSnapshot`, `FSharpProjectIdentifier` — `FSharpProjectSnapshot.fs`.
- Graph consumed by `FSharpWorkspaceQuery.fs`; instantiated by `FSharpWorkspace.fs`.
- Graph library: `Internal.Utilities.DependencyGraph` (`LockOperatedDependencyGraph`, `GraphBuilder`, `AddOrUpdateNode`, `AddDependentNode`, `AddList`).

# TransparentCompiler.fsi

## Pipeline role

This file belongs to the Service folder of the F# compiler. It defines the public (and internal) surface of the "transparent compiler" — the graph-based type-checking backend used by FCS (`FSharp.Compiler.CodeAnalysis.TransparentCompiler`). Whereas the classic `BackgroundCompiler` buffers type-check requests through an incremental builder keyed on on-disk files and options, the transparent compiler is a project-snapshot based engine: everything flows from a `ProjectSnapshot` describing files, references and command-line options, applies `GraphChecking`-style parallel type checking over a dependency graph, and memoizes intermediate results (parse, type-check, dependency graph, script closure, assembly data, semantic classification, item-key store) through a set of strongly/weakly sized `AsyncMemoize` caches. `CacheSizes` and the caching knobs are exposed here; the `TransparentCompiler` class itself implements `IBackgroundCompiler` and is the drop-in replacement compiler for `FSharpChecker`.

## Namespaces, opens

- Namespace `FSharp.Compiler.CodeAnalysis.TransparentCompiler`.
- Opens `Internal.Utilities.Collections`, plus, among others, `FSharp.Compiler.AbstractIL.ILBinaryReader`, `FSharp.Compiler.CodeAnalysis`, `CompilerConfig`, `CompilerImports`, `CheckBasics`, `Diagnostics`, `DiagnosticsLogger`, `ScriptClosure`, `Symbols`, `TcGlobals`, `Text`, `ParseAndCheckInputs`, `GraphChecking`, `Syntax`, `NameResolution`, `TypedTree`, `CheckDeclarations`, `EditorServices`, and `FSharp.Compiler.CodeAnalysis.ProjectSnapshot`.

## Internal types

### `TcInfo`

`[<NoEquality; NoComparison>]` record — the minimum accumulated state needed to continue type-checking following files:

- `tcState: TcState` — current type-check state.
- `tcEnvAtEndOfFile: TcEnv` — environment at the end of the last checked file.
- `moduleNamesDict: ModuleNamesDict` — disambiguation table for module names.
- `topAttribs: TopAttribs option`.
- `latestCcuSigForFile: ModuleOrNamespaceType option`.
- `tcDiagnosticsRev: PhasedDiagnostic[] list` — accumulated diagnostics, last file first.
- `tcDependencyFiles: string list`.
- `sigNameOpt: (string * QualifiedNameOfFile) option`.
- `graphNode: NodeToTypeCheck option`.
- `stateContainsNodes: Set<NodeToTypeCheck>`.
- `sink: TcResultsSinkImpl list`.

### `TcIntermediate`

`[<NoEquality; NoComparison>]` record — the per-file result of type checking held between the check and the final fold:

- `finisher: Finisher<NodeToTypeCheck, TcState, PartialResult>` — deferred completion step applied when folding this file into the final `TcInfo`.
- `moduleNamesDict: ModuleNamesDict`.
- `tcDiagnosticsRev: PhasedDiagnostic array list` — accumulated diagnostics, last file first.
- `tcDependencyFiles: string list`.
- `sink: TcResultsSinkImpl`.

### `BootstrapInfo`

`[<NoEquality; NoComparison>]` record — everything needed to start parsing and checking files for a given project snapshot:

- `Id: int` — unique instance id; partial type-check results from different instances are incompatible, so a new id invalidates all type-check caching.
- `AssemblyName: string`; `OutFile: string`.
- `TcConfig: TcConfig`; `TcImports: TcImports`; `TcGlobals: TcGlobals`.
- `InitialTcInfo: TcInfo` — the imported-assemblies/graph-node type state to start from.
- `LoadedSources: (range * FSharpFileSnapshot) list` — sources loaded via `#load`.
- `LoadClosure: LoadClosure option`.
- `LastFileName: string`.
- `ImportsInvalidatedByTypeProvider: Event<unit>` — fired when any type-provider-held CCU is invalidated; wired (weakly) into `CombineImportedAssembliesTask`.

### `TcIntermediateResult`

Type abbreviation: `TcInfo * TcResultsSinkImpl * CheckedImplFile option * string` — the per-file fold result tuple `(tcInfo, sink, checkedImplFile, fileName)`.

### `DependencyGraphType`

`[<RequireQualifiedAccess>]` union describing the extent of a cached dependency graph.

- `File` — a dependency graph for a single file; missing files this file does not depend on.
- `Project` — a dependency graph for the whole project; contains all files.

### `Extensions`

`[<System.Runtime.CompilerServices.Extension; Class>]` internal static class:

- Extension member `Key` — `fileSnapshots: #IFileSnapshot list * ?extraKeyFlag: DependencyGraphType -> ICacheKey<DependencyGraphType option * byte array, string>`, building a cache key (label = "N files ending with <last>"; key = md5 of file names + optional `extraKeyFlag`; version = string hash of file versions).

## Public types

### `CacheSizes`

`[<Experimental("This FCS type is experimental and will likely change or be removed in the future.")>]` record of 31 strongly/weakly cache-size fields, one pair per cache:

- `ParseFile`, `ParseFileWithoutProject`, `ParseAndCheckFileInProject`, `ParseAndCheckAllFilesInProject`, `ParseAndCheckProject`, `FrameworkImports`, `BootstrapInfoStatic`, `BootstrapInfo`, `TcLastFile`, `TcIntermediate`, `DependencyGraph`, `ProjectExtras`, `AssemblyData`, `SemanticClassification`, `ItemKeyStore`, `ScriptClosure` — each with `*KeepStrongly` and `*KeepWeakly` int fields.

- `static member Create: sizeFactor: int -> CacheSizes` — instantiates sizes as multiples of the factor (e.g. `ParseFile` = 50×, `TcIntermediate` = 20×, most others = 1×/2×; `ParseFileKeepWeakly` is hard-coded 0 so parsing is redone after undo for `WarnScopes`).

## Internal types (continued)

### `CompilerCaches`

Internal class, `new: cacheSizes: CacheSizes -> CompilerCaches`. Exposes one memoize per cache:

- `ParseFile: AsyncMemoize<FSharpProjectIdentifier * string, string * string * bool, FSharpParsedFile>`.
- `ParseFileWithoutProject: AsyncMemoize<string, string, FSharpParseFileResults>`.
- `ParseAndCheckFileInProject: AsyncMemoize<string * FSharpProjectIdentifier, string * string, FSharpParseFileResults * FSharpCheckFileAnswer>`.
- `ParseAndCheckAllFilesInProject: AsyncMemoizeDisabled<obj, obj, obj>` (disabled).
- `ParseAndCheckProject: AsyncMemoize<FSharpProjectIdentifier, string, FSharpCheckProjectResults>`.
- `FrameworkImports: AsyncMemoize<string, FrameworkImportsCacheKey, TcGlobals * TcImports>`.
- `BootstrapInfoStatic: AsyncMemoize<FSharpProjectIdentifier, string * string, int * TcImports * TcGlobals * TcInfo * Event<unit>>`.
- `BootstrapInfo: AsyncMemoize<FSharpProjectIdentifier, string, BootstrapInfo option * FSharpDiagnostic array>`.
- `TcLastFile: AsyncMemoizeDisabled<obj, obj, obj>` (disabled).
- `TcIntermediate: AsyncMemoize<string * FSharpProjectIdentifier, string * int, TcIntermediate>`.
- `DependencyGraph: AsyncMemoize<DependencyGraphType option * byte array, string, Graph<NodeToTypeCheck> * Graph<FileIndex>>`.
- `ProjectExtras: AsyncMemoizeDisabled<obj, obj, obj>` (disabled).
- `AssemblyData: AsyncMemoize<FSharpProjectIdentifier, string * string, ProjectAssemblyDataResult>`.
- `SemanticClassification: AsyncMemoize<string * FSharpProjectIdentifier, string, SemanticClassificationView option>`.
- `ItemKeyStore: AsyncMemoize<string * FSharpProjectIdentifier, string, ItemKeyStore option>`.
- `ScriptClosure: AsyncMemoize<string * FSharpProjectIdentifier, string, LoadClosure>`.
- `CacheSizes: CacheSizes` — the configured sizes.

### `TransparentCompiler`

Internal class implementing `IBackgroundCompiler`. Constructor takes the full interpreter backend configuration: `legacyReferenceResolver`, `projectCacheSize`, `keepAssemblyContents`, `keepAllBackgroundResolutions`, `tryGetMetadataSnapshot`, `suggestNamesForErrors`, `keepAllBackgroundSymbolUses`, `enableBackgroundItemKeyStoreAndSemanticClassification`, `enablePartialTypeChecking`, `parallelReferenceResolution`, `captureIdentifiersWhenParsing`, `getSource` (custom `(string -> Async<ISourceText option>)` or `None` for the file system), `useChangeNotifications`, optional `?cacheSizes: CacheSizes`.

Additional public members (the `.fs` adds more): `FindReferencesInFile: fileName * ProjectSnapshot.ProjectSnapshot * symbol: FSharpSymbol * userOpName -> Async<range seq>`; `GetAssemblyData: ProjectSnapshot.ProjectSnapshot * fileName * _userOpName -> Async<ProjectAssemblyDataResult>`; `ParseAndCheckFileInProject: fileName * ProjectSnapshot.ProjectSnapshot * userOpName -> Async<FSharpParseFileResults * FSharpCheckFileAnswer>`; `ParseFile: fileName * ProjectSnapshot.ProjectSnapshot * _userOpName -> Async<FSharpParseFileResults>`; `SetCacheSize: cacheSize: CacheSizes -> unit` (recreates the `CompilerCaches` if different); `SetCacheSizeFactor: sizeFactor: int -> unit`; `Caches: CompilerCaches`.
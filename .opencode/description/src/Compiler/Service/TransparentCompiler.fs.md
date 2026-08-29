# TransparentCompiler.fs

## Pipeline role

This file belongs to the Service folder of the F# compiler. It is the implementation behind `TransparentCompiler.fsi`: the snapshot-based, graph-parallel type-checking engine of FCS. It replaces the classic incremental-builder pipeline: given a `ProjectSnapshot` (source files + references + command-line options), it (1) computes "bootstrap" information (TcConfig, TcImports, TcGlobals, initial `TcInfo`), (2) parses all files in parallel, (3) computes a dependency graph (`Graph<FileIndex>` / `Graph<NodeToTypeCheck>`) — degenerate linear for FSharp.Core, otherwise via the `GraphChecking` engine — (4) type-checks the graph bottom-up in parallel, carrying `TcInfo` state between nodes, and (5) materializes the requested results (check-file, check-project, assembly data, semantic classification, item-key store, find-references, script closure). All intermediate computations are memoized in `CompilerCaches` keyed by content hashes/versions with tunable strong/weak retention, so repeated requests for the same file version hit the cache. A legacy `BackgroundCompiler` instance is retained solely for delegating "not-yet-implemented" tasks and legacy events.

## Namespaces, opens

- Namespace `FSharp.Compiler.CodeAnalysis.TransparentCompiler`.
- Opens `System`, `System.Linq`, `System.Collections.Generic`, `System.Runtime.CompilerServices`, `System.Diagnostics`, `System.IO`, `Internal.Utilities.Collections`, `Internal.Utilities.Library` (and `.Extras`), `FSharp.Compiler`, `FSharp.Compiler.AbstractIL.IL` / `ILBinaryReader`, `CodeAnalysis`, `CompilerConfig`, `CompilerImports`, `CompilerOptions`, `CheckBasics`, `DependencyManager`, `Diagnostics`, `DiagnosticsLogger`, `IO`, `ScriptClosure`, `Symbols`, `TcGlobals`, `Text` (and `Text.Range`), `Xml`, `System.Threading.Tasks`, `ParseAndCheckInputs`, `GraphChecking`, `Syntax`, `CompilerDiagnostics`, `NameResolution`, `TypedTree`, `CheckDeclarations`, `EditorServices`, `CreateILModule`, `TypedTreeOps`, `System.Threading`, `Internal.Utilities.Hashing`, `FSharp.Compiler.CodeAnalysis.ProjectSnapshot`.

## Internal types

### `TcInfo`

`[<NoEquality; NoComparison>]` record (same fields as in the signature) plus an extra member present only here:

- `member x.TcDiagnostics = Array.concat (List.rev x.tcDiagnosticsRev)` — flattened diagnostics in source order (diagnostics accumulate reversed, last file first).

### `TcIntermediate`

`[<NoEquality; NoComparison>]` record — same fields as the signature; carries the deferred `Finisher`, updated `moduleNamesDict`, per-file diagnostics, dependency files and the fresh `TcResultsSinkImpl`.

### `BootstrapInfo`

`[<NoEquality; NoComparison>]` record — same fields as the signature. The `Id`-counter warning is documented: partial type-check results using different instances are incompatible, so the `bootstrapId` (`BootstrapInfoIdCounter`) is folded into the `TcIntermediate` cache key; recreating bootstrap info forces a full recheck.

### `TcIntermediateResult`

Alias `TcInfo * TcResultsSinkImpl * CheckedImplFile option * string`.

### `DependencyGraphType`

`[<RequireQualifiedAccess>]` union `File` / `Project` used only in the `Extensions.Key` cache key.

### `Extensions`

`[<Extension>]` internal static class with the extension member:

- `Key<'T when 'T :> IFileSnapshot>(fileSnapshots: 'T list, ?extraKeyFlag)` → `ICacheKey<_, _>`:
  - `GetLabel()` — `"{N} files ending with {lastFile}"` (last file's name via `shortPath`).
  - `GetKey()` — `Md5Hasher` over all file names, hashed together with the optional `extraKeyFlag`.
  - `GetVersion()` — string hash of the file versions (`Md5Hasher.addBytes' fileSnapshot.Version`).

## Internal module `TypeCheckingGraphProcessing`

`[<AutoOpen>] module private TypeCheckingGraphProcessing` — opens `FSharp.Compiler.GraphChecking.GraphProcessing` and contains two workhorses:

- `combineResults (emptyState: TcInfo) (deps: ProcessedNode<_, _> array) (transitiveDeps: ProcessedNode<_, _> array) (folder: TcInfo -> Finisher<NodeToTypeCheck, TcInfo, PartialResult> -> TcInfo) : TcInfo` — combines the type-check results of the dependencies needed for a higher graph node. Optimization: instead of folding from the empty state, it starts from the state of the dependency with the *most* transitive dependencies (biggestState), then folds in only the results not already present, ordered so `PhysicalFile` nodes precede `ArtificialImplFile` nodes and nodes are sorted by index.
- `processTypeCheckingGraph (graph: Graph<NodeToTypeCheck>) (work: NodeToTypeCheck -> TcInfo -> Async<Finisher<NodeToTypeCheck, TcInfo, PartialResult>>) (emptyState: TcInfo) : Async<(int * PartialResult) list * TcInfo>` — a type-checking-specific version of `GraphProcessing.processGraphAsync`. A `workWrapper` folds each node's dependencies into the input `TcInfo` (excluding the node itself), runs `work`, then runs the resulting single `Finisher` against the input state to produce the node's output state + result. After the parallel graph pass, it folds the per-file finishers in order (`finisher state`), skipping `ArtificialImplFile` results, and returns `finalFileResults` (physical-file index, file result) and the final `TcInfo`.

## Public type `CacheSizes`

Record of the same 31 strongly/weakly size fields as in the signature. Members:

- `static member Create sizeFactor` — builds the record (e.g. `ParseFileKeepStrongly = 50 * sizeFactor`, `ParseFileKeepWeakly = 0`, `ParseAndCheckFileInProjectKeepStrongly = sizeFactor`, `TcIntermediate* = 20 * sizeFactor`, most others `1×`/`2×`, weak usually `2× strong`).
- `static member Default` — `CacheSizes.Create 100`.

## Internal class `CompilerCaches(cacheSizes: CacheSizes)`

Property-style constructed `AsyncMemoize` instances for every cache stage (`member val … = AsyncMemoize(…)` with names like "ParseFile", "ParseAndCheckFileInProject", "ParseAndCheckFullProject", "FrameworkImports", "BootstrapInfoStatic", "BootstrapInfo", "TcLastFile" (disabled), "TcIntermediate", "DependencyGraph", "ProjectExtras" (disabled), "AssemblyData", "SemanticClassification", "ItemKeyStore", "ScriptClosure"). Types match the signature. Additional member not in the signature:

- `member this.Clear(projects: Set<FSharpProjectIdentifier>)` — clears all project-scoped caches for the given identifiers (`ParseFile`/`ParseAndCheckFileInProject` keyed on `fst`/`snd` respectively, `ParseAndCheckProject`, `BootstrapInfoStatic`, `BootstrapInfo`, `TcIntermediate` (snd), `AssemblyData`, `SemanticClassification`/`ItemKeyStore`/`ScriptClosure` (snd)).

## Internal class `TransparentCompiler`

Constructed with all backend flags (see signature). Instance setup:

- `documentSource` — `DocumentSource.Custom getSource` or `DocumentSource.FileSystem`.
- `lexResourceManager = Lexhelp.LexResourceManager()`.
- `cacheSizes = defaultArg cacheSizes CacheSizes.Default`; `let mutable caches = CompilerCaches(cacheSizes)`.
- `dependencyProviderForScripts = new DependencyProvider()` (one shared provider for all scripts, per-project provider otherwise).
- Legacy events `beforeFileChecked`, `fileParsed`, `fileChecked` (all `Event<string * FSharpProjectOptions>`), `projectChecked` (`Event<FSharpProjectOptions>`) — published via `IBackgroundCompiler`, used in tests.
- `backgroundCompiler` — a `BackgroundCompiler` instance boxed to `IBackgroundCompiler` for delegating not-yet-implemented tasks (and for `FrameworkImportsCache`, invalidation, notifications, recent-check-results).
- `BootstrapInfoIdCounter` mutable counter (interlocked).

### Private computation helpers

- `ComputeScriptClosureInner` — creates the `LoadClosure` for a script via `LoadClosure.ComputeClosureOfScriptText`, applying fsi compiler options (`--compilertool`? no: `GetCoreFsiCompilerOptions` + `ParseCompilerOptions`) with `errorRecovery`, using `ReduceMemoryFlag.Yes`, `CodeContext.Editing`, and the shared `dependencyProviderForScripts`.
- `mkScriptClosureCacheKey` — builds a `ICacheKey<string * FSharpProjectIdentifier, string>` whose version hashes `otherOptions`, an optional stamp, the source checksum, and the `useSimpleResolution`/`useFsiAuxLib`/`useSdkRefs`/`assumeDotNetFramework` flags.
- `ComputeScriptClosure` — `ComputeScriptClosureInner` memoized through `caches.ScriptClosure` (defaults `useFsiAuxLib`/`useSdkRefs` true, `assumeDotNetFramework` false).
- `ComputeFrameworkImports tcConfig frameworkDLLs nonFrameworkResolutions` — memoized via `caches.FrameworkImports` keyed by `FrameworkImportsCacheKey` (sorted resolved paths, primary assembly name, target framework dirs, fsharpBinariesDir, langVersion, checkNullness); computes `TcGlobals` + framework `TcImports` via `TcImports.BuildFrameworkTcImports`.
- `CombineImportedAssembliesTask …` — links all assemblies to produce the initial type-check accumulator:
  - Builds non-framework `TcImports` (`TcImports.BuildNonFrameworkTcImports`) under a `CompilationGlobalsScope(CompilationDiagnosticLogger("CombineImportedAssembliesTask"), BuildPhase.Parameter)`; on `OperationCanceledException` returns just the framework imports, on other exceptions asserts + warns.
  - Unless `NO_TYPEPROVIDERS`, subscribes to each non-base CCU's `InvalidateEvent` via a `WeakReference<_>` to the `importsInvalidatedByTypeProvider` event, so invalidation triggers a rebuild (handler captures only the weak ref to avoid leaking the TP instance).
  - Computes `GetInitialTcEnv`/`GetInitialTcState` (initial `TcEnv`, `TcState`), folds `LoadClosure` meta-command diagnostics + logger diagnostics into `initialErrors`, and produces the base `tcInfo` (`topAttribs = None`, `moduleNamesDict = Map.empty`, `tcDependencyFiles = basicDependencies`, `sink = []`, empty `stateContainsNodes`).
- `getProjectReferences (project: ProjectSnapshotBase<_>) userOpName` — materializes each referenced project as an `IProjectReference`:
  - `FSharpReference` to another snapshot → an `IProjectReference` whose `EvaluateRawContents()` delegates to `self.GetAssemblyData(snapshot, nm, …)` (cross-project refs; FSharp.Core references are skipped — `GetFSharpCoreLibraryName()` check — so FSharp.Core must exist on disk, as in VisualFSharp.sln/FSharp.sln), `TryGetLogicalTimeStamp` → `None`.
  - `PEReference(getStamp, delayedReader)` → a ref evaluating a lazily-read IL module into `RawFSharpAssemblyData` (`Available`), falling back to `Unavailable false` when no reader; timestamp = `getStamp () |> Some`.
  - `ILModuleReference(nm, getStamp, getReader)` → similar, always evaluating `getReader()` into raw data.
- `ComputeTcConfigBuilder (projectSnapshot: ProjectSnapshot)` — builds the `TcConfigBuilder`: copies `--simpleresolution` switch; computes script load closure when the last source file is a script and `UseScriptResolutionRules` (via `ComputeScriptClosure`); creates the builder with script-relevant settings; sets `primaryAssembly` (Mscorlib or System.Runtime from the closure), `resolutionEnvironment` (`LegacyResolutionEnvironment.EditingOrCompilation true`), conditional `INTERACTIVE`/`COMPILED` define, `--realsig` flag, project references, simple resolution, applies command-line arguments via `ApplyCommandLineArgs` (wrapping errors with `errorRecovery`), disables PDB opening, installs an `IXmlDocumentationInfoLoader` that maps assembly → `.xml` doc file, sets `parallelReferenceResolution` and `captureIdentifiersWhenParsing`. Returns `tcConfigB, sourceFiles, loadClosureOpt`.
- `ComputeBootstrapInfoStatic (projectSnapshot, tcConfig, assemblyName, loadClosureOpt)` — memoized on a project-level cache key (using `projectSnapshot.BaseCacheKeyWith("BootstrapInfoStatic", assemblyName)`):
  - Splits references with `TcAssemblyResolutions.SplitNonFoundationalResolutions`; computes `tcGlobals`/framework imports; re-creates `TcGlobals` if the cached one's `langVersion`/`realsig` differ from the config's.
  - Computes `basicDependencies` from unresolved references (rooted against `ProjectDirectory`) + non-framework resolutions.
  - Chooses the `DependencyProvider` (shared for scripts, new per project).
  - Calls `CombineImportedAssembliesTask` to get `tcImports, initialTcInfo`; increments the bootstrap id; and, on type-provider invalidation (`importsInvalidatedByTypeProvider.Publish`), clears the whole project cache via `caches.Clear(Set.singleton projectSnapshot.Identifier)`.
  - Returns `bootstrapId, tcImports, tcGlobals, initialTcInfo, importsInvalidatedByTypeProvider`.
- `computeBootstrapInfoInner (projectSnapshot)` — runs `ComputeTcConfigBuilder`; for scripts re-applies the load-closure-derived settings (`setupConfigFromLoadClosure`: substitutes `LoadClosure.References` resolutions into `referencedDLLs`, sets primary assembly and `knownUnresolvedReferences`); creates the validated `TcConfig`, decides names (`DecideNames` → outFile, assemblyName); loads `#load`'d sources as `FSharpFileSnapshot`s; returns a `BootstrapInfo` (or `None` when no source files).
- `ComputeBootstrapInfo (projectSnapshot)` — memoized on the project's `NoFileVersionsKey`; captures diagnostics via `CapturingDiagnosticsLogger("IncrementalBuilderCreation")` under a `CompilationGlobalsScope(BuildPhase.Parameter)`, converting them to `FSharpDiagnostic`s (with `suggestNamesForErrors` and flat-errors). Returns `BootstrapInfo option * FSharpDiagnostic array`.
- `LoadSource (file) isExe isLastCompiland` — reads a snapshot's source, producing `FSharpFileSnapshotWithSource` (with content checksum).
- `LoadSources (bootstrapInfo) (projectSnapshot)` — loads all project source files in parallel (`MultipleDiagnosticsLoggers.Parallel`), marking the last compiland and exe-ness, returning `ProjectSnapshotWithSources`.
- `ComputeParseFile (projectSnapshot) (tcConfig) (file)` — memoized parse under the parse cache key (identifier + file name, versioned by `ParsingVersion`, `file.StringVersion`, and "last compiland && exe"): builds a `CompilationDiagnosticLogger("Parse")` + `CompilationGlobalsScope(BuildPhase.Parse)`, calls `ParseOneInputSourceText`, fires the legacy `fileParsed` event, and returns `FSharpParsedFile(fileName, inputHash=file.Version, sourceText, input, parse diagnostics)`.
- `mkLinearGraph count` — builds the degenerate `Graph<FileIndex>` (each file depends on its predecessor) used when `tcConfig.compilingFSharpCore`.
- `computeDependencyGraph (tcConfig) parsedInputs (processGraph)` — wraps parsed inputs as `FileInProject` records, builds the `FilePairMap`, produces dependency `graph` (linear for FSharp.Core, else `DependencyResolution.mkGraph`), transforms it via `TransformDependencyGraph` into `Graph<NodeToTypeCheck>`; both graphs serialized to Mermaid and tagged for activity tracing.
- `removeImplFilesThatHaveSignaturesExceptLastOne` — removes impl files that have an accompanying `.fsi`, except for the project's last file (handles the `.fsi`→`.fs` name pairing via `.Substring(0, len-1)`).
- `ComputeDependencyGraphForFile (tcConfig) priorSnapshot` — memoized single-file graph (key = `priorSnapshot.SourceFiles.Key(DependencyGraphType.File)`), applying `removeImplFilesThatHaveSignaturesExceptLastOne` as the graph processor.
- `ComputeDependencyGraphForProject (tcConfig) projectSnapshot` — memoized full-project graph (key = `Key(DependencyGraphType.Project)`), processor `id`.
- `ComputeTcIntermediate projectSnapshot dependencyGraph index nodeToCheck bootstrapInfo prevTcInfo` — memoized per-file "up to this point" type check (key = file key with extra `bootstrapInfo.Id` version):
  - Reads the file's parsed input; sets up `ParseAndCheckFile.DiagnosticsHandler`-based diagnostics logger (filtered with `GetDiagnosticsLoggerFilteringByScopedNowarn`) under `BuildPhase.TypeCheck`; applies meta-commands via `ApplyMetaCommandsFromInputToTcConfig`; creates `TcResultsSinkImpl(tcGlobals, sourceText)`; skips apparent type errors when the file had parse errors (`hadParseErrors`); deduplicates module names with `DeduplicateParsedInputModuleName prevTcInfo.moduleNamesDict input`; runs `CheckOneInputWithCallback` with the callback "stop-if-errors" function and `TcResultsSink.WithSink sink`, converting to async; fires `beforeFileChecked`/`fileChecked`; returns a `TcIntermediate` (finisher, updated `moduleNamesDict`, per-file diagnostics, `tcDependencyFiles = [fileName]`, sink).
- `processGraphNode projectSnapshot bootstrapInfo dependencyFiles collectSinks (fileNode) tcInfo` — builds each node's `Finisher`:
  - `PhysicalFile index` — first computes the `TcIntermediate`, then returns a `Finisher(node, folder)` that, when the file's turn comes, runs the deferred finisher on `tcInfo.tcState`, extracts `(tcEnv, topAttribs, checkImplFileOpt, ccuSigForFile)`, chooses `tcEnvAtEndOfFile` (`tcEnv` when `keepAllBackgroundResolutions`, else `tcState.TcEnvFromImpls`), rebuilds `tcInfo` (new `tcState`, `tcEnvAtEndOfFile`, `moduleNamesDict`, `topAttribs = Some`, diagnostics/dependency files prepended, `latestCcuSigForFile`, `graphNode`, `stateContainsNodes` + node, and the sink list — `tcIntermediate.sink :: tcInfo.sink` when collecting, else `[sink]`).
  - `ArtificialImplFile index` — the finisher applies `AddSignatureResultToTcImplEnv` (implanting the signature into `TcEnvFromImpls`), and otherwise updates the state identically.
- `parseSourceFiles (projectSnapshotWithSources) tcConfig` — parses all sources in parallel (`ComputeParseFile`), producing a `ProjectSnapshotBase<_>` of parsed files.
- `ComputeTcLastFile (bootstrapInfo) (projectSnapshotWithSources)` — memoized (disabled cache: `TcLastFile`): parses sources, computes the single-file dependency graph, runs `processTypeCheckingGraph` with `collectSinks=false`, and returns `(lastResult, tcInfo)` where `lastResult = results |> List.head |> snd`.
- `getParseResult projectSnapshot creationDiags file tcConfig` — converts a parsed file into a public `FSharpParseFileResults` (combining diagnostic transmission: `creationDiags` + created diagnostics, `parseHadErrors`, empty dependency files placeholder).
- `emptyParseResult fileName diagnostics` — an empty `FSharpParseFileResults` over `EmptyParsedInput` with `parseHadErrors = true` (used when bootstrap fails/cancels).
- `ComputeParseAndCheckFileInProject (fileName) (projectSnapshot)` — the main check-file pipeline, memoized on `FileKeyWithExtraFileSnapshotVersion`:
  - Runs `ComputeBootstrapInfo`; on `None` returns `emptyParseResult + Aborted`.
  - Otherwise, loads sources for the project truncated at `fileName` (`projectSnapshot.UpTo fileName`), gets the last file's parse result, computes `TcLastFile`, and extracts the `TcEnv`/`topAttribs`/`ccuSigForFile`/`tcState`; the sink's `GetResolutions()/GetSymbolUses()/GetOpenDeclarations()`.
  - Creates diagnostics (tc + extra diagnostics captured while formatting, under `CapturingDiagnosticsLogger("DiagnosticsWhileCreatingDiagnostics")`, with `SymbolEnv`).
  - Computes the script closure for the checked file via `ComputeScriptClosure` (for dependency files), then builds `FSharpCheckFileResults.Make(…)` with resolutions, symbol uses, open declarations, and the checked impl file; succeeds with `FSharpCheckFileAnswer.Succeeded`.
- `ComputeParseAndCheckAllFilesInProject (bootstrapInfo) (projectSnapshotWithSources)` — memoized (disabled): parses all sources, collects all parse diagnostics, computes the full project graph, and runs `processTypeCheckingGraph` with `collectSinks=true`; returns `(results, tcInfo, parseDiagnostics)`.
- `TryGetRecentCheckResultsForFile (fileName, FSharpProjectSnapshot, userOpName)` — looks up `caches.ParseAndCheckFileInProject.TryGet(cacheKey)` matching the file-content version; returns `(FSharpParseFileResults * FSharpCheckFileResults) option` for succeeding answers.
- `ComputeProjectExtras (bootstrapInfo) (projectSnapshotWithSources)` — memoized on `SignatureKey`:
  - Runs `ComputeParseAndCheckAllFilesInProject`, sorts results by index, and completes checking via `CheckMultipleInputsFinish` then `CheckClosedInputSetFinish`, yielding `tcState`, `ccuContents`, `generatedCcu`.
  - Computes the assembly identity from attributes (`classifyAssemblyAttrib` over `AssemblyCultureAttribute`/`AssemblyVersionAttribute`/`TypeProviderAssemblyAttribute`, strong-name key via `ValidateKeySigningAttributes`/`GetStrongNameSigner`, `parseILVersion`, default version from `tcConfig.version`), building an `ILAssemblyRef`.
  - Production of `ProjectAssemblyDataResult`: `Unavailable true` when the state creates generated provided types or has a type-provider assembly attribute (such assemblies can't be cross-referenced), else `Available (RawFSharpAssemblyDataBackedByLanguageService tcConfig tcGlobals generatedCcu OutFile topAttrs assemblyName ilAssemRef)`; errors are recovered to `Unavailable true`.
  - Returns `finalInfo, ilAssemRef, assemblyDataResult, checkedImplFiles, parseDiagnostics`.
- `ComputeAssemblyData (projectSnapshot) fileName` — memoized assembly data for cross-project references: prefers the on-disk assembly when its last-write time ≥ the snapshot's last modified time (`shouldUseOnDisk`), otherwise checks all files in-memory via `ComputeProjectExtras` and returns the assembly data (or `Unavailable true` fallbacks).
- `ComputeParseAndCheckProject (projectSnapshot)` — memoized full-project check (`FullKey`): bootstrap; on failure returns an `FSharpCheckProjectResults` with creation diagnostics and no details; on success runs `ComputeProjectExtras`, builds merged diagnostics (parse + tc + creation), symbol uses (collected from all sinks in reverse order), and constructs `FSharpCheckProjectResults` with full details (`tcGlobals`, `tcImports`, `Ccu`, `CcuSig`, symbol uses, `topAttribs`, assembly-data getter, `ilAssemRef`, access rights, checked impl files, dependency files).
- `tryGetSink (fileName) (projectSnapshot)` — computes the `TcResultsSinkImpl` + bootstrap info for a file (bootstrap → UpTo-load → `ComputeTcLastFile` → `tcInfo.sink |> List.tryHead`).
- `ComputeSemanticClassification (fileName, projectSnapshot)` — memoized (`FileKey`): gets the sink, builds `SemanticClassificationKeyStoreBuilder` from `GetResolutions().GetSemanticClassification(...RelatedSymbolUseKind.All)` and returns its `.GetView()`.
- `ComputeItemKeyStore (fileName, projectSnapshot)` — memoized (`FileKey`): builds an `ItemKeyStoreBuilder` from captured name resolutions and captured related symbol uses, skipping synthetic ranges and deduplicating equal (start,end) positions via a `HashSet` with a custom `IEqualityComparer<struct (pos * pos)>`.

### Public members (non-interface)

- `ParseFile(fileName, projectSnapshot, _userOpName)` — bootstrap; `None` → `emptyParseResult`, else locates the file snapshot in the project, loads its source (marking exe/last-compiland), and returns `getParseResult`.
- `ParseFileWithoutProject(fileName, sourceText, options, cache, flatErrors, userOpName)` — standalone parse via `ParseAndCheckFile.parseFile`; when `cache` is set, memoized via `caches.ParseFileWithoutProject` keyed by file name with a version hash covering file name, conditional defines, source files, lang version, the source checksum, all diagnostic warn settings and boolean flags.
- `ParseAndCheckFileInProject(fileName, projectSnapshot, userOpName)` — delegates to `ComputeParseAndCheckFileInProject`.
- `FindReferencesInFile(fileName, projectSnapshot, symbol, userOpName)` — computes the item-key store and returns `itemKeyStore.FindAll symbol.Item` (empty sequence if no store).
- `GetAssemblyData(projectSnapshot, fileName, _userOpName)` — `ComputeAssemblyData`.
- `Caches` — the current `CompilerCaches`.
- `SetCacheSize(cacheSize)` — replaces `caches` with a fresh `CompilerCaches`; `SetCacheSizeFactor(sizeFactor)` — `CacheSizes.Create` then `SetCacheSize`.

### `interface IBackgroundCompiler` implementation

- `CheckFileInProject(parseResults, fileName, fileVersion, sourceText, options, userOpName)` — snapshot via `FSharpProjectSnapshot.FromOptions`, then `ParseAndCheckFileInProject`; returns the `FSharpCheckFileAnswer`.
- `CheckFileInProjectAllowingStaleCachedResults(…)` — same but `Some answer`.
- `ClearCache(projects: FSharpProjectIdentifier seq, …)` — `this.Caches.Clear(Set projects)` (under `Activity.start "TransparentCompiler.ClearCache"`).
- `ClearCache(options: seq<FSharpProjectOptions>, …)` — clears the legacy `backgroundCompiler` for those options and `this.Caches.Clear` over their project identifiers.
- `ClearCaches()` — clears the legacy compiler and recreates `caches <- CompilerCaches(cacheSizes)`.
- `DownsizeCaches()` — legacy `backgroundCompiler.DownsizeCaches()`.
- Events — `BeforeBackgroundFileCheck = beforeFileChecked.Publish`, `FileParsed = fileParsed.Publish`, `FileChecked = fileChecked.Publish`, `ProjectChecked = projectChecked.Publish`.
- `FindReferencesInFile(fileName, options, symbol, canInvalidateProject, userOpName)` — snapshot from options then delegate to the member; the snapshot-typed overload unwraps `FSharpProjectSnapshot`.
- `FrameworkImportsCache` — delegate to legacy `backgroundCompiler.FrameworkImportsCache`.
- `GetAssemblyData(options, fileName, userOpName)` and his `FSharpProjectSnapshot` overload — snapshot then delegate.
- `GetBackgroundCheckResultsForFileInProject(fileName, options, userOpName)` — check-file result or an empty `FSharpCheckFileResults` on `Aborted`.
- `GetBackgroundParseResultsForFileInProject(fileName, options, userOpName)` — `ParseFile` result.
- `GetCachedCheckFileResult(builder, fileName, sourceText, options)` — ignores `builder`, snapshots, and returns the cached pair or `None` on abort.
- `GetProjectOptionsFromScript(…)` — delegates to `GetProjectSnapshotFromScript` and converts to `FSharpProjectOptions`.
- `GetProjectSnapshotFromScript(…)` — the script snapshot pipeline:
  - Defaults `useFsiAuxLib=true`, `useSdkRefs=true`, `previewEnabled=false`, `assumeDotNetFramework=false`; adds `--langversion:preview` when preview; opens a `DiagnosticsScope` (flat-errors aware); `loadedTimeStamp` defaults to `DateTime.MaxValue` ("not now", to avoid forced reloading).
  - Creates the current-source `FSharpFileSnapshot`, always computes the load closure (`ComputeScriptClosureInner`) since a loaded file might load more files (no caching here).
  - Adds `--noframework`/`--warn:3` to the flags, populates the `ScriptClosure` cache, and builds the `FSharpProjectSnapshot.Create(...)` from closure source files/references/flags (with unresolved reference set and load references); diagnostics from the closure root file → `FSharpDiagnostic`s.
- `GetSemanticClassificationForFile(fileName, FSharpProjectSnapshot/FSharpProjectOptions, userOpName)` — `ComputeSemanticClassification`.
- `InvalidateConfiguration(options, userOpName)` — legacy delegate; snapshot overload clears the project cache.
- `NotifyFileChanged` / `NotifyProjectCleaned` — legacy delegates.
- `ParseAndCheckFileInProject(fileName, fileVersion, sourceText, options, userOpName)` and `(fileName, FSharpProjectSnapshot, userOpName)` overloads — snapshot/unwrap then delegate.
- `ParseAndCheckProject(options | FSharpProjectSnapshot, userOpName)` — snapshot/`ComputeParseAndCheckProject`.
- `ParseFile(fileName, FSharpProjectSnapshot/sourceText-options overloads)` — unwrap; source-text overload = `ParseFileWithoutProject`.
- `TryGetRecentCheckResultsForFile(options…)` — legacy delegate; snapshot overload = `TryGetRecentCheckResultsForFile` member.

## Relation to the signature

The `.fs` fully implements the `.fsi` surface (all internal types, `CacheSizes`, `CompilerCaches`, `TransparentCompiler` members) and additionally defines: `TcInfo.TcDiagnostics`; `CompilerCaches.Clear`; `CacheSizes.Default` (not in the signature); `TransparentCompiler.ParseFileWithoutProject`; the legacy-event plumbing and the whole `IBackgroundCompiler` interface implementation; the private `TypeCheckingGraphProcessing` module; and every private computation helper above. `CacheSizes` in the `.fsi` is `[<Experimental>]` public; in the `.fs` it is declared plainly (accessibility governed by the signature).
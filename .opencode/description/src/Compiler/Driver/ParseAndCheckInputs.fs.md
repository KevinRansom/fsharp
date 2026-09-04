# ParseAndCheckInputs.fs

**Purpose** Implements the parse and type-check phase of a compilation. Parses each input file (`.fs`, `.fsi`, `.fsx`, …) into a `ParsedInput`, processes `#r`/`#I`/`#light`/etc. hash directives along the way, deduplicates module names, and then type-checks the set of inputs to produce the `TcState`, the `CheckedImplFile` list, the top attributes, and the inferred `ModuleOrNamespaceType`. Provides both a sequential "check the files one by one" path and a parallel "graph" path that models per-file dependencies.

**Namespace(s)** `FSharp.Compiler` (module `FSharp.Compiler.ParseAndCheckInputs`, internal)

**Functions / values (top-level, not grouped)**
- `CanonicalizeFilename`, `IsScript`, `QualFileNameOf*` (module/file/specs/impls variants), `ComputeQualifiedNameOfFileFromUniquePath`, `PrependPathToQualFileName/Impl/Spec/Input` — qualified-name helpers for `QualifiedNameOfFile`.
- `IsValidAnonModuleName`, `ComputeAnonModuleName` — derive an anonymous module name for files that don't declare one (honoring `-defaultns` and `--standalone`).
- `FileRequiresModuleOrNamespaceDecl`, `PostParseModuleImpl(s)`, `PostParseModuleSpec(s)` — post-parse rewrite of the top-level `ParsedInput` for impl/spec files, including injecting the synthesized `Check` module / anonymous module when needed.
- `FinishPreprocessing`, `collectParsedInputTrivia`, `getImplSubmoduleRanges`, `getSpecSubmoduleRanges` — finalize `#`-directive state and collect trivia after a file is parsed.
- `ModuleNamesDict` type + `DeduplicateModuleName`, `DeduplicateParsedInputModuleName` — de-duplicate module names across files (so `A.fs` and `A/inner.fs` don't clash).
- `ParseInput` — the core single-input parser (lexes + parses via `Parser`, recovers on parse errors per `FSharpDiagnosticOptions`, handles `--printAST` etc.).
- `Tokenizer` type, `ShowAllTokensAndExit`, `TestInteractionParserAndExit`, `ReportParsingStatistics` — token/dump helpers for `--tokenize`/`--testinteractionparser` flags.
- `EmptyParsedInput`, `parseInputStreamAux`/`parseInputSourceTextAux`/`parseInputFileAux`, `ParseOneInputStream`, `ParseOneInputSourceText`, `ParseOneInputFile`, `ParseOneInputLexbuf` — the four parse-one-entries (each opens the input, creates a `LexBuffer`, runs `ParseInput`, and post-processes).
- `ValidSuffixes`, `checkInputFile` — validate the file extension before parsing.
- `UseMultipleDiagnosticLoggers` — wrap a multi-file pass so each file has its own diagnostics stream.
- `ParseInputFilesInParallel` / `ParseInputFilesSequential` / `ParseInputFiles` — parse-all entry that picks the strategy (parallel when `tcConfig.parallelParsing` is set, sequential otherwise), dispatching each file on a worker thread.
- `ProcessMetaCommandsFromInput`, `ApplyMetaCommandsFromInputToTcConfig` — walk the `#`-directives in a file, calling back into `TcConfigBuilder`'s `AddReferenceDirective` / `AddIncludePath` / `AddLoadedSource` etc., and returning an updated `TcConfig`.
- `GetInitialTcEnv` — build the seed `TcEnv`: `mscorlib`/`System.Runtime` + `FSharp.Core` + the `OpenDeclaration`s from `tcConfig.implicitOpens`, and apply `InternalsVisibleTo` attributes from the referenced assemblies.
- `CheckSimulateException` — the `--simulateexception` test flag.
- `RootSigs`, `RootImpls`, `qnameOrder` — Zmap/Zset bookkeeping for which files' signatures / impls have been incorporated.
- `TcState` (class) — the incremental check state: `Ccu`, `TcEnvFromSignatures`, `TcEnvFromImpls`, `CcuSig`, plus `NextStateAfterIncrementalFragment` and `CreatesGeneratedProvidedTypes`.
- `GetInitialTcState`, `AddCheckResultsToTcState` — build the seed state and fold per-file check results back into it.
- `PartialResult` type + `SkippedImplFilePlaceholder` — the placeholder path for an impl file that was skipped because its paired signature was already checked (graph mode).
- `CheckOneInput`, `DiagnosticsLoggerForInput`, `CheckOneInputEntry` — the single-file check entry used by both the sequential and graph paths.
- `CheckMultipleInputsFinish`, `CheckOneInputAndFinish`, `CheckClosedInputSetFinish`, `CheckMultipleInputsSequential` — fold the per-file results into the final `TcState` + `CheckedImplFile` list (+ `TopAttribs`).
- `State`, `FinalFileResult` — the per-node result wrapper for the graph path.
- `NodeToTypeCheck` type + `CheckOneInputWithCallback` — the graph-mode check entry; takes a `NodeToTypeCheck` so that an `ArtificialImplFile` (a signature file's contents being promoted into the impls env) is handled via `AddSignatureResultToTcImplEnv` rather than a full impl check.
- `AddSignatureResultToTcImplEnv` — the "signature → impls env" promotion step used by `ArtificialImplFile` nodes.
- Private `TypeCheckingGraphProcessing` module — the implementation of the graph-checking algorithm: building the per-file `Graph<FileIndex>`, scheduling `NodeToTypeCheck` tasks on their dependencies, and recovering from failures.
- `TransformDependencyGraph (graph, filePairs)` — rewrites the `Graph<FileIndex>` (file → dep-files) into the `Graph<NodeToTypeCheck>` by inserting the `ArtificialImplFile` nodes for each paired file.
- `CheckMultipleInputsUsingGraphMode` — the parallel/graph check runner (uses `TypeCheckingGraphProcessing`); respects `tcConfig.typeCheckingConfig.Mode`, and `DumpGraph` serializes the graph as a Mermaid diagram for diagnostics.
- `CheckClosedInputSet` — the full closed-set check entry; dispatches to the sequential or graph strategy per `tcConfig.typeCheckingConfig.Mode`, and returns the final `TcState * TopAttribs * CheckedImplFile list * TcEnv`.

**Public API surface** `ParseInputFiles`, `ParseOneInputFile`/`ParseOneInputStream`/`ParseOneInputSourceText`/`ParseOneInputLexbuf`, `ApplyMetaCommandsFromInputToTcConfig`, `GetInitialTcEnv`, `GetInitialTcState`, `CheckClosedInputSet`, `CheckOneInput(WithCallback)`, the `TcState` class, and the `NodeToTypeCheck` / `ModuleNamesDict` / `PartialResult` types (consumed by FCS and the driver).

**Internal helpers / active patterns**
- The `RootSigs`/`RootImpls` Zmaps, `DeduplicateModuleName`, and the `PostParse*` rewrites keep the check state consistent in the presence of `.fsi`/`.fs` pairs and multiple top-level modules with the same name.
- `UseMultipleDiagnosticLoggers` isolates diagnostics per file so that a failure in one input doesn't bleed into the next.
- `TypeCheckingGraphProcessing` (private module) holds the graph scheduler — the interesting algorithm in this file — that turns the resolved file graph into a parallel DAG of `NodeToTypeCheck` work items.

**Significant internal logic**
- **Pairing of `.fsi` + `.fs`:** when a file has a paired signature, the *signature* is what dependents see; the impl is only checked for its own dependents. Graph mode models this by inserting an `ArtificialImplFile` node per pair so that `B.fs -> A.fsi` is realized as `B.fs -> [ ArtificialImplFile A ]`, and the real `A.fs` node is only reached when something else (e.g. a top-level entry) needs `A.fs` fully.
- **Parallel check:** `CheckMultipleInputsUsingGraphMode` builds the per-file dependency graph, transforms it via `TransformDependencyGraph`, and then schedules `CheckOneInputWithCallback` tasks on their dependencies; `DumpGraph` (when on) writes a Mermaid `graph TD` of the resolved graph to a file next to the output for debugging.
- **TcState split:** `TcEnvFromSignatures` and `TcEnvFromImpls` are maintained separately so the check of a file that only depends on `A.fsi` doesn't pay for `A.fs` — this is the key performance property of the "signature-first" mode.
- Hash-directive processing is interleaved with parsing (`ProcessMetaCommandsFromInput` / `ApplyMetaCommandsFromInputToTcConfig`), so that a `#r` in the middle of a file is applied before the next file in the closure is type-checked.

**Cross-refs** Called from `FSharp.Compiler.Driver` (fsc.fs `main1`) and from FCS; uses `FSharp.Compiler.CompilerConfig` (`TcConfig`), `FSharp.Compiler.CompilerImports` (`TcImports`), `FSharp.Compiler.CheckDeclarations` (`TcEnv`, `TcResultsSink`, `CheckedImplFile`, `TopAttribs`), `FSharp.Compiler.ConstraintSolver` (the `Cancellable`/`Eventually` type used by `CheckOneInput`/`CheckOneInputWithCallback`), `FSharp.Compiler.GraphChecking` (`Graph<FileIndex>`, `FilePairMap`), `FSharp.Compiler.NameResolution`, `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypedTree`, `FSharp.Compiler.DependencyManager`.

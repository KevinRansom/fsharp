# ParseAndCheckInputs.fsi

**Purpose** Signature for the parse-and-type-check stage. Declares the entry points to (a) parse one or more input files into `ParsedInput`s, processing `#`-directives, and (b) type-check those inputs to produce a `TcState`, `CheckedImplFile` list, `TopAttribs`, and the inferred `ModuleOrNamespaceType` per file. Includes the infrastructure for the parallel/graph-checking mode.

**Namespace(s)** `FSharp.Compiler` (module `FSharp.Compiler.ParseAndCheckInputs`, internal)

**Types declared (contract)**
- `NodeToTypeCheck` — `PhysicalFile FileIndex | ArtificialImplFile signatureFileIndex`: the graph-checking "work item" — either a real physical file, or an artificial node that copies the already-checked signature file's `TcEnvFromSignatures` contents into `TcEnvFromImpls` so that dependents can check against the *implementation* env. The signature doc explains how this lets a `B.fs -> A.fsi` dependency be modeled without forcing a full `A.fs` check.
- `ModuleNamesDict` — `Map<string, Map<string, QualifiedNameOfFile>>`: dedupe state across files so two files with the same module name in the same path get distinct qualified names.
- `PartialResult` — `TcEnv * TopAttribs * CheckedImplFile option * ModuleOrNamespaceType` — the per-file check result.
- `TcState` (sealed) — the incremental check state for a set of inputs:
  - `Ccu: CcuThunk` — the assembly thunk being built.
  - `TcEnvFromSignatures: TcEnv` — env from signature files + inferred sigs of impl files checked so far.
  - `TcEnvFromImpls: TcEnv` — env from checked implementation files.
  - `CcuSig: ModuleOrNamespaceType` — inferred assembly contents so far.
  - `NextStateAfterIncrementalFragment tcEnv -> TcState` — advance for an incremental fragment.
  - `CreatesGeneratedProvidedTypes: bool` — whether type providers contributed generated types.

**Functions (contract)**
- `IsScript fileName : bool`.
- `ComputeQualifiedNameOfFileFromUniquePath (m, paths) -> QualifiedNameOfFile`.
- `PrependPathToInput (longIdent, input) -> ParsedInput` — prepend a module/namespace path to a parsed input (for `#load`-ed files inside a namespace).
- `DeduplicateParsedInputModuleName (moduleNamesDict, input) -> ParsedInput * ModuleNamesDict`.
- `ParseInput ... -> ParsedInput` — parse a single `lexbuf`-fed input using a given lexer.
- `ProcessMetaCommandsFromInput ...` / `ApplyMetaCommandsFromInputToTcConfig (tcConfig, input, sourcePath, dependencyProvider) -> TcConfig` — process `#r`/`#I`/`#light`/etc. directives and update the (builder or snapshot) config as appropriate.
- `ParseOneInputStream / ParseOneInputSourceText / ParseOneInputFile / ParseOneInputLexbuf` — the four parse-one-entries.
- `EmptyParsedInput (fileName, isLastCompiland)`.
- `ParseInputFiles (tcConfig, lexResourceManager, sourceFiles, diagnosticsLogger, retryLocked) -> (ParsedInput * string) list` — parse many files (dispatches to parallel vs sequential).
- `FinishPreprocessing lexbuf diagnosticOptions isScript submoduleRanges` — finalize `#`-directive bookkeeping after a file is parsed.
- `GetInitialTcEnv (assemblyName, m, tcConfig, tcImports, tcGlobals) -> TcEnv * OpenDeclaration list` — seed the initial TcEnv (mscorlib/System.Runtime, FSharp.Core, InternalsVisibleTo, `open FSharp.Core.*`).
- `GetInitialTcState (m, ccuName, tcConfig, tcGlobals, tcImports, tcEnv0, openDecls0) -> TcState`.
- `SkippedImplFilePlaceholder (tcConfig, tcImports, tcGlobals, tcState, input) -> PartialResult * TcState option` — placeholder result for impl files that were skipped because their signature was already checked (used in graph mode).
- `CheckOneInput ...` / `CheckOneInputWithCallback node ...` — check a single input (the latter is the graph-mode entry, parameterized by the `NodeToTypeCheck` so an `ArtificialImplFile` can be handled distinctly).
- `AddCheckResultsToTcState ...` — fold a single file's check results into `TcState` (adds to `TcEnvFromImpls`/`TcEnvFromSignatures` as appropriate).
- `AddSignatureResultToTcImplEnv ...` — the `ArtificialImplFile` path: copy a signature file's signature env into the impls env.
- `TransformDependencyGraph (graph, filePairs) -> Graph<NodeToTypeCheck>` — rewrites a per-`FileIndex` dependency graph into a per-`NodeToTypeCheck` graph by splicing in the `ArtificialImplFile` nodes for paired files.
- `CheckMultipleInputsFinish (results, tcState) -> (env * topAttrs * impls * mtys) * TcState`.
- `CheckClosedInputSetFinish (declaredImpls, tcState) -> TcState * CheckedImplFile list * ModuleOrNamespace`.
- `CheckClosedInputSet ctok ... -> TcState * TopAttribs * CheckedImplFile list * TcEnv` — the full closed-set check entry.
- `CheckOneInputAndFinish ...` — single-input convenience wrapper.

**Public API surface** `GetInitialTcEnv`, `ParseInputFiles`, `ApplyMetaCommandsFromInputToTcConfig`, `CheckClosedInputSet`, `CheckOneInput(WithCallback)`, `GetInitialTcState`; the rest are supporting helpers used within the driver and (for service use) FCS.

**Internal helpers / active patterns** The .fs holds the per-file check implementations (`CheckOneInputEntry`, `TypeCheckingGraphProcessing`, sequential / graph-mode loops) — see that description.

**Significant internal logic** `TcState` deliberately keeps two separate typing environments — signatures and impls — because for an F# assembly with paired `.fsi`/`.fs` files the *signature* env is what dependents should see, while the *impls* env carries the full definition. The `ArtificialImplFile` node (used by graph mode) is an artificial graph vertex whose job is to promote a signature file's contents into `TcEnvFromImpls` so that a dependent file's checker sees the union, without paying for the real impl check.

**Cross-refs** Called from `FSharp.Compiler.Driver` (fsc.fs `main1`); uses `FSharp.Compiler.CompilerConfig` (`TcConfig`), `FSharp.Compiler.CompilerImports` (`TcImports`), `FSharp.Compiler.Diagnostics` (`PhasedDiagnostic`/`DiagnosticsLogger`), `FSharp.Compiler.GraphChecking` (`Graph`), `FSharp.Compiler.CheckDeclarations` (`TcResultsSink`, `TcEnv`, `TopAttribs`, `CheckedImplFile`), `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypedTree`.

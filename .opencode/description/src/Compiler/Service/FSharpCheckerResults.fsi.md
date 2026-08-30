# FSharpCheckerResults.fsi

**Purpose**: Public contract for the core option and result types of the FCS API: `FSharpProjectOptions`, `FSharpReferencedProject`, `FSharpParsingOptions`, `FSharpCodeCompletionOptions`, `FSharpSymbolUse`, `FSharpProjectContext`, `FSharpCheckFileAnswer`, `FSharpCheckFileResults`, `FSharpCheckProjectResults`, plus supporting types `DocumentSource`, `DelayedILModuleReader`, `FSharpUnresolvedReferencesSet`.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## Records / Unions / Types declared

- **`DocumentSource`** (union, experimental) — `FileSystem` | `Custom of (string -> Async<ISourceText option>)`.
- **`DelayedILModuleReader`** (sealed) — `new: name * (CancellationToken -> Stream option) -> _`; `OutputFile: string`; evaluated once, thread-safe.
- **`FSharpUnresolvedReferencesSet`** — opaque wrapper; should be `None` on user input.
- **`FSharpProjectOptions`** (record) — `ProjectFileName`, `ProjectId`, `SourceFiles`, `OtherOptions`, `ReferencedProjects: FSharpReferencedProject[]`, `IsIncompleteTypeCheckEnvironment`, `UseScriptResolutionRules`, `LoadTime`, `UnresolvedReferences` (unused), `OriginalLoadReferences` (unused), `Stamp` (equality-by-stamp).
- **`FSharpReferencedProject`** (union) — `FSharpReference` (output file + child `FSharpProjectOptions`), `PEReference` (stamp fn + `DelayedILModuleReader`), `ILModuleReference` (output + stamp + reader factory); `OutputFile` member.
- **`FSharpSymbolUse`** (sealed) — a symbol use from F# source: `Symbol`, `GenericArguments`, `DisplayContext`, `IsFromDefinition/Pattern/Type/Attribute/DispatchSlotImplementation/ComputationExpression/OpenStatement/Use`, `FileName`, `Range`, `IsPrivateToFileAndSignatureFile`, `IsPrivateToFile`.
- **`FSharpProjectContext`** (sealed) — `GetReferencedAssemblies`, `AccessibilityRights`, `ProjectOptions`.
- **`FSharpParsingOptions`** (record) — `SourceFiles`, `ApplyLineDirectives`, `ConditionalDefines`, `DiagnosticOptions`, `LangVersionText`, `IsInteractive`, `CompilingFSharpCore`, `IsExe`; `Default` static.
- **`FSharpCodeCompletionOptions`** (record) — `SuggestPatternNames`, `SuggestObsoleteSymbols`, `SuggestGeneratedOverrides`, `SuggestOverrideBodies`; `Default`.
- **`FSharpCheckFileResults`** (sealed) — the file-level intellisense/query surface (see below); internal `MakeEmpty`/`Make`/`CheckOneFile` constructors.
- **`FSharpCheckFileAnswer`** (union) — `Aborted` | `Succeeded of FSharpCheckFileResults`.
- **`FSharpCheckProjectResults`** (sealed) — project-level results: `Diagnostics`, `AssemblySignature`, `AssemblyContents`, `GetOptimizedAssemblyContents`, `ProjectContext`, `GetUsesOfSymbol`, `GetAllUsesOfAllSymbols`, `HasCriticalErrors`, `DependencyFiles`; internal constructor.
- **`FsiInteractiveChecker`** (internal) — `ParseAndCheckInteraction` for FSI.
- **`FSharpCheckerResultsSettings`** (internal module) — `defaultFSharpBinariesDir`.

## FSharpCheckFileResults — key members (contract)

- State: `Diagnostics`, `HasErrors`, `PartialAssemblySignature`, `ProjectContext`, `HasFullTypeCheckInfo`, `DependencyFiles`, `ImplementationFile`, `OpenDeclarations`.
- Lookup: `TryGetCapturedType/DisplayContext`, `ImportILType`, `GetSymbolUseAtLocation`, `GetSymbolUsesAtLocation`, `GetDeclarationLocation` (returns `FindDeclResult` from `ExternalSymbol.fsi`), `GetDisplayContextForPos`, `IsRelativeNameResolvable(FromSymbol)`, `GetAllUsesOfAllSymbolsInFile`, `GetUsesOfSymbolInFile`.
- IntelliSense: `GetDeclarationListInfo`, `GetDeclarationListSymbols` (both take `PartialLongName` from `QuickParse.fsi`), `GetKeywordTooltip`, `GetToolTip`, `GetDescription`, `GetF1Keyword`, `GetMethods`, `GetMethodsAsSymbols`.
- Coloring/format: `GetSemanticClassification` (returns `SemanticClassificationItem[]` from `SemanticClassification.fsi`), `GetFormatSpecifierLocations` (obsolete), `GetFormatSpecifierLocationsAndArity`, `GenerateSignature`.

## Internal helpers / active patterns

- `UseSameProject`/`AreSameForChecking` (FSharpProjectOptions equality helpers), `ProjectDirectory`, `FromTcConfig(Builder)` — all internal.
- `ParseAndCheckFile` module (`parseFile`, `matchBraces`, `DiagnosticsHandler`) is internal per the fsi.

## Significant internal logic (contract notes)

- `FSharpOptions Stamp` equality: two options with stamps compare equal iff the stamps are equal — this is how hosts force cache identity.
- `FSharpCheckFileAnswer.Aborted` signals cancellation; `Succeeded` carries results.
- `FSharpCheckProjectResults.AssemblySignature/Contents` are only valid when `HasCriticalErrors` is false.
- `FSharpCheckFileResults.Make` documents the full captured checked state (TcGlobals, TcImports, CcuThunk, TcResolutions, TcSymbolUses, impl file, open declarations) backing the lazy public queries.

## Cross-references

- Implemented by `FSharpCheckerResults.fs`.
- Types consumed by `service.fsi` (FSharpChecker), `BackgroundCompiler.fsi` (IBackgroundCompiler), `FSharpWorkspaceQuery.fs`, `ExternalSymbol.fsi` (`FindDeclResult`), `QuickParse.fsi` (`PartialLongName`), `SemanticClassification.fsi` (`SemanticClassificationItem`).
- `TcResolutions` extension methods (GetSemanticClassification) live in `SemanticClassification.fsi`.

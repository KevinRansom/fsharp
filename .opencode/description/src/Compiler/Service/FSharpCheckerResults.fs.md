# FSharpCheckerResults.fs

**Purpose**: Implementation of the core result/option types of the FCS public API: `FSharpProjectOptions`, `FSharpReferencedProject`, `FSharpParsingOptions`, `FSharpSymbolUse`, `FSharpProjectContext`, `FSharpCheckFileResults`, `FSharpCheckProjectResults`, plus `FsiInteractiveChecker` for FSI and the internal `ParseAndCheckFile` workhorse module that parses a file and drives the one-file check.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## Types / Modules declared

- **`FSharpUnresolvedReferencesSet`** — newtype over `UnresolvedAssemblyReference list` (documented as unused-in-API; must be `None`/`[]` on user input).
- **`DocumentSource`** (union) — `FileSystem` | `Custom of (string -> Async<ISourceText option>)`.
- **`DelayedILModuleReader`** (sealed) — lazily creates an `ILModuleReader` from a `(CancellationToken -> Stream option)` factory; double-checked lock so the stream is opened at most once and can be called from multiple threads; `OutputFile` property.
- **`FSharpReferencedProject`** (union) — `FSharpReference of outputFile * FSharpProjectOptions`, `PEReference of getStamp * DelayedILModuleReader`, `ILModuleReference of outputFile * getStamp * getReader`; `OutputFile` member. Used inside `FSharpProjectOptions.ReferencedProjects`.
- **`FSharpSymbolUse`** (sealed, ~line 212) — one use of a symbol from source: `Symbol`, `GenericArguments`, `DisplayContext`, `IsFromDefinition/Pattern/Type/Attribute/DispatchSlotImplementation/ComputationExpression/OpenStatement/Use`, `FileName`, `Range`, `IsPrivateToFileAndSignatureFile`, `IsPrivateToFile`; internal ctor from `(denv, symbol, inst, itemOcc, range)`; implements `IEquatable`, hashing, `IEquatable<FSharpSymbol>`, etc.
- **Internal name-resolution result types** (~line 315): `NameResResult`, `ResolveOverloads`, `ExprTypingsResult`, `Names`.
- **`FSharpCodeCompletionOptions`** (+ `Default`) — `SuggestPatternNames`, `SuggestObsoleteSymbols`, `SuggestGeneratedOverrides`, `SuggestOverrideBodies`.
- **`FSharpParsingOptions`** (~line 2896) — `SourceFiles`, `ApplyLineDirectives` (usually false for editors, true for compilation), `ConditionalDefines`, `DiagnosticOptions`, `LangVersionText`, `IsInteractive`, `CompilingFSharpCore`, `IsExe`; `Default`, `FromTcConfig`, `FromTcConfigBuilder` (internal).
- **`FSharpProjectContext`** (~line 3435) — `GetReferencedAssemblies`, `AccessibilityRights`, `ProjectOptions`.
- **`FSharpCheckFileResults`** (~line 3452) — the big one: `Diagnostics`, `HasErrors`, `PartialAssemblySignature`, `ProjectContext`, `HasFullTypeCheckInfo`, `DependencyFiles`, `TryGetCapturedType/DisplayContext`, `ImportILType`, `GetDeclarationListInfo`/`GetDeclarationListSymbols`, `GetKeywordTooltip`, `GetToolTip`, `GetDescription`, `GetF1Keyword`, `GetMethods`/`GetMethodsAsSymbols`, `GetDeclarationLocation`, `GetSymbolUseAtLocation`/`GetSymbolUsesAtLocation`, `GetSemanticClassification`, `GetFormatSpecifierLocations(AndArity)`, `GetAllUsesOfAllSymbolsInFile`, `GetUsesOfSymbolInFile`, `GetDisplayContextForPos`, `IsRelativeNameResolvable(FromSymbol)`, `ImplementationFile`, `OpenDeclarations`, `GenerateSignature`, `MakeEmpty`/`Make`/`CheckOneFile` internal ctors.
- **`FSharpCheckProjectResults`** (~line 3851) — `Diagnostics`, `AssemblySignature`, `AssemblyContents`, `GetOptimizedAssemblyContents`, `ProjectContext`, `GetUsesOfSymbol`, `GetAllUsesOfAllSymbols`, `HasCriticalErrors`, `DependencyFiles`.
- **`FsiInteractiveChecker`** (~line 4057, internal) — `ParseAndCheckInteraction`: typecheck one FSI interaction against an existing TcState/TcImports for intellisense over the REPL.
- Internal modules: `ParseAndCheckFile` (with `parseFile`, `matchBraces`, and `DiagnosticsHandler` — a `DiagnosticsLogger` wrapper that accumulates `PhasedDiagnostic`s and converts to `FSharpDiagnostic` with name suggestions), `FSharpCheckerResultsSettings.defaultFSharpBinariesDir`.

## Public API surface

- All the public types above. `FSharpCheckFileResults` is by far the richest surface — every intellisense/tooltip/goto-decl/find-uses operation routes through it.
- `FSharpSymbolUse` is the currency returned by "uses of symbol" queries.

## Internal helpers / active patterns

- `DiagnosticsHandler` — unifies parse/check diagnostics, error counting, `CollectedDiagnostics (symbolEnv option)` for name-suggestion decoration.
- `DelayedILModuleReader.TryGetILModuleReader` — `Cancellable` + `lock` double-checked pattern.
- Heavy internal plumbing: `TcGlobals`, `TcImports`, `TcState`, `CcuThunk`, `ModuleOrNamespaceType`, `TcResolutions`, `TcSymbolUses`, `OpenDeclaration` lists stored alongside the public surface.

## Significant internal logic

- `FSharpCheckFileResults` wraps the full checked state of a file (TcImports, TcResolutions, fallback `NameResolutionEnv`, `CheckedImplFile`, `LoadClosure` for scripts, etc.) and the public query methods (tooltip, methods, find decl) run name resolution lazily against that captured state for the given line/column/names.
- `parseFile` builds a `DiagnosticsHandler`, runs the parser with symbol capture/conditional defines from `FSharpParsingOptions`, and returns `(diagnostics, ParsedInput, hadErrors)`; `matchBraces` is the same but just matching parens.
- `GetDeclarationLocation` returns `FindDeclResult` (see `ExternalSymbol.fs`) — local ranges, or `ExternalDecl` for non-F# symbols.
- `GetSemanticClassification` delegates to `TcResolutionsExtensions.GetSemanticClassification` (see `SemanticClassification.fs`).
- `FSharpCheckProjectResults` keeps optional `CheckedImplFile list` (typed impl files) used for IL generation and `GenerateSignature`.

## Cross-references

- Contract: `FSharpCheckerResults.fsi`.
- Built/used by `BackgroundCompiler.fs` and `IncrementalBuild.fs` (`CheckOneFile` is called from the incremental pipeline).
- Tooltip/declaration-list details in `ServiceDeclItems`/`ServiceDeclarationLists.fs`; semantic classification in `SemanticClassification.fs`; symbol vocabulary in `FSharp.Compiler.Symbols`.
- `FsiInteractiveChecker` is used by the F# Interactive front-ends.

# service.fsi

**Purpose**: The public API contract of FSharp.Compiler.Service — "SourceCodeServices API to the compiler as an incremental service for parsing, type checking and intellisense-like environment-reporting." Declares `FSharpChecker` (the central class with `Create`, parse/check entry points and background-work events) and `CompilerEnvironment` (static helpers about the compilation environment).

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis` (FSharpChecker), `FSharp.Compiler` (CompilerEnvironment)

## Primary public types

- **`FSharpChecker`** (sealed, non-serializable) — see below for the full surface.
- **`CompilerEnvironment`** (class, static members) — `BinFolderOfDefaultFSharpCompiler`, `DefaultReferencesForOrphanSources`, `GetConditionalDefinesForEditing`, `IsCheckerSupportedSubcategory`, `GetDebuggerLanguageID`, `IsScriptFile`, `IsCompilable`, `MustBeSingleFileProject`.

## FSharpChecker — public API surface

- **Creation**: `static member Create` with optional `projectCacheSize`, `keepAssemblyContents`, `keepAllBackgroundResolutions`, `legacyReferenceResolver`, `tryGetMetadataSnapshot`, `suggestNamesForErrors`, `keepAllBackgroundSymbolUses`, `enableBackgroundItemKeyStoreAndSemanticClassification`, `enablePartialTypeChecking` (cannot combine with `keepAssemblyContents`), `parallelReferenceResolution`, `captureIdentifiersWhenParsing`, experimental `documentSource`, `useTransparentCompiler`, `transparentCompilerCacheSizes`. Also `UsesTransparentCompiler`, obsolete `Instance`, `ActualParseFileCount`/`ActualCheckFileCount` (test statistics).
- **Parse**: `MatchBraces` (ISourceText + obsolete string/FSharpProjectOptions overloads), `ParseFile` (and experimental snapshot overload), obsolete `ParseFileInProject`, `GetBackgroundParseResultsForFileInProject`.
- **Check**: `CheckFileInProjectAllowingStaleCachedResults` (obsolete), `CheckFileInProject`, `ParseAndCheckFileInProject` (+ snapshot), `ParseAndCheckProject` (+ snapshot), `GetBackgroundCheckResultsForFileInProject`, `TryGetRecentCheckResultsForFile` (returns parse results + check results + hash/version, or snapshot form).
- **Find all / classification**: `FindBackgroundReferencesInFile` (options form with `canInvalidateProject` and experimental `fastCheck` requiring `captureIdentifiersWhenParsing=true`, plus snapshot form), `GetBackgroundSemanticClassificationForFile` (options + snapshot forms, return `SemanticClassificationView option`).
- **Scripts / options**: `GetProjectOptionsFromScript`, experimental `GetProjectSnapshotFromScript` (takes `ISourceTextNew` + `DocumentSource`), `GetProjectOptionsFromCommandLineArgs`, `GetParsingOptionsFromCommandLineArgs` (two overloads, both also yielding diagnostics), `GetParsingOptionsFromProjectOptions`.
- **Compile**: `Compile: argv * ?userOpName -> Async<FSharpDiagnostic[] * exn option>` — source names resolved via the FileSystem API, `-o` required, first arg ignored.
- **Invalidation / caches**: `InvalidateAll`, `InvalidateConfiguration` (options + snapshot), `ClearCache` (options seq + `FSharpProjectIdentifier` seq), `ClearLanguageServiceRootCachesAndCollectAndFinalizeAllTransients`, `NotifyProjectCleaned` (obsolete), `NotifyFileChanged` (experimental, required with `documentSource = Custom`).
- **Events** (raised on background threads): `BeforeBackgroundFileCheck: IEvent<string * FSharpProjectOptions>`, `FileParsed`, `FileChecked`, `ProjectChecked: IEvent<FSharpProjectOptions>`.
- **Tokenizer**: `TokenizeLine` (state = int-tagged `FSharpTokenizerLexState`), `TokenizeFile`.
- **Internal**: `TransparentCompiler`, `Caches: CompilerCaches`, `FrameworkImportsCache`, `ReferenceResolver: LegacyReferenceResolver`.

## Result / option types referenced

- `FSharpParseFileResults`, `FSharpCheckFileAnswer`, `FSharpCheckFileResults`, `FSharpCheckProjectResults`, `FSharpProjectOptions`, `FSharpParsingOptions`, `FSharpProjectSnapshot`, `FSharpSymbol`, `FSharpDiagnostic`, `SemanticClassificationView`, `FSharpTokenizerLexState`/`FSharpTokenInfo` — all defined in other files (notably `FSharpCheckerResults.fsi`, `FSharpParseFileResults.fsi`, `FSharpProjectSnapshot.fs`, `SemanticClassification.fsi`).

## Notable contract details

- `CheckFileInProject` returns `Aborted` if a parse tree was unavailable; `CheckFileInProjectAllowingStaleCachedResults` may return `NoAntecedent` while the background builder is still preparing.
- `TryGetRecentCheckResultsForFile` results may be stale if the source changed; safe for intellisense menus.
- `Compile`'s first argv element is ignored ("can just be fsc.exe").

## Cross-references

- Implemented by `service.fs`; heavy result type contracts live in `FSharpCheckerResults.fsi`.
- `FSharpWorkspace` (see `FSharpWorkspace.fs`) wraps an `FSharpChecker` created with an aggressive option set.
- Background work implemented in `BackgroundCompiler.fs` (or `TransparentCompiler.fs`).

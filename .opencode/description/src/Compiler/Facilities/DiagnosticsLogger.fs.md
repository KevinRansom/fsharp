# DiagnosticsLogger.fs

**Purpose**: The compiler's diagnostics "log" infrastructure: the exception types that represent all errors/warnings (as raised exceptions, per F#'s traditional design), the abstract `DiagnosticsLogger` and its concrete implementations, the thread-static logger/build-phase mechanism, error-recovery combinators, the `trackErrors` monad for collecting warnings, the `--flaterrors` string normalization, and the stack guard that hops to a new thread when the stack runs low.

**Namespace(s)**: module `FSharp.Compiler.DiagnosticsLogger` (no namespace; internal per .fsi)

**Primary declarations**:
- `DiagnosticStyle` union: `Default | Emacs | Test | VisualStudio | Gcc | Rich` (error-format style)
- Exceptions: `WrappedError`, `ReportedError`, `StopProcessingExn` (+ `StopProcessing` value and `(|StopProcessing|_|)` pattern), `DiagnosticWithText`, `InternalError`, `InternalException`, `UserCompilerMessage`, `LibraryUseOnly`, `Deprecated`, `Experimental`, `PossibleUnverifiableCode`, `UnresolvedReferenceNoRange/Error`, `UnresolvedPathReferenceNoRange/…` , `DiagnosticWithSuggestions`, `DiagnosticEnabledWithLanguageFeature`, `ObsoleteDiagnostic`
- `Error`, `ErrorWithSuggestions`, `ErrorEnabledWithLanguageFeature` — exception constructors
- `Exiter` (abstract `Exit`), `QuitProcessExiter`, `StopProcessingExiter`
- `BuildPhase` union + `BuildPhaseSubcategory` literal-string module
- `PhasedDiagnostic` record: `{ Exception; Phase; Severity; DefaultSeverity }` with `Create`, `Subcategory()`, `IsSubcategoryOfCompile`, `IsPhaseInCompile`
- `DiagnosticsLogger` (abstract base): `DiagnosticSink`, `ErrorCount`, `CheckForErrors`, `CheckForRealErrorsIgnoringWarnings`
- `DiscardErrorsLogger`, `AssertFalseDiagnosticsLogger`, `CapturingDiagnosticsLogger` (with `CommitDelayedDiagnostics`)
- `DiagnosticsThreadStatics`: `AsyncLocal`-based `BuildPhase` + `DiagnosticsLogger`
- `<AutoOpen> DiagnosticsLoggerExtensions`: `EmitDiagnostic/ErrorR/Warning/InformationalWarning/Error/SimulateError/ErrorRecovery/StopProcessingRecovery/ErrorRecoveryNoRange`; `PreserveStackTrace`
- Scope helpers: `UseBuildPhase`, `UseTransformedDiagnosticsLogger`, `UseDiagnosticsLogger`, `SetThread*NoUnwind`, `CompilationGlobalsScope`
- Global report functions: `errorR/warning/informationalWarning/error/simulateError/diagnosticSink/errorRecovery(...)`, `deprecatedWithError`, `libraryOnlyError/Warning`, `deprecatedOperator`, `suppressErrorReporting`, `conditionallySuppressErrorReporting`
- Errors-as-data: `OperationResult<'T>` (`OkResult`/`ErrorResult`), `ImperativeOperationResult`, `ReportWarnings/CommitOperationResult/RaiseOperationResult`, `*D` combinators (`ErrorD/WarnD/CompleteD/ResultD`, `bind/IterateD/WhileD/MapD/OptionD/IterateIdxD/Iterate2D/TryD/RepeatWhileD/AtLeastOneD/MapReduceD...`), `TrackErrorsBuilder`/`trackErrors`, `OperationResult.ignore`
- `--flaterrors` support: `stringThatIsAProxyForANewlineInFlatErrors` (ASCII 29), `NewlineifyErrorString`, `NormalizeErrorString`, `NormalizeErrorRichText`
- `SuppressLanguageFeatureCheck` union; `languageFeatureError`, `tryLanguageFeatureErrorOption`, `checkLanguageFeatureError(s)`, `tryCheckLanguageFeatureAndRecover`, `checkLanguageFeatureAndRecover`, `languageFeatureNotSupportedInLibraryError`
- `StackGuardMetrics` module: OTel-style counter/listener for stack-guard jumps
- `StackGuard` class: `Guard` (hops to new thread via `Async.SwitchToNewThread` when `TryEnsureSufficientExecutionStack` fails), `GuardCancellable`
- `MultipleDiagnosticsLoggers` module: `Parallel` (per-computation capturing loggers via `TaskCompletionSource`, ordered replay), `Sequential`

**Significant internal logic**:
- `AttachRange m exn` re-attaches source range to un-ranged exceptions (`UnresolvedReferenceNoRange` → `…Error`), unwrapping `TargetInvocationException`
- Error-recovery protocol: `error` reports + raises `ReportedError`; `errorRecovery` catches `ReportedError`/`StopProcessing` per the rules documented in the .fsi
- `NormalizeErrorString`/`NormalizeErrorRichText`: replace newlines with the ASCII-29 group separator (preserving tagged parts) for IDE `--flaterrors`/QuickInfo
- `languageFeatureError` builds the "feature X is not supported in F# Y..." message via `LanguageVersion.GetFeature*String` — the link to the feature gate
- `StackGuard.Guard` uses `CallerFilePath/LineNumber` attributes to tag stack-jump metrics; netstandard2.0 has a throwing fallback path

**Cross-references**: RichText.fs (messages are `RichText`), LanguageFeatures.fs (feature-gate errors), TextLayoutRender.fs (formats these messages), Driver error reporting, `AsyncMemoize` (uses `CapturingDiagnosticsLogger`, `CompilationGlobalsScope`).

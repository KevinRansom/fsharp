# DiagnosticsLogger.fsi

**Purpose**: The contract for `DiagnosticsLogger.fs` — one of the largest Facilities contracts. Declares: all diagnostic exception types, `DiagnosticStyle`, the `DiagnosticsLogger` hierarchy, thread-statics, the report/recovery free functions, the `OperationResult` warning-collection monad (`trackErrors`), flat-error string normalization, language-feature checks, `StackGuard`, and the parallel/sequential multi-logger runners.

**Namespace(s)**: module `FSharp.Compiler.DiagnosticsLogger` (all `internal`)

**Key declared items**:
- `DiagnosticStyle`: `Default | Emacs | Test | VisualStudio | Gcc | Rich`
- Exceptions: `WrappedError`, `ReportedError`, `StopProcessingExn`, `DiagnosticWithText`, `InternalError`, `InternalException`, `UserCompilerMessage`, `LibraryUseOnly`, `Deprecated`, `Experimental`, `PossibleUnverifiableCode`, `UnresolvedReferenceNoRange/Error`, `UnresolvedPathReferenceNoRange`, `UnresolvedPathReference`, `DiagnosticWithSuggestions`, `ObsoleteDiagnostic`, `DiagnosticEnabledWithLanguageFeature`
- Constructors/values: `Error`, `ErrorWithSuggestions`, `ErrorEnabledWithLanguageFeature`, `findOriginalException`, `Suggestions`/`NoSuggestions`, `StopProcessing`, `(|StopProcessing|_|)`, `AttachRange`, `protectAssemblyExploration(F/NoReraise)`
- `Exiter`, `QuitProcessExiter`, `StopProcessingExiter`
- `BuildPhase`, `BuildPhaseSubcategory` (literals: "", "compile", "parameter", "parse", "typecheck", "codegen", "optimize", "ilxgen", "ilgen", "output", "interactive", "internal")
- `PhasedDiagnostic` record (+ `Create`, `Subcategory`, `IsSubcategoryOfCompile`, `IsPhaseInCompile`, `DebugDisplay`)
- `DiagnosticsLogger` (abstract): `DiagnosticSink`, `ErrorCount`, `CheckForErrors` (Obsolete — "use CheckForRealErrorsIgnoringWarnings"), `CheckForRealErrorsIgnoringWarnings`
- `DiscardErrorsLogger`, `AssertFalseDiagnosticsLogger`, `CapturingDiagnosticsLogger` (`Diagnostics`, `CommitDelayedDiagnostics`, `?eagerFormat` constructor arg)
- `DiagnosticsThreadStatics`: `BuildPhase` get/set, `DiagnosticsLogger` get/set
- Extensions: `ErrorR/Warning/Error/SimulateError/ErrorRecovery/StopProcessingRecovery/ErrorRecoveryNoRange`, `PreserveStackTrace`, `tryAndDetectDev15`
- Scoping: `UseBuildPhase`, `UseTransformedDiagnosticsLogger`, `UseDiagnosticsLogger`, `SetThreadBuildPhaseNoUnwind`, `SetThreadDiagnosticsLoggerNoUnwind`, `CompilationGlobalsScope`
- Report/free functions: `errorR/warning/informationalWarning/error/simulateError/diagnosticSink/errorRecovery/stopProcessingRecovery/errorRecoveryNoRange`, `deprecatedWithError`, `libraryOnlyError/Warning`, `deprecatedOperator`, `suppressErrorReporting`, `conditionallySuppressErrorReporting`
- `OperationResult<'T>` / `ImperativeOperationResult`, `ReportWarnings/CommitOperationResult/RaiseOperationResult`, `*D` combinators (`ErrorD/WarnD/CompleteD/ResultD/bind/IterateD/WhileD/MapD/OptionD/IterateIdxD/Iterate2D/TryD/RepeatWhileD/AtLeastOneD/AtLeastOne2D/MapReduceD/MapReduce2D`), `TrackErrorsBuilder` + `trackErrors`, `OperationResult.ignore`
- Flat errors: `stringThatIsAProxyForANewlineInFlatErrors`, `NewlineifyErrorString`, `NormalizeErrorString`, `NormalizeErrorRichText`
- `SuppressLanguageFeatureCheck`, `languageFeatureError`, `checkLanguageFeatureError`, `tryCheckLanguageFeatureAndRecover`, `checkLanguageFeatureAndRecover`, `tryLanguageFeatureErrorOption`, `languageFeatureNotSupportedInLibraryError`
- `StackGuardMetrics` (Listen/StatsToString/CaptureStatsAndWriteToConsole), `StackGuard` (`Guard`, `GuardCancellable`)
- `MultipleDiagnosticsLoggers`: `Parallel`, `Sequential`

**Cross-references**: Implements DiagnosticsLogger.fs; consumes DiagnosticOptions (severity), LanguageFeatures (feature checks), RichText; output formatting in TextLayoutRender.

# fsi.fs

**Purpose**: The implementation of F# Interactive (Fsi) itself — the largest file in the interactive subsystem (~5400 lines). It hosts the `FsiEvaluationSession`: a long-lived "compilation unit" that reads interactions from stdin (or `EvalInteraction`/`EvalScript` calls), lexes/parses/checks/executes them incrementally against an in-memory assembly, and supports `#r`, `#i`, `#b`, `#t`, `#measure`, `#cd`, `#light`, `#time`, `#nowarn` and other directives, Ctrl+Break interrupts, bound values, custom printers, and GUI event-loop integration.

**Namespace(s)**: `FSharp.Compiler.Interactive` (module `FSharp.Compiler.Interactive.Shell`)

**Public types** (as exposed by `fsi.fsi`):
- `FsiValue` — a value bound during evaluation: reflection value, `.NET type`, F# type, plus `ToString()`.
- `FsiBoundValue` — `(name, FsiValue)` root-level binding.
- `EvaluationEventArgs` — args for the `Evaluation` event: optional result `FsiValue`, `FSharpSymbolUse`, and the `FSharpImplementationFileDeclaration` that was executed.
- `FsiEvaluationSessionHostConfig` — host configuration (see below); includes `UseFsiAuxLib`, `PrintDepth`/`PrintLength`/`PrintSize`/`PrintWidth`, `ShowProperties`, `ShowIEnumerable`, `ShowDeclarationValues`, `FloatingPointFormat`, `FormatProvider`, custom printers/transformers, `CommandLineArgs`, `EventLoop`, `GetFsiCommandLine`, and the `Evaluation` event.
- `FsiCompilationException` — exception carrying `FSharpDiagnostic[]` (`ErrorInfos`).
- `FsiEvaluationSession` — the session (see **Public API surface** below).
- `Settings` module — `IEventLoop` (`Run`, `Invoke`, `ScheduleRestart`); `InteractiveSettings` (the `fsi` object: `FloatingPointFormat`, `FormatProvider`, `PrintWidth/Depth/Length/Size`, `ShowProperties`, `ShowIEnumerable`, `ShowDeclarationValues`, `AddPrinter<'T>`, `AddPrintTransformer<'T>`, `CommandLineArgs`, `EventLoop`); `val fsi : InteractiveSettings` (default instance).
- `CompilerInputStream` / `CompilerOutputStream` — `Stream` subclasses used to feed/capture I/O of a hosted dynamic-compiler process (`Add`, `Write`, `Read`).

**Key internal types** (implementation details of the session machinery):
- `Utilities` module — reflection helpers (`getAnyToLayoutCall`, `getMember`, property accessors, method invokers, `getOutputDir`).
- `ILMultiInMemoryAssemblyEmitEnv` + `ILAssemblyEmitEnv` — emit environment that maintains a *multi-fragment* in-memory assembly (fragmented re-emission of the dynamic module on each new interaction) with type/assembly reference conversion (`convTypeRef`, `convAssemblyRef`, `convResolveAssemblyRef`).
- `FsiValuePrinter` + `FsiValuePrinterMode` — reflection-based value printing honoring the host settings (depth/length/size, `ToString` overrides, registered printers/transformers).
- `FsiStdinSyphon` — background reader of stdin used to detect Ctrl+C/Ctrl+Break mid-expression.
- `FsiConsoleOutput` — console-style output (line endings, color where possible).
- `DiagnosticsLoggerThatStopsOnFirstError` — Fsi-specific diagnostics logger with early termination.
- `FsiCommandLineOptions` — parses Fsi/`fsi.exe`-style command line (`--use`, `--exec`, `--gui`, `--i`, `--r`, `--cd`, `--debug...`, `--fsimain`, `-O2`/`-g`/`-w`/`--nowarn`, `--show-properties-...`, UI culture, etc.) and builds the initial `TcConfig`.
- `FsiConsolePrompt` — emits the `fsi >` prompt (and `@f` continuation markers) based on input state.
- `FsiConsoleInput` — manages lexer buffer input and prompt state.
- `FsiInteractionStepStatus` — outcome of a parse/execute step (`Completed`, `CompletedWithReportedError`, `CtrlC`, `EndOfFile`, …).
- `FsiDynamicCompilerState` — the "compilation unit" accumulator: `currState` (checked-state), bound values, etc.
- `FsiDynamicCompiler` — the heart: `EmitInMemoryAssembly`, `CreateModuleFragment`, `ConvReflectionTypeToILType(Ref)`, `CheckEntryPoint`, `ExecuteInteractionGroup`, `ParseAndExecuteInteractionFromLexbuf`, `EvalIncludedScript(s)`, `LoadInitialFiles`, `EvalInteractionScript`, `EvalSingleInteraction`, `mkBoundValueTypedImpl`/`SetBoundValue`, fragment bookkeeping (`nextFragmentId`, `deleteScriptingSymbols`).
- `ControlEventHandler` delegate (`int -> bool`), `FsiInterruptController` + related state/request types — Ctrl+Break handling: a "killer thread" watches the interrupt flag, aborts the current thread (via `ControlledExecution`), resets abort; `MagicAssemblyResolution` — intercepts assembly resolution during dynamic compilation to keep in-memory references resolvable.
- `FsiStdinLexerProvider` — lexer factories: `LexbufFromLineReader`, `CreateLexerForLexBuffer`, included-script lexer.
- `InteractionGroup` / `FsiInteractionProcessor` — parse one interaction (expression, definition, or `#directive`) into an `InteractionGroup` and then execute it (`PartiallyProcessHashDirective`, `ExecuteInteractionGroup`, `ExecuteParsedInteractionOnMainThread`, `ParseExpression`, `EvalIncludedScript`).
- `FsiEvaluationSession` — the public session; wires the above pieces together; exposes `Create`, `Run`, `Interrupt`, `GetCompletions`, `EvalInteraction*`, `EvalScript*`, `EvalExpression*`, `FormatValue`, `ParseAndCheckInteraction`, `InteractiveChecker`, `CurrentPartialAssemblySignature`, `DynamicAssemblies`, `IsGui`, `LCID`, `ReportUnhandledException`, `ValueBound`, `GetBoundValues`/`TryFindBoundValue`/`AddBoundValue`, `GetDefaultConfiguration` (3 overloads).
- `Settings` module implementation — `IEventLoop` default, `InteractiveSettings` instance.
- `CompilerInputStream` / `CompilerOutputStream` — `Stream` implementations backed by a ring buffer for the external fsi process (used in `fsi --use` style hosting).

**Significant internal logic**:
- Session construction (`FsiEvaluationSession` constructor) sets up `TcConfigBuilder` with `isInteractive`, `INTERACTIVE` define, `netcore` profile on CoreCLR, preset `--optimize+ -g --tailcalls+`, AMD64/X86 based on `IntPtr.Size`, legacy reference resolver, `DiagnosticsLoggerThatStopsOnFirstError`, banner text, `FsiCommandLineOptions`, the interrupt controller, `FsiDynamicCompiler`, and starts the stdin reader if interacting; `Run()` then executes the main loop.
- Dynamic assembly is re-emitted in fragments (`ILMultiInMemoryAssemblyEmitEnv`) so the session's assembly survives across evaluations without losing bindings; `MagicAssemblyResolution` patches up resolution of the in-memory assembly for late-loaded code.
- Directives (`#r`, `#i`, `#cd`, `#b`, `#t`, `#measure`, `#time`, `#light`, `#nowarn`, `#nowarn`, `#printf`-style) are handled in `PartiallyProcessHashDirective` / `ExecuteInteractionGroup`; `#eval`/`#run`-style flow goes through `EvalInteraction`/`EvalScript`.
- Ctrl+Break: `FsiStdinSyphon` reads stdin on a background thread; `FsiInterruptController` runs a killer thread that, on interrupt, throws into the evaluation thread (via `Thread.Abort` on desktop / `ControlledExecution.Run` + cancel on CoreCLR) and then `ResetAbort`s.
- `EvalExpression`/`EvalInteraction` run parsing on the caller thread but execute on the "main"/event-loop thread (via the host's `IEventLoop`), enabling GUI hosting.
- `ValueBound` event fires each time a root-level `let` is bound; `GetBoundValues`/`TryFindBoundValue`/`AddBoundValue` expose the session's root bindings to hosts.

**Cross-references**:
- Signature: `fsi.fsi` (the authoritative public surface).
- `ControlledExecution.fs` — safe thread abort used by the interrupt controller.
- `FSharpInteractiveServer.fs` — Ctrl+Break named-pipe channel consumed by the host.
- `fsihelp.fs` — used by fsi for `#help`/`Help` display (via `FsiHelp`).
- `DependencyProvider` (`src/Compiler/DependencyManager/`) — `#r "nuget:…"` resolution.

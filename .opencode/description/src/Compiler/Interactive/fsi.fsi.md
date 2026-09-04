# fsi.fsi

**Purpose**: Public contract of the F# Interactive host API — everything a host (fsi.exe, Visual Studio, REPL tooling) can do with an `FsiEvaluationSession`: run it, feed it interactions, evaluate expressions and scripts, query bound values, and configure the host "fsi" settings object.

**Namespace(s)**: `FSharp.Compiler.Interactive` (module `FSharp.Compiler.Interactive.Shell`)

**Public types** (as declared):
- `FsiValue` — `ReflectionValue`, `ReflectionType`, `FSharpType`, `ToString()`.
- `FsiBoundValue` — name + `FsiValue`.
- `EvaluationEventArgs` — `Value : FsiValue option`, `SymbolUse`, `Decl : FSharpImplementationFileDeclaration`.
- `FsiEvaluationSessionHostConfig` — host configuration; members include:
  - `UseFsiAuxLib : bool` (whether `FSharp.Compiler.Interactive.Settings.dll` is referenced by default),
  - `PrintDepth`, `PrintLength`, `PrintSize`, `PrintWidth`,
  - `ShowProperties`, `ShowIEnumerable`, `ShowDeclarationValues`,
  - `FloatingPointFormat`, `FormatProvider`,
  - `AddPrinter<'T>('T -> string)`, `AddPrintTransformer<'T>('T -> objnull)`, `GetAddedPrinters`,
  - `CommandLineArgs : string[]`,
  - `EventLoop : Settings.IEventLoop`,
  - `GetFsiCommandLine : unit -> string[]`, and the `Evaluation` event.
- `FsiCompilationException` — `new : string * FSharpDiagnostic[] option`, `ErrorInfos`.
- `FsiEvaluationSession` (`[Class]`, `IDisposable`) — the session façade:
  - `Create : fsiConfig * argv * inReader * outWriter * errorWriter * ?collectible * ?legacyReferenceResolver -> FsiEvaluationSession`.
  - Execution: `Run()`, `Interrupt()`, `EvalInteraction(code, ?ct)`, `EvalInteraction(code, scriptFileName, ?ct)`, `EvalInteractionNonThrowing(...)` (both overloads), `EvalScript(filePath)`, `EvalScriptNonThrowing`, `EvalExpression(code)`, `EvalExpression(code, scriptFileName)`, `EvalExpressionNonThrowing` (both).
  - Introspection: `FormatValue(value, type)`, `ParseAndCheckInteraction(code, ?keepAssemblyContents) : FSharpParseFileResults * FSharpCheckFileResults * FSharpCheckProjectResults`, `InteractiveChecker : FSharpChecker`, `CurrentPartialAssemblySignature : FSharpAssemblySignature`, `DynamicAssemblies : Assembly[]`, `GetCompletions(longIdent) : seq<string>`, `IsGui : bool`, `LCID : int option`, `ReportUnhandledException(exn)`.
  - Bound values: `ValueBound : IEvent<objnull * Type * string>`, `GetBoundValues() : FsiBoundValue list`, `TryFindBoundValue(name) : FsiBoundValue option`, `AddBoundValue(name, value)`.
  - `PartialAssemblySignatureUpdated : IEvent<unit>`.
  - `GetDefaultConfiguration` (3 overloads: with fsi-obj + flag, with fsi-obj, or unit).
- `Settings` module — `IEventLoop` (`Run : unit -> bool`, `Invoke<'T>(unit -> 'T) : 'T`, `ScheduleRestart()`) and `InteractiveSettings` (sealed; the "fsi" object with the same formatting/display members as the host config, plus `CommandLineArgs` and `EventLoop`); `val fsi : InteractiveSettings` (the default instance used by `GetDefaultConfiguration()`).
- `CompilerInputStream` — read-only `Stream` with `Add(str)` for feeding a hosted fsi process's stdin.
- `CompilerOutputStream` — write-only `Stream` for capturing a hosted fsi process's stdout.

**Significant contract notes** (from the doc comments):
- `EvalInteraction*`, `EvalScript*` execute on the "Run()" thread and stop on first error, discarding the rest of the input; the `NonThrowing` variants return `Choice<FsiValue option, exn> * FSharpDiagnostic[]`.
- `EvalExpression*` parse on the current thread and execute synchronously on the "main" thread (blocking).
- Thread safety caveat: running these concurrently with stdin-driven evaluation is *not* fully thread-safe (repeated in each doc comment).
- `GetCompletions` is similarly not thread-safe concurrent with stdin evaluation.
- `ParseAndCheckInteraction` is intended for intellisense/brace-matching/resolve support in hosts; `keepAssemblyContents = true` retains checked contents.

**Cross-references**:
- Implementation: `fsi.fs`.
- `Settings.IEventLoop` / `InteractiveSettings` mirror the `FSharp.Compiler.Interactive.Settings.dll` contract.
- `FsiValue` / `FsiBoundValue` / `EvaluationEventArgs` are also used by `fsihelp.fs` (via `Quotations.Expr` for help rendering).

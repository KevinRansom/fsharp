# fsc.fsi

**Purpose** Signature of the driver entry point. Declares the diagnostics-logger abstractions (`IDiagnosticsLoggerProvider`, the default `ConsoleLoggerProvider`, and the test harness's `DiagnosticsLoggerUpToMaxErrors`) plus the single public entry point `CompileFromCommandLineArguments`, which is what fsc.exe and the F# SDK call to drive a whole compile invocation: parse → resolve references → parse + type-check → optimize + codegen → static link (optional) → create the IL module → save + emit pdb and XML doc.

**Pipeline role** The one call the host makes into the driver. Everything it needs — how to report diagnostics, how to exit (on a `maxErrors` breach or success), how to capture `TcImports` for the language service, and optionally how to intercept the final `ILModuleDef` (in-memory emit) — is passed as parameters.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.Driver`, declared `internal`.

**Types (contract)**

- **`IDiagnosticsLoggerProvider`** — single-method interface:
  `abstract CreateLogger: tcConfigB: TcConfigBuilder * exiter: Exiter -> DiagnosticsLogger`.
  Rationale (doc comment): "DiagnosticLoggers can be sensitive to the TcConfig flags. During the checking of the flags themselves we have to create temporary loggers, until the full configuration is available" — hence the provider takes the *not-yet-final* `TcConfigBuilder` rather than a `TcConfig`.
- **`ConsoleLoggerProvider`** — the default implementation; creates `ConsoleDiagnosticsLogger (tcConfigB, exiter)` which writes to `stderr`, colored by `DoWithDiagnosticColor`, and enforces `maxErrors` (see the error path in the .fs: `if errors >= tcConfig.maxErrors then x.HandleTooManyErrors (FSComp.SR.fscTooManyErrors ()); exiter.Exit 1`).
- **`DiagnosticsLoggerUpToMaxErrors`** (`AbstractClass`, inherits `DiagnosticsLogger`) — the base class both the real logger and the test-harness logger derive from. Constructor `(tcConfigB, exiter, nameForDebugging)`. Abstracts:
  - `HandleIssue: tcConfig * diagnostic: PhasedDiagnostic * severity: FSharpDiagnosticSeverity -> unit`
  - `HandleTooManyErrors: text: string -> unit`
  Overrides `ErrorCount` (a mutable counter) and `DiagnosticSink` (adjust severity, count errors, call `HandleTooManyErrors`+`exiter.Exit 1` on overflow, or `HandleIssue` for error/warning/info; hidden ones dropped). Doc comment notes: "Used only in LegacyHostedCompilerForTesting".

**Functions (contract)**

- **`CompileFromCommandLineArguments`** — signature:
  `ctok: CompilationThreadToken *
   argv: string[] *
   legacyReferenceResolver: LegacyReferenceResolver *
   bannerAlreadyPrinted: bool *
   reduceMemoryUsage: ReduceMemoryFlag *
   defaultCopyFSharpCore: CopyFSharpCoreFlag *
   exiter: Exiter *
   loggerProvider: IDiagnosticsLoggerProvider *
   tcImportsCapture: (TcImports -> unit) option *
   dynamicAssemblyCreator: (TcConfig * TcGlobals * string * ILModuleDef -> unit) option -> unit`.
  Runs the whole pipeline under a `DisposablesTracker` so `TcImports`/resources are disposed deterministically on both success and failure paths.

- **`internal getParallelReferenceResolutionFromEnvironment : unit -> ParallelReferenceResolution option`** — reads the env-var override for `--parallelrefresolution` (used so tests / the environment can force On/Off without touching argv).

**Public API surface (per signature)**
- `CompileFromCommandLineArguments` — the one call into the driver.
- The three logger types — the extension points the SDK / test harness use to redirect diagnostics, capture a "too many errors" event, or plug a non-interactive logger.
- `getParallelReferenceResolutionFromEnvironment` — the only `internal` extra.

**Internal helpers / active patterns** The .fs holds the whole staged implementation (`main1..main6`, `CapturingDiagnosticsLogger.CommitDelayedDiagnostics`, `SetProcessThreadLocals`, `AdjustForScriptCompile`, `ProcessCommandLineFlags`, `InterfaceFileWriter`, `CopyFSharpCore`, `TryFindVersionAttribute`, `Args`).

**Significant internal logic**
- The **provider + exiter indirection is what makes the compiler hostable**: the caller supplies how to report diagnostics, how to exit, and optionally how to capture the intermediate `TcImports` (the language service reuses this) or how to intercept the final `ILModuleDef` (used to emit in-memory rather than to file).
- The staged design (`main1 → main6`) is documented in `fsc.fs.md` — each stage returns an `Args` bundle so that the host can interpose (e.g. `tcImportsCapture` after `main1`, `dynamicAssemblyCreator` at `main5`) without re-implementing the pipeline.
- `DiagnosticsLoggerUpToMaxErrors` is the *single* place where `maxErrors` is applied; the test-harness's subclass overrides `HandleIssue` only to route the message instead of the console.

**Cross-refs**
- Implemented in: `fsc.fs` (same directory).
- Drives: `FSharp.Compiler.CompilerOptions` (flag parsing), `FSharp.Compiler.CompilerConfig` (`TcConfigBuilder`/`TcConfig`/`TcConfigProvider`), `FSharp.Compiler.CompilerImports` (`TcImports.Build*TcImports`), `FSharp.Compiler.ParseAndCheckInputs` (parse + check), `FSharp.Compiler.OptimizeInputs` (optimize + Ilx), `FSharp.Compiler.StaticLinking` (optional static link), `FSharp.Compiler.CreateILModule` (`CreateMainModule`), `FSharp.Compiler.XmlDocFileWriter` (XML doc).
- Depends on: `FSharp.Compiler.Diagnostics` (`PhasedDiagnostic`, `FSharpDiagnosticSeverity`), `FSharp.Compiler.CompilerDiagnostics` (`GetDiagnosticsLoggerFilteringByScopedNowarn`), `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.CodeAnalysis` (`Exiter`, `LegacyReferenceResolver`), `FSharp.Compiler.Text` (`range`).

# fsc.fs

**Purpose** The top-level driver for a single compilation invocation (the "fsc" pipeline). Parses the command line, resolves the reference set, and then walks the whole pipeline sequentially — parse, check, link/optimize, codegen, and finally create + save the output module, PDB, resources and XML doc file — reporting diagnostics through a pluggable logger. This is the entry point `FSharp.Compiler.Driver.CompileFromCommandLineArguments` is built around, and it is what fsc.exe and the F# SDK call.

**Namespace(s)** `FSharp.Compiler` (module `FSharp.Compiler.Driver`, internal)

**Types declared**
- `DiagnosticsLoggerUpToMaxErrors` (inherits `DiagnosticsLogger`) — reports up to a max then notifies the `exiter`; the abstract `HandleIssue`/`HandleTooManyErrors` are overridable (used by `LegacyHostedCompilerForTesting`).
- `IDiagnosticsLoggerProvider` — single-method interface `CreateLogger(tcConfigB, exiter) -> DiagnosticsLogger`, so the host can supply a config-aware logger.
- `CapturingDiagnosticsLogger` (with) — a buffering logger used to hold diagnostics raised while the options are still being parsed, then re-emit them once the real config is in place.
- `ConsoleLoggerProvider` — the default `IDiagnosticsLoggerProvider` (console, respects `maxErrors`).
- `Args<'T>` — a small newtype wrapper bundling the state handed between the `main1..main6` pipeline stages.

**Functions (pipeline stages)**
- `ConsoleDiagnosticsLogger`, `AbortOnError`, `SetProcessThreadLocals`.
- `TypeCheck ...` — the check stage: calls `ParseAndCheckInputs.CheckClosedInputSet` and threads the `TcState`/`TcResultsSink`.
- `AdjustForScriptCompile`, `ProcessCommandLineFlags`, `InterfaceFileWriter` (module that emits a `--sig` file), `CopyFSharpCore`, `TryFindVersionAttribute`, `getParallelReferenceResolutionFromEnvironment`.
- `main1` — config + options + TcImports build + parse + check (returns an `Args` bundle).
- `main2` — signature-file emission and attribute validation, prepares `Args` for codegen.
- `main3` — optimization + Ilx codegen (`OptimizeInputs.ApplyAllOptimizations`, `GenerateIlxCode`), builds `IlxGenResults`.
- `main4` — static linking (`StaticLinking.StaticLink`), reflection-free/`Ilx`-backend assembly generation.
- `main5` — `CreateILModule.CreateMainModule` + saving the module/PDB.
- `main6` — XML doc file writer (`XmlDocFileWriter`), FSharp.Core copy, final cleanup.
- `CompileFromCommandLineArguments` — the single external entry; wires `main1..main6` together and exposes the `IDiagnosticsLoggerProvider` + `exiter` + optional `dynamicAssemblyCreator`/`tcImportsCapture`.

**Public API surface** `CompileFromCommandLineArguments` (per the .fsi) — the public F#-checker-style entry the F# SDK uses. The rest is the internal staged implementation.

**Internal helpers / active patterns**
- `Args<'T>` — the "bag" threaded across `main1..main6` so that each stage only pulls what it needs.
- `CapturingDiagnosticsLogger.CommitDelayedDiagnostics` — flushes diagnostics buffered during option parsing once the final `TcConfig` is built.
- `InterfaceFileWriter` module — writes a `--sig`/signatures-only output when requested.
- `TryFindVersionAttribute` — reads `System.Reflection.AssemblyVersionAttribute`/`AssemblyFileVersionAttribute` from `TopAttribs` for the `main5` module stamping.

**Significant internal logic**
- The pipeline is deliberately split into six `mainN` stages rather than one big function so that (a) diagnostics produced early (during option parsing) are buffered and re-emitted under the final config, and (b) the host can interpose (e.g. `tcImportsCapture`, `dynamicAssemblyCreator`) without re-implementing the pipeline.
- `main1` builds `TcConfigBuilder` from CLI args (via `ProcessCommandLineFlags` → `CompilerOptions.ApplyCommandLineArgs`), constructs `TcConfig`, then resolves references (`TcImports.BuildTcImports`), parses (`ParseAndCheckInputs.ParseInputFiles`), and type-checks (`CheckClosedInputSet`).
- Ordering is: `Parse → Check → (main2) signature emit/attr check → (main3) Optimize → (main4) static link + Ilx → (main5) CreateMainModule + save → (main6) XML doc + FSharp.Core copy`.
- `main3`/`main4` call out to `FSharp.Compiler.OptimizeInputs` and `FSharp.Compiler.StaticLinking` respectively; `main5` calls `FSharp.Compiler.CreateILModule`.

**Cross-refs** `FSharp.Compiler.CompilerOptions` (flag parsing), `FSharp.Compiler.CompilerConfig` (`TcConfigBuilder`/`TcConfig`/`TcConfigProvider`), `FSharp.Compiler.CompilerImports` (`TcImports`, `TcAssemblyResolutions`), `FSharp.Compiler.ParseAndCheckInputs` (parse/check), `FSharp.Compiler.OptimizeInputs` (optimize + codegen), `FSharp.Compiler.StaticLinking`, `FSharp.Compiler.CreateILModule` (`CreateMainModule`), `FSharp.Compiler.XmlDocFileWriter`, `FSharp.Compiler.Diagnostics` (`PhasedDiagnostic`, `Exiter`), `FSharp.Compiler.TcGlobals`.

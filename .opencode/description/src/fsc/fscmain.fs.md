# fscmain.fs

> Pipeline role: The `fsc.exe` command-line entry point — a thin wrapper that names the host process, installs compiler thread context, handles `--pause`/`--times` flags, loads the MSBuild legacy reference resolver, and delegates to `Driver.CompileFromCommandLineArguments`.
> Namespace: `module internal FSharp.Compiler.CommandLineMain` (line 3).

---

## Implementation

- `[<Dependency("FSharp.Compiler.Service", LoadHint.Always)>] do ()` (19) — guarantees the compiler service is always loaded.
- `[<EntryPoint>] let main (argv)` (22) — the native `fsc` process main:
  - `compilerName` (25): `"fscAnyCpu.exe"` on 64-bit desktop .NET Framework (i.e. not on CoreCLR, detected via `typeof<obj>.Assembly.GetName().Name <> "System.Private.CoreLib"`), else `"fsc.exe"`.
  - `Thread.CurrentThread.Name <- "F# Main Thread"`; enters `UseBuildPhase BuildPhase.Parameter` (batch GC mode).
  - `AssumeCompilationThreadWithoutEvidence()` acquires the compilation-thread cookie `ctok`.
  - Prepends `compilerName` to `argv` (the compiler expects `argv[0]` to be the executable name though it ignores it).
  - Scans for `--pause` (break so a debugger can attach) and `--times` (writes `ILBinaryReader.GetStatistics()` "STATS: …" counters on `ProcessExit`, lines 58–68).
  - `LegacyMSBuildReferenceResolver.getResolver ()` (71).
  - Calls `CompileFromCommandLineArguments(ctok, argv, legacyReferenceResolver, false, ReduceMemoryFlag.No, CopyFSharpCoreFlag.Yes, QuitProcessExiter, ConsoleLoggerProvider(), None, None)` (79).
    - Comments document invariants: this is the only place `ReduceMemoryFlag.No` is set (a short-lived process may use file-locking memory-mapped files) and one of two places `CopyFSharpCoreFlag.Yes` is set (the other is `LegacyHostedCompilerForTesting`).
  - Returns `0` on success; top-level `errorRecovery e Range.range0` returns exit code `1` on any exception (last-chance).

---

## Related

- Builds on: `CompilerConfig`, `Driver` (`CompileFromCommandLineArguments`), `DiagnosticsLogger.CompilationThread`, `LegacyMSBuildResolver`, `CodeAnalysis` (for console logging + `QuitProcessExiter`), `AbstractIL.ILBinaryReader`.
- Counterpart: `fsi\fsimain.fs`, `Microsoft.FSharp.Compiler\Program.fs`.
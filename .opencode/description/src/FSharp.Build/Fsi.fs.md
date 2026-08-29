# Fsi.fs

> Pipeline role: The MSBuild task that drives the `fsi.exe` interactive session as a build-time tool (`Fsi` MSBuild task) — used by `@(FsiScripts)` project items and by tooling that needs FSI execution during build. A `ToolTask` subclass mirroring `Fsc` with interactive flags; also hosts `IFsiHostObject` integration and can *execute the inputs in-proc* for non-interactive tests via `FsiExec`.
> Namespace: `FSharp.Build` (line 3).

---

## `type public Fsi() as this = inherit ToolTask()` (line 20)

Fields: `capturedArguments`/`capturedFilenames` (for HostObject), `codePage`, `disabledWarnings`, `dotnetFsiCompilerPath`, `fsiExec`, `langVersion`, `noFramework`, `optimize`, `otherFlags`, `preferredUILang`, `provideCommandLineArgs`, `references`, `referencePath`, `skipCompilerExecution`, `sources`/`loadSources`/`useSources`, `tailcalls`, `targetProfile`, `treatWarningsAsErrors`, `warningsAsErrors`/`warningsNotAsErrors`, `warningLevel`, `vslcid`, `utf8output`, `useReflectionFreeCodeGen`; `toolPath` resolved like `Fsc` via `FSharpEnvironment.BinFolderOfDefaultFSharpCompiler`. `do this.YieldDuringToolExecution <- true` (bug 6483 comment, line 67).

**`generateCommandLineBuilder ()` (69)** emits: `--codepage:`, `--langversion:`, pointers into F# interactive `--noframework`, `--define:` items, `--optimize+/-`, `--tailcalls-`, `-r:` references, `--lib:`, `--warn:`, `--warnaserror`, `--warnaserror:` lists, `--nowarn`, `--LCID:`, `--preferreduilang:`, `--utf8output`, `--reflectionfree`, `--fullpaths`/`--flaterrors`, `--targetprofile:`, `--load:` items, `--use:` items, unquoted `otherFlags`, then `--exec` (with `Sources` after).

**Overrides**:

- `ToolName` = `"fsi.exe"` (310); `GenerateFullPathToTool` (324); `StandardErrorEncoding`/`StandardOutputEncoding` (312/318) — UTF8.
- `LogCommandLine`/`LogToolCommand` (330) — `LogMessagesFromStandardOutput`-style; `ExecuteTool(pathToTool, responseFileCommands, commandLineCommands)` (339) — runs `fsi.exe` with the built args, streaming and capturing output; on non-Windows uses the alternate `dotnet fsi.dll` path passed as a bare arg (`GenerateCommandLineCommands`, 400: `| NonNull dotnetFsiCompilerPath -> builder.AppendSwitch(dotnetFsiCompilerPath)`).
- `GenerateCommandLineCommands` (400) + `GenerateResponseFileCommands` (410) — the long-arg path writes a `.rsp` response file; `InternalGenerateCommandLineCommands` (415) helper.
- `LogEventsFromTextOutput(line, msgImportance)` (164) — parses diagnostic lines (`error FS...`, `warning FS...`) via a regex, converts to `Log.LogError/Log.LogWarning`, and forwards each to the HostObject `IFsiHostObject` (compiler errors/`--nologo` not relevant in interactive).
- `Execute()` — when `FsiExec` is set, runs the input through an in-proc `FsiEvaluationSession` instead of the external process (`fsiExecPath`? path resolution); else standard ToolTask execution. Returns `!Log.HasLoggedErrors`; `CaptureTextOutput`/`TextOutput` field holds captured stdout when requested.

---

## Related

- Uses `FSharpCommandLineBuilder`, `FSharpEnvironment`, `IFsiHostObject` host protocol; pairs with `Fsc.fs`. Imports `FSharp.Compiler.Interactive` for the `FsiExec` in-proc path.
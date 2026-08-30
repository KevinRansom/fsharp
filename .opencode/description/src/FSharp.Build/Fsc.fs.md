# Fsc.fs

> Pipeline role: The MSBuild task that runs the F# compiler. A `ToolTask` subclass (`fsc.exe`) exposing the common compiler switches as strongly-typed MSBuild properties with all the standard task semantics (`ToolPath`, `StandardOutputImportance`, `YieldDuringToolExecution`, response files, error/log capture). Header comment: "For now, not all of them are represented in the Fsc class object model. The goal is to have the most common/important flags available via the Fsc class, and the rest can be 'backdoored' through the .OtherFlags property."
> Namespace: `FSharp.Build` (line 3).

---

## `type public Fsc() as this = inherit ToolTask()` (line 19)

**Property backing fields (elsewhere in file)**: `baseAddress`, `checksumAlgorithm`, `codePage`, `compilerTools`, `compressmetadata: bool option`, `debugSymbols`, `debugType`, `defineConstants: ITaskItem[]`, `delaySign`, `deterministic`, `disabledWarnings`, `documentationFile`, `dotnetFscCompilerPath`, `embedAllSources`, `embeddedFiles`, `generateInterfaceFile`, `highEntropyVA`, `keyFile`, `langVersion`, `disabledLanguageFeatures: ITaskItem[]`, `noFramework`, `noInterfaceData`, `noOptimizationData`, `optimize` (default `true`), `otherFlags`, `outputAssembly`, `outputRefAssembly`, `pathMap`, `pdbFile`, `platform`, `prefer32bit`, `preferredUILang`, `publicSign`, `provideCommandLineArgs`, `alwaysInline: bool option`, `realsig: bool option`, `references: ITaskItem[]`, `referencePath`, `refOnly`, `resources: ITaskItem[]`, `skipCompilerExecution`, `sources: ITaskItem[]`, `sourceLink`, `subsystemVersion`, `tailcalls` (default `true`), `targetProfile`, `targetType`, `treatWarningsAsErrors`, `useStandardResourceNames`, `warningsAsErrors`, `warningsNotAsErrors`, `versionFile`, `warningLevel`, `warnOn`, `win32icon`, `win32res`, `win32manifest`, `vserrors`, `vslcid`, `utf8output`, `useReflectionFreeCodeGen`, `nullable: bool option`, `parallelCompilation: bool option`, `capturedArguments`/`capturedFilenames` (for HostObject `Compile()`).

- `defaultToolPath` (75) — resolved via `FSharpEnvironment.BinFolderOfDefaultFSharpCompiler(locationOfThisDll)`; falls back to `""`.
- `wsCharsToTrim`/`splitAndWsTrim` (102–114) — splits `;`/`,`/CR/LF-separated property lists.
- `do this.YieldDuringToolExecution <- true` (117) — "See bug 6483; this makes parallel build faster, and is fine to set unconditionally".

**`generateCommandLineBuilder ()` (119)** — the big switch-emitter mapping properties to `fsc` command-line flags via `FSharpCommandLineBuilder`:

- Output/docs/embed: `-o:'`, `--codepage:`, `-g` (debug), `--debug:` (normalized `portable|pdbonly|embedded|full`), `--embed:+`/`--embed:` items, `--sourcelink:`, `--langversion:`, `--disableLanguageFeature:`, `--noframework`, `--nointerfacedata`, `--nooptimizationdata`, `--baseaddress:`, `--compressmetadata` (optional bool), `--define:` items, `--doc:`, `--sig:`, `--keyfile:`.
- Signing/PP/switches: `--delaysign+`, `--publicsign+`, `--optimize+/-`, `--always-inline`/`--realsig` optional bools, `--tailcalls-`, nullable `--checknulls+` (+ `--define:NULLABLE`) / `--checknulls-`, `--pdb:`, `--platform:` (normalized `anycpu32bitpreferred` when AnyCPU+32bit+EXE target, else `anycpu/x86/x64/arm/arm64`), `--checksumalgorithm:`, `--win32icon:`/`--win32res:`/`--win32manifest:`.
- `--versionfile:`, `--pathmap:`, resource embedding (`--resource:` from `resources`, ref/out ref as `--refonly`/`-o:`), `--standalone`? (via `UseAlternateCommandLine`), `--pidl`? (not); custom `--compilertool:` items, references `-r:` items and `--lib:` paths, `--targetprofile:`, `--target:` (exe/winexe/library/module), `--tailcalls`, `--warn:`, `--warnon:`, `--warnaserror[+/-]` and `--warnaserror` lists, `--nowarn`, `--checked`?, `--fullpaths`, `--vserrors`, `--utf8output`, `--preferreduilang:`, `--LCID:`, `--win32manifest`, `--subsystemversion:`, `--highentropyva`, `--reflectionfree`, and finally `--` + `sources`.
- `OtherFlags` appended unquoted last; `ProvideCommandLineArgs`/`SkipCompilerExecution` gates the actual invocation.

**Overrides**: `ToolName` (`"fsc.exe"` or the `DotnetFscCompilerPath`), `GenerateFullPathToTool`, `GenerateCommandLineCommands` + `GenerateResponseFileCommands` (splitting long lists into a `.rsp` — the response path also uses `--nologo`), `LogToolCommand` (for `--testHarness`-style commands), `ExecuteTool` (executes `fsc.exe`, capturing stdout/stderr and logging events), `LogEventsFromTextOutput` (parses `warning FSxxxx`/`error FSxxxx` lines into `LogErrorFromException`-style events and forwards to HostObject `FscHostObject` when one is attached: `this.HostObject` ), `StandardOutput/ErrorEncoding` (UTF8), `HandleTaskExecutionErrors`.

**`Execute()`** — orchestrates: resolves tool path, builds either alternate (`dotnet fsc.dll`) or standard command line, sets env vars (`FSC_EXE`), runs the tool (`YieldDuringToolExecution`), and returns `!Log.HasLoggedErrors`.

---

## Related

- Uses `FSharpCommandLineBuilder`, `FSharpEnvironment` (resolver), and the HostObject protocol with Visual Studio (`IFscHostObject`, `ICompilerHostObject`).
- Sibling task: `Fsi.fs`; the actual compiler lives in `FSharp.Compiler.Service`/`fscmain`.
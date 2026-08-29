# FSharp.DependencyManager.Utilities.fs

> Pipeline role: Tool-execution and data-translation helpers for the nuget dependency manager — shared record types (`Resolution`, `PackageBuildResolutionResult`), the `DependencyManagerAttribute`, parsing of the `.resolvedReferences.paths` format, derivation of references / loads / includes from resolutions, `dotnet`/msbuild process running, parsing of `dotnet nuget list source` output, and hashing.
> Namespace: `FSharp.DependencyManager.Nuget` (line 1).

---

## Types

- `[<AttributeUsage(AttributeTargets.Assembly ||| AttributeTargets.Class, AllowMultiple = false)>] type DependencyManagerAttribute() = inherit Attribute()` (line 11) — marks a script-dependency-manager assembly/class.
- `type Resolution` (line 16) — one CSV resolution row: `NugetPackageId`, `NugetPackageVersion`, `PackageRoot`, `FullPath`, `AssetType`, `IsNotImplementationReference`, `InitializeSourcePath`, `NativePath`.
- `type PackageBuildResolutionResult` (line 29) — `{ success; projectPath; stdOut: string array; stdErr: string array; resolutionsFile: string option; resolutions: Resolution[]; references: string list; loads: string list; includes: string list }`.

## `module internal Utilities`

- `verifyFilesExist files` — all files exist?
- `findLoadsFromResolutions` — resolutions with non-empty `NugetPackageId`+`InitializeSourcePath` where that path exists → distinct init-script paths (the `#load`s).
- `findReferencesFromResolutions` — non-empty id+`FullPath`, `IsNotImplementationReference <> "true"`, `AssetType = "runtime"` → distinct runnable assembly paths (case-insensitive compare).
- `findIncludesFromResolutions` — managed `PackageRoot`s (existing dirs) + `NativePath` dirs or parent dirs of native files, all distinct (native paths slash-normalized) → probing paths to add.
- `getResolutionsFromFile resolutionsFile` (93) — splits the asset file into lines, parses the ≤8 comma-separated fields into `Resolution` records; `raise InvalidOperationException("Internal error - Invalid resolutions file format ...")` for fewer than 8 fields.
- `getOptions text` (126) — quote/escape-aware comma splitting of one directive's argument list (tracks `'` quotes, honors `\'`-style escapes, trims whitespace/quotes, lowercases names), yielding `(nameOpt, valueOpt)` pairs.
- `executeTool pathToExe arguments workingDir environment timeout` (170) — runs a process with redirected stdout/stderr (locks around per-line append), `CreateNoWindow`, strips `MSBuildSDKsPath` (host-added; can break things, line 193), sets environment vars; `TimeoutException` on `!WaitForExit(timeout)` (`SR.timedoutResolvingPackages`); returns `(successExitCode=0, output[], errors[])`.
- `buildProject dotnetHostPath projectPath binLogPath timeout` (220) — `msbuild -v:quiet -restore [/bl:"..."] "<projectPath>" /nologo /t:InteractivePackageManagement`; DEBUG-mode writes `build_CommandLine.txt`/`build_StandardOutput.txt`/`build_StandardError.txt`; on success reads `<projectPath>.resolvedReferences.paths` into the full `PackageBuildResolutionResult`.
- `generateSourcesFromNugetConfigs dotnetHostPath scriptDirectory workingDir timeout` (286) — runs `dotnet nuget list source --format detailed` (with `DOTNET_CLI_UI_LANGUAGE=en-us`); regex `(\s*\d+\.+\s*)(?'name'\S*)(\s*)\[(?'enabled'Enabled|Disabled)\](\s*)(?'uri'[^\0\r\n]*)` (ExplicitCapture) picks **enabled** feeds only and renders `<add key="…" value="…" />` lines (the CLI output shape is documented in the comment at 307–315).
- `computeSha256HashOfBytes (bytes)` — SHA-256.

---

## Related

- Backs `FSharp.DependencyManager.fs` (`readResolutions`/cache + `prepareDependencyResolutionFiles`); the resolutions-file contract is produced by the MSBuild template in `FSharp.DependencyManager.ProjectFile.fs` (`InteractivePackageManagement` target).
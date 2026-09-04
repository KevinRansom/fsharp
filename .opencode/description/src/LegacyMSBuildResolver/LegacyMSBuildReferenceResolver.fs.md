# LegacyMSBuildReferenceResolver.fs

> Pipeline role: Reference resolution for the F# compiler/FSI via an in-proc `ResolveAssemblyReference` (RAR) task from the Microsoft.Build SDK — the "legacy" (non-`.NET Core`) path used to find .NET Framework reference assemblies, searching the TargetFrameworkDirectory, AssemblyFolders(+Ex) registry locations, GAC, explicit `-I`/`#I` dirs, FSharp.Core dir and the project dir, then falling back to the implementation assemblies. It handles the dangerous `{RawFileName}` case by partitioning rooted vs unrooted references, and builds resolved "baggage"-carrying items with tooltips describing *where* each assembly was found (debug output).
> Namespace: `module FSharp.Compiler.CodeAnalysis.LegacyMSBuildReferenceResolver` (line 3).

---

## Helpers & constants

- `type Object with member GetPropertyValue(propName)` — reflection getter (used to read RAR task properties).
- `(|Null|NonNull|)` active pattern on `null`.
- `DotNetFrameworkReferenceAssembliesRootDirectory` (27) — `PF(x86) + @"\Reference Assemblies\Microsoft\Framework\.NETFramework"` (comment: ProgramFilesX86 is correct for x86 and x64).
- `[<Literal>] Net45..Net481` version strings; `SupportedDesktopFrameworkVersions` (75) ordered newest-first.
- `GetPathToDotNetFrameworkImplementationAssemblies v` (92) — maps to `ToolLocationHelper.GetPathToDotNetFramework(TargetDotNetFrameworkVersion.X)` as the **last-resort** path.
- `GetPathToDotNetFrameworkReferenceAssemblies version` (117) — `ToolLocationHelper.GetPathToStandardLibraries(".NETFramework", version, "")` (empty on `NETSTANDARD`).
- `HighestInstalledRefAssembliesOrDotNETFramework ()` (130) — picks the highest installed version: first scans `SupportedDesktopFrameworkVersions` for one whose reference-assemblies directory exists (`ToolLocationHelper.GetPathToReferenceAssemblies(FrameworkName(".NETFramework", v))`), else walks `GetPathToDotNetFramework` from v4.8.1 down. ATTENTION comment (37–41): the framework list/DeriveTargetFrameworkDirectories/HighestInstalledRefAssemblies/GetPathToDotNetFrameworkImplementationAssemblies all need updating per new MSBuild/.NET Framework release.
- `DeriveTargetFrameworkDirectories (targetFrameworkVersion, logMessage)` (192) — prepends `v` if missing, returns the reference-assemblies directories.
- `type ResolvedFrom = AssemblyFolders | AssemblyFoldersEx | TargetFrameworkDirectory | RawFileName | GlobalAssemblyCache | Path of string | Unknown` (208).
- `DecodeResolvedFrom` (218) — RAR's `ResolvedFrom` metadata string decode (incl. `"{Registry:...}"` prefix → AssemblyFoldersEx).
- `TooltipForResolvedFrom (resolvedFrom, fusionName, redist)` (227) — tooltip text enumerating path/fusion/GAC/redist/registry-key messages using `LegacyResolver.SR.*` strings ("Found by assembly folderseX search on the machine" etc.).

## `ResolveCore` (line 267)

Given env + references + TFM directories + arch + FSharp.Core dir + include dirs + flags:

- `frameworkRegistryBase/assemblyFoldersSuffix/assemblyFoldersConditions = "Software\Microsoft\.NetFramework", "AssemblyFoldersEx", ""`.
- Empty references → `[||]` (fast path).
- `protect`+`backgroundException` guard for the `IBuildEngine` adapter (logs only `LogCustomEvent`/`LogMessageEvent` to `logMessage`; errors/warnings through `logDiagnostic`), and default task-node metadata.
- Derives TF directories when empty; filters blank reference names.
- Builds `searchPaths` (331): note the *historically* different ordering for `LegacyResolutionEnvironment.EditingOrCompilation false` (scripts — TFM path first) vs `true`/`CompilationAndEvaluation` (TFM last, after include dirs); then raw file name (if `allowRawFileName`), explicit include dirs, fsharpCoreDir, implicitIncludeDir, registry, AssemblyFolders, GAC, then implementation assemblies.
- Creates `TaskItem`s carrying `Baggage` metadata; runs `ResolveAssemblyReference` with `FindRelatedFiles/FindDependencies/FindSatellites/FindSerializationAssemblies = false`, `AllowedAssemblyExtensions = dll/exe`, `TargetProcessorArchitecture`, `TargetedRuntimeVersion` (from the mscorlib `ImageRuntimeVersion`), `CopyLocalDependenciesWhenParentReferenceInGac = true`.
- Failure (`not succeeded`) → `raise LegacyResolutionFailure`.
- Maps `rar.ResolvedFiles` to `{ itemSpec; prepareToolTip; baggage }` records with decoded `ResolvedFrom`.

## `getResolver ()` (409)

`{ new ILegacyReferenceResolver with ... }`:

- `HighestInstalledNetFrameworkVersion()` → highest.
- `DotNetFrameworkReferenceAssembliesRootDirectory`.
- `Resolve(...)` — **rooted/unrooted split** (documented comment lines 432–436): `{RawFileName}` uses `Directory.GetCurrentDirectory()` which is unreliable inside Visual Studio, so only **rooted** references (e.g. `C:\...\foo.dll`) may use it; **unrooted** filename-only references stay (resolvable via  `implicitIncludeDir`); bare relative paths (`bin/Debug/foo.exe`, `..\Yadda\bar.dll`) are re-rooted at `implicitIncludeDir` before partitioning. Runs `ResolveCore` once with `allowRawFileName=true` for rooted and once with `false` for unrooted, then concatenates the results.

---

## Related

- Contract in `LegacyMSBuildReferenceResolver.fsi`; callers: `fscmain` (`LegacyMSBuildReferenceResolver.getResolver()`), FSI session plumbing, and the service's `FSharpProjectOptions` script-package resolution when `useSdkRefs` is off.
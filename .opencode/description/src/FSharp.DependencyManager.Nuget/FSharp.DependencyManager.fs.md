# FSharp.DependencyManager.fs

> Pipeline role: The F# `#r "nuget:..."` dependency manager — a `FSDependencyManager.IScriptDependencyManager` implementation (registration via `[<assembly: DependencyManager>]`) that parses `#r "nuget:pkg, version"` / `#r "nuget: pkg, version, options"` directives in .fsx/.csx scripts, generates an MSBuild project (`Project.fsproj`) + `NuGet.config` with the requested `PackageReference`s and restore sources, runs `dotnet msbuild -restore /t:InteractivePackageManagement`, reads the resulting `.resolvedReferences.paths` file, and produces `ResolveDependenciesResult` (references / loads / includes). Results are cached by a content hash of the resolution inputs.
> Namespace: `FSharp.DependencyManager.Nuget` (line 3).

---

## `module FSharpDependencyManager` (line 17)

- `[<assembly: DependencyManager>] do ()` — marks this assembly as implementing the F# dependency-manager protocol (`FSharp.DependencyManager.Nuget.FSDependencyManager`).

**Directive parsing**:

- `parsePackageReferenceOption scriptExt (setBinLogPath) (setTimeout) line` (91) — parses a single directive's option list; `validatePackageName` rejects attempts to reference `System`-ish packages (`SR.cantReferenceSystemPackage`). Handles `version=`, `include=`/`exclude=` (with package-id qualifications), `restoreSources=`, `script=` (a `.fsx` init script to `#load`), `binlog=` (sets binlog path), `timeout=`, `nowarn=`, `nugetConfigFile`? (`generateSource`?) etc.; accumulates a `PackageReference` record with defaults (`Version = "*"`, empty rest).
- `parsePackageReference scriptExt (lines: string list)` (205) — splits the raw directive text (comma-separated, quote-aware) into name + options; `parsePackageDirective scriptExt (lines: (string * string) list)` (214) — iterates over `#r`-directive text lines (the tuple is `(fileName, line)`-ish from the caller) yielding `(PackageReference list, binLogPath, timeout)`.
- `formatPackageReference p` (54) — renders a `PackageReference` as an MSBuild `<PackageReference>` item (with `ExcludeAssets='build;buildTransitive;buildMultitargeting'` unless `UsePackageTargets`) + `RestoreAdditionalProjectSources` property-group fragments via `validateAndFormatRestoreSources`.
- `validateAndFormatRestoreSources sources` (29) — file/URL restore sources: file sources get a `PropertyGroup Condition="Exists('...')"` with `RestoreAdditionalProjectSources`; missing directories raise `SR.sourceDirectoryDoesntExist`.
- `computeHashForResolutionInputs` (227) — SHA-256 over `(scriptExt, directiveLines, targetFrameworkMoniker, runtimeIdentifier)`; used as the cache key.
- `concat` helper (22) — `;`-joining of restore sources.

**Project-file generation** (`prepareDependencyResolutionFiles`, 385):

- Normalizes `scriptExt` (`.csx`→C# else `.fsx`); parses the directives into `packageReferences`/`binLogPath`/`package_timeout`.
- Emits generated nuget sources from `generateSourcesFromNugetConfigs dotnetHostPath scriptDirectory projectDirectory timeout` (parses `dotnet nuget list source --format detailed` output for enabled feeds — reference format documented inline at lines 307–315 — producing `<add key=... value=... />` entries).
- Writes `Project.fsproj` (template from `ProjectFile.generateProjectFile` with `$(TARGETFRAMEWORK)`, `$(RUNTIMEIDENTIFIER)`, `$(PACKAGEREFERENCES)`, `$(SCRIPTEXTENSION)` substituted) and `NuGet.config` (`generateProjectNugetConfigFile`, `$(NUGET_SOURCES)` substituted) via `emitFile` (dedup by hash).
- Runs `buildProject dotnetHostPath projectPath binLogPath timeout` → `PackageBuildResolutionResult` (see `Utilities.fs`).

**Class `type FSharpDependencyManager(outputDirectory, useResultsCache, additionalParams)`** (307):

- `key = "nuget"`, `name = "MsBuild Nuget DependencyManager"`.
- `projectDirectory`/`cacheDirectory` derived from `outputDirectory`; `generatedScripts: ConcurrentDictionary<string,string>`; `sdkDirOverride` from `additionalParams` ("SdkDirOverride").
- On `AppDomain.ProcessExit`: `deleteScripts ()` (best-effort cleanup of generated project files in the output dir).
- `Name`, `Key`, `HelpMessages` (two `#r "nuget:..."` examples using `SR.loadNugetPackage`/`SR.version`/`SR.highestVersion` strings).
- `ClearResultsCache()` — deletes + recreates the cache directory.
- `ResolveDependencies(scriptDirectory, scriptName, scriptExt, packageManagerTextLines, targetFrameworkMoniker, runtimeIdentifier, timeout) : obj` (502):
  - picks the `#r` prefix (double-quoted for `.csx`, verbatim `#r @"` for scripts).
  - computes `resolutionHash`; consults `tryGetResultsForResolutionHash` when caching enabled (448: reads `cache/<hash>.resolvedReferences.paths`, `verifyFilesExist`, reconstructs references/loads/includes) — else `prepareDependencyResolutionFiles`.
  - on success emits the generated script (`makeScriptFromReferences`) into the cache path (or next to the project when no hash), copies the resolutions file for reuse, and returns `ResolveDependenciesResult(success, stdOut, stdErr, references, [generatedScriptPath; ...loads], includes) :> obj`; on failure returns empty results with the failure payload.
- Constructor overloads: `new(outputDirectory, useResultsCache)`, `new(outputDirectory)` (wraps through the `IDictionary`-taking ctor).

---

## Related

- Contract in `FSharp.DependencyManager.fsi`; helpers `Utilities.fs` (resolution-file formats, tool execution) and `ProjectFile.fs` (templates); consumed by FSI/FSharp.Compiler.Service's script dependency resolution (`Checker.FindLibDirs`/`GetResolver`).
# FSharp.DependencyManager.ProjectFile.fs

> Pipeline role: MSBuild project templates + generated-script authoring for the nuget dependency manager — the `.fsproj`/`NuGet.config` XML skeletons with the `InteractivePackageManagement` target chain that computes resolved assemblies / native roots / package-info lines and writes `<project>.resolvedReferences.paths`, plus the `.fsx` helper script that `#r`s the resolved assemblies.
> Namespace: `FSharp.DependencyManager.Nuget` (line 2).

---

## `type PackageReference` (line 9)

- `{ Include: string; Version: string; RestoreSources: string; Script: string; UsePackageTargets: bool }` — the model produced by the directive parser and rendered by `formatPackageReference`.

## `module internal ProjectFile` (line 18)

- `let fsxExt = ".fsx"`, `let csxExt = ".csx"`.
- `makeScriptFromReferences (references: string seq) poundRprefix dotnetHostPath` (24) — emits the generated script body: banner with `DOTNET_HOST_PATH` (defaults `"???"` when unknown), then one `poundRprefix + ref + "\""` line per resolved reference (e.g. `#r @"C:\...\Assembly.dll"`).
- `generateProjectFile` (string literal, 46) — the `<Project Sdk='Microsoft.NET.Sdk'>` template:
  - PropertyGroup: `TargetFramework`/`RuntimeIdentifier` placeholders, `IsPackable=false`, `DisableFSharpCorePreviewCheck=true`, `RestoreEnablePackagePruning=false`, `DisableImplicitFSharpCoreReference` when not `.fsx`, `MSBuildAllProjects`, `FSharpCoreImplicitPackageVersion` fallbacks (temp fix for SDKs with broken parameterization).
  - `PackageReference Microsoft.NETFramework.ReferenceAssemblies 1.0.0` for `.NETFramework`.
  - `$(PACKAGEREFERENCES)` slot.
  - Targets: `RetrieveNuspecIdAndVersion` (`XmlPeek` into each `*.nuspec` for id/version → `NugetPackageInfo` items with `PackageRoot`), `RetrieveNuspecMetadatas` (`PropertyNames`/`NuspecFiles` discovery), `ComputePackageRootsForInteractivePackageManagement` (depends on ResolveReferences/etc.) building `InteractiveResolvedFile` items with normalized identities, `PackageRoot`, `IsNotImplementationReference` (`ref/` prefix), NuGet id/version, plus the shared-framework-conflict override (lines 144–155 — when a `Microsoft.NETCore.App.Ref`-provided assembly is missing from `_CopyLocalNames`, mark it runtime-loadable), `InitializeSourcePath` for package `content/<id>.fsx`, `NativeIncludeRoots` from `NativeCopyLocalItems`/`RuntimeTargetsCopyLocalItems`, `ProvidedPackageRoots`; and `InteractivePackageManagement` (BeforeTargets=`CoreCompile`, AfterTargets=`PrepareForBuild`) writing `$(MSBuildProjectFullPath).resolvedReferences.paths` via `WriteLinesToFile` lines of 8 comma-separated fields (NugetPackageId, Version, PackageRoot, FullPath, AssetType, IsNotImplementationReference, InitializeSourcePath, [NativePath]).
- `generateProjectNugetConfigFile` (line 216) — `nuget.config` template with `<clear />` then `$(NUGET_SOURCES)` `<add key/name/value/>` entries.

---

## Related

- Consumed by `FSharp.DependencyManager.fs` (`prepareDependencyResolutionFiles` string substitution); the `ProjectFile` module header imports `FSharpEnvironment` for host path resolution.
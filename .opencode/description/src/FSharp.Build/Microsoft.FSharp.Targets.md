# Microsoft.FSharp.Targets

## Pipeline role
The classic F# MSBuild targets file (the "F# .NET project build") — the file that actually
invokes the F# compiler through the `Fsc` task and performs resource-name generation and
compile ordering for F# projects. Imported at the bottom by
`Microsoft.FSharp.NetSdk.targets` (and by Windows/Mono variants via
`Microsoft.Portable.FSharp.Targets`).

## Task registration
`UsingTask` for `Fsc`, `Fsi`, `FSharpEmbedResourceText`, `FSharpEmbedResXSource`,
`CreateFSharpManifestResourceName`, `WriteCodeFragment`, `FSharpPlatformInformation`,
`SubstituteText` — all in `$(FSharpBuildAssemblyFile)` (next to this file, i.e.
`FSharp.Build.dll`).

## Compiler tool selection
- Properties: `FSharpPreferNetFrameworkTools`, `FSharpPreferAnyCpuTools`,
  `FSharpPrefer64BitTools`. On Arm64 machines native Arm64 fsc is default; otherwise
  AnyCPU; driven by `FSharp_Shim_Present`, `Fsc_NetFramework_*` and `Fsc_Dotnet_*`
  variables supplied by the tooling, selecting `FscToolPath/FscToolExe` and
  `DotnetFscCompilerPath`.

## Targets
- `CreateManifestResourceNames` — runs `CreateFSharpManifestResourceName` to assign
  manifest resource names to `.resx`/non-resx `EmbeddedResource` items, with xbuild
  (`UsingXBuild`) and MSBuild paths; F# subfolder naming rules apply
  (`SubFolder\Res1.resx` => `SubFolder.Res1`, `*.fr.resx` => culture satellite).
- `GenerateFSharpTextResources` (Before CoreResGen/PrepareForBuild) — `FSharpEmbedResXSource`
  generates F# accessor source from `.resx`; `FSharpEmbedResourceText` converts
  `@(EmbeddedText)` (string tables like FSComp.txt) into `.resources` + typed accessor F#
  source; both feed `@(Compile)` (CompileOrder=CompileBefore) and `@(EmbeddedResource)`.
- `FSharpSourceCodeCompileOrder` — reorders `@(Compile)` honoring
  `CompileOrder`/`CompileFirst`/`CompileBefore`/`CompileAfter`/`CompileLast` metadata
  (compile order matters for F# type inference).
- `CoreCompile` — the main F# compile: computes Inputs/Outputs for incremental build,
  emits Silverlight guard, warns on legacy `Win32ResourceFile`, merges embedded resources
  (msbuild vs xbuild variants), embeds PDB/source (`@(Embed)`, SourceLink, FsGeneratedSource),
  sets `--simpleresolution` for `SimpleResolution`, then calls the `Fsc` task passing the
  full command-line surface (`Optimize`, `Tailcalls`, `TargetProfile`, `References`,
  `WarningsAsErrors`, `Nullable`, ...).
- `GenerateTargetFrameworkMonikerAttribute` (Before BeforeCompile) — writes
  `TargetFrameworkAttribute` source for mscorlib v4+.
- `RedirectFSharpCoreReferenceToNewRedistributableLocation` (Before ResolveAssemblyReferences)
  — rewrites legacy `FSharp.Core.dll` HintPaths from the old Reference-Assemblies location to
  `$(VsInstallRoot)\Common7\IDE\CommonExtensions\Microsoft\FSharpSdk`.
- `RedirectTPReferenceToNewRedistributableLocation` — fails builds referencing the inbox
  `FSharp.Data.TypeProviders.dll` (removed in VS 16.7, directs to NuGet).
- Imports `Microsoft.Common.targets`, and optional ImportBefore/ImportAfter wildcards.

## Packaging
Shipped to the output directory by `FSharp.Build.fsproj` and included in the
`Microsoft.FSharp.Compiler` nupkg content files.
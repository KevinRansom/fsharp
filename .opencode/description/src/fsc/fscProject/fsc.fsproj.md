# fsc.fsproj

## Pipeline role
The main fsc launcher: builds the production F# compiler executable used by normal
compilations.

## Project type / frameworks
- `Microsoft.NET.Sdk`, OutputType=Exe (via fsc.targets).
- Non-Proto: on Windows `net472;$(FSharpNetCoreProductTargetFramework)`; on Unix or when
  `BUILDING_USING_DOTNET=true` only `$(FSharpNetCoreProductTargetFramework)`.
  `PlatformTarget=x86` for the `net472` target (classic fsc.exe x86 build).
- Proto configuration: single `$(FSharpNetCoreProductTargetFramework)` build with
  ReadyToRun (`PublishReadyToRun`), `RuntimeIdentifier=$(NETCoreSdkRuntimeIdentifier)`,
  and `mibc` (Managed Instrumentation Byte Code) profile-guided optimization data:
  `ReadyToRunOptimizationData=$(MibcFile)` — the MIBC file is located per
  `MibcTargetOS-MibcTargetArchitecture` under `$(ArtifactsDir)mibc-proto\...\DotNet_FSharp.mibc`.
  PGO excludes FSharp.Build.dll and FSharp.Core.dll from ReadyToRun.
- `ValidateMibcFile` target (when `IgnoreMibc != true`) fails the Proto build if the MIBC
  file is missing.

## Imports / output layout
- `BUILDING_USING_DOTNET=true` reroutes OutputPath/IntermediateOutputPath into the
  artifacts dir (`artifacts/bin/fsc/...`).
- Imports the shared `fsc.targets`, which defines the compile items and reference graph.

## Output
`fsc.exe` (net472 x86) and/or `fsc.dll` (product framework).
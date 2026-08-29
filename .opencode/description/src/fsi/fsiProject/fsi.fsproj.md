# fsi.fsproj

## Pipeline role
The main fsi launcher: builds the production F# Interactive executable.

## Project type / frameworks
- `Microsoft.NET.Sdk`, OutputType=Exe (via fsi.targets).
- Non-Proto: on Windows `net472;$(FSharpNetCoreProductTargetFramework)`; otherwise just
  `$(FSharpNetCoreProductTargetFramework)`. `PlatformTarget=x86` for net472.
- Proto configuration: single `$(FSharpNetCoreProductTargetFramework)` build with
  ReadyToRun **disabled** (`PublishReadyToRun=false`) — a comment notes crossgen2 in the
  .NET 11 preview SDK crashes on fsi (exit code 0xDEAD); re-enable once stabilized.
  PGO excludes FSharp.Build.dll and FSharp.Core.dll.
- `BUILDING_USING_DOTNET=true` reroutes Output/IntermediateOutput paths under artifacts.

## Imports / output
Imports the shared `fsi.targets` (fsimain.fs, console.fs, Legacy resolver, Win32Resource,
reference graph).

## Output
`fsi.exe` (net472 x86) and/or `fsi.dll` (product framework) — edged into the dotnet SDK
via the `Microsoft.FSharp.Compiler.nupkg`'s repack flow.
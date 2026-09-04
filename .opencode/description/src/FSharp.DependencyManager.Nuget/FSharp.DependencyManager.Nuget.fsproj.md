# FSharp.DependencyManager.Nuget.fsproj

## Pipeline role
Builds `FSharp.DependencyManager.Nuget.dll` — the NuGet-based F# dependency manager used
by F# Interactive (`#r "nuget:..."`) and the compiler service scripting pipeline.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Library`; `TargetFrameworks=netstandard2.0`;
  `AssemblyName=FSharp.DependencyManager.Nuget`; `AllowCrossTargeting=true`;
  `DefineConstants COMPILER`; `Tailcalls=true`; `Configurations=Debug;Release`.
- `NoOptimizationData=true`, `NoInterfaceData=false`, `CompressMetadata=true`.
- `CopyToBuiltBin` target (BuiltProjectOutputGroup) — placeholder used by Arcade/pack flows
  to include the dll in the built-output group.

## Compile items
- Shared compiler sources: `..\Compiler\Utilities\NullHelpers.fs`,
  `..\Compiler\Facilities\CompilerLocation.fsi/.fs`.
- `EmbeddedText`: `FSDependencyManager.txt` and
  `..\Compiler\Facilities\UtilsStrings.txt`.
- Manager implementation: `FSharp.DependencyManager.ProjectFile.fs`,
  `FSharp.DependencyManager.Utilities.fs`, `FSharp.DependencyManager.fsi/.fs` (the
  `IDependencyManagerProvider`-style implementation that shells out to `dotnet restore` of
  a generated project and reports resolved references).
- `InternalsVisibleTo FSharp.Compiler.Private.Scripting.UnitTests`.

## References
- FSharp.Core project reference (or package when `FSHARPCORE_USE_PACKAGE=true`).
- No Microsoft.Build packages — restore is delegated to the `dotnet` CLI, keeping the
  manager portable to netstandard2.0.

## Output
`FSharp.DependencyManager.Nuget.dll` (+ xml, satellites) — bundled inside
`FSharp.Compiler.Service`'s nupkg and the `Microsoft.FSharp.Compiler.nupkg`; loaded
(`--compilertool`) or found next to `fsi.dll` by scripting hosts.
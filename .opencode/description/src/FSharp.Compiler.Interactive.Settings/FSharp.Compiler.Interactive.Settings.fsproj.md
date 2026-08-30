# FSharp.Compiler.Interactive.Settings.fsproj

## Pipeline role
Builds `FSharp.Compiler.Interactive.Settings.dll` — a tiny, stable, public library that
host applications (fsi, tooling) use to obtain F# compiler configuration
(`CompilerDefinedDefaults`) and the `FSharp.Compiler.Interactive.Settings` attributes.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Library`; `TargetFrameworks=netstandard2.0`;
  `AssemblyName=FSharp.Compiler.Interactive.Settings`; `AllowCrossTargeting=true`;
  `Configurations=Debug;Release`.
- `NoOptimizationData=true`, `NoInterfaceData=false`, `CompressMetadata=true` (public
  reference surface for tool builders).
- `TolerateUnusedBindings=true` — the generated boilerplate for the (nearly empty)
  `FSInteractiveSettings.txt` resource includes a `GetStringFunc` never referenced.

## Compile items
- `EmbeddedText` `FSInteractiveSettings.txt`.
- `fsiattrs.fs` — defines the FSI attribute types (e.g. `[<CompilerDeterminedSettings>]`,
  `FSharpEnvironment` definitions).
- `fsiaux.fsi` / `fsiaux.fs` — auxiliary types: `CompilerDefinedDefaults`
  (`UseSdkLibs`, `UseFsiLibs`, `SupportedFSharpUnitsOfMeasureNames`...), the FSI server
  settings and helper modules used by fsi and VS tooling.
- `InternalsVisibleTo`: fsi, fsiAnyCpu, fsiArm64, FSharp.Compiler.

## References
- FSharp.Core project reference (or package when `FSHARPCORE_USE_PACKAGE=true`);
  `BUILDING_USING_DOTNET=true` reroutes output paths under artifacts.

## Output
`FSharp.Compiler.Interactive.Settings.dll` (+ xml, satellites). Packaged into the
`Microsoft.FSharp.Compiler` nupkg and consumed by `fsi.targets`.
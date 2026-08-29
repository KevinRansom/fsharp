# Microsoft.FSharp.Compiler.nuspec

## Pipeline role
Packaging manifest for the standalone `Microsoft.FSharp.Compiler` nupkg (the "dotnet fsc"
compiler package). Electron-style repack via `Microsoft.DotNet.NuGetRepack.Tasks`;
`{{tokens}}` are substituted by `NuspecProperties` in the fsproj.

## Structure
- Metadata: id/version from tokens, authors Microsoft, license MIT, project/repository
  https://github.com/dotnet/fsharp, description ".NET Core compatible version of the F#
  compiler fsc.exe.", `developmentDependency=true`.
  Compatibility deps group for `$FSharpNetCoreProductTargetFramework$` -> dependency on
  `FSharp.Core` at `$(FSharpCorePackageVersion)`.
- **contentFiles** (the F# MSBuild SDK support files), `any\any`:
  `default.win32manifest`, `Microsoft.FSharp.Targets`, `Microsoft.Portable.FSharp.targets`,
  `Microsoft.FSharp.NetSdk.props`, `Microsoft.FSharp.NetSdk.targets`,
  `Microsoft.FSharp.Overrides.NetSdk.targets`.
- **files**: `fsc\configuration\framework\fsc.dll`
  (buildPreference), `fsc.exe` net472 shim + `fsc.dll` product framework launcher,
  `fsi.dll` (product framework), `FSharp.Core.sigdata/optdata` passthrough, the FSI
  `fsi.exe` net472 shim, and localized satellite `**\*.resources.dll` (comments: "tiny
  deployment" — no PDBs, no .xml except where referenced).
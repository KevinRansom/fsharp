# Microsoft.FSharp.Compiler.fsproj

## Pipeline role
Builds the standalone **`Microsoft.FSharp.Compiler` NuGet package** ("dotnet fsc")
containing the .NET (Core) F# compiler `fsc.dll`, its launcher, fsi, and the F# MSBuild
props/targets for standalone use — the artifact installed by `dotnet tool install
Microsoft.FSharp.Compiler`/NuGet for compiler-on-command-line scenarios.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Exe`; `TargetFramework=$(FSharpNetCoreProductTargetFramework)`;
  `PreRelease=true`; `IsPackable=true`; `PackageId=Microsoft.FSharp.Compiler`;
  `PackageDescription=".NET Core compatible version of the F# compiler fsc.exe."`;
  `PackageLicenseExpression=MIT`, PackageProjectUrl/RepositoryUrl
  `https://github.com/dotnet/fsharp`, `PackageTags="F# fsharp .NET Compiler"`.
- `NoDefaultExcludes=true` (keep all shipped files), `NoOptimizationData=true,
  NoInterfaceData=false, CompressMetadata=true`.
- Packaging: `NuspecFile=Microsoft.FSharp.Compiler.nuspec`; `NuspecProperties` feed
  `$(FSharpNetCoreProductTargetFramework)`, `$(MicrosoftFSharpCompilerPackageVersion)`
  (from `UseFSharpProductVersion` versioning), `$(FSharpCorePackageVersion)`
  (FSharp.Core dependency token) and repo metadata; `PackageReference
  Microsoft.DotNet.NuGetRepack.Tasks` for Arcade-style repacking.

## References (project)
- `..\fsi\fsiProject\fsi.fsproj` and `..\fsc\fscProject\fsc.fsproj`
  (ReferenceOutputAssembly=true / ReferenceOnly) so they build first and their dlls are
  picked up by the nuspec's files section; plus FSharp.Core project (or package) and
  `..\Compiler\FSharp.Compiler.Service.fsproj` for the settings surface.

## Output
`Microsoft.FSharp.Compiler.<version>.nupkg` — the standalone compiler distribution package.
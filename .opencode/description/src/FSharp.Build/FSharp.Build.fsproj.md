# FSharp.Build.fsproj

## Pipeline role
Builds `FSharp.Build.dll` — the MSBuild task library used by F# projects: the `Fsc`/`Fsi`
compiler-invocation tasks, resource-text embedding, embedded resx code generation, manifest
resource naming, SourceRoot mapping, and writes the shipped `Microsoft.FSharp.*` props/
targets files.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Library`; `TargetFramework=netstandard2.0`; `AssemblyName
  =FSharp.Build`; `Nullable=enable`; `LangVersion=9` (must run inside VS that hosts older
  FSharp.Cores — no unshipped features); `NoWarn 75`; `DefineConstants LOCALIZATION_FSBUILD`;
  `CopyLocalLockFileAssemblies=true`; `Configurations Debug;Release;Proto`.
- `NoOptimizationData=true, NoInterfaceData=false, CompressMetadata=true`.
- `BUILDING_USING_DOTNET=true` reroutes output/intermediate paths under artifacts.

## Key compile items
- Shared compiler sources: `..\Compiler\Utilities\NullHelpers.fs`,
  `..\Compiler\Facilities\CompilerLocation.fs`, and `EmbeddedText` for `FSBuild.txt` and
  `..\Compiler\Facilities\UtilsStrings.txt`.
- Task implementations: `FSharpCommandLineBuilder.fs`, `Fsc.fs`, `Fsi.fs`,
  `FSharpEmbedResourceText.fs`, `FSharpEmbedResXSource.fs`, `WriteCodeFragment.fs`,
  `CreateFSharpManifestResourceName.fs`, `SubstituteText.fs`, `MapSourceRoots.fs`,
  `GenerateILLinkSubstitutions.fs`.

## Content / packaging items (None -> CopyToOutputDirectory)
`Microsoft.FSharp.Targets`, `Microsoft.Portable.FSharp.Targets`, `Microsoft.FSharp.NetSdk.props`,
`Microsoft.FSharp.NetSdk.targets`, `Microsoft.FSharp.Overrides.NetSdk.targets`, and
`Microsoft.FSharp.Core.NetSdk.props` — emitted multiple times through `NoneSubstituteText`
with the `{{FSCorePackageVersionValue}}` token replaced per distribution (Release/Shipping/
PreRelease sub-folders).

## References
- `InternalsVisibleTo VisualFSharp.UnitTests`.
- FSharp.Core project reference (or package); Microsoft.Build.Framework / Tasks.Core /
  Utilities.Core packages.

## Output
`FSharp.Build.dll` (+ xml, resource satellites, and the bundled .targets/.props files)
loaded by MSBuild via the `UsingTask` declarations in `Microsoft.FSharp.Targets`.
# Microsoft.FSharp.NetSdk.targets

## Pipeline role
.NET SDK F# language targets, imported at the bottom of evaluation. Chains the classic
`Microsoft.FSharp.Targets` and adds SDK-era behavior: simple resolution, PDB shape,
mscorlib/TargetProfile, design-time provider packaging, deterministic SourceRoot/PathMap,
trimmer substitutions, and an FSharp.Core version guard.

## Targets / properties defined
- `UsingTask MapSourceRoots` (from `$(FSharpBuildAssemblyFile)`).
- Miscellaneous defaults: `AlwaysUseNumericalSuffixInItemNames`,
  `DefineCommon*Schemas=true`, `SimpleResolution=true`.
- PDB normalization: adds missing `.pdb` extension to `_DebugSymbolsIntermediatePath`.
- `_ExplicitReference` sub-includes `$(FrameworkPathOverride)\mscorlib.dll` unless
  `NoStdLib`.
- `TargetProfile`: `mscorlib` (.NETFramework) vs `netcore` vs `netstandard` (netstandard2.0+).
- Imports `Microsoft.FSharp.Targets`.
- **Design-time provider plumbing**: `CollectFSharpDesignTimeTools` (BeforeCompile) builds
  `FscCompilerTools`/`PropertyNames` items from packages flagged
  `IsFSharpDesignTimeProvider`; `PackageFSharpDesignTimeTools` (via
  `TargetsForTfmSpecificContentInPackage`, gated by `IsFSharpDesignTimeProvider`) validates
  `FSharpToolsDirectory` (`tools`/`typeproviders`) and `FSharpDesignTimeProtocol` (only
  `fsharp41`), resolves provider TFMs with `GetTargetFrameworks`/`GetTargetPath`/NuGet's
  `GetReferenceNearestTargetFrameworkTask`, then packs the provider output (minus
  FSharp.Core/System.ValueTuple/FSharp.Core.resources) preserving subfolder layout.
- Restore source: adds `_FSharpCoreLibraryPacksFolder` to `RestoreAdditionalProjectSources`
  (when present and not disabled) so internally-built FSharp.Core preview packages resolve.
- **Deterministic/SourceRoot** (copied from Roslyn per comment): `DeterministicSourcePaths`
  auto-on when `Deterministic && ContinuousIntegrationBuild`; `InitializeSourceRootMappedPaths`
  (DependsOn `_InitializeSourceRootMappedPathsFromSourceControl`) runs `MapSourceRoots`,
  replaces `SourceRoot` items with mapped ones, declares
  `SourceRootMappedPathsFeatureSupported`; `_SetPathMapFromSourceRoots` (BeforeCoreCompile)
  prepends `SourceRoot.MappedPath`-derived entries to `PathMap`.
- **Trimming**: `GenerateFSharpILLinkSubstitutions` (BeforeCoreCompile, unless
  `DisableILLinkSubstitutions` or AssemblyName=FSharp.Core) runs `GenerateILLinkSubstitutions`
  and adds the generated `EmbeddedResource` so F# metadata resources (FSharpCheckGenerated)
  are removed under trimming; FSharp.Core itself carries the shipped substitutions.
- **FSSDK0001 warning**: `_CheckForUnsupportedFSharpCoreVersion` (AfterResolvePackageAssets)
  compares the resolved FSharp.Core major version against `FSharpCoreMaximumMajorVersion`
  and warns when a project pulls a newer FSharp.Core than this SDK's compiler supports.
# fsc.targets

## Pipeline role
Shared MSBuild `.targets` imported by all three fsc launcher projects (fscAnyCpu,
fscArm64, fscProject). These are wrapper projects over the single `FSharp.Compiler.Service`
library — the targets add the tiny fsc entry-point sources and framework-specific
switches, and resolve the needed references.

## Key definitions
- `OutputType=Exe`, `Configurations=Debug;Release;Proto`, `NoWarn 44/75` (Obsolete /
  InternalCommandLineOption), `AllowCrossTargeting=true`.
- `NoOptimizationData/NoInterfaceData=true, CompressMetadata=true` — fsc exposes no public
  reference surface, so the compiler omits optimization/interface metadata.
- Silences `MSB3277` (assembly-conflict error) that modern MSBuild can spuriously raise on
  the net472 build due to System.ValueTuple facade conflicts.

## Items
- `EmbeddedText` `LegacyResolver.txt` (from `..\LegacyMSBuildResolver\`) — assembly
  resolution narrative strings for the legacy resolver.
- `Compile` `LegacyMSBuildReferenceResolver.fsi/.fs` and `fscmain.fs` — the fsc entry
  point that drives `Driver\fsc.fs` from the compiler service.
- `NoneSubstituteText` `App.config` — token `{{FSCoreVersion}}` -> `$(FSCoreVersion)`.

## References
- FSharp.Core via project reference (or package when `FSHARPCORE_USE_PACKAGE=true`).
- ProjectReferences: `FSharp.Build.fsproj`, `FSharp.Compiler.Service.fsproj`,
  `FSharp.DependencyManager.Nuget.fsproj`.
- PackageReferences: Microsoft.Build.Framework / Tasks.Core / Utilities.Core.

## Output
`fsc.exe` (net472 x86 default) / `fsc.dll` (net core) per launcher flavor.
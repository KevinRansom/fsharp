# fsi.targets

## Pipeline role
Shared MSBuild `.targets` imported by all three fsi launcher projects (fsiAnyCpu,
fsiArm64, fsiProject) — adds the fsi main entry point, Win32 resources, framework-specific
references and the FSharp.Compiler.Interactive.Settings dependency on top of
FSharp.Compiler.Service.

## Key definitions
- `OutputType=Exe`, `Configurations=Debug;Release;Proto`, `NoWarn 44`,
  `AllowCrossTargeting=true`.
- `Win32Resource=fsi.res` — embeds the icon/manifest resource blob into the exe.
- net472 target defines `FSI_SHADOW_COPY_REFERENCES;FSI_SERVER` (shadow-copy reference
  loading and the --fsi-server remoting protocol used by the VS F# interactive window).
- `NoOptimizationData/NoInterfaceData=true, CompressMetadata=true` — no public reference
  surface.
- Silences `MSB3277` for net472 (System.ValueTuple facade conflict).
- `EmbeddedText` `LegacyResolver.txt` + `Compile` `LegacyMSBuildReferenceResolver.*` (from
  `..\LegacyMSBuildResolver\`), plus `console.fs` and `fsimain.fs` (entry points for the
  console host and server host).
- `NoneSubstituteText` `App.config` (FSCoreVersion token substitution).

## References
- FSharp.Core (project reference / FSHARPCORE_USE_PACKAGE conditional).
- ProjectReferences: `FSharp.Compiler.Service.fsproj`,
  `FSharp.Compiler.Interactive.Settings.fsproj`.
- net472 framework refs: System.Drawing, System.Windows.Forms, PresentationCore,
  PresentationFramework, WindowsBase (Windows Forms/GUI event loop support).
- PackageReferences: Microsoft.Build.Framework / Tasks.Core / Utilities.Core.

## Output
`fsi.exe` (net472) / `fsi.dll` (net core) per flavor.
# fscAnyCpu.fsproj

## Pipeline role
One of three fsc launcher projects: produces the **AnyCPU** .NET Framework variant of the
F# compiler executable (`fscAnyCpu.exe`), used on x64/arm64 dev machines where the
platform has a "preferred" flavor, and as a process-agnostic fallback.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Exe` (from imported fsc.targets);
  `TargetFrameworks=net472`; `PlatformTarget=anycpu`.
- `ExcludeFromSourceOnlyBuild=true` — the AnyCPU/Arm64 flavors are convenience launchers
  and are not part of source-build.
- Defines the AnyCPU-specific `DefineConstants`/platform handling inherited from the
  shim-selection logic in `Microsoft.FSharp.Targets`.

## Imports
Imports `fsc.targets` via `GetPathOfFileAbove`, which supplies the real fsc (fscmain.fs,
LegacyMSBuildReferenceResolver) compile items and reference graph.

## Output
`fscAnyCpu.exe` — a thin native-launchable host over FSharp.Compiler.Service.
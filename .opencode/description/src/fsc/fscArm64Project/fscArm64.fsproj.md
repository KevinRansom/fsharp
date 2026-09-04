# fscArm64.fsproj

## Pipeline role
One of three fsc launcher projects: produces the **Arm64** .NET Framework variant of the
F# compiler executable (`fscArm64.exe`), preferred on Windows-on-Arm64 machines since
native Arm64 outperforms the AnyCPU build there (see the compiler-selection comment blocks
in `Microsoft.FSharp.Targets`).

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Exe` (inherited); `TargetFrameworks=net472`;
  `PlatformTarget=arm64`.
- `ExcludeFromSourceOnlyBuild=true` — a convenience launcher not part of source-build.

## Imports
Imports `fsc.targets` (via `GetPathOfFileAbove`), giving the shared fsc compile items
(fscmain.fs, LegacyMSBuildReferenceResolver) and the FSharp.Build / Compiler.Service /
DependencyManager reference graph for this platform flavor.

## Output
`fscArm64.exe`.
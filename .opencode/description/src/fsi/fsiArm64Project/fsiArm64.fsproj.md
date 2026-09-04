# fsiArm64.fsproj

## Pipeline role
One of three fsi launcher projects: the **Arm64** .NET Framework variant of F# Interactive
(`fsiArm64.exe`), the preferred flavor on Windows-on-Arm64.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Exe` (inherited); `TargetFrameworks=net472`;
  `PlatformTarget=arm64`.
- `ExcludeFromSourceOnlyBuild=true`.
- Defines `FSI_SHADOW_COPY_REFERENCES;FSI_SERVER` for net472 server behavior.

## Imports
Imports `fsi.targets` (via `GetPathOfFileAbove`), supplying the shared fsi compile items
and resource setup.

## Output
`fsiArm64.exe`.
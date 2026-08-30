# fsiAnyCpu.fsproj

## Pipeline role
One of three fsi launcher projects: the **AnyCPU** .NET Framework variant of F# Interactive
(`fsiAnyCpu.exe`) — the flavor referenced by FSharp.Compiler.Service's runtime for scripting
diagnostics and used by the VM-independent tooling paths.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Exe` (inherited); `TargetFrameworks=net472`;
  `PlatformTarget=anycpu`.
- `ExcludeFromSourceOnlyBuild=true`.
- Defines `FSI_SHADOW_COPY_REFERENCES;FSI_SERVER` for the .NET Framework FSI server
  behavior.

## Imports
Imports `fsi.targets` via `GetPathOfFileAbove`, supplying fsimain.fs/console.fs,
LegacyMSBuildReferenceResolver, Win32Resource and reference graph.

## Output
`fsiAnyCpu.exe`.
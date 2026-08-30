# Microsoft.Portable.FSharp.Targets

## Pipeline role
Thin legacy wrapper that bootstraps F# support for **Portable Class Library** (PCL) F#
projects by importing the classic targets in an order that works on both Windows/MSBuild and
Mono.

## Import logic
- Self-registers in `MSBuildAllProjects`.
- Detects the platform flavor by probing for the portable core props:
  - Windows/.NET Framework: imports `Microsoft\Portable\Microsoft.Portable.Core.props` +
    this directory's `Microsoft.FSharp.Targets` + `Microsoft.Portable.Core.targets`.
  - Mono: imports `Microsoft\Portable\v4.0\Microsoft.Portable.Common.targets` +
    `Microsoft.FSharp.Targets` instead.
- Copes with case-sensitive filesystems: imports `Microsoft.FSharp.Targets` if present,
  else `Microsoft.FSharp.targets`.

## Content / distribution
Shipped from `FSharp.Build.fsproj` (CopyToOutputDirectory) and packaged in the
`Microsoft.FSharp.Compiler.nupkg` (`contentFiles\any\any\Microsoft.Portable.FSharp.targets`).
Retained for compatibility with legacy PCL F# projects.
# FSharp.Compiler.Service.nuspec

## Pipeline role
NuGet packaging manifest for the `FSharp.Compiler.Service` package. Consumed when
`FSharp.Compiler.Service.fsproj` is packed (IsPackable=true, `NuspecFile=
FSharp.Compiler.Service.nuspec`).

## Structure
- `$CommonMetadataElements$` and `$CommonFileElements$` are replaced by the SDK/Arcade
  NuGet repack pipeline with standard metadata (id/version/authors/description from the
  project) and the default file set.
- Metadata: `language en-US`; a single dependency group
  `targetFramework=".NETStandard2.0"` declaring runtime package dependency versions —
  `FSharp.Core` plus the seven System.* companions (Buffers, Collections.Immutable,
  DiagnosticSource, Memory, Reflection.Emit, Reflection.Metadata,
  Runtime.CompilerServices.Unsafe). Version tokens are injected as `NuspecProperty`
  items in the fsproj.
- Files under `lib\netstandard2.0`:
  - `FSharp.Compiler.Service.dll` + `.xml`
  - `FSharp.DependencyManager.Nuget.dll` + `.xml` (the bundled dependency manager)
  - `default.win32manifest`
  - culture satellites `**\FSharp.Compiler.Service.resources.dll` and
    `FSharp.DependencyManager.Nuget.resources.dll`

## Output
The published `FSharp.Compiler.Service` nupkg — the compiler-as-a-service distribution
used by F# language tooling (Ionide, LSP, FSharp.Editor).
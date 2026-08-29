# Microsoft.FSharp.Core.NetSdk.props

## Pipeline role
A Visual Studio support `.props` (imported at the top of evaluation) that makes the
selected FSharp.Core version visible to the rest of the F# SDK build. It is the file whose
`{{FSCorePackageVersionValue}}` token is substituted at FSharp.Build pack time via
`NoneSubstituteText` in `FSharp.Build.fsproj`.

## Key properties
- Appends itself to `MSBuildAllProjects` (files that influence the build graph).
- `FSCorePackageVersion` — set once (`FSCorePackageVersionSet` guard) to the substituted
  FSharp.Core package version.
- `_FSharpCoreLibraryPacksFolder` — defaults to a local `library-packs` directory next to
  the props file (used by `Microsoft.FSharp.NetSdk.targets` to add a restore source for
  internally-produced FSharp.Core nupkgs).
- `FSharpCoreMaximumMajorVersion` — once `FSCorePackageVersion` is concrete (no leftover
  `{` token), parsed from the version's major component and used by
  `_CheckForUnsupportedFSharpCoreVersion` in `Microsoft.FSharp.NetSdk.targets` to emit the
  `FSSDK0001` warning when a project references a newer FSharp.Core than the SDK compiler
  supports.

## Import
Imported by `Microsoft.FSharp.NetSdk.props` at the point the implicit FSharp.Core is
resolved.
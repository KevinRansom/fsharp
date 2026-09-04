# FSBuild.txt

## Pipeline role
String table for the `FSharp.Build` MSBuild task library. Embedded via `EmbeddedText` in
`FSharp.Build.fsproj`.

## Content (id = value)
- `toolpathUnknown,"ToolPath is unknown; specify the path to the tool."` — emitted by the
  Fsc/Fsi tasks when the compiler tool path was never resolved.
- `mapSourceRootsContainsDuplicate,"SourceRoot contains duplicate items '%s' ..."`
- `mapSourceRootsPathMustEndWithSlashOrBackslash,"SourceRoot paths are required to end
  with a slash or backslash: '%s'"`
- `mapSourceRootsNoTopLevelSourceRoot,"SourceRoot items must include at least one
  top-level (not nested) item when DeterministicSourcePaths is true"`
- `mapSourceRootsNoSuchTopLevelSourceRoot,"The value of SourceRoot.ContainingRoot was not
  found in SourceRoot items ..."`

## Roles
- The `toolpathUnknown` message surfaces when `FscToolPath`/`FsiToolPath` are unresolved in
  the FSharp task validation.
- The four `mapSourceRoots*` messages are errors raised by the **MapSourceRoots** task (the
  deterministic-build SourceRoot/PathMap machinery copied from Roslyn into
  `Microsoft.FSharp.NetSdk.targets`).

## Format / consumption
Standard `name,"value"` table; `FSharpEmbedResourceText` generates a `.resources`
satellite plus typed accessors compiled in via `LOCALIZATION_FSBUILD`. xlf satellites
provide localized builds.
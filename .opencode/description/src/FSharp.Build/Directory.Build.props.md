# Directory.Build.props

## Pipeline role
Folder-level props for `src\FSharp.Build` (the MSBuild task library). Loaded before the
src-root/repo-root props.

## What it sets
- `UseFSharpProductVersion = true` — FSharp.Build takes the F# product version scheme
  (it ships inside the dotnet SDK / Visual Studio next to fsc), not the compiler-service
  version.

## Import chain
`.props` semantics: applied first; the trailing `GetPathOfFileAbove` chains src-root and
repo-root props (LangVersion, DebugType, signing, artifacts layout).
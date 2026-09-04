# Directory.Build.props

## Pipeline role
Folder-level props for `src\Microsoft.FSharp.Compiler` (the standalone compiler NuGet
producer).

## What it sets
- `UseFSharpProductVersion = true` — this package/project version matches the F# *product*
  version (same line as the in-SDK fsc/fsi), appropriate because it repacks the compiler
  executables for redistribution outside the repo's own SDK layout.

## Import chain
`.props` semantics: applied first; trailing `GetPathOfFileAbove` chains src-root and
repo-root props (LangVersion, DebugType, signing, artifacts layout, TargetFrameworks
props).
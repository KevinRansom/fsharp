# Directory.Build.props

## Pipeline role
Folder-level props for `src\FSharp.Compiler.Interactive.Settings` (the small library that
defines `CompilerDefinedDefaults` and the `fsi` settings surface used by tool hosts).

## What it sets
- `UseFSharpProductVersion = true` — this assembly (used by the standalone `Microsoft.FSharp.Compiler`
  NuGet repack set and by every fsi flavor) takes the F# product versioning scheme.

## Import chain
`.props` semantics: applied first; trailing `GetPathOfFileAbove` chains src-root and
repo-root props.
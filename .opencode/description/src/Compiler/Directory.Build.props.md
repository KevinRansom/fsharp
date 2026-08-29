# Directory.Build.props

## Pipeline role
Directory-level props for everything under `src\Compiler`. Loaded via
`GetPathOfFileAbove` before the src-root and repo-root props.

## What it sets
- `UseFSharpCompilerServiceVersion = true` — Tells the shared versioning scripts
  (`eng/Versions.props` mechanism) that projects in this folder should take their
  assembly/file version from the FSharp.Compiler.Service version (the "compiler service"
  versioning sub-system) rather than the plain F# product version.
- Because it is a `.props`, it is evaluated before project body properties, so downstream
  property groups in `FSharp.Compiler.Service.fsproj` can rely on it.

## Notes
- This is the props file referenced in the task mapping hint as the one that governs every
  project built under `src\Compiler` (compiler service, fsc/fsi library portions etc.).
- The final `Import` chains the parent (src root) and repo-root props so LangVersion,
  DebugType, signing and artifact layout defaults from those levels still apply.
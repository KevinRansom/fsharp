# Directory.Build.props

## Pipeline role
Folder-level props for the `fsi` executable projects (`fsiProject`, `fsiAnyCpuProject`,
`fsiArm64Project`). Imported before the src-root/repo-root props.

## What it sets
- `UseFSharpProductVersion = true` — versioning for fsi executables uses the F# "product"
  version scheme (fsi.exe file/assembly version), matching fsc.
- .props semantics: evaluated first; the trailing `GetPathOfFileAbove` chains the src-root
  and repo-root props so LangVersion/DebugType/signing/artifacts defaults apply.
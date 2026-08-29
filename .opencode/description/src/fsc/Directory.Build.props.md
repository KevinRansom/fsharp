# Directory.Build.props

## Pipeline role
Folder-level props for the `fsc` executable projects (`fscProject`, `fscAnyCpuProject`,
`fscArm64Project`). Imported before the src-root/repo-root props.

## What it sets
- `UseFSharpProductVersion = true` — Switches versioning for projects under `src\fsc` to
  the F# "product" versioning scheme (the fsc.exe file/assembly version mechanism defined
  by the shared versioning scripts), rather than the compiler-service version.
- .props semantics: evaluated first; the trailing `GetPathOfFileAbove` import chains the
  parent (src root) Directory.Build.props and repo-root settings (LangVersion, DebugType,
  signing, artifacts layout).
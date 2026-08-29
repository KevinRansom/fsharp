# Directory.Build.targets

## Pipeline role
Root MSBuild targets file imported at the bottom of every project's evaluation under
`src`. It wires the shared `buildtools` targets and the repository-level
`Directory.Build.targets`.

## What it does
- `Import buildtools\buildtools.targets` — Brings in the repository's shared build-tool
  infrastructure (fslex/fsyacc tool invocation, artifacts layout helpers, etc.) used by
  the compiler and library projects.
- Imports the repo-root `Directory.Build.targets` via `GetPathOfFileAbove`.

## How it is imported
`.targets` semantics: evaluated after the project body, so it can hook targets already
declared elsewhere. Because it merely chains two imports, most targets defined by this
level get a chance to run after each project's own targets.
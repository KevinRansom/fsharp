# Directory.Build.props

## Pipeline role
Folder-level props for `src\FSharp.Core`, the F# standard library project.

## What it sets
- `UseFSharpPackageVersion = true` — the property that routes versioning for FSharp.Core to
  the *library/package* versioning scheme (FSharp.Core gets its own version line, tracked
  separately from the product / compiler-service versions), which the repo's version
  scripts consume to produce `FSCorePackageVersion`, `FSharpCoreShippedNetTargetFramework`
  pins, and the published FSharp.Core nupkg version.

## Import chain
`.props` semantics: applied first; trailing `GetPathOfFileAbove` chains src-root and
repo-root props (LangVersion, TargetFrameworks props, signing, artifacts layout).
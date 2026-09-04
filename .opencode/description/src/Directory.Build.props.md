# Directory.Build.props

## Pipeline role
Root MSBuild props file for every project under `src`. It is imported at the top of every
project build (via `GetPathOfFileAbove`) and seeds common properties used by all source
projects (compiler, FSharp.Core, fsc, fsi, FSharp.Build, tooling, VSIX).

## What it sets
- Imports the repository-level `Directory.Build.props` from the parent directory
  (repo root), which in turn imports `eng/TargetFrameworks.props` (the single source of
  truth for target frameworks) and `eng/Versions.props`.
- `DisableImplicitFSharpCoreReference = true` — Prevents the SDK from silently injecting a
  NuGet `FSharp.Core` reference; the source tree supplies FSharp.Core explicitly via
  project references (or one of the `FSHARPCORE_USE_PACKAGE` package references).
- `UseStandardResourceNames = false` — Configures the F# resource-name task used by
  `FSharp.Build`; the compiler uses its own naming scheme (e.g. `FSStrings.resources`).
- `PackageOutputPath = $(ArtifactsPackagesDir)\$(Configuration)` — Routes produced NuGet
  packages into the per-configuration artifacts packages directory.
- `ShouldUnsetParentConfigurationAndPlatform = false` — Preserves the parent's
  Configuration/Platform across the project evaluation.

## How it is imported
`.props` semantics: loaded when the project first evaluates, so these defaults are visible
to all subsequent property/item declarations and to `Directory.Build.targets`.
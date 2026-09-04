# AGENTS.md — F# Compiler Repository

Guidance for AI coding agents working in the `dotnet/fsharp` repository.
Everything below is grounded in the files in this repo (README, DEVGUIDE,
TESTGUIDE, `global.json`, `eng/Build.ps1`, `.editorconfig`, `.fantomasignore`,
the `.slnx` solution files, and the `eng/common/AGENTS.md` note). If something
here conflicts with source-of-truth files, trust the files and update this doc.

## What this repo is

The F# compiler (`fsc`), the F# core library (`FSharp.Core`), the F#
interactive (`fsi`), the compiler service library
(`FSharp.Compiler.Service`/"FCS"), the MSBuild integration, and the F# tools
for Visual Studio (the Visual F# project system, language service, and F#
editor).

## Repository layout

- **`src/`** — Primary source code.
  - `src/Compiler/` — The compiler + `FSharp.Compiler.Service` (one project
    building multiple components; `FSharp.Compiler.Service.fsproj`).
  - `src/FSharp.Core/` — The F# standard library.
  - `src/fsc/`, `src/fsi/` — `fsc.exe` (compiler) and `fsi.exe`
    (interactive) executable projects (per-architecture variants included).
  - `src/FSharp.Build/` — MSBuild targets/tasks for F# projects.
  - `src/FSharp.Compiler.LanguageServer/`,
    `src/FSharp.VisualStudio.Extension/` — LSP and VS extension entry points.
- **`tests/`** — Test suites (see the Test Suites section below).
  - `tests/fsharp/` — The older "FSharp Suite" (Cambridge) tests.
  - `tests/FSharp.Compiler.ComponentTests/` — Primary language/behavior suite.
  - `tests/FSharp.Compiler.Service.Tests/` — FCS API and internal tests,
    includes surface-area baselines.
  - `tests/FSharp.Core.UnitTests/` — FSharp.Core tests.
  - `tests/FSharp.Compiler.Private.Scripting.UnitTests/` — FSI/scripting.
  - `tests/FSharp.Test.Utilities/` — Shared xUnit v3 helpers and fixtures.
  - `tests/ILVerify/` — IL verification baselines.
  - `tests/benchmarks/` — Benchmark projects (see per-folder READMEs).
- **`vsintegration/`** — F# tools for Visual Studio.
  - `vsintegration/src/` — F# editor, project system, language service.
  - `vsintegration/Vsix/` — `VisualFSharpFull` / `VisualFSharpDebug` VSIX
    entry points, item/project templates.
  - `vsintegration/tests/` — Unit tests, editor tests, integration tests,
    mock type providers.
- **`buildtools/`** — Build helper tools (`fslex`, `fsyacc`, `AssemblyCheck`,
  `checkpackages`, `Misc`).
- **`eng/`** — Build infrastructure.
  - `eng/Build.ps1` — The main build script (restore/build/sign/pack/test/
    publish phases).
  - `eng/build.sh`, `eng/build-utils.ps1`, `eng/targets/`, `eng/tests/` —
    Supporting build logic and MSBuild infrastructure.
  - `eng/Packages.props`, `eng/Version.Details.xml`, `eng/Versions.props` —
    Package version centralization (via
    `Directory.Packages.props` → `eng/Packages.props`).
  - `eng/common/` — **Arcade-sourced files. Do NOT edit these directly; they
    are overwritten by automation.** (see `eng/common/AGENTS.md`).
- **`docs/`** — Developer documentation for the compiler, including
  `docs/index.md` (entry point) and `docs/coding-standards.md` (abbreviations
  and style guidance).
- **`setup/`** — NuGet/SDK packaging projects (e.g. `Microsoft.FSharp.SDK`).
- **`artifacts/`** — Build output (created by the build scripts; not
  committed).

## Solutions (`.slnx`)

| File | Purpose |
|------|---------|
| `FSharp.slnx` | Compiler, FSharp.Core, `fsc`, `fsi`, FSharp.Build, and core compiler tests. The primary "core" solution. |
| `FSharp.Compiler.Service.slnx` | Smaller slice: `FSharp.Compiler.Service`, FSharp.Core, `fsc`, `fsi`, FSharp.Build, ComponentTests, Service.Tests + buildtools (`fslex`, `fsyacc`, `AssemblyCheck`). Good for a lightweight, cross-platform build of FCS. |
| `VisualFSharp.slnx` | Everything in `FSharp.slnx` + the F# tools for Visual Studio under `vsintegration/` and Language Server. Only buildable on Windows with Visual Studio. |
| `VSFSharpExtension.slnx` | Small solution for the new `FSharp.VisualStudio.Extension` + LSP + F# Editor. |

## Build

### Requirements

- .NET SDK, exact version pinned in **`global.json`**
  (currently `11.0.100-preview.6.26359.118`, `allowPrerelease: true`,
  `rollForward: latestMinor`).
- If the pinned SDK is not installed, the scripts will error with
  "The .NET SDK could not be found, please run ./eng/common/dotnet.sh."
  Install it once with:
  - **Windows:** `.\eng\common\dotnet.cmd`
  - **Linux/macOS:** `./eng/common/dotnet.sh`
- On Windows, building the VS integration (`VisualFSharp.slnx`) additionally
  requires Visual Studio with the F# and Visual Studio extension development
  workloads. Use the `-noVisualStudio` flag to build only the compiler and
  FCS without VS.

### Build scripts (preferred entry points)

The root scripts are thin wrappers around `eng/Build.ps1` / `eng/build.sh`:

- **Windows (with Visual Studio):** `build.cmd`
- **Windows (compiler/FCS only, no VS required):** `build.cmd -noVisualStudio`
- **Linux / macOS:** `./build.sh`
- **Restore only:** `Restore.cmd` (Windows) or `./restore.sh` (Linux/macOS)
- **CI build:** `eng/CIBuild.cmd` / `eng/cibuild.sh`

Common flags (all supported by `eng/Build.ps1`; the `-h`/`-help` switch
prints the full list):

```
-configuration <Debug|Release>     (alias: -c)   [default: Debug]
-verbosity <q|m|n|d|diag>          (alias: -v)   [default: m (minimal)]
-restore  / -norestore             (alias: -r)
-build    / -rebuild               (alias: -b)
-sign    / -noSign
-pack
-publish
-binaryLog  / -noLog               (alias: -bl / -nolog)
-ci                            Marks a CI build
-noVisualStudio              Build only core compiler + FCS (no VS needed)
-msbuildEngine <dotnet|vs>      MSBuild engine to drive the build
/p:<k>=<v>                    Passed through to MSBuild
```

### Running `dotnet` directly against a project or solution

After the SDK has been installed once via `eng/common/dotnet.*`, you can call
`dotnet` directly:

```
dotnet build FSharp.slnx
dotnet build FSharp.Compiler.Service.slnx
dotnet build --project tests/FSharp.Compiler.ComponentTests/FSharp.Compiler.ComponentTests.fsproj
dotnet test  --project tests/FSharp.Compiler.ComponentTests/FSharp.Compiler.ComponentTests.fsproj -c Release -f net10.0
```

`global.json` sets `"test.runner": "Microsoft.Testing.Platform"`, so
`dotnet test` routes through the Microsoft Testing Platform (MTP) runner.

### Bootstrapping / proto build

The build script auto-detects whether a "bootstrap" (proto) compiler needs to
be built first (see `Update-Arguments` in `eng/Build.ps1`). To force a fresh
bootstrap, delete `artifacts/Bootstrap/` and `artifacts/Proto/` (or the whole
`artifacts/` directory) and re-run the build. This is also the way to pick up
compiler changes for building the compiler itself (see DEVGUIDE.md,
"Using your custom compiler to build this repository").

## Running tests

### Test scripts and flags

Run the same build script with a `-test*` switch. The `Test.cmd` / `test.sh`
root wrappers are equivalent to
`eng/build.ps1 -test ...`; they all build first (so keep VS closed while
desktop tests run — see TESTGUIDE.md "Close any open VisualFSharp.slnx").

```
-test                          Alias for -testDesktop (Windows, .NET Framework)
-testAll                        All suites (implies testDesktop, testCoreClr,
                                testIntegration, testVs, testAOT)
-testAllButIntegration          All minus integration tests
-testAllButIntegrationAndAot    All minus integration and AOT tests
-testCoreClr                    Cross-platform (.NET Standard / Core) tests
-testDesktop                    .NET Framework (net472) tests
-testCambridge                  Cambridge / "FSharp Suite" tests
-testCompiler                   Compiler unit tests (ComponentTests + Service.Tests)
-testCompilerComponentTests     FSharp.Compiler.ComponentTests only
-testCompilerService            FSharp.Compiler.Service.Tests only
-testFSharpCore                 FSharp.Core unit tests (both TFMs)
-testScripting                  FSI / scripting tests
-testVs                         F# editor unit tests (Windows + VS)
-testEditor                     VS Editor tests
-testIntegration                 VS IDE integration tests
-testAOT                        AOT / trimming tests (tests/AheadOfTime)
-testpack                        Verify built NuGet packages (sourcelink)
```

Examples:

```
build.cmd -testCompiler -c Release
build.cmd -testCompilerService -c Release
build.cmd -testCompilerComponentTests -c Release
build.cmd -testCambridge -c Release -ci -nobl
build.cmd -testFSharpCore -c Release
build.cmd -testScripting -c Release
build.cmd -testVs -c Release
build.cmd -testAOT -c Release
build.cmd -testAll -c Release
```

=============================================



=============================================




Notes:
- **`-c Release` is effectively required** for most test groups. Running on
  the default `Debug` can cause `StackOverflowException` or other odd
  failures (see TESTGUIDE.md → "StackOverflow exception").
- On **Linux/macOS**, only `-testCoreClr` (and its sub-test sets) are known
  to pass. Other suites are Windows-only.
- `-ci -nobl` (or `-ci -bl`) is mandatory for some test groups (Cambridge,
  some integration, etc.); `-nobl` disables binary log output.
- `-norestore` skips NuGet restore (speedup).

### Test infrastructure (xUnit v3 / MTP)

- Framework: **xUnit v3** (3.2.2) + **Microsoft.Testing.Platform (MTP)**;
  FsCheck 2.16.6 is used for property-based tests.
- All test projects are `<OutputType>Exe</OutputType>` executables (an xUnit
  v3 requirement).
- Package versions are centrally managed under `Directory.Packages.props`
  → `eng/Packages.props`.
- Test projects are run via `dotnet test --project`/`--solution` with MTP
  flags; the build script `TestUsingMSBuild` in `eng/Build.ps1` handles the
  invocation and adds xUnit TRX reporting, hang-dump timeouts, and
  results-directory placement under `artifacts/TestResults/<config>`.
- Test configuration (e.g. `parallelizeTestCollections`,
  `maxParallelThreads`) lives in `testconfig.json` files inside each test
  project.
- Shared xUnit v3 extensions (console output capture `TestConsole`,
  `DirectoryAttribute`, `FileInlineDataAttribute`, `StressAttribute`,
  `XunitSetup` assembly initializer) are in
  [tests/FSharp.Test.Utilities/](tests/FSharp.Test.Utilities/).
- The older `FSharpXunitFramework` custom test framework and `XUNIT_EXTRAS`
  batch-parallelization is **disabled / pending xUnit v3 API adaptation**
  (see TESTGUIDE.md).
- `net472` test projects are forced to `x64` in `tests/Directory.Build.props`
  to avoid OOM.

### Baselines (`.bsl`) and updating them

Many tests are baseline-driven (expected diagnostics / syntax trees / IL /
API surface area are stored in `.bsl` files and compared against actual
output in `.err`/`.vserr` during the test run).

- To update baselines in local runs, set `TEST_UPDATE_BSL=1` (see
  DEVGUIDE.md → "Updating baselines in tests").
- FSharp Suite baselines can be updated with
  `fsi tests\scripts\update-baselines.fsx` (add `-n` for a dry-run).
- ILVerify baselines live under `tests/ILVerify/` (see DEVGUIDE.md for
  `ilverify.ps1` and the two-level "exact, then soft" comparison).
- FCS surface-area baselines live under
  `tests/FSharp.Compiler.Service.Tests/...` (see DEVGUIDE.md → "Updating FCS
  surface area baselines").
- PR commands (see CONTRIBUTING.md → "Repository automation via commands"):
  - `/run fantomas` — runs `dotnet fantomas .`
  - `/run ilverify` — updates the IL verification baseline
  - `/run xlf` — refreshes localisation files for translatable strings
  - `/run test-baseline <filter>` — runs tests under `TEST_UPDATE_BSL=1` with
    a filter (e.g. `/*/*/ParseFile*/*`)

## Coding conventions and style

- Format with **Fantomas**. Configure via [`.editorconfig`](.editorconfig)
  and [`.fantomasignore`](.fantomasignore).
  - Run: `dotnet fantomas .`
  - CI check: `dotnet fantomas . --check`
  - At the time of writing only a subset of signature files (`*.fsi`) are
    formatted; the ignore file lists every directory/file excluded (all of
    `buildtools/`, `docs/`, `eng/`, `setup/`, `tests/`, and many compiler
    implementation files where the F# formatters are not yet stable).
- Line-length and other `fsharp_*` style rules are in
  [`.editorconfig`](.editorconfig) (defaults: `max_line_length=140` for
  `*.fs`, `fsharp_keep_max_number_of_blank_lines=1`, aligned bracket style,
  and several file-specific overrides under `src/Compiler/Service` and
  `src/FSharp.Build`).
- Follow the [F# style guide](https://learn.microsoft.com/dotnet/fsharp/style-guide/).
  See also [docs/coding-standards.md](docs/coding-standards.md) for the
  compiler-internal abbreviation glossary.
- Specific compiler-idiom conventions from DEVGUIDE.md → "Coding
  conventions":
  - Avoid tick-identifiers like `body'`; use an `R` suffix
    (e.g. `bodyR`) instead.
  - Avoid all-lowercase abbreviations like `bodyty`; prefer `bodyTy`.
  - Prefer `for ... do ...` over `List.iter` / `Array.iter` in the compiler
    (easier to read and debug).
- Centralised package versions: `Directory.Packages.props` →
  `eng/Packages.props` (`ManagePackageVersionsCentrally = true`). Do not
  duplicate versions in individual `.fsproj` / `.csproj` files.
- Centralised build props/targets live in the repository root
  (`Directory.Build.props`, `Directory.Build.targets`, plus `FSharpBuild.*`
  and `FSharpTests.*` variants) and in `src/`, `tests/`, `vsintegration/`.
  Be careful when adding files — pick the right folder so the right
  `Directory.Build.props` chain applies.
- **Do not edit `eng/common/**`.** That tree is Arcade-sourced and is
  overwritten by automation (see `eng/common/AGENTS.md`).

## Cross-platform notes

- **Windows-centric**: The F# tools for Visual Studio
  (`vsintegration/VisualFSharp.slnx`), the desktop `.NET Framework 4.7.2`
  target, and the majority of the test groups (`-testDesktop`,
  `-testCambridge`, `-testVs`, `-testAOT`, `-testpack`, `-testFSharpCore`,
  `-testScripting`, `-testCompiler`/`-testCompilerService`) run on Windows
  only.
- **Linux/macOS**: Only `-testCoreClr` is known to work. Use
  `./build.sh -noVisualStudio` (Windows: `build.cmd -noVisualStudio`) to
  build only the core compiler + FCS without a Visual Studio dependency.
- On Linux, `Restore.cmd`/`build.cmd`/`Test.cmd` have POSIX equivalents
  `restore.sh`, `build.sh`, `test.sh`.
- `.vsconfig` drives VS component install on Windows. If you do not want
  that, use `-noVisualStudio` and `.NET Framework 4.7.2` runtime.

## Deep reference material (read as needed)

- [README.md](README.md) — high-level overview, quick start, NuGet feed
  info, branch layout.
- [CONTRIBUTING.md](CONTRIBUTING.md) — PR policy, review expectations,
  security reporting (MSRC: `secure@microsoft.com`), PR automation commands
  (`/run fantomas`, `/run ilverify`, `/run xlf`, `/run test-baseline ...`).
- [DEVGUIDE.md](DEVGUIDE.md) — Build workflow, updating baselines, ILVerify,
  bootstrapping, FSharp.Core reference customization, VS integration F5 /
  VSIX deployment, benchmarking, and coding conventions.
- [TESTGUIDE.md](TESTGUIDE.md) — Test-suite map, xUnit v3 + MTP details,
  testgroup flags, per-run timing, common failures.
- [docs/index.md](docs/index.md) — F# Compiler technical guide (architecture,
  debugging, memory, optimizations, naming, etc.).
- [docs/coding-standards.md](docs/coding-standards.md) — Compiler-internal
  abbreviation glossary and style direction.
- [TESTGUIDE.md → Test Infrastructure](TESTGUIDE.md) — xUnit v3 / MTP /
  FsCheck / HangDump / `testconfig.json` details.
- [eng/common/AGENTS.md](eng/common/AGENTS.md) — Arcade ownership notes.

## Do's and don'ts for agents

- DO run `build.cmd` / `./build.sh` (or the `-noVisualStudio` variant)
  before running tests, and prefer `-c Release` when tests are failing with
  SOE / weird behavior.
- DO close Visual Studio (and running `dotnet` / `VBCSCompiler` /
  `MSBuild`) processes before running desktop / Cambridge tests; on
  Windows, kill dangling `MSBuild.exe` / `VBCSCompiler.exe` via
  Sysinternals Process Explorer when you see "file in use" errors.
- DO review baseline diffs (`.bsl`) carefully before committing — the goal
  of baselines is to surface *intentional* behavior changes for PR review.
- DO keep PRs small, well-scoped, and free of binary-breaking changes to
  FCS public surface, FSharp.Core, or `FSharp.Build` (see CONTRIBUTING.md
  "firm considerations").
- DO NOT submit language-feature PRs directly here; language evolution goes
  through `fsharp/fslang-suggestions` → `fsharp/fslang-design` → this repo
  (see CONTRIBUTING.md).
- DO NOT edit `eng/common/**` (Arcade-managed).
- DO NOT add or change NuGet package versions in per-project `.fsproj` /
  `.csproj` files; use `eng/Packages.props`.
- DO NOT commit build outputs, `artifacts/`, or `.dotnet/`.
- DO NOT bypass or reformat large chunks of code (e.g. "run prettier over
  the whole repo") — see CONTRIBUTING.md "DO NOT submit large code
  formatting changes without discussing with the team first".
- DO run `dotnet fantomas . --check` (or rely on the `/run fantomas` PR
  command) after touching files under the Fantomas-formatted set.


## cheat mode handy tips

### **Single?file “cheat mode” compilation (optional helper)**

Agents may occasionally need to compile a **single `.fs` file** to validate IL or inspect compiler behavior. When the scenario is **not platform?dependent**, there is an easy shortcut available on **Windows**:

> **Cheat mode:**  
> After a **successful build** (either `build -c Release` or `build -c Debug`), you may run the built **net472** compiler executable directly.  
> This requires **no special configuration** and is suitable for quick, isolated tests.

**Example:**
```
artifacts\bin\fsc\Release\net472\fsc.exe --nologo tests\FSharp.Compiler.ComponentTests\EmittedIL\RealInternalSignature\nested_generic_closure.fs --realsig+ --optimize+ --out:artifacts\Temp\RealsigPlusOptimise+.exe
```

**Example output file:**
```
09/02/2026  10:07 PM            23,552 RealsigPlusOptimise+.exe
```

**Notes:**
- This cheat mode works **only on Windows**, because it relies on the desktop CLR e.g `.NET Framework 4.7.2` or later (`net472`) compiler build.  
- It requires that the corresponding build (`Release` or `Debug`) has **already succeeded**, so the compiler binary exists under `artifacts\bin\fsc\<Configuration>\net472\`.  
- This is **not** a required workflow.  
- It is simply a **convenient shortcut** for quick, single?file builds when platform differences do not matter.  
- Agents should continue using the normal build/test infrastructure for all multi?file, platform?specific, or repository?wide tasks.


## License

MIT — see [License.txt](License.txt).

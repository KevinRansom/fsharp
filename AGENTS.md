# F# Compiler, Core Library, and Editor Tools

This repository contains the F# compiler (`fsc`), the F# core library (`FSharp.Core`), the compiler service (`FSharp.Compiler.Service`), and the F# tools for Visual Studio. It is an F# codebase (C#-hosted) built with Arcade-style tooling and an `.slnx` solution layout.

> Before non-trivial work, read `README.md`, `DEVGUIDE.md`, `TESTGUIDE.md`, and `docs/index.md` (the F# Compiler Technical Guide). `docs/coding-standards.md` is essential for understanding the compiler's compressed identifier conventions.

## Build

Build from the repository root with the build script (it provisions the correct .NET SDK from `global.json`). Do **not** run a bare `dotnet build` before the first SDK restore.

```shell
build.cmd                                # Windows: full build, incl. Visual Studio integration
build.cmd -noVisualStudio                # Windows: compiler + library, skip the VS dependency
./build.sh                               # Linux / macOS
```

Only after the SDK is provisioned can you use plain `dotnet` commands, e.g.:

```shell
dotnet build FSharp.Compiler.Service.slnx
dotnet build src/Compiler /t:UpdateXlf   # sync XLF localization files after touching keywords
```

After a successful build, open `FSharp.slnx` (core compiler + library) or `VisualFSharp.slnx` (larger, includes VS tooling) in your editor.

## Testing

Run tests through the build script from the repository root. Several groups require `-c Release` (Debug runs can throw StackOverflow). On Linux/macOS only `-testCoreClr` is currently reliable.

```shell
build.cmd -testCompiler -c Release              # quick FSharpCompiler unit tests
build.cmd -testCompilerService -c Release       # FSharpCompilerService unit tests
build.cmd -testCompilerComponentTests -c Release  # primary compiler functionality suite
build.cmd -testFSharpCore -c Release            # FSharp.Core.dll tests
build.cmd -testScripting -c Release             # fsx / fsi command-line tests
build.cmd -testCambridge -c Release -ci -nobl   # Cambridge suite (Windows; opens extra windows)
build.cmd -testAOT -c Release                   # AOT / trimming tests (Windows)
build.cmd -testAll -c Release                   # everything
```

You can also target a single xUnit v3 / Microsoft Testing Platform project:

```shell
dotnet test --project tests/FSharp.Compiler.ComponentTests/FSharp.Compiler.ComponentTests.fsproj -c Release -f net10.0
dotnet test --project <project> -c Release -- --filter-method "*YourTestName*"
```

To refresh baseline (`.bsl`) files for tests, set `TEST_UPDATE_BSL=1`, or use `fsi tests\scripts\update-baselines.fsx` (add `-n` to dry-run). Review baseline diffs carefully before committing.

Before testing after touching the lexer/parser, switching branches, or after a failed build, clean generated state:

```shell
git clean -xdf -e .vs
```

The test infrastructure is xUnit v3 (3.2.2) on the Microsoft Testing Platform (MTP). Package references are centrally managed in `tests/Directory.Build.props`, and per-project behavior is driven by `testconfig.json` files.

## Repository layout

- `src/Compiler/` — the compiler: `SyntaxTree` (parsing/lexing) → `Checking` → `TypedTree` → `Optimize` (lowering) → `CodeGen` (AbstractIL), plus `Driver` (options/diagnostics), `Symbols` (public API), `Service` (incremental build + IDE services), and `Interactive` (REPL / notebook core).
- `src/Compiler/Service/` — incremental compilation and editor-facing services.
- `src/FSharp.Core/` — the core library (implicit reference for compiled F# code).
- `src/FSharp.Compiler.LanguageServer/` — the language server.
- `tests/` — all test suites; primary is `FSharp.Compiler.ComponentTests` (compiler APIs + language conformance).
- `vsintegration/` — the F# Visual Studio project system and language service.
- `docs/` — internal compiler documentation; the required-reading technical guide.
- `eng/common/` — Arcade files, synced by automation (see `eng/common/AGENTS.md`). Do **not** hand-edit; changes must be made in the Arcade repo.

## Conventions

- Follow the existing style of the file you are editing. Format with Fantomas (`dotnet fantomas .`; checked in CI as `dotnet fantomas . --check`). See `.editorconfig` (max line length 140 for `*.fs`, Fantomas settings) and the [F# style guide](https://learn.microsoft.com/dotnet/fsharp/style-guide/).
- The compiler uses heavily compressed identifiers (`cenv`, `tcref`, `vref`, `mdef`, `bodyTy`, ...). Read `docs/coding-standards.md` for the abbreviations before assuming these are typos.
- Prefer `for ... do ...` loops over `List.iter` / `Array.iter` in the compiler.
- Avoid tick-identifiers (`body'`); use an `R` suffix (`bodyR`) for rewritten/result values.
- Avoid all-lowercase abbreviations like `bodyty`; use `bodyTy`.
- Use `Debug` configuration for local development and VS tooling iteration; do not use `Release` for local VS debugging. For performance work, build both the candidate and a baseline from source, in `Release`.

## Workflow

- This is a fork of [`dotnet/fsharp`](https://github.com/dotnet/fsharp) (`upstream`). Keep the fork in sync with the recommended commands in `DEVGUIDE.md`.
- Do not commit generated artifacts under `artifacts/`.
- Language changes follow a cross-repo process: suggestions → RFC (`fsharp/fslang-design`) → implementation here. The F# language spec is the authority for ambiguous behavior.

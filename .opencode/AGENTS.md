# F# Compiler Repository

The F# compiler (fsc), core library (FSharp.Core), and editor tooling. C#-hosted F# codebase.

## Build

```shell
build.cmd                          # Windows (full build incl. Visual Studio integration)
build.cmd -noVisualStudio          # skip VS dependency
./build.sh                         # Linux/macOS
```

Restore only via the build script (it provisions the SDK from global.json). Do not run bare `dotnet build` for the first build. After building, open `FSharp.slnx` (core) or `VisualFSharp.slnx` (with VS tools) in an editor.

## Tests (from repo root, via build script)

```shell
build.cmd -testCompiler -c Release
build.cmd -testCompilerService -c Release
build.cmd -testCompilerComponentTests -c Release
build.cmd -testFSharpCore -c Release
build.cmd -testScripting -c Release
build.cmd -testCambridge -c Release -ci -nobl
build.cmd -testAll -c Release
```

Linux/macOS: only `-testCoreClr` is reliable. See `TESTGUIDE.md` for the full suite map.

## Conventions

- Follow existing code style in the file you're editing; F# idiomatic, Fantomas-formatted (settings in `.editorconfig`, max line 140).
- Read `docs/coding-standards.md` for the compiler's abbreviations (`cenv`, `tcref`, `vref`, `mdef`, etc.) — many identifiers are heavily compressed by convention.
- Compiler architecture: `src/Compiler/` phases run in order SyntaxTree → Checking → TypedTree → Optimize → CodeGen; `src/Compiler/Service/` is incremental build + IDE services; `src/FSharp.Core/` is the core library.
- Compiler internals documentation in `docs/` is required reading before non-trivial changes.
- Don't commit generated artifacts in `artifacts/`; `git clean -xdf` is recommended before test runs after touching lexer/parser or switching branches.

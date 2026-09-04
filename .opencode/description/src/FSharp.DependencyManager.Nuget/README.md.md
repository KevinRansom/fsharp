# README.md

## Pipeline role
User-facing readme for the F# Interactive **Dependency Manager Plugins** feature (since
F# 5.0). Its URL is referenced at https://aka.ms/dotnetdepmanager — the header asks the F#
team to keep the redirect in sync if the file moves.

## Content summary
- Explains the `#r "myextension: my extension parameters"` directive syntax used by
  `dotnet fsi` and `FsiAnyCPU.exe`.
- Deployment of extension managers: place the plugin next to `fsi.dll` (dotnet SDK) or
  `FsiAnyCPU.exe` (.NET Framework), or pass `--compilertool:<extensionsfolderpath>`; the
  same applies to hosts of FSharp.Compiler.Service.
- Points at the initial RFC (fslang-design FST-1027 "fsi references") and at
  `DependencyProvider.fs` in the compiler for the runtime-reflection (late binding)
  protocol the compiler uses to discover conforming extensions.
- Documents the built-in managers:
  - `#r "nuget:"` — `FSharp.DependencyManager.Nuget`, ships by default with `dotnet fsi`;
    example referencing `Newtonsoft.Json` with optional version pinning.
  - `#r "paket:"` — Paket integration for nuget/git/gist/github dependencies with a
    `CsvProvider` example.
- Footer links: "Referencing packages in F# Interactive" and "F# Interactive options"
  learn docs plus the data attribute footnote section.

## Consumers
Users of F# Interactive scripting and maintainers of in-tree dependency managers
(FSharp.DependencyManager.Nuget).
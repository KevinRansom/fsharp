# CompilerOptions.fsi

**Purpose** Signature for the compiler option parser. Declares the option-spec DSL (`OptionSpec`, `CompilerOption`, `CompilerOptionBlock`) and the entry points to parse/process the full set of `fsc`/`fsi` command-line flags into a `TcConfigBuilder`, plus the support functions for help text, response files, abbreviations, and console output styling.

**Pipeline role** First user-facing stage: fsc.exe / fsi / the language service all call in here to turn their argument strings into flag mutations on a `TcConfigBuilder` (`ApplyCommandLineArgs`) and to collect the non-flag filenames (the source files) for the next stage (`ParseAndCheckInputs`).

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.CompilerOptions`, declared `internal`.

**Types (contract)**
- `OptionSwitch` — `On | Off`; for switches that can be suffixed with `+`/`-` (e.g. `--optimize+`, `--optimize-`).
- `OptionSpec` — the discriminated union of actions a flag triggers:
  - `OptionClear of bool ref`, `OptionSet of bool ref` — bool toggles.
  - `OptionFloat of (float -> unit)`, `OptionInt of (int -> unit)` — numeric.
  - `OptionSwitch of (OptionSwitch -> unit)` — on/off flag.
  - `OptionIntList of (int -> unit)`, `OptionIntListSwitch of (int -> OptionSwitch -> unit)`.
  - `OptionRest of (string -> unit)` — the "rest of the line" form (e.g. `--define:x` where `x` can be anything).
  - `OptionString of (string -> unit)`, `OptionStringList of (string -> unit)`, `OptionStringListSwitch of (string -> OptionSwitch -> unit)`.
  - `OptionUnit of (unit -> unit)` — no-arg flag.
  - `OptionConsoleOnly of (CompilerOptionBlock list -> unit)` — help-only action (e.g. `--help`).
  - `OptionGeneral of (string list -> bool) * (string list -> string list)` — `Applies?` * `ApplyReturningResidualArgs`; used for options whose arg shape is irregular.
- `CompilerOption` — `name: string * argumentDescriptionString * actionSpec * deprecationError: exn option * helpText: string option`.
- `CompilerOptionBlock` — `PublicOptions of heading: string * options: CompilerOption list | PrivateOptions of options: CompilerOption list` — groups options so `--help` can show only the public groups.

**Functions / values (contract)**
- Help/QA: `GetCompilerOptionBlocks (blocks, width) -> string`, `DumpCompilerOptionBlocks blocks -> unit` (used by QA tools), `FilterCompilerOptionBlock (CompilerOption -> bool) -> CompilerOptionBlock -> CompilerOptionBlock`.
- `ParseCompilerOptions (collectOtherArgument, blocks, args) -> unit` — the token loop: expands `@` response files, recognises `/flag` and `--flag` forms, dispatches each token to its `OptionSpec` action, and funnels non-flag tokens to `collectOtherArgument` (used to accumulate the source-file list).
- Banner/help/version: `GetBannerText tcConfigB`, `GetHelpFsc (tcConfigB, blocks)`, `GetVersion tcConfigB`, `GetLanguageVersions : unit -> string`.
- Option block builders: `GetCoreFscCompilerOptions`, `GetCoreFsiCompilerOptions`, `GetCoreServiceCompilerOptions` (each `TcConfigBuilder -> CompilerOptionBlock list`).
- `CheckAndReportSourceFileDuplicates (ResizeArray<string>) -> string list` — report files given twice.
- `ApplyCommandLineArgs (tcConfigB, sourceFiles, argv) -> string list` — the main entry used by fsc/fsi: parses flags, mutates the builder, and returns the collected source-file list.
- Switch setters (exposed so callers can preset defaults before parsing): `SetOptimizeSwitch`, `SetTailcallSwitch`, `SetDebugSwitch`, `SetTargetProfile`.
- `PrintOptionInfo tcConfigB` — dump current option values (used by `--?`-style tools).
- Miscellany: `ignoreFailureOnMono1_1_16` (compat helper), `mutable enableConsoleColoring: bool`, `formatOptionSwitch: bool -> string`, `DoWithColor: ConsoleColor -> (unit -> 'T) -> 'T`, `DoWithDiagnosticColor: FSharpDiagnosticSeverity -> (unit -> 'T) -> 'T`, `ReportTime: (TcConfig -> string -> unit)` (a value that reports a phase's elapsed time), `GetAbbrevFlagSet (tcConfigB, isFsc) -> Set<string>`, `PostProcessCompilerArgs (Set<string>) (string[]) -> string list` (apply abbreviations).

**Public API surface** `ApplyCommandLineArgs`, `ParseCompilerOptions`, the banner/help/version getters, `GetCoreFscCompilerOptions` / `GetCoreFsiCompilerOptions` / `GetCoreServiceCompilerOptions`, the switch setters, `CheckAndReportSourceFileDuplicates`, and the miscellany (`DoWithColor`, `DoWithDiagnosticColor`, `ReportTime`, `formatOptionSwitch`, `GetAbbrevFlagSet`, `PostProcessCompilerArgs`).

**Internal helpers / active patterns** Not exposed in the signature — the .fs holds the tag-string constants, the per-group flag tables, the switch implementations (each a closure over `TcConfigBuilder`), and the `ResponseFile` module; see `CompilerOptions.fs.md`.

**Significant internal logic** The option system is data-driven: each option is a `CompilerOption` record pairing a *name* with an `OptionSpec` closure that mutates the `TcConfigBuilder`. `ParseCompilerOptions` is the single dispatch loop; `ApplyCommandLineArgs` wraps it with the "collect the filenames" collector. Response files (`@file`) and abbreviations (`-O`, `-g`, …) are handled by `ResponseFile` and `PostProcessCompilerArgs` respectively.

**Cross-refs** Mutates `FSharp.Compiler.CompilerConfig.TcConfigBuilder`; used by `FSharp.Compiler.Driver` (fsc.fs `ProcessCommandLineFlags` / `CompileFromCommandLineArguments`); depends on `FSharp.Compiler.Diagnostics` (`FSharpDiagnosticSeverity` for `DoWithDiagnosticColor`) and `FSharp.Compiler.CompilerConfig` (`OptionSwitch` consumer, `TcConfig`).

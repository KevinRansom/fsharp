# CompilerOptions.fs (implementation)

**Purpose** The command-line option parser and flag tables for fsc/fsi. Defines the small option-spec DSL, the full catalogue of recognised switches (input/output, code-gen, language, advanced, abbreviated, internal, deprecated), response-file handling, and the `ApplyCommandLineArgs` entry point that fsc/fsi use to turn `argv` into a configured `TcConfigBuilder` plus the list of source files.

**Pipeline role** First user-facing stage of every compile: `fsc.fs` calls `ApplyCommandLineArgs`/`ProcessCommandLineFlags` before anything else, and `--help`/`--version` output is rendered from the option blocks defined here.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.CompilerOptions`, `internal`.

**Types**
- `OptionSwitch` — `On | Off`.
- `OptionSpec` — `OptionClear`, `OptionFloat`, `OptionInt`, `OptionSwitch`, `OptionIntList`, `OptionIntListSwitch`, `OptionRest`, `OptionSet`, `OptionString`, `OptionStringList`, `OptionStringListSwitch`, `OptionUnit`, `OptionConsoleOnly`, `OptionGeneral`.
- `CompilerOption` — `CompilerOption of name * argumentDescriptionString * actionSpec * deprecationError * helpText`.
- `CompilerOptionBlock` — `PublicOptions of heading * options | PrivateOptions of options`.
- `ResponseFileData` / `ResponseFileLine` — `CompilerOptionSpec of string | Comment of string`.

**Core parsing (lines ~227-510)**
- `ResponseFile.parseFile path -> Choice<ResponseFileData, Exception>` — reads a `@` response file line by line, stripping `#` comments and blank lines.
- `ParseCompilerOptions (collectOtherArgument, blocks, args)` — the token loop: flattens the blocks into specs, and for each argument handles `@responseFile` expansion (errors `optsResponseFileNameInvalid` / `optsResponseFileNotFound`), `--` end-of-options, and both `-x`/`--x` and `/x` forms via `parseOption` (splits name from `:args`), `getOptionArg`/`getOptionArgList` (errors `buildOptionRequiresParameter` when an argument is required but missing; list form splits on `,` and `;`), `getSwitch`/`getSwitchOpt` (recognises `+`/`-` suffixes → `OptionSwitch.On/Off`), then dispatches into the `OptionSpec` action.
- `isSlashOpt` — recognise MSFT-style `/flag` form; `CompilerOptionUsage` / `getCompilerOption` / `getPublicOptions` / `GetCompilerOptionBlocks` / `DumpCompilerOptionBlocks` render the block tables (with optional width-wrapping) for `--help` output.

**Switch implementations (each a closure over `TcConfigBuilder`)** — notables:
- Optimization/codegen: `SetOptimizeOn`/`SetOptimizeOff`/`SetOptimizeSwitch`, `SetTailcallSwitch`, `SetDeterministicSwitch`, `SetRealsig`, `SetReferenceAssemblyOnlySwitch`, `SetReferenceAssemblyOutSwitch`, `jitoptimizeSwitch`, `localoptimizeSwitch`, `crossOptimizeSwitch`, `splittingSwitch`, `callVirtSwitch`, `callParallelCompilationSwitch`, `useHighEntropyVASwitch`, `subSystemVersionSwitch` (validate "major.minor").
- Target/output: `SetTarget` (maps `exe`/`winexe`/`library`/`module` to `CompilerTarget`), `setOutFileName`, `setSignatureFile`, `setAllSignatureFiles`, `SetDebugSwitch` (validates full/pdbonly/portable/embedded), `SetEmbedAllSourceSwitch`, `libFlag`, `AddPathMapping` (parses `old=new;...` pairs).
- Language: `languageFlags tcConfigB` + `setLanguageVersion` + `GetLanguageVersions` (validates `version`/`latest`/`preview`); `defineSymbol`; `codePageFlag`; `preferredUiLang`; `utf8OutputFlag`; `fullPathsFlag`.
- References/framework: `cliRootFlag`, `SetTargetProfile` (validates a profile name), `SetUseSdkSwitch`, `noFrameworkFlag isFsc`.
- Diagnostics: `errorsAndWarningsFlags` (warn lists, `maxerrors`, `flaterrors`, `checknullness`, `checkoverflow`), `gnuStyleErrorsFlag`, reporting style.
- FSLIB-specific compilation: `compilingFsLibFlag` / `compilingFsLib20Flag` / `compilingFsLib40Flag` / `compilingFsLibNoBigIntFlag` (set of mutually-exclusive "compiling FSharp.Core" modes).
- Testing/QA: `testFlag tcConfigB` (the large `#if TEST`-gated table incl. `simulateexception`, `reportnumdecls`, `tokenize` variants, interaction parser tests), `testingAndQAFlags`.
- Internal: `internalFlags` (~370 lines of private/test switches), `editorSpecificFlags`.
- Deprecated: `deprecatedFlagsFsi` / `deprecatedFlagsFsc` (raise `DeprecatedCommandLineOption*` via `deprecationError`).
- Miscellany: `miscFlagsBoth/Fsc/Fsi` (banner, times, pause, stats, `reporttimes`, codepage, `--utf8output`), `abbreviatedFlagsBoth/Fsc/Fsi` (the `-O`, `-g`, `-d:`, `-out:` short flags) + `GetAbbrevFlagSet` / `PostProcessCompilerArgs`, `miscFlagsFsi`, `PrintOptionInfo`, `GetBannerText`, `GetHelpFsc`, `GetVersion`, `SimulateException`.

**Miscellany**
- `mutable enableConsoleColoring = true` — global switch; `DoWithColor` / `DoWithDiagnosticColor` switch the console foreground colour around a computation (with restore), and `foreBackColor()` snapshots the previous state.
- `ReportTime = (tcConfig: TcConfig) (s: string)` — value-level helper printing per-phase timing when `tcConfig.showTimes`.
- `formatOptionSwitch value = if value then "on" else "off"`.
- `ignoreFailureOnMono1_1_16 f` — swallow an `IOException` from an old Mono bug.
- `CheckAndReportSourceFileDuplicates (sourceFiles: ResizeArray<string>) -> string list` — report `buildSourceFileSpecifiedMultipleTimes` for duplicates and de-dup the list.
- `ApplyCommandLineArgs (tcConfigB, sourceFiles, argv) -> string list` (line ~2367) — the entry: calls `ParseCompilerOptions` with a collector accumulating non-flag args, then `CheckAndReportSourceFileDuplicates`.

**Public API surface** See `CompilerOptions.fsi.md`; from the .fs the additionally visible internal helpers are the switch closures (all used by the option tables).

**Significant internal logic**
- Flags are *closures over the builder*: each table function returns `CompilerOption list`, each `OptionSpec` calls `tcConfigB.<field> <- ...`, so the whole table is pure data plus small closures, easy to filter (`FilterCompilerOptionBlock`) or compose per host (fsc vs fsi vs service).
- Response-file parsing is deliberately simple (one token per line, `#` comments) and is expanded *in place* of the `@` token, so a response file can itself contain further `@` files.
- Deprecated options still parse but their `deprecationError` is raised as a *recoverable* diagnostic at parse time, which `CompilerDiagnostics` renders with the standard message format.

**Cross-refs** `FSharp.Compiler.CompilerConfig` (all setters target `TcConfigBuilder`), `FSharp.Compiler.Diagnostics` (severity for coloured output), `FSharp.Driver`/fsc.fs (consumer), and `FSharp.Compiler.CompilerDiagnostics` (the `DeprecatedCommandLineOption*` exceptions defined there are raised via the `deprecationError` field).

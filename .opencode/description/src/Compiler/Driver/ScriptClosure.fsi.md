# ScriptClosure.fsi

**Purpose** Signature for computing the "load closure" of an F# script — the full set of `#load`ed files, `#r`ed references, and package-manager references (and their diagnostics) that a script or a set of root files transitively brings in. Used to drive both F# Interactive and `fsc` when the input is a script.

**Namespace(s)** `FSharp.Compiler` (module `FSharp.Compiler.ScriptClosure`, internal)

**Types declared (contract)**
- `CodeContext` — `CompilationAndEvaluation | Compilation | Editing`: the mode in which the closure is being computed; affects which directives are legal.
- `LoadClosureInput` — `{ FileName; SyntaxTree: ParsedInput option; ParseDiagnostics; MetaCommandDiagnostics }` — one script in the closure with its (maybe) parsed syntax tree and the diagnostics for it.
- `LoadClosure` — the full result:
  - `SourceFiles: (string * range list) list` — source file names + the `#load` ranges in each.
  - `References: (string * AssemblyResolution list) list` — references + the `#r` ranges in each.
  - `PackageReferences: (range * string list)[]` — package-manager `#r` lines.
  - `PackageManagerLines: Map<string, PackageManagerLine list>` — the raw package-manager lines.
  - `UseDesktopFramework: bool` — whether a .NET Framework reference set was decided for.
  - `SdkDirOverride: string option` — the SDK directory override if given.
  - `UnresolvedReferences: UnresolvedAssemblyReference list` — references that didn't resolve.
  - `Inputs: LoadClosureInput list` — the inputs themselves.
  - `OriginalLoadReferences: (range * string * string) list` — all `#load` references (including failures).
  - `ResolutionDiagnostics: PhasedDiagnostic list` — diagnostics during resolution.
  - `AllRootFileDiagnostics: PhasedDiagnostic list` — for the root file (used by fsc.fs).
  - `LoadClosureRootFileDiagnostics: PhasedDiagnostic list` — for the "compiler-options-implied" root.

**Functions (contract)**
- `LoadClosure.ComputeClosureOfScriptText legacyReferenceResolver defaultFSharpBinariesDir fileName sourceText caret implicitDefines useSimpleResolution useFsiAuxLib useSdkRefs sdkDir lexResourceManager applyCompilerOptions assumeDotNetFramework tryGetMetadataSnapshot reduceMemoryUsage dependencyProvider -> LoadClosure` — analyze a raw script *text* (from the FCS edit scenario) and find its closure. The long parameter list is deliberate (per the doc comment in the .fsi): a temporary `TcConfig` must be synthesized from host-supplied flags so that the closure computation matches the rest of the application's configuration — in particular `applyCompilerOptions : TcConfigBuilder -> unit` lets the host apply its own defaults (per the doc comment: "We want to be sure to use exactly the same arguments as the rest of the application"), `caret : Position option` is the editor cursor position (used to exclude an in-flight `#r` line from resolution), and `assumeDotNetFramework` seeds the primary-assembly choice.
- `LoadClosure.ComputeClosureOfScriptFiles (tcConfig, (fileName, range) list, implicitDefines, lexResourceManager, dependencyProvider) -> LoadClosure` — the fsc/fsi entry: given an existing `TcConfig` and the list of root files (command-line or `#load`), compute the closure; the caller (fsc `main1`, via `AdjustForScriptCompile`) then adds the resolved references back into the builder.

**Record-shape notes**
- `SourceFiles: (string * range list) list` pairs each source file with the *ranges of the `#load`s* that introduced it — the driver uses this to report `#load` diagnostics at the right places.
- `References: (string * AssemblyResolution list) list` pairs each `#r` text with the concrete resolutions (so FCS or fsc can add exactly those to the builder and still report per-`#r` diagnostics), while `PackageReferences: (range * string list)[]` retains the raw package-manager lines keyed by the directive range and `PackageManagerLines` the unprocessed directives.
- `UseDesktopFramework: bool` records the framework decision for the whole closure; fsc uses it to pick the primary assembly (`Mscorlib` vs `System.Runtime`) — see `fsc.fs` `AdjustForScriptCompile`.
- `SdkDirOverride: string option` is preserved from the input so that downstream stages (e.g. `TcImports` resolution) see the same SDK directory the closure was computed against.
- `UnresolvedReferences` (a `CompilerConfig` type) carries the `#r` lines that failed to resolve, so the driver can report them with proper context rather than losing them in the closure.
- Three separate diagnostic lists, `ResolutionDiagnostics`, `AllRootFileDiagnostics` (the .fsi note: "used by fsc.fs") and `LoadClosureRootFileDiagnostics` (the "compiler options implied root of closure" diagnostics) split the three sources of diagnostics the closure can produce: during reference resolution, for the root file itself, and for the compiler-options-derived implicit root.
- `OriginalLoadReferences: (range * string * string) list` retains every `#load` reference (including the ones that did not resolve — the .fsi says "including those that didn't resolve"), so diagnostics can cite the original text as the user typed it.

**Public API surface** `ComputeClosureOfScriptText` (FCS) and `ComputeClosureOfScriptFiles` (fsc/fsi) — both static members of `LoadClosure`. Everything else of the API is the record shape documented above.

**Internal helpers / active patterns** The walking/iteration logic is in the `.fs` (see `ScriptClosure.fs.md`): the `Observed` cycle-breaker, the mutually recursive closure walk (`FindClosureFiles`), and the three-way dependency-manager recursion (`resolveDependencyManagerSources` / `processPackageManagerLines` / `resolvePackageManagerLines`) are all `.fs` internals, not part of this signature.

**Significant internal logic**
- The closure computation is *separate from* type-checking: it only parses scripts and resolves their directives. This is what lets `fsc` know the full set of source files + references before it builds `TcImports` (see fsc.fs `main1`), and what lets FCS edit a script without having a real project.
- `PackageReferences` are reported alongside the plain `References` because a `#r "NuGet(id=...)"`-style line may resolve via the dependency manager to a concrete assembly that is *different from* (and in addition to) a plain `#r "Assembly.dll"` reference, and the driver needs to distinguish the two when it builds `TcImports`.
- `CodeContext` (the first declared type) drives which directives are *legal* (e.g. `#load`/`#r` are only allowed in scripts under `CompilationAndEvaluation` or `Editing` contexts with a script file) and which `LegacyResolutionEnvironment` (compilation vs evaluation) the temporary `TcConfig` gets.
- The `caret` parameter does not appear in the record shape but does appear in `ComputeClosureOfScriptText`'s signature; it is the position of the insertion point when FCS is analyzing, and in the `.fs` implementation it is used to filter out package-manager lines whose range covers the caret so they are not resolved mid-typing.

**Cross-refs** Called from `FSharp.Compiler.Driver` (fsc.fs `main1`, via `AdjustForScriptCompile`, when the roots are scripts) and from FCS (the `ComputeClosureOfScriptText` path). Depends on `FSharp.Compiler.CompilerConfig` (`TcConfig`/`TcConfigBuilder`, `PackageManagerLine`, `UnresolvedAssemblyReference`), `FSharp.Compiler.CompilerImports` (`AssemblyResolution`), `FSharp.Compiler.DependencyManager` (`DependencyProvider`, the dependency-manager `#r` resolution), `FSharp.Compiler.FxResolver` (default references, TFM/RID), `FSharp.Compiler.Diagnostics` (`PhasedDiagnostic`), `FSharp.Compiler.ParseAndCheckInputs` (`ParseOneInputSourceText` / `ParseOneInputLexbuf` per input, `IsScript`, `ProcessMetaCommandsFromInput`), and `FSharp.Compiler.Syntax` (`ParsedInput`).


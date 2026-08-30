# CompilerConfig.fs (implementation)

**Purpose** The compiler's configuration object. Defines the mutable `TcConfigBuilder` (all flags accumulated from the command line and `#`-directives) and the immutable `TcConfig` (a snapshot of it) threaded through the whole compile, plus the reference-assembly plumbing used by the language service (`IProjectReference`, `IRawFSharpAssemblyData`) and the deferred-config wrapper `TcConfigProvider`.

**Pipeline role** The single source of truth for *how* a compilation runs. `CompilerOptions` fills the builder, `fsc.fs` turns it into a `TcConfig`, and every later stage (`CompilerImports`, `ParseAndCheckInputs`, `OptimizeInputs`, `StaticLinking`, `CreateILModule`, `XmlDocFileWriter`) takes the `TcConfig` (or a `TcConfigProvider`) as input.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.CompilerConfig`, `internal`.

**Module-level values**
- `(++) x s = x @ [s]` — list-append operator used throughout.
- `FSharpSigFileSuffixes = [".fsi"]`; `FSharpImplFileSuffixes = [".fs"; ".fsscript"; ".fsx"]`; `FSharpScriptFileSuffixes = [".fsscript"; ".fsx"]`.
- `FSharpExperimentalFeaturesEnabledAutomatically` — true iff the `FSHARP_EXPERIMENTAL_FEATURES` env var is set and non-whitespace.
- `TryResolveFileUsingPaths (paths, m, fileName)` — resolve a possibly-relative file name against the path list (rooted names are checked directly; invalid paths raise a `buildProblemWithFilename` error).
- `ResolveFileUsingPaths` — same, but raises `FileNameNotResolved` on failure.
- `GetWarningNumber (m, description, langVersion, source)` — parse a `-warn`/`#nowarn` description; handles `FS`-prefixed codes and gates on `LanguageFeature.ParsedHashDirectiveArgumentNonQuotes`, warning via `buildInvalidWarningNumber` when a compiler directive specifies an unrecognised code.
- `ComputeMakePathAbsolute implicitIncludeDir path` — strip quotes and make relative paths absolute.
- `GetFSharpCoreLibraryName () = getFSharpCoreLibraryName` (line ~1515).

**Exceptions** `FileNameNotResolved of searchedLocations * fileName * range`; `LoadedSourceNotFoundIgnoring of fileName * range`.

**Enums / small types**
- `WarningNumberSource` — `CommandLineOption | CompilerDirective`.
- `WarningDescription` — `Int32 of int | String of string | Ident of Ident`.
- `CompilerTarget` — `WinExe | ConsoleExe | Dll | Module` + `IsExe`.
- `ResolveAssemblyReferenceMode` — `Speculative | ReportErrors` (internal use by CompilerImports).
- `CopyFSharpCoreFlag` — `Yes | No`.
- `VersionFlag` — `VersionString | VersionFile | VersionNone`, with `GetVersionInfo` (parses to `ILVersionInfo`, erroring `buildInvalidVersionString`) and `GetVersionString` (reads first line of the file, erroring `buildInvalidVersionFile`).
- `TimeStampCache` — `ConcurrentDictionary`-backed file-timestamp cache (`GetFileTimeStamp`) and project-reference logical-timestamp cache (`GetProjectReferenceTimeStamp`), seeded with a `defaultTimeStamp`.
- `ProjectAssemblyDataResult` — `Available of IRawFSharpAssemblyData | Unavailable of useOnDiskInstead: bool`.
- `IProjectReference` — abstract: `FileName`, `EvaluateRawContents: Async<ProjectAssemblyDataResult>`, `TryGetLogicalTimeStamp cache -> DateTime option`.
- `IRawFSharpAssemblyData` — abstract: `GetAutoOpenAttributes`, `GetInternalsVisibleToAttributes`, `TryGetILModuleDef`, `HasAnyFSharpSignatureDataAttribute`, `HasMatchingFSharpSignatureDataAttribute`, `GetRawFSharpSignatureData`, `GetRawFSharpOptimizationData`, `GetRawTypeForwarders`, `ILScopeRef`, `ILAssemblyRefs`, `ShortAssemblyName`.
- `AssemblyReference` — `AssemblyReference of range * text * IProjectReference option`, members `Range`, `Text`, `ProjectReference`, `SimpleAssemblyNameIs` (tolerant: compares filename-without-extension, or parses a strong-name identity via `System.Reflection.AssemblyName`), `ToString`.
- `UnresolvedAssemblyReference` — `string * AssemblyReference list`.
- `ResolvedExtensionReference` (typeproviders) — `string * AssemblyReference list * Tainted<ITypeProvider> list`.
- `ImportedAssembly` — record: `ILScopeRef`, `FSharpViewOfMetadata: CcuThunk`, `AssemblyAutoOpenAttributes`, `AssemblyInternalsVisibleToAttributes`, optional `IsProviderGenerated`/`mutable TypeProviders`, `FSharpOptimizationData: Lazy<LazyModuleInfo option>`.
- `AvailableImportedAssembly` — `ResolvedImportedAssembly | UnresolvedImportedAssembly`.
- `CcuLoadFailureAction` — `RaiseError | ReturnNone`.
- `Directive` — `Resolution | Include`.
- `LStatus` — `Unprocessed | Processed`.
- `TokenizeOption` — `AndCompile | Only | Debug | Unfiltered`.
- `PackageManagerLine` — record (`Directive`, `LineStatus`, `Line`, `Range`) with static members: `AddLineWithKey` (appends a stripped, unprocessed line under a package key via `MultiMap`), `RemoveUnprocessedLines`, `SetLinesAsProcessed`, `StripDependencyManagerKey`.
- `MetadataAssemblyGeneration` — `None | ReferenceOut of outputPath | ReferenceOnly`.
- `ParallelReferenceResolution` — `On | Off`.
- `TypeCheckingMode` — `Sequential | Graph`; `TypeCheckingConfig` — `{ Mode; DumpGraph }` (default `Mode=Graph`, `DumpGraph=false`).

**`TcConfigBuilder`** (line ~449, `NoEquality NoComparison`)
- The large mutable record (~150 fields) — every flag from `-O`, `-g`, `--target`, `-doc`, strong-name, PDB, resources, language features, parallelism, `LanguageFeature`/`langVersion`, `exiter`, `typeCheckingConfig`, `compilationMode`, etc.
- `GetNativeProbingRoots()` (line ~669) — *delayed* `seq` of native-DLL probing roots: includes → compilerToolPaths → directories of referenced DLLs → `implicitIncludeDir`, then `distinct`. The comment stresses it must stay a lazy sequence because it is recomputed at each resolution and can grow.
- `static member CreateNew (...)` (line ~682) — installs every default (e.g. `primaryAssembly=Mscorlib`, `target=ConsoleExe`, `maxErrors=100`, `compressMetadata=true`, `portablePDB=true`, `parallelParsing=true`, `parallelIlxGen=true`, `alwaysCallVirt=true`, `jitTracking=true`, `checksumAlgorithm=Sha256`, `typeCheckingConfig={Graph; false}`, `exiter=QuitProcessExiter`, …).
- `FxResolver` (line ~859) — lazily creates the `FxResolver` from `primaryAssembly`/`useSdkRefs`/`sdkDirOverride` and caches it; `SetPrimaryAssembly`/`SetUseSdkRefs` invalidate the cache.
- `ResolveSourceFile (m, nm, pathLoadedFrom)` (line ~888) — resolve against `includes` + `pathLoadedFrom`.
- `DecideNames sourceFiles` (line ~900) — error if no inputs; derive output extension from `target` (`.dll`/`.netmodule`/`.exe`), derive output + assembly name from the last impl file unless `-out` given, derive the PDB name (error `buildPdbRequiresDebug` if `-debug-` but `-debugfile` given).
- `TurnWarningOff/On (m, s)` (line ~951/~962) — update `diagnosticsOptions.WarnOff/WarnOn` via `GetWarningNumber`.
- `AddIncludePath` (line ~973) — validate existence, warn if missing, de-duplicate.
- `AddLoadedSource` (line ~995) — resolve + de-duplicate `#load`ed sources.
- `AddEmbeddedSourceFile` / `AddEmbeddedResource` (line ~1015/~1018).
- `AddCompilerToolsByPath` (line ~1021) — de-duplicate by path text.
- `AddReferencedAssemblyByPath` (line ~1030) — warn if invalid, de-duplicate by (range, text), attach an `IProjectReference` if one matches by `FileName`.
- `AddDependencyManagerText` (line ~1045) / `AddReferenceDirective` (line ~1048) — route `#r`/`#i`: query the `DependencyProvider` in `compilerToolPaths` (reporting via `ResolvingErrorReport`); a plain path becomes a reference; a dependency-manager match requires `LanguageFeature.PackageManagement` (error `packageManagementRequiresVFive` otherwise); `#I` with no manager → `poundiNotSupportedByRegisteredDependencyManagers`; neither → `buildInvalidHashrDirective`.
- `RemoveReferencedAssemblyByPath` (line ~1082).
- `AddPathMapping` (line ~1087) — `PathMap.addMapping`.
- `SplitCommandLineResourceInfo` (line ~1090) — parse `file[,name[,public|private]]` for linked resources; error `buildInvalidPrivacy` for a bad flag.

**`TcConfig`** (line ~1119, `Sealed`)
- Constructor: optionally validates (`version.GetVersionInfo`) and clones the builder record.
- Closures computed once: `computeKnownDllReference` (locate primary-assembly and FSharp.Core references among `referencedDLLs`, falling back to a default `AssemblyReference`), explicit `primaryAssemblyReference`, `fslibReference`, `clrRootValue`/`targetFrameworkVersionValue` (rooted at the explicit primary-assembly dir or `HighestInstalledNetFrameworkVersion`), `makePathAbsolute`, `targetFrameworkDirectories` (branches on explicit clrRoot and on `resolutionEnvironment` between CompilationAndEvaluation — runtime dir + Facades + WPF + refs-pack dirs — and EditingOrCompilation — framework reference-assemblies root/version + Facades + refs-pack).
- `static member Create (builder, validate)` (line ~1406, wraps in `UseBuildPhase Parameter`).
- Members mirroring every builder flag, plus: `FxResolver`, `alwaysInline` (defaults to `optSettings.LocalOptimizationsEnabled || extraOptimizationIterations > 0` when `alwaysInline=None`), `CloneToBuilder`, `ComputeCanContainEntryPoint` (only the last file, if an exe target), `GetTargetFrameworkDirectories`, `GetAvailableLoadedSources` (second-chance resolve against `includes`, else `LoadedSourceNotFoundIgnoring`), `GetSearchPathsForLibraryFiles`, `MakePathAbsolute`, `ResolveSourceFile`, `PrimaryAssemblyDllReference`, `CoreLibraryDllReference`, `GetNativeProbingRoots`, `IsSystemAssembly` (in target dirs, or `FxResolver.GetSystemAssemblies` base-name set, or a reference-pack directory), `GenerateSignatureData`/`GenerateOptimizationData` (not `standalone` and not `noSignatureData`), `assumeDotNetFramework` (`primaryAssembly = Mscorlib`).

**`TcConfigProvider`** (line ~1501)
- `TcConfigProvider of (CompilationThreadToken -> TcConfig)`; `Get ctok`; `Constant`; `BasedOnMutableBuilder` (re-creates from the live builder on each `Get` — used by F# Interactive).

**Public API surface** `TcConfig.Create`, `TcConfigBuilder.CreateNew` + all mutation/query methods, `TcConfigProvider.*`, `TryResolveFileUsingPaths`, `ResolveFileUsingPaths`, `GetWarningNumber`, `GetFSharpCoreLibraryName`, the suffix lists, `FSharpExperimentalFeaturesEnabledAutomatically`.

**Significant internal logic**
- **Immutability contract:** `TcConfig` clones the builder record and reads only the local copy; the header comment says it must stay immutable.
- **`FxResolver` memoization:** the resolver depends on late-set flags, so it is created on demand and invalidated by the two setters.
- **Deferred probing roots:** `GetNativeProbingRoots` is a lazy sequence deliberately recomputed on every call (comment at line ~659-668).
- **Target-framework dir set:** the branch on `resolutionEnvironment` is what lets F# Interactive use implementation assemblies while fsc uses reference assemblies (per the inline comments).

**Cross-refs** `FSharp.Compiler.CompilerOptions` (populates the builder), `FSharp.Compiler.CompilerImports` (reads `AssemblyReference`/`IRawFSharpAssemblyData`, builds `TcImports` under a `TcConfigProvider`), `FSharp.Compiler.FxResolver` (the memoized member + `IsSystemAssembly`), `FSharp.Compiler.Driver` (creates the builder + `TcConfig` for fsc), `FSharp.Compiler.CompilerDiagnostics` (reads `diagnosticsOptions`), `FSharp.Compiler.TcGlobals`/checkers (read the dozens of flags), `FSharp.Compiler.CodeAnalysis` (`LegacyReferenceResolver`, `Exiter`).

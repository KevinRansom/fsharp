# CompilerConfig.fsi

**Purpose** Signature for the compiler configuration types. Defines the contract for `TcConfigBuilder` (mutable, command-line-driven) and the immutable `TcConfig` snapshot threaded through the entire compilation (parse, check, optimize, codegen, emit), plus the reference-assembly plumbing types (`AssemblyReference`, `IProjectReference`, `IRawFSharpAssemblyData`, `PackageManagerLine`) and small enums shared across the driver (`CompilerTarget`, `CopyFSharpCoreFlag`, `MetadataAssemblyGeneration`, `TypeCheckingMode`, …).

**Pipeline role** Central data type: every other driver module reads the `TcConfig` produced here — `CompilerOptions` mutates the builder; `CompilerImports` reads `AssemblyReference`/`IProjectReference`; `ParseAndCheckInputs`, `OptimizeInputs`, `CreateILModule`, `StaticLinking`, and `XmlDocFileWriter` all take `TcConfig` as their first parameter.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.CompilerConfig`, declared `internal`.

**Exceptions declared**
- `FileNameNotResolved of searchedLocations * fileName * range` — raised when a source file cannot be found in any include path.
- `LoadedSourceNotFoundIgnoring of fileName * range` — a `#load`ed source that does not exist (downgraded to ignoring).

**Types declared (contract)**
- **`IRawFSharpAssemblyData`** — abstract interface for a referenced F# assembly: `GetAutoOpenAttributes`, `GetInternalsVisibleToAttributes`, `TryGetILModuleDef` (absent for cross-project refs), `HasAnyFSharpSignatureDataAttribute`, `HasMatchingFSharpSignatureDataAttribute`, `GetRawFSharpSignatureData`, `GetRawFSharpOptimizationData`, `GetRawTypeForwarders`, `ILScopeRef`, `ILAssemblyRefs`, `ShortAssemblyName`.
- **`TimeStampCache`** — `defaultTimeStamp -> ...`; members `GetFileTimeStamp`, `GetProjectReferenceTimeStamp` — caches timestamps for incremental-build queries.
- **`ProjectAssemblyDataResult`** (`RequireQualifiedAccess`) — `Available of IRawFSharpAssemblyData | Unavailable of useOnDiskInstead: bool`.
- **`IProjectReference`** — abstract: `FileName`, `EvaluateRawContents: Async<ProjectAssemblyDataResult>`, `TryGetLogicalTimeStamp: TimeStampCache -> DateTime option`.
- **`AssemblyReference`** — a `#r` reference: `range * text * IProjectReference option`; members `Range`, `Text`, `ProjectReference`, `SimpleAssemblyNameIs`.
- **`UnresolvedAssemblyReference`** — `string * AssemblyReference list`.
- **`CompilerTarget`** — `WinExe | ConsoleExe | Dll | Module`, with `IsExe`.
- **`CopyFSharpCoreFlag`** — `Yes | No`.
- **`VersionFlag`** — `VersionString | VersionFile | VersionNone`; members `GetVersionInfo implicitIncludeDir -> ILVersionInfo`, `GetVersionString implicitIncludeDir -> string`.
- **`Directive`** (`Resolution | Include`), **`LStatus`** (`Unprocessed | Processed`), **`TokenizeOption`** (`AndCompile | Only | Debug | Unfiltered`).
- **`PackageManagerLine`** — record `{ Directive; LineStatus; Line; Range }`; static members `AddLineWithKey`, `RemoveUnprocessedLines`, `SetLinesAsProcessed`, `StripDependencyManagerKey` — bookkeeping for `#r`/`#i` lines awaiting a dependency manager.
- **`MetadataAssemblyGeneration`** — `None | ReferenceOut outputPath | ReferenceOnly`.
- **`ParallelReferenceResolution`** — `On | Off`.
- **`TypeCheckingMode`** — `Sequential | Graph`; **`TypeCheckingConfig`** — `{ Mode; DumpGraph }` (default `Graph` with `DumpGraph=false`; `DumpGraph` serializes the file graph as a Mermaid diagram).
- **`WarningNumberSource`** (`CommandLineOption | CompilerDirective`), **`WarningDescription`** (`Int32 | String | Ident`).

**Main types**
- **`TcConfigBuilder`** (`NoEquality; NoComparison`) — the mutable record holding every compilation flag (150+ fields: `primaryAssembly`, `referencedDLLs`, `projectReferences`, `packageManagerLines`, `outputDir/File`, `target`, `debuginfo`, `portablePDB`, `embeddedPDB`, `embedAllSource`, `sourceLink`, `signer`, `delaysign`, `publicsign`, `version`, `standalone`, `extraStaticLinkRoots`, `compressMetadata`, `noSignatureData`, `useOptimizationDataFile`, `jitTracking`, `extraOptimizationIterations`, `win32icon/res/manifest`, `includewin32manifest`, `legacyReferenceResolver`, `showFullPaths`, `diagnosticStyle`, `utf8output`, `flatErrors`, `maxErrors`, `abortOnError`, `baseAddress`, `checksumAlgorithm`, `showTerms`, `doDetuple/TLR/FinalSimplify`, `optsOn`, `optSettings`, `emitTailcalls`, `deterministic`, `parallelParsing`, `parallelIlxGen`, `emitMetadataAssembly`, `preferredUiLang`, `showBanner`, `showTimes`, `showLoadedAssemblies`, `pause`, `alwaysCallVirt`, `noDebugAttributes`, `useReflectionFreeCodeGen`, `isInteractive`, `isInvalidationSupported`, `emitDebugInfoInQuotations`, `alwaysInline`, `exename`, `copyFSharpCore`, `shadowCopyReferences`, `useSdkRefs`, `fxResolver`, `bufferWidth`, `fsiMultiAssemblyEmit`, `exiter`, `parallelReferenceResolution`, `captureIdentifiersWhenParsing`, `typeCheckingConfig`, `dumpSignatureData`, `realsig`, `compilationMode`, …) plus a small number of *non-mutable* core fields (`primaryAssembly`, `defaultFSharpBinariesDir`, `reduceMemoryUsage`, `isInteractive`, `isInvalidationSupported`, `rangeForErrors`, `sdkDirOverride`).
  - `static member CreateNew ...` (full defaults).
  - Mutation/query members: `DecideNames sourceFiles` (derive output/pdb/assembly names from `target`), `TurnWarningOff/On`, `AddIncludePath`, `AddCompilerToolsByPath`, `AddReferencedAssemblyByPath`, `RemoveReferencedAssemblyByPath`, `AddEmbeddedSourceFile`, `AddEmbeddedResource`, `AddPathMapping`, `SplitCommandLineResourceInfo`, `GetNativeProbingRoots` (delayed sequence: includes + tool paths + ref-dll dirs + implicit dir), `AddReferenceDirective (dependencyProvider, m, path, directive)` (routes `#r`/`#i` to a dependency manager or to a plain reference, honoring `LanguageFeature.PackageManagement`), `AddLoadedSource`, `FxResolver` (lazily memoized, invalidated by `SetPrimaryAssembly`/`SetUseSdkRefs`), `SetUseSdkRefs`, `SetPrimaryAssembly`.
- **`TcConfig`** (sealed, immutable) — snapshot of the builder with read-only members for every flag (`<NoEquality; NoComparison>`; the file header comment stresses it must stay immutable). Notable computed/query members:
  - `static member Create (builder, validate) -> TcConfig` (validation runs `version.GetVersionInfo`).
  - `primaryAssembly`, `fsharpBinariesDir`, `compilingFSharpCore`, `useIncrementalBuilder`, `includes`, `implicitOpens`, `useFsiAuxLib`, `implicitlyReferenceDotNetAssemblies`, `implicitlyResolveAssemblies`, `resolutionEnvironment`, `conditionalDefines`, `subsystemVersion`, `useHighEntropyVA`, `compilerToolPaths`, `referencedDLLs`, `reduceMemoryUsage`, `inputCodePage`, `clearResultsCache`, `embedResources`, `diagnosticsOptions`, `checkNullness`, `checkOverflow`, `showReferenceResolutions`, `outputDir/File`, `platform`, `prefer32Bit`, `useSimpleResolution`, `target`, `debuginfo`, `typeCheckOnly`, `parseOnly`, `importAllReferencesOnly`, `simulateException`, `printAst`, `tokenize`, `reportNumDecls`, `printSignature/File`, `printAllSignatureFiles`, `xmlDocOutputFile`, `stats`, `generateFilterBlocks`, `signer`, `container`, `delaysign`, `publicsign`, `version`, `metadataVersion`, `standalone`, `extraStaticLinkRoots`, `compressMetadata`, `noSignatureData`, `onlyEssentialOptimizationData`, `useOptimizationDataFile`, `jitTracking`, `portablePDB`, `embeddedPDB`, `embedAllSource`, `embedSourceList`, `sourceLink`, `internConstantStrings`, `extraOptimizationIterations`, `win32icon/res/manifest`, `includewin32manifest`, `linkResources`, `legacyReferenceResolver`, …
  - Computed: `FxResolver`, `alwaysInline` (bool, with default derived from `optSettings`/`extraOptimizationIterations`), `GetTargetFrameworkDirectories`, `GetAvailableLoadedSources`, `ComputeCanContainEntryPoint`, `ResolveSourceFile`, `MakePathAbsolute`, `IsSystemAssembly` (in target dirs / `FxResolver.GetSystemAssemblies` set / reference-pack dir), `GetSearchPathsForLibraryFiles`, `PrimaryAssemblyDllReference`, `CoreLibraryDllReference`, `GetNativeProbingRoots`, `CloneToBuilder`, `GenerateSignatureData` (not `standalone` and not `noSignatureData`), `GenerateOptimizationData` (same), `assumeDotNetFramework` (primary = `Mscorlib`).
- **`TcConfigProvider`** (sealed) — deferred `TcConfig`; members `Get ctok -> TcConfig`, statics `Constant tcConfig`, `BasedOnMutableBuilder tcConfigB` (the F# Interactive live-builder variant).

**Module-level values (contract)**
- `TryResolveFileUsingPaths (paths, m, fileName) -> string option`.
- `ResolveFileUsingPaths (paths, m, fileName) -> string` (raises `FileNameNotResolved`).
- `GetWarningNumber (m, description, langVersion, source) -> int option`.
- `GetFSharpCoreLibraryName : unit -> string`.
- `FSharpSigFileSuffixes : string list` (= `.fsi`), `FSharpImplFileSuffixes` (= `.fs; .fsscript; .fsx`), `FSharpScriptFileSuffixes` (= `.fsscript; .fsx`).
- `FSharpExperimentalFeaturesEnabledAutomatically : bool` (env-var driven).

**Public API surface** `TcConfig.Create`, `TcConfigBuilder.CreateNew` + mutation members, `TcConfigProvider.Constant`/`BasedOnMutableBuilder`/`Get`; the resolution and warning-number helpers above; the suffix lists.

**Internal helpers / active patterns** Most helpers live in the .fs (`ComputeMakePathAbsolute`, `(++)` operator); the `.fsi` only surfaces the resolution and warning-number utilities.

**Significant internal logic** `TcConfig` is created by *cloning* the builder's record and then reading only from the local immutable copy — the header comment stresses it must remain immutable. Target-framework directory computation branches on whether a primary-assembly file was given explicitly, and between "editing-or-compilation" (framework reference assemblies by version + Facades + refs pack) and "compilation-and-evaluation" (runtime dir + WPF + Facades + refs pack), always also consulting `FxResolver.GetFrameworkRefsPackDirectory`.

**Cross-refs** `FSharp.Compiler.CompilerOptions` (applies CLI args to the builder); `FSharp.Compiler.FxResolver` (member on both builder and config, and `IsSystemAssembly`); `FSharp.Compiler.CompilerImports` (consumes `AssemblyReference`, `IProjectReference`, `IRawFSharpAssemblyData`); `FSharp.Compiler.Driver` (creates the `TcConfigBuilder` for fsc); `FSharp.Compiler.CodeAnalysis` (`Exiter`); `FSharp.Compiler.Text` (`range`).

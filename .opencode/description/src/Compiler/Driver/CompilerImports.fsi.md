# CompilerImports.fsi

**Purpose** Signature for the assembly-resolution / imports layer. Declares the central `TcImports` table (referenced assemblies: their IL scope refs, pickled F# "CCU" metadata, and type-provider state), the `TcAssemblyResolutions` table of resolved reference paths, the `IRawFSharpAssemblyData`-backed `RawFSharpAssemblyData`, and the encode/decode operations for the F# signature + optimization data resources read from and written to assemblies.

**Pipeline role** Bridge between "references on disk" and "the typechecker's view of them": fsc `main1` calls `TcImports.BuildFrameworkTcImports` and `BuildNonFrameworkTcImports`; `ParseAndCheckInputs` reads `CcuThunk`s from `TcImports` while checking; `OptimizeInputs` seeds the optimization env from `ImportedAssembly.FSharpOptimizationData`; `StaticLinking` and `CreateILModule` read the IL module data.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.CompilerImports`, `internal`.

**Exceptions**
- `AssemblyNotResolved of originalName * range`.
- `MSBuildReferenceResolutionWarning of message * warningCode * range`.
- `MSBuildReferenceResolutionError of message * warningCode * range`.

**Types (contract)**
- `ResolveAssemblyReferenceMode` — `Speculative | ReportErrors` (speculative = don't report errors, used while exploring the import graph).
- `ResolvedExtensionReference` (typeproviders) — `string * AssemblyReference list * Tainted<ITypeProvider> list`.
- `AssemblyResolution` — record: `originalReference: AssemblyReference`, `resolvedPath: string`, `prepareToolTip: unit -> string`, `sysdir: bool` (is an installed system assembly like System.dll), `mutable ilAssemblyRef: ILAssemblyRef option` (lazily populated).
- `ImportedBinary` — `FileName: string`, `RawMetadata: IRawFSharpAssemblyData`, optional `ProviderGeneratedAssembly`/`IsProviderGenerated`/`ProviderGeneratedStaticLinkMap`, `ILAssemblyRefs: ILAssemblyRef list`, `ILScopeRef: ILScopeRef`.
- `ImportedAssembly` — `ILScopeRef`, `FSharpViewOfMetadata: CcuThunk`, `AssemblyAutoOpenAttributes`, `AssemblyInternalsVisibleToAttributes`, optional `IsProviderGenerated` + `mutable TypeProviders: Tainted<ITypeProvider> list`, `FSharpOptimizationData: InterruptibleLazy<LazyModuleInfo option>`.
- `TcAssemblyResolutions` (sealed) — the resolution table:
  - `GetAssemblyResolutions : unit -> AssemblyResolution list`.
  - `static SplitNonFoundationalResolutions (tcConfig) -> AssemblyResolution list (sys) * AssemblyResolution list (other) * UnresolvedAssemblyReference list`.
  - `static BuildFromPriorResolutions (tcConfig, results, unresolved) -> TcAssemblyResolutions`.
  - `static GetAssemblyResolutionInformation (tcConfig) -> AssemblyResolution list * UnresolvedAssemblyReference list`.
- `RawFSharpAssemblyData` (sealed) — `new (ilModule: ILModuleDef * ilAssemblyRefs)`; `interface IRawFSharpAssemblyData` — the disk-backed implementation of the raw-data interface (used for ordinary `.dll` references).
- `TcImports` (sealed, `IDisposable`) — the main table.

**Functions (contract)**
- Resource classification: `IsSignatureDataResource`, `IsSignatureDataResourceB`, `IsOptimizationDataResource`, `IsOptimizationDataResourceB` (all `ILResource -> bool`), `IsReflectedDefinitionsResource: ILResource -> bool`.
- `GetResourceNameAndSignatureDataFuncs (ILResource list) -> (string * ((unit -> ReadOnlyByteMemory) * (unit -> ReadOnlyByteMemory) option)) list`.
- `EncodeSignatureData (tcConfig, tcGlobals, exportRemapping, generatedCcu, outfile, isIncrementalBuild) -> ILAttribute list * ILResource list`.
- `EncodeOptimizationData (tcGlobals, tcConfig, outfile, exportRemapping, (CcuThunk * #CcuOptimizationInfo), isIncrementalBuild) -> ILResource list`.
- `RequireReferences (ctok, tcImports, tcEnv, thisAssemblyName, resolutions) -> TcEnv * ImportedAssembly list` — F# Interactive `#r` processing: adds the references to `tcImports` and the CCUs to the type-checking environment.

**`TcImports` members (contract)**
- `DllTable: NameMap<ImportedBinary>`.
- `GetImportedAssemblies : unit -> ImportedAssembly list`.
- `GetCcusInDeclOrder : unit -> CcuThunk list`.
- `GetCcusExcludingBase : unit -> CcuThunk list` — excludes framework imports (which may be shared between multiple builds).
- `FindDllInfo (ctok, m, name) : ImportedBinary`; `TryFindDllInfo (ctok, m, name, lookupOnly) : ImportedBinary option`.
- `FindCcuFromAssemblyRef (ctok, m, aref) -> CcuResolutionResult`.
- `ProviderGeneratedTypeRoots : ProviderGeneratedType list` (typeproviders).
- `GetImportMap : unit -> Import.ImportMap`.
- `DependencyProvider: DependencyProvider`.
- `TryResolveAssemblyReference (ctok, ref, mode) -> OperationResult<AssemblyResolution list>`.
- `ResolveAssemblyReference (ctok, ref, mode) -> AssemblyResolution list`.
- `TryFindExistingFullyQualifiedPathBySimpleAssemblyName (string) -> string option`; `TryFindExistingFullyQualifiedPathByExactAssemblyRef (ILAssemblyRef) -> string option`.
- `TryFindProviderGeneratedAssemblyByName (ctok, name) -> System.Reflection.Assembly option` (typeproviders).
- `ReportUnresolvedAssemblyReferences (UnresolvedAssemblyReference list) -> unit`.
- `SystemRuntimeContainsType (string) -> bool`.
- `internal Base: TcImports option`.
- `static BuildFrameworkTcImports (tcConfigP, sysRes, otherRes) -> Async<TcGlobals * TcImports>`.
- `static BuildNonFrameworkTcImports (tcConfigP, tcImports, otherRes, unresolved, dependencyProvider) -> Async<TcImports>`.
- `static BuildTcImports (tcConfigP, dependencyProvider) -> Async<TcGlobals * TcImports>`.

**Public API surface (per signature)** See the member lists above; `TcImports.BuildTcImports` (+ the Framework/NonFramework variants) are the top-level entry points; `EncodeSignatureData`/`EncodeOptimizationData` are the writers consumed by `CreateILModule`.

**Internal helpers / active patterns** All decoding logic (resource name→reader pairing, compression, pickling) lives in the .fs — see `CompilerImports.fs.md`.

**Significant internal logic** `TcImports` is the "runtime view" of what the compilation references: it caches the pickled `CcuThunk` per assembly so the typechecker sees exact F# signatures rather than raw IL, and it holds the type-provider state used by static linking and by F# Interactive's `#r`. It is deliberately disposable and — per the doc comment in the `.fsi` (line ~149-151) — should usually be left to GC + finalizer rather than disposed explicitly, because the language service may still be reading its contents.

**Cross-refs** `FSharp.Compiler.CompilerConfig` (`TcConfig`, `AssemblyReference`, `IProjectReference`, `IRawFSharpAssemblyData`, `TcConfigProvider`), `FSharp.Compiler.AbstractIL.IL` (`ILModuleDef`, `ILAssemblyRef`, `ILScopeRef`, `ILResource`, `ILExportedTypesAndForwarders`), `FSharp.Compiler.TypeProviders` (provider state), `FSharp.Compiler.TcGlobals` (built alongside by `Build*TcImports`), and consumed by `FSharp.Compiler.Driver` (main1/main2), `FSharp.Compiler.ParseAndCheckInputs`, `FSharp.Compiler.OptimizeInputs`, `FSharp.Compiler.StaticLinking`, `FSharp.Compiler.CreateILModule`.

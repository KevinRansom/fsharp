# CompilerImports.fs

**Purpose** Implements assembly resolution and the `TcImports` table of referenced assemblies. Reads the F# "CCU" signature-data resources out of referenced IL assemblies (uncompressing when needed), caches them as `CcuThunk`s, keeps the type-provider state, and provides the build entry points (`BuildTcImports`, `BuildFrameworkTcImports`, `BuildNonFrameworkTcImports`) that wire up everything the typechecker needs to see across assemblies.

**Namespace(s)** `FSharp.Compiler` (module `FSharp.Compiler.CompilerImports`, internal)

**Functions / values declared**
- `IsSignatureDataResource`, `IsSignatureDataResourceB`, `IsOptimizationDataResource`, `IsOptimizationDataResourceB`, `IsReflectedDefinitionsResource` — classify an `ILResource` by name prefix.
- `decompressResource` — inflate a Deflate-compressed resource into a `ReadOnlyByteMemory`.
- `GetSignatureDataResourceName`, `GetResourceNameAndSignatureDataFuncs`, `GetOptimizationDataResourceName`, `GetResourceNameAndOptimizationDataFuncs` — map resources to `(name, (readerA, readerB?))`, decompressing compressed variants and pairing A with a matching B.
- `PickleToResource compress file g ...` — pickle an F# value into an `ILResource` (with optional B-stream).
- `GetSignatureData`, `WriteSignatureData`, `GetOptimizationData`, `WriteOptimizationData` — read/write the CCU (pickled) signature and optimization data.
- `EncodeSignatureData` — produces `ILAttribute list * ILResource list` for the output module.
- `EncodeOptimizationData` — produces `ILResource list` for the output module.
- `OpenILBinary` — open an IL binary to read (honoring `reduceMemoryUsage`, `shadowCopyReferences`, metadata-snapshot).
- `GetNameOfILModule`, `MakeScopeRefForILModule`, `GetCustomAttributesOfILModule`, `GetAutoOpenAttributes`, `GetInternalsVisibleToAttributes` — extract identity/attributes from an `ILModuleDef`.
- `IsNetModule` / `IsDLL` / `IsExe`, `isHashRReference`.
- `RequireReferences` (line ~2694) — F# Interactive `#r` processing.

**Types declared**
- `ResolveAssemblyReferenceMode` — `Speculative | ReportErrors`.
- `ResolvedExtensionReference` (typeproviders-guarded) — `string * AssemblyReference list * Tainted<ITypeProvider> list`.
- `AssemblyResolution` — record (see .fsi).
- `ImportedBinary`, `ImportedAssembly`, `AvailableImportedAssembly`, `CcuLoadFailureAction` — imported-assembly representations.
- `TcImportsLockToken` / `TcImportsLock` (`Lock`) + `RequireTcImportsLock` — lock protecting concurrent access.
- `TcConfig with` (line ~521) — extension members on `TcConfig` (e.g. resolution helpers used by this module).
- `TcAssemblyResolutions` (sealed) — resolution table; `BuildFromPriorResolutions`, `SplitNonFoundationalResolutions`, `GetAssemblyResolutionInformation`, `GetAssemblyResolutions`.
- `RawFSharpAssemblyDataBackedByFileOnDisk` → `RawFSharpAssemblyData` (sealed) — `ILModuleDef`-backed `IRawFSharpAssemblyData`.
- `TcImportsSafeDisposal` (line ~1100) — safe-disposal wrapper.
- `TcImportsDllInfoFacade`, `TcImportsWeakFacade` — weak-reference facade so the language service can keep a soft handle to a `TcImports` without pinning it for GC.
- `TcImports` (sealed, `IDisposable`) — the main table; members per .fsi plus the build statics.

**Public API surface** See the .fsi description; the .fs adds the internal decode/encode/lock machinery and the `TcImports` implementation. `TcImports.BuildTcImports` is the top-level orchestrator; `BuildFrameworkTcImports` vs `BuildNonFrameworkTcImports` split system-referenced vs user-referenced assemblies.

**Internal helpers / active patterns**
- `addConstraintSources` — adds type-provider constraint sources to an `ImportedAssembly`.
- `ByteBufferToBytes` — convert a `ByteBuffer` to a byte array.
- `TcImportsWeakFacade` / `TcImportsDllInfoFacade` — keep a `WeakReference<TcImports>` so the large `TcImports` can be reclaimed while a facade remains usable.

**Significant internal logic**
- Reads pickled F# signature data (stream A, optional stream B) and un-pickles it into a `CcuThunk` (the F#-typed view of a referenced assembly) — this is what lets the typechecker reason about exact F# signatures rather than just IL.
- Handles compressed resources (`CompressedDataResourceName*`) via `decompressResource`.
- The lazy `FSharpOptimizationData: InterruptibleLazy<LazyModuleInfo option>` defers loading of optimization data until the optimizer needs it.
- `TcImports` is disposable but, per the doc comment, normally left to the GC/finalizer so the language service can keep using contents.

**Cross-refs** `FSharp.Compiler.CompilerConfig` (`TcConfig`, `AssemblyReference`, `IProjectReference`, `IRawFSharpAssemblyData`), `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypeProviders` (provider-generated assemblies/static linking), `FSharp.Compiler.Driver` (builds `TcImports` in main1), and consumed by `FSharp.Compiler.ParseAndCheckInputs` + `FSharp.Compiler.OptimizeInputs` + `FSharp.Compiler.StaticLinking`.

# ReferenceResolver.fsi

**Purpose**: The contract for `ReferenceResolver.fs`: declares the legacy reference-resolution API surface — `LegacyResolutionFailure`, `LegacyResolutionEnvironment`, `LegacyResolvedFile`, `ILegacyReferenceResolver`, and the obsolete `LegacyReferenceResolver` wrapper class.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

**Declarations**:
- `exception LegacyResolutionFailure`
- `[<RequireQualifiedAccess>] type LegacyResolutionEnvironment`: `EditingOrCompilation of isEditing: bool` ("Uses reference assemblies, not implementation assemblies") | `CompilationAndEvaluation` ("dynamically compiled and executed — implementation assemblies")
- `type LegacyResolvedFile`: `{ itemSpec: string; prepareToolTip: string * string -> string; baggage: string }`
- `[<AllowNullLiteral>] type ILegacyReferenceResolver`:
  - `abstract HighestInstalledNetFrameworkVersion: unit -> string` (v4.x moniker; explicit mscorlib ⇒ `--noframework` ⇒ logic essentially unused)
  - `abstract Resolve: resolutionEnvironment * references: (string*string)[] * targetFrameworkVersion: string * targetFrameworkDirectories: string list * targetProcessorArchitecture: string * fsharpCoreDir: string * explicitIncludeDirs: string list * implicitIncludeDir: string * logMessage * logDiagnostic -> LegacyResolvedFile[]`
  - `abstract DotNetFrameworkReferenceAssembliesRootDirectory: string` (Windows; appended to the design-time resolution path)
- `[<Class; AllowNullLiteral; Obsolete("This API is obsolete and not for external use")>] type LegacyReferenceResolver`: `new: impl -> LegacyReferenceResolver`, `member internal Impl`; comment notes exactly two implementations exist and none more may be added externally

**Cross-references**: Implemented by SimulatedMSBuildReferenceResolver.fsi (and the C# MSBuild-backed resolver); used by the driver to resolve `--r:…` references for fsc/fsi/service.

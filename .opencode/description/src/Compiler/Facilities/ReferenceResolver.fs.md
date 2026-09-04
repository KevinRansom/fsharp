# ReferenceResolver.fs

**Purpose**: Declares the (legacy) .NET reference-resolution abstractions under the `FSharp.Compiler.CodeAnalysis` namespace: the resolution-environment enum (editing/compilation vs run), the resolved-file record, and the `ILegacyReferenceResolver` interface plus the `LegacyReferenceResolver` wrapper class that hides the implementation. Real PE-identity probing lives in the C# side of this namespace; this file just defines contract and the obsolete wrapper.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

**TypeDefs / Records / Unions declared**:
- `exception LegacyResolutionFailure`: thrown when legacy resolution fails
- `[<RequireQualifiedAccess>] type LegacyResolutionEnvironment`: `EditingOrCompilation of isEditing: bool` (uses reference assemblies) | `CompilationAndEvaluation` (uses implementation assemblies — script execute)
- `type LegacyResolvedFile`: record `{ itemSpec: string; prepareToolTip: string * string -> string; baggage: string }` with `ToString()` — note the field docs: item spec, tooltip text generator, round-tripped baggage
- `type ILegacyReferenceResolver` `[<AllowNullLiteral>]`: abstract `HighestInstalledNetFrameworkVersion: unit -> string`, `DotNetFrameworkReferenceAssembliesRootDirectory: string`, `Resolve: (LegacyResolutionEnvironment * (string*string)[] * string * string list * string * string * string list * string * (string->unit) * (bool->string->string->unit)) -> LegacyResolvedFile[]`
- `type LegacyReferenceResolver(impl)` `[<AllowNullLiteral>]`: wraps an `ILegacyReferenceResolver`, exposes `member internal Impl`

**Public API surface**:
- The `Resolve` signature is the key contract: reference specs (string * baggage) in, `LegacyResolvedFile[]` out, plus logging callbacks `logMessage` and `logDiagnostic (isError, code, text)`
- `HighestInstalledNetFrameworkVersion` returns the "v4.5.1"-style moniker; doc notes that an explicit `mscorlib` implies `--noframework` and the resolver is essentially unused

**Significant notes**:
- The .fsi marks `LegacyReferenceResolver` `[<Class; AllowNullLiteral; Obsolete("This API is obsolete and not for external use")>]` and states "two implementations of this are provided, and no further implementations can be added from outside FSharp.Compiler.Service"
- Concrete implementations: SimulatedMSBuildReferenceResolver.fs (in-process simulation) and the C#/MSBuild-backed resolver elsewhere in the service

**Cross-references**: Consumed by SimulatedMSBuildReferenceResolver.fs; driven by the compiler driver's reference-options handling; diagnostics fed back via `logDiagnostic`.

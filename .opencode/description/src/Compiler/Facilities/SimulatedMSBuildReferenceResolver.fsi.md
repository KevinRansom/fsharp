# SimulatedMSBuildReferenceResolver.fsi

**Purpose**: The minimal contract for `SimulatedMSBuildReferenceResolver.fs`: it exposes a single internal entry point returning the simulated-MSBuild legacy reference resolver.

**Namespace(s)**: module `FSharp.Compiler.CodeAnalysis.SimulatedMSBuildReferenceResolver` (internal)

**Contract**:
- `val getResolver: unit -> LegacyReferenceResolver` — the sole binding; callers (e.g. the compiler driver) obtain the resolver instance and invoke ILegacyReferenceResolver's members (`HighestInstalledNetFrameworkVersion`, `DotNetFrameworkReferenceAssembliesRootDirectory`, `Resolve`).

**Notes**: All of the resolution logic (search paths, FSharp.Core ref-assembly probe, GAC scanning, framework-version list) is implementation detail kept in the .fs. Types like `LegacyReferenceResolver` and `ILegacyReferenceResolver` come from ReferenceResolver.fsi.

**Cross-references**: Implements SimulatedMSBuildReferenceResolver.fs; depends on ReferenceResolver.fs/.fsi types.

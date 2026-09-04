# SimulatedMSBuildReferenceResolver.fs

**Purpose**: Implements `ILegacyReferenceResolver` by *simulating* MSBuild evaluation, in-process, when no real MSBuild project context is available (e.g. script editing outside Visual Studio): it searches a list of directory paths and, on Windows, the GAC plus special FSharp.Core reference-assembly locations to find the actual .dll files for a reference list.

**Namespace(s)**: module `FSharp.Compiler.CodeAnalysis.SimulatedMSBuildReferenceResolver` (internal)

**Declarations**:
- Framework literals: `Net45` … `Net481`; `SupportedDesktopFrameworkVersions` (descending list)
- `SimulatedMSBuildResolver: LegacyReferenceResolver` — the singleton implementation
- `internal getResolver: unit -> LegacyReferenceResolver`
- `#if INTERACTIVE` block: manual test `resolve` scripts exercising every resolution path (partial names, dll names, ref assemblies, GAC, exact-version FSharp.Core)
- ATTENTION comment: hardcoded framework list must be updated when MSBuild/.NET Framework versions change

**Significant internal logic** (the `Resolve` implementation):
- Search path order: `targetFrameworkDirectories` → `explicitIncludeDirs` → `fsharpCoreDir` → `implicitIncludeDir` → .NET Framework reference assemblies (stub returns `[]`) → implementation assemblies (Wine: `RuntimeEnvironment.GetRuntimeDirectory()` only on mscorlib)
- Resolution attempts per reference: (1) rooted path that exists; (2) `FSharp.Core, Version=…` exact lookup under `%ProgramFiles(x86)%\Reference Assemblies\Microsoft\FSharp\.NETFramework\v4.0\<ver>\<name>.dll`; (3) probe each search path with the qualified name (`AssemblyName(r).Name + ".dll"`, or as-is when ending in `.dll`/`.exe`); (4) GAC scan: if the assembly name has version & public-key token, go straight to `<gac>\<arch>\<name>\v4.0_<ver>__<token>\<name>.dll`; otherwise enumerate all `<name>\*` dirs and pick the lexicographically last (highest version)
- `HighestInstalledNetFrameworkVersion()`: first framework dir (4.8.1→4.5) that exists under the Reference Assemblies root, else `v4.5`
- `DotNetFrameworkReferenceAssembliesRootDirectory`: `<PF>%\Reference Assemblies\Microsoft\Framework\.NETFramework` on Windows, `""` elsewhere
- Errors logged via `logWarningOrError false "SR001" …`

**Cross-references**: ReferenceResolver.fs/.fsi (provides `ILegacyReferenceResolver`, `LegacyReferenceResolver`); used by the driver/script resolution path; related to CompilerLocation (PF/dotnet probing).

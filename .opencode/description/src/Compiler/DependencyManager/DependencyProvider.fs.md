# DependencyProvider.fs

**Purpose**: The compiler's generic dependency/assembly resolution service. It discovers and wraps external "DependencyManager" plugins (e.g. NuGet, Paket) via reflection, exposes their `ResolveDependencies` results to the compiler (references, scripts, package roots), and additionally installs managed-assembly and native-DLL resolve handlers so the runtime can load the compiler's own dependencies at runtime.

**Namespace(s)**: `FSharp.Compiler.DependencyManager`

**Modules**:
- `module Option` — `ofString : string | null -> string option` (null/empty → `None`).
- `module ReflectionHelper` (`AutoOpen`) — reflection plumbing against the dependency-manager plugin contract: name/attribute constants (`*DependencyManager*.dll`, `DependencyManagerAttribute`, `ResolveDependencies`, `ClearResultsCache`, `Name`, `Key`, `HelpMessages`), plus helpers `assemblyHasAttribute`, `getAttributeNamed`, `getInstanceProperty<'T>`, `getInstanceMethod<'T>`, `stripTieWrapper` (unwraps `TargetInvocationException`).

**Types / delegates**:
- `ErrorReportType` — union `Warning | Error` (`RequireQualifiedAccess`); the severity level for reports.
- `ResolvingErrorReport` — delegate `ErrorReportType * int * string -> unit` invoked to surface progress/diagnostic messages.
- `IResolveDependenciesResult` — interface: `Success`, `StdOut`, `StdError`, `Resolutions`, `SourceFiles`, `Roots` (full paths to resolved dlls, source files, and package roots for native probing).
- `IDependencyManagerProvider` — interface a plugin must satisfy: `Name`, `Key`, `HelpMessages`, `ClearResultsCache`, and `ResolveDependencies(scriptDir, mainScriptName, scriptName, scriptExt, packageManagerTextLines, tfm, rid, timeout)`.
- `ReflectionDependencyManagerProvider` — reflection-based adapter for plugins that do not link against this assembly: locates `Name`/`Key`/`HelpMessages` properties, the `ResolveDependencies` overloads (4-, 5-, 6-parameter, with/without timeout and script info), and `ClearResultsCache`; `InstanceMaker` falls back through progressively smaller constructor signatures; `MakeResultFromObject` / `MakeResultFromFields` adapt plugin result objects to `IResolveDependenciesResult`.
- `DependencyProvider` — the main public class: constructors (no handlers, native-only, managed+native, each with an optional `useResultsCache` flag); members `GetRegisteredDependencyManagerHelpText`, `ClearResultsCache`, `CreatePackageManagerUnknownError`, `Resolve` (the main entry: takes an `IDependencyManagerProvider` plus package-manager text lines and returns an `IResolveDependenciesResult`), `TryFindDependencyManagerByKey`, `TryFindDependencyManagerInPath` (parses `#r "key:sometext"`), `Dispose`; internal state includes `NativeDllResolveHandler`, an optional `AssemblyResolveHandler`, an `FSharpLazyList` of assembly search paths/location, and a cached `Map<string, IDependencyManagerProvider>` of registered managers.

**Internal helpers**:
- `enumerateDependencyManagerAssemblies compilerTools reportError` — probes the compiler tools directories for `*DependencyManager*.dll`, loads each, and checks for the `DependencyManagerAttribute`.
- `RegisteredDependencyManagers` property — cached lazy map of key → provider, built from `enumerateDependencyManagerAssemblies` plus any default providers.
- The `Resolve` member derives the manager key from the `#r` text, invokes the provider (catching exceptions into `CreatePackageManagerUnknownError` reports), and computes the execution RID with `RidHelpers`.

**Significant internal logic**:
- Everything is reflection-based so plugins don't need to reference FSharp.Compiler.DependencyManager (only the attribute contract).
- Constructor parameter compatibility: the latest plugin constructor takes `(outputDir: string option, useResultsCache: bool, sdkDirOverrideDict)`; `InstanceMaker` walks back over older signatures (5 → 1 args) so old plugins still load.
- Native dependency probing delegates to `NativeDllResolveHandler`; managed assembly resolution uses `AssemblyResolveHandler` (see sibling files).

**Cross-references**:
- `AssemblyResolveHandler.fs` / `AssemblyResolveHandler.fsi` — managed `.dll` resolution on .NET Framework vs CoreCLR.
- `NativeDllResolveHandler.fs` / `.fsi` — unmanaged native library probing and PATH manipulation.
- Fsi (#r handling): see `src/Compiler/Interactive/fsi.fs` `FsiEvaluationSession`.

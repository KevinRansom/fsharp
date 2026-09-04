# DependencyProvider.fsi

**Purpose**: Public contract of the DependencyManager subsystem: the plugin interfaces (`IDependencyManagerProvider`, `IResolveDependenciesResult`), the error-reporting delegate, and the `DependencyProvider` façade the compiler/host uses to find and run a dependency manager (NuGet, Paket, …) via `#r "key:text"` lines and to resolve managed + native dependencies.

**Namespace(s)**: `FSharp.Compiler.DependencyManager` (opens `System`, `System.Runtime.InteropServices`, `FSharp.Compiler.Text`)

**Types / delegates (public contract)**:
- `IResolveDependenciesResult` — `Success : bool`; `StdOut : string[]`; `StdError : string[]`; `Resolutions : seq<string>` (equivalent to `#r "…dll"`); `SourceFiles : seq<string>`; `Roots : seq<string>` (package roots, e.g. `#I "…package-root"`; nuget-layout roots are probed natively by the compiler).
- `IDependencyManagerProvider` — `Name`, `Key` (`nuget`, `paket`, …), `HelpMessages : string[]`, `ClearResultsCache()`, and `ResolveDependencies(scriptDir, mainScriptName, scriptName, scriptExt, packageManagerTextLines, tfm, rid, Timeout) : IResolveDependenciesResult`.
- `ErrorReportType` — `Warning | Error`.
- `ResolvingErrorReport` — delegate `ErrorReportType * int * string -> unit` used to report progress/diagnostic messages to the host.
- `DependencyProvider` — `IDisposable`; six constructor overloads (unit; native-only; native-only + cache flag; managed + native; managed + native + cache flag).

**Public API surface** (members):
- `GetRegisteredDependencyManagerHelpText (compilerTools, outputDir | null, sdkDirOverride, reportError) : string[]` — formatted help text for all registered managers.
- `ClearResultsCache (compilerTools, outputDir | null, sdkDirOverride, reportError)` — clear plugin caches.
- `CreatePackageManagerUnknownError (compilerTools, text, sdkDirOverride, key, reportError) : int * RichText` — the host-facing error for an unresolvable `key`.
- `Resolve (packageManager, scriptExt, packageManagerTextLines, reportError, executionTfm, ?executionRid, ?implicitIncludeDir, ?mainScriptName, ?fileName, ?timeout) : IResolveDependenciesResult` — the main call: resolve the given lines via the chosen manager.
- `TryFindDependencyManagerByKey (compilerTools, outputDir, sdkDirOverride, reportError, key) : IDependencyManagerProvider | null`.
- `TryFindDependencyManagerInPath (compilerTools, outputDir, sdkDirOverride, reportError, path) : string | null * IDependencyManagerProvider | null` — parses `#r "key:text"` into key + provider.

**Notes**:
- `compilerTools` and `outputDir` are assumed invariant for the lifetime of a provider (documented in the class comment).
- The signature does *not* expose `ReflectionDependencyManagerProvider` — it is an internal implementation detail of the .fs.

**Cross-references**:
- `AssemblyResolveHandler.fsi`, `NativeDllResolveHandler.fsi` — the delegate types used in the `DependencyProvider` constructors.
- Consumers: `src/Compiler/Interactive/fsi.fs` (`#r`/`#I` handling), type providers and tooling.

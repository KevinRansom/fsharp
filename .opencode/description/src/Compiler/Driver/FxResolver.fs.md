# FxResolver.fs

**Purpose** Implements the framework-reference resolution logic: given the running environment (SDK installation, `global.json`, runtime), determine the correct target-framework moniker / RID, the SDK directory, the reference-assembly pack directory, and the default set of references (e.g. `FSharp.Core`, `System.Runtime`, …) for a compile. Used for both `fsc.exe` and `fsi.exe`, for project and out-of-project / script scenarios.

**Namespace(s)** `FSharp.Compiler` (module `FSharp.Compiler`, type `FxResolver` internal)

**Types declared**
- `FxResolverLockToken` / `FxResolverLock` (`Lock`) — a process-wide lock protecting mutation of the shared lazy caches; `RequireFxResolverLock` is the active-pattern guard.
- `FxResolver` (class) — the resolver; see API below.

**Module-level functions / values (notable)**
- `fxlock` — the process-wide resolver lock.
- `desiredDotNetSdkVersionForDirectoryCache` — a shared cache so the `global.json`-based SDK pin is computed once per (dir, host) and reused.
- `executeProcess pathToExe arguments workingDir timeout` — helper to invoke `dotnet`/`dotnet.dll` and capture stdout.
- `tryGetDesiredDotNetSdkVersionForDirectoryInfo` / `tryGetDesiredDotNetSdkVersionForDirectory` — invoke the SDK to read `global.json` pinning for the current directory.
- `trySdkDir` (lazy), `tryGetSdkDir` — resolve the SDK directory.
- `getRunningImplementationAssemblyDir`, `implementationAssemblyDir` (lazy), `getImplementationAssemblyDir` — the directory of the running `System.Private.CoreLib` (used as a fallback when the SDK is unavailable).
- `getFSharpLibImplementationReferences useFsiAuxLib` — the default `fsharp.lib`-based reference list for the *implementation* reference set (i.e. F# Interactive-style).
- `getSystemValueTupleImplementationReference` — locate `System.ValueTuple.dll` in the implementation-assembly dir.
- `tryGetVersionedSubDirectory`, `tryNetCoreRefsPackDirectoryRoot` (lazy) / `tryGetNetCoreRefsPackDirectoryRoot` — resolve a .NET Core reference pack root (with versioned subdir probing).
- `getTfmNumber`, `tryGetRunningTfm` — determine the current TFM from the running runtime (e.g. `net8.0`).
- `trySdkRefsPackDirectory` (lazy) / `tryGetSdkRefsPackDirectory` — the SDK-resolved reference pack directory.
- `getDependenciesOf assemblyReferences` — compute the transitive dependency set of a reference list from `.deps.json`/runtime assets.
- `tryGetTfmFromSdkDir`.
- `getDotNetFrameworkDefaultReferences useFsiAuxLib` — .NET Framework default reference list.
- `getDotNetCoreImplementationReferences useFsiAuxLib` — .NET Core implementation-assembly reference list.
- `systemAssemblies` (static lazy `HashSet<string>`) + `GetSystemAssemblies()` — the set of base names considered "system assemblies" (used by `TcConfig.IsSystemAssembly`).

**Type members**
- `ClearStaticCaches` — resets the lazy caches (`trySdkDir`, `implementationAssemblyDir`, `tryNetCoreRefsPackDirectoryRoot`, `trySdkRefsPackDirectory`, `systemAssemblies`, etc.) so a host can re-resolve after, e.g., switching SDKs.
- `GetDefaultReferences useFsiAuxLib : unit -> string list * bool` — returns `(refs, usedDotNetFramework)`.
- `GetFrameworkRefsPackDirectory : unit -> string option` — the resolved framework refs pack dir if any.
- `GetTfmAndRid : unit -> string * string` — TFM + running RID.
- `TryGetDesiredDotNetSdkVersionForDirectory : unit -> Result<string, exn>` — the `global.json`-pinned SDK version.
- `TryGetSdkDir : unit -> string option` — resolved SDK directory.
- `IsReferenceAssemblyPackDirectoryApprox dirName : bool` — heuristic check.

**Public API surface** `FxResolver` members above; from `FSharp.Compiler.CompilerConfig` the resolver is exposed through the lazily-created `TcConfigBuilder.FxResolver` / `TcConfig.FxResolver` member, so driver code typically reads it via the config rather than constructing it directly.

**Internal helpers / active patterns** `RequireFxResolverLock` guards mutation of the lazy caches so concurrent invocations don't race; most of the discovery is via lazy bindings (evaluated once) keyed off the running runtime and SDK.

**Significant internal logic** The resolver's job is to bridge "this machine / this SDK / this project directory" to a concrete set of default references and a TFM. It prefers the SDK-provided reference packs (for compilation) and falls back to the running runtime's implementation-assembly directory (for interactive / evaluation scenarios), and it caches aggressively in static lazy state to avoid re-invoking `dotnet` for every query.

**Cross-refs** Consumed by `FSharp.Compiler.CompilerConfig` (`TcConfigBuilder.FxResolver`, `TcConfig.FxResolver`, `IsSystemAssembly`, `GetSearchPathsForLibraryFiles`) and `FSharp.Compiler.Driver` (default reference resolution for fsc/fsi). Depends on `FSharp.Compiler.Text` (`range` for `rangeForErrors`) and the OS / SDK layout of the target machine.

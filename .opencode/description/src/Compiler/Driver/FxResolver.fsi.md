# FxResolver.fsi

**Purpose** Signature of the framework-reference resolver. `FxResolver` picks, from the running environment (SDK installation, `global.json`, the running runtime), the correct **target-framework moniker (TFM) + RID**, the **SDK directory**, the **reference-assembly pack directory**, and the **default reference-assembly list** for a compile. It is the single source of truth for "which framework am I compiling against?" and is used for `fsc.exe` default refs, `fsi.exe` default refs, script execution/editing/compilation, and out-of-project source editing.

**Pipeline role** Called (indirectly, through the `TcConfig`/`TcConfigBuilder.FxResolver` members defined in `FSharp.Compiler.CompilerConfig`) by the reference-resolution stage of fsc/fsi, and by `TcConfig.IsSystemAssembly` + `TcConfig.GetTargetFrameworkDirectories` to build the search path. The resolver is memoized on the builder/config and invalidated by `SetPrimaryAssembly` / `SetUseSdkRefs`.

**Namespace(s)** `FSharp.Compiler` — type `FSharp.Compiler.FxResolver`, declared `internal`.

**Type (contract)**

- `FxResolver` — the resolver class.
  - **Constructor** (single `new`):
    `assumeDotNetFramework: bool * projectDir: string * useSdkRefs: bool * isInteractive: bool * rangeForErrors: Text.range * sdkDirOverride: string option -> FxResolver`.
    The six inputs:
    - `assumeDotNetFramework` — set true when the primary assembly is `Mscorlib` (i.e. a .NET Framework build); false for `System.Runtime`-based builds. Drives which reference set is chosen.
    - `projectDir` — the "project" directory (the `implicitIncludeDir`), used as the base for any `global.json` lookup.
    - `useSdkRefs` — whether to use SDK-provided reference assemblies (vs the implementation assemblies).
    - `isInteractive` — the F# Interactive flag; changes the default-reference set (e.g. adds FSI-aux libraries).
    - `rangeForErrors` — the `range` reported on resolution failures (so diagnostics point at the right flag/directive).
    - `sdkDirOverride` — an explicit SDK directory (typically `None`; FCS may pin one).

  - **Static members:**
    - `ClearStaticCaches : unit -> unit` — resets the process-wide lazy caches (`trySdkDir`, `implementationAssemblyDir`, `tryNetCoreRefsPackDirectoryRoot`, `trySdkRefsPackDirectory`, `systemAssemblies`, …) so a long-running host can re-resolve after switching SDKs or changing the project directory.
    - `GetSystemAssemblies : unit -> HashSet<string>` — the *base-name* set (e.g. `System.Runtime`, `FSharp.Core`, …) of "system assemblies" — the set `TcConfig.IsSystemAssembly` consults.
    - `IsReferenceAssemblyPackDirectoryApprox : dirName: string -> bool` — a cheap heuristic ("looks like a reference-pack directory") used by `TcConfig.IsSystemAssembly` without doing any discovery.

  - **Instance members:**
    - `GetDefaultReferences : useFsiAuxLib: bool -> string list * bool` — the *default* reference list (the assemblies `fsc`/`fsi` reference by default: `FSharp.Core`, `System.Runtime`, etc., plus FSI-aux when requested) and a `bool` flag reporting whether a .NET-Framework-style reference set was chosen.
    - `GetFrameworkRefsPackDirectory : unit -> string option` — the resolved "framework refs pack" directory (if any); consulted by `TcConfig.GetTargetFrameworkDirectories` in *both* resolution environments.
    - `GetTfmAndRid : unit -> string * string` — the (selected TFM, e.g. `net8.0` / `net472`, and the running RID, e.g. `win-x64`).
    - `TryGetDesiredDotNetSdkVersionForDirectory : unit -> Result<string, exn>` — the `global.json`-pinned SDK version for the current directory; `Result.Error` on read failure.
    - `TryGetSdkDir : unit -> string option` — the resolved SDK directory (if any).

**Public API surface (per signature)** The members above. In practice, driver code rarely constructs an `FxResolver` directly — it reads `tcConfig.FxResolver` (memoized on the `TcConfig`/`TcConfigBuilder` by `FSharp.Compiler.CompilerConfig`) and calls:
- `GetDefaultReferences` — when computing the default reference list.
- `GetSystemAssemblies` — in `TcConfig.IsSystemAssembly`, to decide if a given base name is "system" (shared across compilations).
- `GetFrameworkRefsPackDirectory` — in `TcConfig.GetTargetFrameworkDirectories`.
- `GetTfmAndRid` / `TryGetSdkDir` / `TryGetDesiredDotNetSdkVersionForDirectory` — mostly for host/tool introspection (e.g. FCS, `--sdk`-related flags).
- `ClearStaticCaches` — from hosts that change their project/SDK context at runtime.

**Internal helpers / active patterns** None are declared in the signature. All discovery logic (invoking `dotnet --version`, parsing `global.json`, locating the running `System.Private.CoreLib`, the `trySdkDir`/`tryNetCoreRefsPackDirectoryRoot`/`trySdkRefsPackDirectory` lazy caches, the `implementationAssemblyDir` fallback, the `systemAssemblies` set) lives in the `.fs` — see `FxResolver.fs.md`.

**Significant internal logic** `FxResolver` is a "best-effort" resolver: it prefers SDK-provided reference packs (for compilation) and falls back to the running runtime's implementation-assembly directory (for interactive / evaluation scenarios), caching results in static lazy state so repeated resolutions in a long-running host do not re-run `dotnet`. The `assumeDotNetFramework` flag is the primary switch — it is derived by `TcConfigBuilder` from `primaryAssembly = Mscorlib` at construction time, which is why changing the primary assembly (or `useSdkRefs`) invalidates the cached resolver.

**Cross-refs**

- Created/cached by: `FSharp.Compiler.CompilerConfig` — the `TcConfigBuilder.FxResolver` member (lazily memoized; invalidated by `SetPrimaryAssembly` / `SetUseSdkRefs`), and the read-only `TcConfig.FxResolver` member.
- Queried by: `TcConfig.IsSystemAssembly` (`GetSystemAssemblies`, `IsReferenceAssemblyPackDirectoryApprox`), `TcConfig.GetTargetFrameworkDirectories` (`GetFrameworkRefsPackDirectory`), `FSharp.Compiler.Driver` (fsc/fsi default reference resolution).
- Depends on: `FSharp.Compiler.Text` (`range` for `rangeForErrors`) and the OS/SDK layout of the target machine (the `.fs` shells out to `dotnet` to discover the SDK and reads `global.json`).

# NativeDllResolveHandler.fs

**Purpose**: Hooks .NET's native (unmanaged) library resolution via `AssemblyLoadContext.ResolvingUnmanagedDll` (via reflection, for .NET (Core) runtimes) so the compiler runtime can find native libraries of its dependencies. Implements the coreclr probing algorithm (bare name, `.dll/.exe`, `.dylib`, `.so`, with or without a `lib` prefix) over user-supplied "probing roots" and the per-rid `runtimes/<rid>/native/` layout.

**Namespace(s)**: `FSharp.Compiler.DependencyManager`

**Types**:
- `ProbingPathsStore` (internal) — tracks which probing paths were added to the process `PATH` environment variable and removes them on `Dispose`; members `RefreshPathsInEnvironment roots`, `AddProbeToProcessPath`, static `AppendPathSeparator`, static `RemoveProbeFromProcessPath`.
- `NativeDllResolveHandlerCoreClr` (internal) — reflection-based: finds `System.Runtime.InteropServices.NativeLibrary.TryLoad`, defines probing file-name variations via `probingFileNames`, and `resolveUnmanagedDll (assembly, name) : IntPtr` that searches probing roots and `runtimes/<rid>/native/<name>` for a file.
- `NativeDllResolveHandler` (public façade) — wraps `NativeDllResolveHandlerCoreClr`; `new(NativeResolutionProbe option)` / `new(NativeResolutionProbe | null)`; `RefreshPathsInEnvironment roots : seq<string> -> unit`; `IDisposable`.

**Public API surface**:
- `NativeResolutionProbe` delegate type: `unit -> seq<string>` returning package roots to probe.
- `NativeDllResolveHandler` constructors, `RefreshPathsInEnvironment`, `Dispose`.

**Internal helpers**:
- `ProbingPathsStore.AppendPathSeparator / RemoveProbeFromProcessPath` — safe PATH mutation (append/remove with the platform path separator).
- `probingFileNames name` — produces candidate file names: name; `name.{dll,exe}` or `name.{dylib}` or `name.so`; `lib{name}.{suffix}`; `lib{name}` — matching coreclr's `LibraryNameVariation` algorithm.
- `resolveUnmanagedDll` — for each probing root: try `<root>/<name>` and `<root>/runtimes/<rid>/native/<name>` (for each of `RidHelpers.probingRids`); on a hit call `NativeLibrary.TryLoad` and return the `IntPtr` handle.
- Reflection accessors for `AssemblyLoadContext`, its `ResolvingUnmanagedDll` event, and the default ALC.

**Significant internal logic**:
- `ProbingPathsStore` mutates `Environment.GetEnvironmentVariable("PATH")` so that the *host process* can natively discover the libraries (belt-and-braces in addition to ALC hooks). `Dispose` removes only the paths that this store added, leaving any pre-existing PATH entries intact.
- Only active on CoreCLR (`isRunningOnCoreClr`); on the desktop CLR the handler is `None`.
- The native resolution path is wired into `DependencyProvider` when the host supplies `nativeProbingRoots`.

**Cross-references**:
- `NativeDllResolveHandler.fsi` — public contract (probe delegate, façade members, dispose semantics).
- `DependencyProvider.fs` — consumes this handler; the Roots from a resolved package are fed to `RefreshPathsInEnvironment`.
- `AssemblyResolveHandler.fs` — sibling managed-assembly resolver.

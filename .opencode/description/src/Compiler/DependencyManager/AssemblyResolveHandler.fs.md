# AssemblyResolveHandler.fs

**Purpose**: Hooks .NET's managed assembly resolution so the compiler runtime can find its own dependencies. On .NET (Core) it subscribes to `AssemblyLoadContext.Default.Resolving`; on .NET Framework it subscribes to `AppDomain.AssemblyResolve`. In both cases it probes a user-supplied list of "assembly probing paths" for a `.dll` matching the requested simple name.

**Namespace(s)**: `FSharp.Compiler.DependencyManager`

**Types / delegates**:
- `AssemblyResolutionProbe` — `delegate of unit -> seq<string>` implemented by the host to return candidate assembly file paths.
- `AssemblyResolveHandlerCoreclr` (internal) — uses reflection to locate `System.Runtime.Loader.AssemblyLoadContext.Resolving` and `LoadFromAssemblyPath` (works without a hard reference to `AssemblyLoadContext`). The handler is a generic method (`ResolveAssemblyNetStandard`) instantiated for the ALC type via `MakeGenericMethod`, and attached to the default ALC's `Resolving` event in the constructor; `Dispose` detaches it.
- `AssemblyResolveHandlerDeskTop` (public) — implements the same logic for .NET Framework via `AppDomain.CurrentDomain.add_AssemblyResolve` and `Assembly.LoadFrom`.
- `AssemblyResolveHandler` (internal, the façade) — picks `Coreclr` when `isRunningOnCoreClr`, otherwise `DeskTop`; `new(AssemblyResolutionProbe option)` and `new(AssemblyResolutionProbe | null)`; `IDisposable` disposes the chosen handler.

**Public API surface**:
- `AssemblyResolutionProbe` delegate type.
- `AssemblyResolveHandler` constructors (see above) and `Dispose`.

**Internal helpers**:
- `ResolveAssemblyNetStandard(ctxt, assemblyName)` — generic method attached to the ALC `Resolving` event; returns `defaultof<Assembly>` on failure (so the default resolution can continue); matches on `Path.GetFileNameWithoutExtension(path) = assemblyName.Name`.
- `resolveAssemblyNET (assemblyName)` — same matching for the desktop path, then `Assembly.LoadFrom`.

**Significant internal logic**:
- The CoreCLR path is entirely reflection-based (the compiler assembly does not target a framework shipping `AssemblyLoadContext`), which is why `MakeGenericMethod` + `Delegate.CreateDelegate` is used.
- `ResolveAssemblyNetStandard` catches all exceptions and returns `null` (null = "I couldn't resolve, let the runtime keep looking" per the .NET convention).
- Matching is by simple name only (e.g. `"System.IO.FileSystem"` ignoring version/culture/token).
- The handler pair is created in `DependencyProvider.fs` and installed when a `DependencyProvider` is constructed.

**Cross-references**:
- `AssemblyResolveHandler.fsi` — contract (public type: `AssemblyResolutionProbe`; internal façade `AssemblyResolveHandler`).
- `NativeDllResolveHandler.fs` — sibling, for native libraries.
- `DependencyProvider.fs` — creates and owns these handlers.

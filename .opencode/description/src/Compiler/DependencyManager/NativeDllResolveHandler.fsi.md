# NativeDllResolveHandler.fsi

**Purpose**: Public contract for the native-library resolve hook: a host-facing probe delegate plus a small façade (`NativeDllResolveHandler`) that registers handlers so the compiler runtime can find native (.so/.dll/.dylib) dependencies of resolved packages.

**Namespace(s)**: `FSharp.Compiler.DependencyManager`

**Types**:
- `NativeResolutionProbe` — `delegate of unit -> seq<string>`; host-implemented, returns package roots to probe for native dependencies.
- `NativeDllResolveHandler` — documented as a "cut-down AssemblyLoadContext" for loading native libraries; constructors:
  - `new(NativeResolutionProbe | null) : NativeDllResolveHandler` (public)
  - `new(NativeResolutionProbe option) : NativeDllResolveHandler` (internal)
  - `RefreshPathsInEnvironment : seq<string> -> unit` (internal) — refreshes the `PATH` environment for these roots.
  - `IDisposable` — unregisters the hooks.

**Notes**:
- The CoreCLR/ALC plumbing, the `NativeLibrary.TryLoad` invocation, and the probing file-name algorithm (bare name, `name.dll/.exe/.dylib/.so`, `lib` prefix variants) all live in the .fs and are not part of the contract.
- Only used when the host (e.g. Fsi via `DependencyProvider`) needs to run native dependencies of resolved packages.

**Cross-references**:
- Implementation: `NativeDllResolveHandler.fs`.
- `AssemblyResolveHandler.fsi` — sibling for managed assemblies.
- `DependencyProvider.fsi` — the constructors that accept `NativeResolutionProbe`.

# AssemblyResolveHandler.fsi

**Purpose**: Public contract for the managed-assembly resolve hook used to load the compiler's own dependencies at runtime. Exposes the host-facing `AssemblyResolutionProbe` delegate and the `AssemblyResolveHandler` façade (internal to the assembly, but visible to the compiler).

**Namespace(s)**: `FSharp.Compiler.DependencyManager`

**Types (public contract)**:
- `AssemblyResolutionProbe` — `delegate of unit -> seq<string>` implemented by the host; the host is expected to return a sequence of assembly file paths to probe.
- `AssemblyResolveHandler` — internal façade; `new(AssemblyResolutionProbe | null)` public, `new(AssemblyResolutionProbe option)` internal; implements `IDisposable`. On `Dispose` the .NET event subscription is released.

**Notes**:
- Both the CoreCLR (`AssemblyLoadContext.Resolving`) and .NET Framework (`AppDomain.AssemblyResolve`) implementations live only in the .fs — not part of the signature.
- This handler is only created when the compiler is running on a runtime that needs managed plugin dependencies to be found.

**Cross-references**:
- Implementation: `AssemblyResolveHandler.fs`.
- `NativeDllResolveHandler.fsi` — sibling, for native probing.
- `DependencyProvider.fsi` — the `DependencyProvider` constructors take an `AssemblyResolutionProbe`.

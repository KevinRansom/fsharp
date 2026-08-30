# RidHelpers.fs

**Purpose**: Computes the .NET runtime identifier (RID) values for the environment the compiler is running in (per the dotnet RID catalog, e.g. `win-x64`, `osx-arm64`, `linux-x64`). Produces the probing RID list (`any`, base RID, platform RID) plus the base and platform RIDs, used by runtime-identifier-dependent lookup such as platform-specific native asset resolution in F# Interactive.

**Namespace(s)**: `Internal.Utilities`

**Modules / Types declared**:

- `module internal RidHelpers` — the sole declaration (no types).

**Public API surface** (all internal):

- `probingRids : string[]` — `[| "any"; baseRid; platformRid |]`, the ordered list of RIDs to probe.
- `baseRid : string` — the OS-level RID (`"win"`, `"osx"`, or `"linux"`).
- `platformRid : string` — the architecture-qualified RID (`<baseRid>-x64` / `-x86` / `-arm64` / `-arm`).

All three are bound in a single `let` tuple, computed once at module initialization from `System.Runtime.InteropServices.RuntimeInformation` (`IsOSPlatform` for Windows/OSX/otherwise-linux, and `ProcessArchitecture` for the suffix — x64, x86, Arm64, else arm).

**Internal helpers**: None.

**Significant internal logic**: Pure environment introspection; no fallbacks or caching — the values are module-level constants evaluated once at first use. The comment points to the official RID catalog (https://learn.microsoft.com/dotnet/core/rid-catalog) for the valid RID forms.

**Cross-references**: No `.fsi` counterpart (implementation-only file in `src/Compiler/Utilities/`). Same `Internal.Utilities` namespace as `PathMap.fs`, `RidHelpers` (self), `ResizeArray.fs`, `TaggedCollections.*`, `zmap.fs`, `zset.fs`; consumed by F# Interactive / native-asset probing code paths.

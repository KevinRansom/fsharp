# ilsupp.fsi

**Purpose**
Interface contract for the platform-specific "support" module (`Support`). Contains functions that vary between supported implementations of the CLI Common Language Runtime (e.g. SSCLI, Mono, Microsoft CLR) — specifically the timestamp used in the PE header and the native-resource linker/unlinker.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.Support`)

**Public API surface**
- `absilWriteGetTimeStamp: unit -> int32` — the timestamp used in the PE header (deterministic builds use a fixed value; non-deterministic uses the current time).
- `IStream = System.Runtime.InteropServices.ComTypes.IStream` — alias used by the native-resource linker.
- `linkNativeResources (unlinkedResources: byte[] list) (rva: int32) : byte[]` — link the collection of unmanaged-resource buffers into a single buffer, writing the `rva` field where the resources begin. May be called twice (once with a zero-RVA and an empty buffer to probe the required size, once with the real buffer).
- `unlinkResource (rva: int32) (linkedBuffer: byte[]) : byte[]` — the inverse: extract a single resource from a linked buffer given its rva (a patch operation).

**Cross-references**
- `ilwrite.fs` (consumer of `linkNativeResources`/`unlinkResource` when writing native resources; consumer of `absilWriteGetTimeStamp` for the PE header)

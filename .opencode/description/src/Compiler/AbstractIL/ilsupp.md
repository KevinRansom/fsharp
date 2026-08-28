# ilsupp.fs

**Purpose**
Implementation of the platform-specific support module for the IL writer. Beyond the small contract in `ilsupp.fsi` (timestamp + native-resource link/unlink), this file contains the substantial low-level PE-file manipulation code: F# classes mirroring the Windows PE structures (`IMAGE_FILE_HEADER`, `IMAGE_SECTION_HEADER`, `IMAGE_SYMBOL`, `IMAGE_RELOCATION`, `IMAGE_RESOURCE_DIRECTORY`, `IMAGE_RESOURCE_DIRECTORY_ENTRY`, `IMAGE_RESOURCE_DATA_ENTRY`, `ResFormatHeader`), byte-level (de)serializers for each, the `CvtRes`-style linker/unlinker used to pack/unpack native resources into a .NET binary, and helpers to patch section headers when the image is laid out.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.Support`)

**Public API (per ilsupp.fsi)**
- `DateTime1970Jan01`, `absilWriteGetTimeStamp` — ECMA Part II 24.2.2 PE header timestamp (now - 1970-01-01 UTC, in seconds).
- `IStream = System.Runtime.InteropServices.ComTypes.IStream` — alias for native-resource linking.
- `linkNativeResources (unlinkedResources: byte[] list) (rva: int32) : byte[]` — link resources.
- `unlinkResource (rva: int32) (linkedBuffer: byte[]) : byte[]` — extract a single resource.

**Key internal bindings / helpers / classes**
- `E_FAIL = 0x80004005`.
- Byte-packing primitives `bytesToWord`, `bytesToDWord`, `dwToBytes`, `wToBytes`.
- F# classes mirroring Windows PE structs (each with a `static member Width` and a `toBytes()` method):
  - `IMAGE_FILE_HEADER` (20 bytes)
  - `IMAGE_SECTION_HEADER` (40 bytes) — note `PhysicalAddress/VirtualSize` are aliased to the same field
  - `IMAGE_SYMBOL` (18 bytes)
  - `IMAGE_RELOCATION` (10 bytes)
  - `IMAGE_RESOURCE_DIRECTORY` (16 bytes)
  - `IMAGE_RESOURCE_DIRECTORY_ENTRY` (8 bytes) — `DataIsDirectory` derived from bit 0x80000000
  - `IMAGE_RESOURCE_DATA_ENTRY` (16 bytes)
  - `ResFormatHeader` (32 bytes)
- `bytesToIRD` / `bytesToIRDE` / `bytesToIRDataE` — inverse (de)serializers for the resource structs.
- The native-resource linker/unlinker (used by `ilwrite.fs` when emitting native resources; the `IStream` alias and resource struct types support it).

**Significant internal logic**
- All PE structs are value-oriented F# records with mutable fields; `toBytes()` emits little-endian via `ByteBuffer` (from `FSharp.Compiler.IO`) at the documented `Width`.
- `linkNativeResources`/`unlinkResource` work over the resource tree encoded as `IMAGE_RESOURCE_DIRECTORY` / `IMAGE_RESOURCE_DATA_ENTRY` nodes embedded in `ResFormatHeader`-style headers.

**Cross-references**
- `ilsupp.fsi` (contract), `FSharp.Compiler.IO` (ByteBuffer), `ilwrite.fs` (consumer), `ilnativeres.fs` (native-resource type `Win32Resource`)

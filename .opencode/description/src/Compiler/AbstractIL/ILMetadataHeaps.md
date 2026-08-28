# ILMetadataHeaps.fs

**Purpose**
Abstraction layer for .NET metadata heap indexing. Provides a shared interface so both full assembly emission (ilwrite.fs) and the hot-reload delta emitter (tracked in dotnet/fsharp#19941) can index the #Strings, #Blob, #GUID, and #US (user strings) heaps using the same access patterns over different underlying storage.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILMetadataHeaps`)

**TypeDefs declared**
- `IMetadataHeaps` (interface) — metadata heap indexing operations:
  - `GetStringHeapIdx: string -> int` — get-or-add in #Strings; empty/null returns 0
  - `GetBlobHeapIdx: byte[] -> int` — get-or-add in #Blob; empty array returns 0
  - `GetGuidIdx: byte[] -> int` — get-or-add in #GUID (1-based)
  - `GetUserStringHeapIdx: string -> int` — get-or-add in #US
- `MetadataHeapsExtensions` (AutoOpen module) — `GetStringHeapIdxOption(sopt: string option)` extension mapping `None -> 0`.
- `MetadataHeapSizes` (record, NoEquality/NoComparison) — snapshot of uncompressed heap sizes (`StringHeapSize`, `UserStringHeapSize`, `BlobHeapSize`, `GuidHeapSize`) produced during emission so later delta passes can reason about stream growth. Delta-owned type kept here rather than in `ilwrite`.

**Significant internal logic**
- The type is intentionally placed in the delta-owning files so the baseline IL writer's public surface is not expanded.

**Cross-references**
- `ilwrite.fs` (implementer for full assembly emission)
- `FSharpDeltaMetadataWriter.fs`, `DeltaMetadataSerializer.fs`, `DeltaIndexSizing.fs` (consumers, e.g. `MetadataHeapSizes` in `DeltaMetadataSizes`)

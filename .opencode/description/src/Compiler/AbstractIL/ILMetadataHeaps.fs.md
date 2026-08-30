# ILMetadataHeaps.fs

## Pipeline role

Part of the AbstractIL layer. This file defines abstractions for metadata heap indexing — the string (`#Strings`), blob (`#Blob`), GUID (`#GUID`), and user-string (`#US`) heaps of a .NET metadata stream. It is used by full assembly emission (`ilwrite.fs`) and is intended to also back the delta emitter tracked in F# hot-reload work (dotnet/fsharp#19941), providing a unified interface so full-assembly and delta emission share the same heap access patterns over different underlying storage. It also records uncompressed heap sizes that later delta passes use to reason about stream growth.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.ILMetadataHeaps` (module `internal`)

## Types

- `IMetadataHeaps` (interface) — abstraction for metadata heap indexing operations:
  - `GetStringHeapIdx: string -> int` — get or add a string to the `#Strings` heap, returning the heap index (empty/null returns 0).
  - `GetBlobHeapIdx: byte[] -> int` — get or add a byte array to the `#Blob` heap, returning the heap index (empty returns 0).
  - `GetGuidIdx: byte[] -> int` — get or add a GUID to the `#GUID` heap, returning the 1-based index.
  - `GetUserStringHeapIdx: string -> int` — get or add a string to the `#US` (user strings) heap, returning the heap index.
- `MetadataHeapSizes` (record, `[<NoEquality; NoComparison>]`) — records the uncompressed heap sizes produced during metadata emission so later delta passes can reason about stream growth:
  - `StringHeapSize: int`
  - `UserStringHeapSize: int`
  - `BlobHeapSize: int`
  - `GuidHeapSize: int`

## Modules

### MetadataHeapsExtensions

`[<AutoOpen>]` extension module with extension members on `IMetadataHeaps`:

- `GetStringHeapIdxOption(sopt: string option) : int` — returns the heap index for `Some s`, or 0 for `None`.

## Significant internal logic

- `MetadataHeapSizes` is delta-owned by design: the full-assembly IL writer (`ilwrite.fs`) does not currently expose an equivalent snapshot type, so keeping the definition here lets the delta writer stay self-contained without growing `ilwrite.fsi`'s public surface. A future PR that wires a baseline producer into the delta writer can reuse this type directly or convert into it at the boundary.
- All heap accesors return 0 (an index that is a null/empty reference in metadata) for empty inputs, matching ECMA-335 conventions for zero-length heaps.
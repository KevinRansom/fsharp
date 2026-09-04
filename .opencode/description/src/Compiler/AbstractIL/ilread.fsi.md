# ilread.fsi

**Purpose**
Interface contract for the .NET binary reader (`ILBinaryReader`). Declares the reader options (PDB search path, memory-usage strategy, metadata-only mode, Roslyn metadata-snapshot hook), the `ILModuleReader` abstract type, and the `Shim` module (an AutoOpen public hook used by Resharper to override the default reader implementation).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `FSharp.Compiler.AbstractIL.ILBinaryReader` — public)

**TypeDefs declared**
- `ILReaderMetadataSnapshot = obj * nativeint * int` — a (user, nativeint, int) tuple that acts as a Roslyn-provided snapshot of the metadata section of a .NET binary, used to avoid opening the file when `metadataOnly = Yes`.
- `ILReaderTryGetMetadataSnapshot = string * System.DateTime -> ILReaderMetadataSnapshot option` — callback for the above, given (path, timestamp).
- `MetadataOnlyFlag = Yes | No` (`[<RequireQualifiedAccess>]`) — whether to open the reader for metadata only (no IL body, no native resources, no static field data).
- `ReduceMemoryFlag = Yes | No` — trade-off: `Yes` for FSI/FCS (less cache, less memory-mapped, slightly slower); `No` for `fsc.exe` (more cache, faster access).
- `ILReaderOptions` (record) — `{ pdbDirPath, reduceMemoryUsage, metadataOnly, tryGetMetadataSnapshot }`.
- `ILModuleReader` (abstract class, `IDisposable`) — `ILModuleDef: ILModuleDef`, `ILAssemblyRefs: ILAssemblyRef list`; only needs explicit `Dispose` when memory-mapping is in use.
- `Statistics` (record, mutable) — internal counters: `rawMemoryFileCount`, `memoryMapFileOpenedCount`, `memoryMapFileClosedCount`, `weakByteFileCount`, `byteFileCount`; exposed via `GetStatistics`.

**Public API surface**
- `IAssemblyReader` (auto-open interface) — `GetILModuleReader: string * ILReaderOptions -> ILModuleReader`.
- `AssemblyReader: IAssemblyReader` (mutable) — the public API hook for changing the IL assembly reader (used by Resharper).

**Internal entry points**
- `OpenILModuleReader: string -> ILReaderOptions -> ILModuleReader` — copy the binary into memory, close the file; PDB not read here; internally cached.
- `ClearAllILModuleReaderCache: unit -> unit` — clear the above cache.
- `OpenILModuleReaderFromBytes: fileName -> assemblyContents -> ILReaderOptions -> ILModuleReader` — reader over given bytes; not cached.
- `OpenILModuleReaderFromStream: fileName -> peStream -> ILReaderOptions -> ILModuleReader` — reader over given stream; the reader owns the stream and disposes it.

**Significant notes on the contract**
- Metadata is "relative" to the loaded module: `ILScopeRef.Local` means "local to that module"; use `rescopeILType`/etc. (in `Morphs`) to copy metadata into your own module.
- PDB reading is opt-in via `pdbDirPath` (directory only, not a file name); debug info is folded in as `I_seqpoint` annotations in instruction streams — no mapping from class def to source line is directly available in the PDB.

**Cross-references**
- `ilread.fs` (implementation), `il.fs` (ILModuleDef, ILAssemblyRef, ILScopeRef, ILMethodDef), `ilmorph.fsi` (rescopeILType)

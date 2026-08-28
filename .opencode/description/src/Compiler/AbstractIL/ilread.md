# ilread.fs

**Purpose**
Implementation of the .NET binary reader (`ILBinaryReader`) — reads a .NET PE binary (from disk, a byte array, or a `MemoryStream`) and converts it into AbstractIL data structures (`ILModuleDef` + `ILAssemblyRef list`). Decodes the CLR metadata (#~ tables, #Strings/#Blob/#GUID/#US heaps) via `System.Reflection.Metadata`/`System.Reflection.PortableExecutable`, decodes IL method bodies (fat/tiny headers, instruction stream with prefixes, exception tables), folds in PDB debug info when `pdbDirPath` is given, and — through an internal two-level cache (strong `AgedLookup` + weak `ConcurrentDictionary`) — provides cheap `OpenILModuleReader` lookups keyed by (full path, write time, options).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `FSharp.Compiler.AbstractIL.ILBinaryReader` — public)

**Internal infrastructure**
- `checking` / `logging` — diagnostic flags.
- `noStableFileHeuristic`, `alwaysMemoryMapFSC` — env-var toggles (`FSharp_NoStableFileHeuristic`, `FSharp_AlwaysMemoryMapCommandLineCompiler`).
- `stronglyHeldReaderCacheSize` (default 30, overridable via `FSharp_StronglyHeldBinaryReaderCacheSize`).
- `singleOfBits` / `doubleOfBits` — bits↔float conversion.
- `align`, `i32ToUncodedToken` — helpers.
- `TaggedIndex<'T>` (internal struct) — (tag, index) pair for coded indices.
- `Statistics` (record, mutable) — file-open counters: rawMemoryFileCount, memoryMapFileOpened/ClosedCount, weakByteFileCount, byteFileCount.
- `BinaryView = ReadOnlyByteMemory`; `BinaryFile` (union) — `RawMemoryFile(fileName, safeHolder, memory) | ByteMemoryFile(fileName, view) | ByteFile(fileName, bytes) | PEFile(fileName, peReader) | WeakByteFile(fileName, chunk)` — the four backends the reader can read from (memory-mapped, byte-array, `PEReader`, weakly-held chunk).
- `ILInstrPrefixesRegister` / `ILInstrDecoder` — decoders for the three instruction encodings (opcode-only, with prefix bytes `I_unaligned/I_volatile/I_constrained/I_tail/I_arglist`, and `EI_*` extensions).
- `ImageChunk { size; addr }` — code-section layout record.
- `RowElementKind` / `RowKind` — the per-table column layout (element kinds in declared order), driving the generic `ISEekReadIndexedRowReader`.
- Row-key unions used by the table readers: `TypeDefAsTypIdx`, `TypeRefAsTypIdx`, `BlobAsMethodSigIdx`, `BlobAsFieldSigIdx`, `BlobAsPropSigIdx`, `BlobAsLocalSigIdx`, `MemberRefAsMspecIdx`, `MethodSpecAsMspecIdx`, `MemberRefAsFspecIdx`, `CustomAttrIdx`, `GenericParamsIdx`.
- `MethodData` / `VarArgMethodData` — reconstructed method shape (enclosing type, calling conv, name, arg/ret types, metadata instantiation).
- `PEReader` (extension class over `System.Reflection.PortableExecutable.PEReader`).
- `ILMetadataReader` — the central metadata reader class holding the `MetadataReader`, the module def, and the per-table indexed-row readers.
- `ISEekReadIndexedRowReader<'RowT,'KeyT,'T>` — generic seekable indexed-row reader (for #~ tables keyed by name or type ref, etc.).
- `CustomAttributeRow` — decoded CustomAttribute table row.
- `Read*` helpers — `readType`, `readMethodRef`, `readFieldRef`, `readCustomAttribute`, `readTypeDef`, `readFieldDef`, `readMethodDef`, `readCode`, `readInstructions`, `readModule`, etc. (walking the `MetadataReader` API and materializing `ILTypeDefs`, `ILMethodDefs`, … lazily).
- `openMetadataReader` / `openPE` / `openPdbOnly` / `openPEMetadataOnly` — orchestration: locate the CLR data directory / metadata root, decode the `ILModuleDef` + `ILAssemblyRefs` (lazy), and optionally fold in PDB sequence points.
- Reader options and cache (contract in `ilread.fsi`):
  - `ILReaderMetadataSnapshot = obj * nativeint * int`, `ILReaderTryGetMetadataSnapshot`;
  - `MetadataOnlyFlag = Yes | No`, `ReduceMemoryFlag = Yes | No`;
  - `ILReaderOptions { pdbDirPath; reduceMemoryUsage; metadataOnly; tryGetMetadataSnapshot }`;
  - `ILModuleReader` (abstract, `IDisposable`) and `ILModuleReaderImpl` (sealed impl holding a lazy assembly-refs list);
  - `ILModuleReaderCacheKey`, `ILModuleReaderCache1LockToken`, `ilModuleReaderCache1` (strong, `AgedLookup`, size `stronglyHeldReaderCacheSize`), `ilModuleReaderCache1Lock`, `ilModuleReaderCache2` (weak, `ConcurrentDictionary<_, WeakReference<_>>`);
  - `stableFileHeuristicApplies` (use `FileSystem.IsStableFileHeuristic` to decide if re-reading is safe → weak file handles).
- `createByteFileChunk` / `getBinaryFile` — pick the `BinaryFile` backend based on `reduceMemoryUsage` and stability heuristic; track memory-map counters.
- Public entry points:
  - `OpenILModuleReaderFromBytes (fileName, assemblyContents, options)` — reader over bytes (uncached).
  - `OpenILModuleReaderFromStream (fileName, peStream, options)` — reader over a `Stream` via `PEReader(PrefetchEntireImage)` (uncached; owns the stream).
  - `ClearAllILModuleReaderCache ()` — clear both caches.
  - `OpenILModuleReader (fileName, opts)` — the main cached entry point: build a cache key (full path, last-write time, has-pdb-dir, options); on cache miss, create the reader (choosing metadata-only / reduce-memory paths), insert into both caches, and return it.
- `Statistics` / `GetStatistics` — diagnostic counters.
- `module Shim` — the public hook (contract in `ilread.fsi`) letting a host (e.g. Resharper) substitute the default reader: `type IAssemblyReader with abstract GetILModuleReader`; `val mutable AssemblyReader: IAssemblyReader`.

**Significant internal logic**
- `OpenILModuleReader` refuses to use the cache when `opts.pdbDirPath.IsSome` (those readers are `IDisposable` and PDB reading requires a fresh reader).
- `OpenILModuleReader` falls back to an uncached reader if the key cannot be computed (e.g., non-existent path) — `Debug.Assert(false, ...)` then a fake key.
- When `reduceMemoryUsage = Yes` and the file is a "stable heuristic" file, `WeakByteFile` is used (a chunked weak reference to the read bytes, re-read on demand) — this is the FSI/FCS path that keeps memory bounded.
- When `metadataOnly = Yes`, the reader uses `opts.tryGetMetadataSnapshot` if it provides a `(obj, start, len)` for a fast path that skips the full PE load.
- `OpenILModuleReaderFromStream` constructs a `PEReader` with `PrefetchEntireImage` and wraps it in a `PEFile` — the reader owns the stream and disposes it with the reader.
- The instruction decoder handles the three instruction encodings (opcode-only, with prefix bytes, `EI_*` extensions) and produces the `ILInstr` union values from `il.fs`.

**Cross-references**
- `ilread.fsi` (contract), `il.fs` (the target data structures: ILModuleDef, ILTypeDef, ILMethodDef, ...), `ilbinary.fs` (opcode / table-name constants), `ilsupp.fs` (PE-header timestamp), `Internal.Utilities` (AgedLookup, HashIdentity, HashMultiMap, etc.)

# FileSystem.fs

**Purpose**: The compiler's filesystem abstraction layer and binary byte-buffering infrastructure. It defines the `IFileSystem` shim (and its `DefaultFileSystem` memory-mapped implementation) used throughout the compiler to do file I/O, path canonicalization, and assembly loading in an FCS-testable way, plus the `ByteMemory`/`ReadOnlyByteMemory`/`ByteBuffer`/`ByteStorage`/`ByteStream` type family for reading and emitting IL/PE binary data without per-byte managed copies. Public contract in `FileSystem.fsi`.

**Namespace(s)** declared: `FSharp.Compiler.IO`

**Modules / Types declared**:
- `exception IllegalFileNameChar of string * char` (internal) — raised on illegal path characters.
- `module internal Bytes` — small helpers for byte arrays and encoding (`get`, `zeroCreate`, `ofInt32Array`, `blit`, `stringAsUtf8NullTerminated`, `stringAsUnicodeNullTerminated`); private `b0..b3`, `dWw0/1` byte extractors.
- `type ByteMemory` (`[<AbstractClass>]`, public) — abstract view over bytes (managed, unmanaged, or memory-mapped backed); read accessors and stream/`Slice`/`CopyTo` operations.
- `type ByteArrayMemory` (sealed) — `ByteMemory` over a `byte[]` with offset/length.
- `type SafeUnmanagedMemoryStream` (sealed) — `UnmanagedMemoryStream` with a holder reference so GC keeps native memory alive.
- `type internal MemoryMappedStream` — `Stream` view over a `MemoryMappedFile` (`ViewStream` property).
- `type RawByteMemory` — `ByteMemory` over a `nativeptr<byte>` + `length` + holder.
- `type internal MemoryMappedFileExtensions` — extension `TryFromByteMemory` / `TryFromMemory` to recover the underlying `MemoryMappedFile`.
- `type ReadOnlyByteMemory` (struct, internal) — read-only wrapper over `ByteMemory`; `Underlying` property exposes the backing memory.
- `module internal FileSystemUtils` — path helpers (see API surface).
- `type IAssemblyLoader` / `DefaultAssemblyLoader` — abstraction for `AssemblyLoad` (by name) and `AssemblyLoadFrom` (by file), used by F# Interactive and type-provider loading.
- `type IFileSystem` (public) — the "file system hook" of the FCS API; ~25 abstract shim members (see API surface).
- `type DefaultFileSystem` (public, `new: unit`) — default implementation over `File`/`Directory`/`MemoryMappedFile`.
- `[<AutoOpen>] module StreamExtensions` (public) — extension members on `System.IO.Stream` (`GetReader`, `AsByteMemory`, `ReadAllBytes`, `WriteAllLines`, etc.).
- `[<AutoOpen>] module FileSystemAutoOpens` (public) — `val mutable FileSystem : IFileSystem`, the global hook.
- `type ByteMemory with` (extension) — `AsReadOnly`, static `Empty`, `FromMemoryMappedFile`, `FromUnsafePointer`, `FromArray`.
- `type internal ByteStream` — sequential reader over `ReadOnlyByteMemory`: `IsEOF`, `ReadByte`, `ReadBytes : int -> ReadOnlyByteMemory`, `ReadUtf8String`, `Position`, static `FromBytes`.
- `type internal ByteBuffer` (sealed, `[MethodImpl(AggressiveInlining)]` on most members) — growable writable byte buffer for emitting IL: many `Emit*` methods, `FixupInt32`, `AsMemory`, `Position`, `Create(capacity, ?useArrayPool)`.
- `type ByteStorage` (sealed) — a thunk (`unit -> ReadOnlyByteMemory`) owning the backing bytes; `FromByteMemory(AndCopy)`, `FromMemoryAndCopy`, `FromByteArray(AndCopy)`.

**Public API surface** (key items, per FileSystem.fsi; many members are `internal`):
- `IFileSystem` — abstract shims the compiler calls instead of BCL directly: `OpenFileForReadShim` (`?useMemoryMappedFile`, `?shouldShadowCopy`), `OpenFileForWriteShim`, `GetFullPathShim`, `GetFullFilePathInDirectoryShim`, `IsPathRootedShim`, `NormalizePathShim`, `IsInvalidPathShim`, `GetTempPathShim`, `GetDirectoryNameShim`, `GetLastWriteTimeShim`, `GetCreationTimeShim`, `CopyShim`, `FileExistsShim`, `FileDeleteShim`, `DirectoryCreateShim`, `DirectoryExistsShim`, `DirectoryDeleteShim`, `EnumerateFilesShim`, `EnumerateDirectoriesShim`, `IsStableFileHeuristic`, `ChangeExtensionShim`, `AssemblyLoader : IAssemblyLoader`.
- `FileSystemAutoOpens.FileSystem : IFileSystem` (mutable) — the active implementation; FCS/test code swaps this.

**Significant internal logic / behavioral notes**:
- `DefaultFileSystem.OpenFileForReadShim` uses `MemoryMappedFile` for large reads (e.g. .dll files) and `FileStream` otherwise; `shouldShadowCopy` enables shadow-copy reads for assemblies.
- `OpenFileForWriteShim` defaults: `FileMode.CreateNew`, `FileAccess.ReadWrite`, `FileShare.None`.
- `ByteMemory` backings: array-backed (`ByteArrayMemory`), memory-mapped (`FromMemoryMappedFile`), or raw-pointer (`FromUnsafePointer`); `SafeUnmanagedMemoryStream` and a holder object prevent native memory from being collected; `CopyTo`/`AsStream` do not own the bytes.
- `ByteBuffer` is a growable append-only buffer (`Ensure newSize` doubles capacity, optional `ArrayPool<byte>` backings for reuse); `FixupInt32 pos value` writes a little-endian int32 at an absolute offset (used for back-patching IL offsets); not thread-safe per doc comment.
- `ByteStorage` decouples "who owns the bytes" from "how to read them": `From*` variants without copy share the underlying memory; `*AndCopy` variants copy out (optionally into a memory-mapped file).
- `RawByteMemory` uses `System.Native`/unsafe pointer arithmetic for reads to avoid bounds-checked array copies on the hot IL path.
- `Bytes` helper module is used by the PE/IL emitters for little-endian assembly.

**Cross-references**: `Caches.fs`/`Caches.fsi` (both in the same folder) don't reference this file, but the IL-emit path (`src/Compiler`, e.g. PE/IL writers under `src/Compiler/`) consumes `ByteBuffer`/`ByteStream`/`ByteStorage`/`ByteMemory` heavily; `ReadOnlyByteMemory` is the read-facing type passed into them.

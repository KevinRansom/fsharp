# FileSystem.fsi

**Purpose**: Public signature file for `FileSystem.fs` (same directory, namespace `FSharp.Compiler.IO`). Defines the FCS API "file system hook" surface: the global `IFileSystem` hook, the `ByteMemory` abstract type and `ByteBuffer`/`ByteStream`/`ByteStorage` binary helpers, plus stream utilities — the compiler consumes these instead of raw BCL I/O so that FCS/test code can swap in mocks.

**Namespace(s)** declared: `FSharp.Compiler.IO`

**Declared items** (public contract):
- `exception internal IllegalFileNameChar of string * char`.
- `module internal Bytes` — `get`, `zeroCreate`, `ofInt32Array`, `blit`, `stringAsUnicodeNullTerminated`, `stringAsUtf8NullTerminated`.
- `[<AbstractClass>] type public ByteMemory` — abstract read view: `Item[int]`, `Length`, `ReadAllBytes`, `ReadBytes`, `ReadInt32`, `ReadUInt16`, `ReadUtf8String`, `Slice`, `CopyTo`, `Copy`, `ToArray`, `AsStream`, `AsReadOnlyStream`.
- `[<Struct; NoEquality; NoComparison>] type internal ReadOnlyByteMemory` — read-only wrapper mirroring most of the above, with `CopyTo`, `ToArray`, `AsStream`.
- `module internal MemoryMappedFileExtensions` — `TryFromByteMemory`, `TryFromMemory`.
- `[<RequireQualifiedAccess>] module internal FileSystemUtils` — `checkPathForIllegalChars`, `checkSuffix`, `chopExtension`, `hasExtension`, `fileNameOfPath`, `fileNameWithoutExtensionWithValidate`, `fileNameWithoutExtension`, `trimQuotes`, `isDll`.
- `type public IAssemblyLoader` — `AssemblyLoad : AssemblyName -> Assembly`, `AssemblyLoadFrom : string -> Assembly`.
- `type DefaultAssemblyLoader` — default implementation.
- `type public IFileSystem` — the full set of `*Shim` abstract members (reads, path canonicalization, file/directory exists/create/delete/copy, enumerate, last-write/creation time, `IsStableFileHeuristic`, `ChangeExtensionShim`) plus `AssemblyLoader : IAssemblyLoader`.
- `type DefaultFileSystem` — default implementation (also re-declares/overrides each shim).
- `[<AutoOpen>] module public StreamExtensions` — extension members on `System.IO.Stream`: `GetWriter`, `WriteAllLines`, `Write<'a>`, `GetReader`, `ReadBytes`, `ReadAllBytes`, `ReadAllText`, `ReadLines`, `ReadAllLines`, `WriteAllText`, `AsByteMemory`.
- `[<AutoOpen>] module public FileSystemAutoOpens` — `val mutable FileSystem : IFileSystem` (the global hook).
- `type internal ByteMemory with` — extensions: `AsReadOnly`, `Empty`, `FromMemoryMappedFile`, `FromUnsafePointer`, `FromArray`.
- `[<Sealed>] type internal ByteStream` — `IsEOF`, `ReadByte`, `ReadBytes : int -> ReadOnlyByteMemory`, `ReadUtf8String`, `Position`, static `FromBytes`.
- `[<Sealed>] type internal ByteBuffer` — growable byte writer for IL emission: `AsMemory`, `EmitIntAsByte`, `EmitIntsAsBytes`, `EmitByte`, `EmitBytes`, `EmitMemory`, `EmitByteMemory`, `EmitInt32`, `EmitInt64`, `EmitInt32AsUInt16`, `EmitBoolAsByte`, `EmitUInt16`, `FixupInt32`, `Position`, static `Create : int * ?useArrayPool -> ByteBuffer`.
- `[<Sealed>] type internal ByteStorage` — `GetByteMemory`; static creators `FromByteMemory(AndCopy)`, `FromMemoryAndCopy`, `FromByteArray(AndCopy)`.

**Relationship to .fs**: The .fs provides the same public API plus implementation types that the .fsi abstracts (e.g. `ByteArrayMemory`, `RawByteMemory`, `MemoryMappedStream`, `SafeUnmanagedMemoryStream`, `Bytes.b0..b3` byte extractors, and the `DefaultFileSystem` body); the .fsi is the contract FCS/external code compiles against.

**Cross-references**: `Caches.md` (sibling) does not depend on this file; see `Caches.md` for the cache infrastructure. Compiler code that emits IL/PE (e.g. under `src/Compiler/`) is the main consumer of `ByteBuffer`/`ByteStream`/`ByteStorage`/`ByteMemory`.

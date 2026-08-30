# ilwritepdb.fsi

**Purpose**
Interface contract for the Portable PDB writer (`ILPdbWriter`). Declares the record types that flow through the writer (`PdbDocumentData`, `PdbLocalVar`, `PdbImport`, `PdbImports`, `PdbMethodScope`, `PdbSourceLoc`, `PdbDebugPoint`, `PdbMethodData`, `PdbMethodCustomDebugInfo`, `PdbModuleCustomDebugInfo`, `PdbData`, `BinaryChunk`, `idd`, `HashAlgorithm`), the main entry point `generatePortablePdb`, the IMAGE_DEBUG_DIRECTORY builders (`getInfoForPortablePdb`, `getInfoForEmbeddedPortablePdb`), the stream compression helper, the checksum helper, the PDB file-name helper, the scope-unshadowing helper `unshadowScopes`, and the `sizeof_IMAGE_DEBUG_DIRECTORY` / `logDebugInfo` diagnostics.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILPdbWriter`)

**TypeDefs declared (per .fsi)**
See the matching section in the `ilwritepdb.md` description for details — the .fsi is the authoritative source for the field names and types.

**Public API surface**
- `getDebugFileName : string -> string` — take the .NET assembly output file name, return the companion PDB file name.
- `sizeof_IMAGE_DEBUG_DIRECTORY : System.Int32` — 28 per `ntimage.h`.
- `logDebugInfo : string -> PdbData -> unit` — dump `PdbData` for diagnostics (called by `ilwrite.fs`).
- `generatePortablePdb :
    embedAllSource : bool ->
    embedSourceList : string list ->
    sourceLink : string ->
    checksumAlgorithm : HashAlgorithm ->
    info : PdbData ->
    pathMap : PathMap ->
    moduleCustomDebugInfoRows : PdbModuleCustomDebugInfo list ->
    methodCustomDebugInfoRows : Map<string, PdbMethodCustomDebugInfo list> ->
        int64 * BlobContentId * MemoryStream * string * byte[]` — produce a compressed Portable PDB stream plus the embedded-chunk info. The 5-tuple is `(embeddedLength, contentId, pdbStream, algorithmName, checksum)`.
- `compressPortablePdbStream : MemoryStream -> MemoryStream` — deflate.
- `getInfoForEmbeddedPortablePdb : (many args, see .fsi) -> idd[]` — build the IMAGE_DEBUG_DIRECTORY rows for an embedded-PDB layout.
- `getInfoForPortablePdb : (many args, see .fsi) -> idd[]` — build the IMAGE_DEBUG_DIRECTORY rows for a side-by-side PDB.
- `unshadowScopes : PdbMethodScope -> PdbMethodScope[]` — the scope-shading algorithm from the .fsi comments.

**Cross-references**
- `ilwritepdb.fs` (implementation), `ilwrite.fs` (consumer; `options.portablePDB` controls whether native or portable is used), `FSharpDeltaMetadataWriter.fs` (hot-reload PDB delta), `EncMethodDebugInformation.fs` (producer of the EnC CDI rows), `il.fs` (`ILSourceDocument`)

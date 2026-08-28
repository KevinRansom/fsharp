# ilwritepdb.fs

**Purpose**
The Portable PDB (.NET metadata + debug info) writer for the F# compiler. Given a `PdbData` blob (module entry-point token, MVID, timestamp, source documents, per-method scopes/locals/imports, sequence-point debug points) and a `PathMap` (canonical-source-path mapping), this module produces a compressed Portable PDB `MemoryStream` plus the `IMAGE_DEBUG_DIRECTORY` rows that `ilwrite.fs` embeds into the PE's CLR data directory. Also implements the scope-unshadowing logic for the locals of a method (push-shadowed-locals, `unshadowScopes`) and the F#-owned EnC `CustomDebugInformation` side channel (`moduleCustomDebugInfoRows` / `methodCustomDebugInfoRows`, see `EncMethodDebugInformation.fs`).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILPdbWriter`)

**Supporting types (per `ilwritepdb.fsi`)**
- `PdbDocumentData = ILSourceDocument` — alias.
- `PdbLocalVar` (record) — `{ Name, Signature : byte[], Index : int32 }`.
- `PdbImport` (union) — `ImportType of int32` | `ImportNamespace of string`.
- `PdbImports` (record) — `{ Parent : PdbImports option; Imports : PdbImport[] }`.
- `PdbMethodScope` (record) — `{ Children; StartOffset; EndOffset; Locals; Imports : PdbImports option }` — the recursive scope tree that `unshadowScopes` walks.
- `PdbSourceLoc` (record) — `{ Document; Line; Column }`.
- `PdbDebugPoint` (record) — `{ Document; Offset; Line; Column; EndLine; EndColumn }`.
- `PdbMethodData` (record) — `{ MethToken; MethName; LocalSignatureToken; Params; RootScope; DebugRange; DebugPoints }`.
- `PdbMethodCustomDebugInfo` (record) — `{ KindGuid : Guid; Blob : byte[] }`.
- `PdbModuleCustomDebugInfo` (record) — `{ KindGuid : Guid; Blob : byte[] }`.
- `PdbData` (record, NoEquality/NoComparison) — `{ EntryPoint; Timestamp; ModuleID; Documents; Methods; TableRowCounts }`.
- `BinaryChunk` (record) — `{ size; addr }`.
- `idd` (record, mirror of `IMAGE_DEBUG_DIRECTORY`) — `{ iddCharacteristics; iddMajorVersion; iddMinorVersion; iddType; iddTimestamp; iddData; iddChunk }`.
- `HashAlgorithm` (union) — `Sha1 | Sha256`.

**Supporting helpers**
- `BlobBuildingStream` (class around `System.IO.MemoryStream` + `System.Reflection.Metadata.BlobBuilder` for buffered writes).
- `SequencePoint` (nested module) — `ILSourceDocument` / `ILInstructionSeqPoint` helpers.
- `sizeof_IMAGE_DEBUG_DIRECTORY = 28`.
- `guidSha1 = ff1816ec-aa5e-4d10-87f7-6f4963833460` (Portable PDB's `.cv`/`.pdb` directory GUID for SHA1); `guidSha2 = 8829d00f-11b8-4213-878b-770e8597ac16` (SHA256 counterpart).
- `checkSum (url : string) (algorithm : HashAlgorithm) : byte[]`.
- `b0/b1/b2/b3`, `i32AsBytes` — little-endian byte packers.
- `cvMagicNumber = 0x53445352L` ("RSDS", the CodeView-style magic used for `#PdbInfo`-style headers).
- `pdbGetCvDebugInfo (mvid) (timestamp) (filepath) (cvChunk) : byte[]` — build the `IMAGE_DEBUG_DIRECTORY` data for the CV-style directory.
- `pdbMagicNumber = 0x4244504D` (PDPB-ish magic for the embedded/PDB directory).
- `pdbGetEmbeddedPdbDebugInfo (embeddedPdbChunk) (uncompressedLength) (compressedStream)` — build the PDPB-format header that embeds an in-memory Portable PDB blob (the `.pdb`-in-PE scheme, used for `--embed:src` / single-file / source-link builds).
- `pdbChecksumDebugInfo (timestamp) (checksumPdbChunk) (algorithmName) (checksum)` — the checksum directory entry (`.pdb-embedded` or `.pdb` checksum).
- `pdbGetDebugDeterministicInfo (deterministicPdbChunk)` — the deterministic PDB directory entry.
- `pdbGetDebugInfo (cvDebugData, pdbDebugData, deterministicPdbData, checksumData)` — final assembly of the idd table.
- `getDebugFileName (outfile) : string` — compute the companion PDB path.
- `sortMethods (info : PdbData) : PdbMethodData[]`, `getRowCounts (tableRowCounts : int[])` — table row-count summary per PDB metadata table (Document/MethodDebugInformation/LocalScope/LocalVariable/LocalConstant/ImportScope/StateMachineMethod/CustomDebugInformation — table numbers 0x30..0x37, per `ILDeltaHandles.DeltaTokens`).
- `scopeSorter (s1, s2)` — comparator for `PdbMethodScope` by (StartOffset, EndOffset).
- `PortablePdbGenerator` (class — large, ~540 lines, around lines 347-890) — the actual Portable PDB builder: owns the `MetadataBuilder` from `System.Reflection.Metadata`, emits the `#Pdb` stream, and produces the compressed `MemoryStream`.
- `generatePortablePdb (embedAllSource) (embedSourceList) (sourceLink) (checksumAlgorithm) (info : PdbData) (pathMap) (moduleCustomDebugInfoRows) (methodCustomDebugInfoRows) : (int64 * BlobContentId * MemoryStream * string * byte[])` — the main entry point used by `ilwrite.fs`.
- `compressPortablePdbStream (stream)` — deflate the stream.
- `getInfoForPortablePdb (contentId, pdbfile, pathMap, cvChunk, deterministicPdbChunk, checksumPdbChunk, algorithmName, checksum, embeddedPdb, deterministic) : idd[]` — build the IMAGE_DEBUG_DIRECTORY rows for a non-embedded PDB.
- `getInfoForEmbeddedPortablePdb (uncompressedLength, contentId, compressedStream, pdbfile, cvChunk, pdbChunk, deterministicPdbChunk, checksumPdbChunk, algorithmName, checksum, deterministic) : idd[]` — build the IMAGE_DEBUG_DIRECTORY rows for an embedded PDB.
- `logDebugInfo (outfile : string) (info : PdbData)` — a debug dump of the PDB tree (for compiler diagnostics).
- Scope unshadowing (F#/C# interop — see the .fsi contract): `allNamesOfScope`, `pushShadowedLocals`, `unshadowScopes (rootScope : PdbMethodScope) : PdbMethodScope[]` — the algorithm that, when a scope has a local with the same name as any of its children, clones the scope into each "gap" and adds `(shadowed)` to the children's conflicting locals.

**Significant internal logic**
- `sortMethods` sorts methods by their metadata token so that the `MethodDebugInformation` PDB rows are emitted in table order (the runtime requires it).
- `getRowCounts` is used to fill the PDB `#~` stream header so the runtime can binary-search the tables.
- `unshadowScopes` is the F#-specific scope model fixup that the C# semantic PDB consumer needs (otherwise C#-style F# locals would be mis-attributed across scopes).
- The `PathMap` mapping is applied to the `Document` table entries so that `#SourceLink`-style source links work.
- The EnC CDI side channels (`moduleCustomDebugInfoRows`, `methodCustomDebugInfoRows`) are applied as `CustomDebugInformation` rows on the enclosing MethodDef and Module rows respectively; fail-closed on method-name ambiguity (see `ilwritepdb.fsi`).

**Cross-references**
- `ilwritepdb.fsi` (contract), `ilwrite.fs` (consumer: PDB emission), `EncMethodDebugInformation.fs` (producer of the EnC CDI rows), `ilread.fs` (PDB reading via `ILReaderOptions.pdbDirPath`), `il.fs` (ILSourceDocument, ILMethodDef, ...), `FSharp.Compiler.AbstractIL.StrongNameSign` (used for checksum algorithm)

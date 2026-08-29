# ilwritepdb.fs

## Pipeline role

Part of the AbstractIL layer. This module writes Portable PDB debug information for compiled assemblies: it converts the F# debug info abstraction (`PdbData` with documents, methods, scopes, locals, and source locations) into a `MetadataBuilder`-driven portable PDB, producing the debug directory entries (CodeView, embedded PDB, deterministic, and checksum) for the PE writer. It also supports embedding source files and source link into the PDB, and a `logDebugInfo` text dump for testing.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.ILPdbWriter` (module `internal`)
- Uses: `System`, `System.Collections.Generic`, `System.Collections.Immutable`, `System.IO`, `System.IO.Compression` (DeflateStream), `System.Reflection.Metadata` (`MetadataBuilder`, `PortablePdbBuilder`, `BlobBuilder`, handle types), `System.Reflection.Metadata.Ecma335` (`MetadataTokens`, `EntityHandle`, `ImportDefinitionKind`, `TableIndex`, `EditAndContinueOperation`-adjacent helpers), `System.Security.Cryptography`, `System.Text`, `Internal.Utilities`, `FSharp.Compiler.AbstractIL.IL`, `Internal.Utilities.Library`, `FSharp.Compiler.DiagnosticsLogger` (`reportTime`), `FSharp.Compiler.IO`.

## Types

- `BlobBuildingStream` (class, `inherit Stream`) — a write-only `Stream` backed by a `BlobBuilder` (32KB chunks): `Write`/`WriteByte`, `WriteInt32`, `ToImmutableArray`, `TryWriteBytes(stream, length)`, non-seekable/readable; `Flush`/`Dispose` are no-ops.
- `PdbDocumentData = ILSourceDocument` (type abbreviation).
- `PdbLocalVar` (record) — `{ Name: string; Signature: byte[]; Index: int32 }`.
- `PdbImport` (DU) — `ImportType of targetTypeToken: int32 | ImportNamespace of targetNamespace: string` (assembly/alias variants commented out).
- `PdbImports` (record) — `{ Parent: PdbImports option; Imports: PdbImport[] }`.
- `PdbMethodScope` (record) — `{ Children: PdbMethodScope[]; StartOffset; EndOffset; Locals: PdbLocalVar[]; Imports: PdbImports option }`.
- `PdbSourceLoc` (record) — `{ Document: int; Line: int; Column: int }`.
- `PdbDebugPoint` (record) — `{ Document; Offset; Line; Column; EndLine; EndColumn }` with a `ToString()` of `(l,c)-(endl,endc)`.
- `PdbMethodData` (record) — `{ MethToken: int32; MethName: string; LocalSignatureToken: int32; Params: PdbLocalVar array; RootScope: PdbMethodScope option; DebugRange: (PdbSourceLoc * PdbSourceLoc) option; DebugPoints: PdbDebugPoint array }`.
- `PdbMethodCustomDebugInfo` (record) — a pre-serialized CustomDebugInformation row `{ KindGuid: Guid; Blob: byte[] }` to attach to a method row.
- `PdbModuleCustomDebugInfo` (record) — the same for the module row.
- `PdbData` (record, `[<NoEquality; NoComparison>]`) — the writer input: `{ EntryPoint: int32 option; Timestamp: int32; ModuleID: byte[]; Documents: PdbDocumentData[]; Methods: PdbMethodData[]; TableRowCounts: int[] }`.
- `BinaryChunk` (record) — `{ size: int32; addr: int32 }` (a placed chunk in the PE).
- `idd` (record) — an `IMAGE_DEBUG_DIRECTORY` row: `{ iddCharacteristics; iddMajorVersion; iddMinorVersion; iddType; iddTimestamp; iddData: byte[]; iddChunk: BinaryChunk }`.
- `HashAlgorithm` (enum-ish DU) — `Sha1 | Sha256` (the PDB hash algorithm).

## Modules and values

- `SequencePoint` module — comparators `orderBySource` (Document, Line, Column) and `orderByOffset`.
- `sizeof_IMAGE_DEBUG_DIRECTORY = 28` — from ntimage.h.
- `guidSha1 = "ff1816ec-aa5e-4d10-87f7-6f4963833460"`, `guidSha2 = "8829d00f-11b8-4213-878b-770e8597ac16"` — document checksum algorithm GUIDs.
- `checkSum url algorithm` — computes the document hash, returning `(guid, checksum)` or `None`.

## Debug-directory builders

- Byte helpers `b0..b3`, `i32AsBytes`.
- `cvMagicNumber = 0x53445352L` ("RSDS"), `pdbMagicNumber = 0x4244504dL` ("MPDB").
- `cvDebugInfo` builders:
  - `pdbGetCvDebugInfo (mvid) (timestamp) (filepath) (cvChunk)` — RSDS record (magic, MVID, count=1, UTF-8 path), type 2 (CODEVIEW), version 0x0100.504d.
  - `pdbGetEmbeddedPdbDebugInfo (embeddedPdbChunk) (uncompressedLength) compressedStream` — type 17 (EMBEDDEDPDB), magic "MPDB", uncompressed length + deflate stream.
  - `pdbChecksumDebugInfo timestamp chunk algorithmName checksum` — type 19 (CHECKSUM), name + NUL + checksum.
  - `pdbGetPdbDebugDeterministicInfo chunk` — type 16 (DETERMINISTIC), empty data.
  - `pdbGetDebugInfo ...` — assembles the array from the pieces, honoring `embeddedPdb`/`deterministic` flags.

## PDB writer functions

- `getDebugFileName outfile` — replaces the extension with `.pdb`.
- `sortMethods info` — sorts methods by `MethToken` in place (`reportTime` diagnostics).
- `getRowCounts tableRowCounts` — `ImmutableArray<int>` of table row counts.
- `scopeSorter` — orders scopes by StartOffset then by larger span first.

## Class

`PortablePdbGenerator(embedAllSource, embedSourceList, sourceLink, checksumAlgorithm, info, pathMap, moduleCustomDebugInfoRows, methodCustomDebugInfoRows)` — the portable PDB builder:

- Internal state: `originalDocFiles`, `docsSorted` (documents sorted by path-mapped file for determinism), one `MetadataBuilder`; well-known GUIDs `corSymLanguageTypeId`, `embeddedSourceId`, `sourceLinkId`; `sourceCompressionThreshold = 200`; `moduleImportScopeHandle = MetadataTokens.ImportScopeHandle 1`.
- `serializeDocumentName name` — path-maps the name, chooses the dominant separator, writes separator byte + compressed per-part UTF-8 blob offsets.
- `includeSource file` — embeds source: uncompressed (`WriteInt32 0` + raw bytes) when < 200 bytes, else deflate-compressed (`WriteInt32 length` prefix) into a `BlobBuildingStream`.
- `documentIndex` — builds the Document table in deterministic order, adding hash/checksum, language, embedded-source CustomDebugInformation, source-link and module custom-debug-info rows; capacity presized.
- `getDocumentHandle d` — maps original document index -> filename -> handle.
- `methodCustomDebugInfoByName` — per-method CDI rows, filtered to method names that occur exactly once (overloads fail closed so rows never land on the wrong method).
- `serializeImport writer import` — writes `ImportDefinitionKind.ImportType`/`ImportNamespace` records (other import kinds commented out).
- `serializeImportsBlob imports` — sorts imports (ImportType before ImportNamespace, then by target) and builds the blob.
- `defineModuleImportScope ()` — adds the empty global ImportScope (asserts rid = 1).
- `getImportScopeIndex imports` — memoized parent-linked ImportScope creation.
- `flattenScopes rootScope` — flattens the scope tree (with proper nesting detection) and sorts with `scopeSorter`.
- `writeMethodScopes methToken rootScope` — adds LocalScope rows with import-scope handles and LocalVariable rows (sorted by `Index`), tracking `lastLocalVariableHandle`.
- `emitMethod minfo` — builds the MethodDebugInformation sequence-point blob:
  - Encodes the local signature token and compressed sequence-point records with initial-document handling for multi-document methods and hidden-sequence-point records (`0xfeefee` lines / zero columns).
  - Caps values: offset <= 0xfffe, lines <= 0x1ffffffe, columns <= 0xfffe (with a comment documenting the Portable PDB spec's gray area).
  - Adds per-method CustomDebugInformation rows and scopes.
- `Emit()` — the entry point: `sortMethods`, presizes MethodDebugInformation capacity, `defineModuleImportScope`, emits all methods, computes the entry point handle, hashes content into `contentId` via an `idProvider` (SHA1/SHA256 per `checksumAlgorithm`), then serializes with `PortablePdbBuilder(metadata, externalRowCounts, entryPoint, idProvider)`, returning `(streamLength, contentId, MemoryStream, algorithmName, contentHash)`.

## Module functions (top level)

- `generatePortablePdb ...` — constructs a `PortablePdbGenerator` and calls `Emit()`.
- `compressPortablePdbStream stream` — deflates a PDB MemoryStream.
- `getInfoForPortablePdb ...` — builds full debug info for an external PDB.
- `getInfoForEmbeddedPortablePdb (uncompressedLength) contentId compressedStream pdbfile ...` — debug info for an embedded PDB (uses just the file name).

## Test/dump helpers

- `logDebugInfo outfile info` — dumps documents, methods, scopes, and points to `<outfile>.debuginfo`.
- `allNamesOfScope` / `allNamesOfScopes` — collect all local names in a scope tree.
- `pushShadowedLocals stackGuard localsToPush scope` — pushes ancestors' locals into child scopes; locals conflicting with a child's own names are renamed with `" (shadowed)"`; if any child forces a split, the parent scope is re-emitted per gap. Uses a `StackGuard` to avoid stack overflow on deep nesting.
- `unshadowScopes rootScope` — the public re-shadowing entry point returning the adjusted scope list (used so scopes with name conflicts are split rather than losing locals).

## Significant internal logic

- Determinism: documents are emitted in path-mapped sorted order while handles are looked up via the original filename index; locals and imports are sorted; content hash is always computed (required for deterministic build).
- Sequence points follow the Portable PDB compressed record spec with clamping to the spec's effective ranges; hidden records (0xfeefee) are encoded as zero lines/columns.
- The engine re-derives scopes (`pushShadowedLocals`/`unshadowScopes`) so shadowed locals are preserved and scope boundaries are split only where needed.
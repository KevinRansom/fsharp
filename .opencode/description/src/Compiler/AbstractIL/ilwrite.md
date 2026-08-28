# ilwrite.fs

**Purpose**
The full-assembly .NET binary writer (`ILBinaryWriter`). Takes an `ILModuleDef` (and a `cenv` containing all the metadata tables, string/blob/GUID/userstring heaps, IL bodies, resources) and emits a .NET PE file: the metadata streams (`#~` tables heap, `#Strings`, `#US`, `#GUID`, `#Blob`), the IL code section, optional native resources, the CLR header/directories, strong-name / delay-signing, and a portable or native PDB. Shared by the command-line writer (`WriteILBinaryFile`) and the in-memory writer (`WriteILBinaryInMemory`).

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILBinaryWriter`)

**TypeDefs declared**
- `RowElement(tag: int32, idx: int32)` — one column in a metadata table row (element type + value).
- `RowElementTags` (nested module) — ECMA-335 coded-index element-tag constants (UShort=0, ULong=1, Data=2, DataResources=3, Guid=4, Blob=5, String=6, `SimpleIndexMin=7..SimpleIndexMax=119`, `TypeDefOrRefOrSpec 120..122`, `TypeOrMethodDef 123..124`, `HasConstant 125..127`, `HasCustomAttribute 128..149`, `HasFieldMarshal 150..151`, `HasDeclSecurity 152..154`, `MemberRefParent 155..159`, `HasSemantics 160..161`, `MethodDefOrRef 162..164`, `MemberForwarded 165..166`, `Implementation 167..169`, `CustomAttributeType 170..173`, `ResolutionScope 174..178`) with per-table-index constructors.
- Convenience row constructors: `UShort/ULong/Data/Guid/Blob/StringE/SimpleIndex/TypeDefOrRefOrSpec/TypeOrMethodDef/HasConstant/HasCustomAttribute/HasFieldMarshal/HasDeclSecurity/MemberRefParent/HasSemantics/MethodDefOrRef/MemberForwarded/Implementation/CustomAttributeType/ResolutionScope`.
- `BlobIndex = int`, `StringIndex = int`.
- `GenericRow = RowElement[]`.
- `SharedRow(elems, hashCode)` — a row with a precomputed hash, used for deduplication in metadata tables.
- `UnsharedRow(elems)` — a row not eligible for sharing by content.
- `ILTypeWriterEnv = { EnclosingTyparCount: int }` — the generic-parameter count of the enclosing type, used when encoding method-ref signatures (to disambiguate `!n` type-var numbers between the enclosing type and the method).
- `MetadataTable<'T when 'T not null>` — a metadata table (list of `RowElement[]` rows) with add/lookup and optional sort.
- Key types for table deduplication: `MethodDefKey`, `FieldDefKey`, `PropertyTableKey`, `EventTableKey`, `TypeDefTableKey`.
- `MetadataTable` (unparameterized concrete union, used as a `cenv.GetTable` key).
- `cenv` (record) — the compilation environment holding the `ILGlobals`, the metadata tables (one per `MetadataTable` key), the heaps (strings/blobs/GUIDs/userStrings), the IL bodies/resources, and the `ILTokenMappings` for cross-module references (a big record — used throughout).
- `ILTokenMappings` (record, mutable) — per-module bookkeeping for assembly refs, type refs, method refs, field refs, method-specs, standalone sigs, custom attribute rows, etc., so they are only created once even if referenced by many rows.
- `ExceptionClauseKind` (union: Catch/Filter/Finally/Fault) and `ExceptionClauseSpec = int * int * int * int * ExceptionClauseKind` — the shape of an exception clause emitted into a method body.
- `CodeBuffer` — a small wrapper around `ResizeArray<byte>` + a fixup table for deferred 32-bit patching (e.g. method tokens, labels).
- `module Codebuf = ...` — helpers for the CodeBuffer API (alloc/fixup/align, label patching).
- `module FileSystemUtilities = ...` — helpers for opening/writing files with retries.
- `options` — writer configuration (see `ilwrite.fsi`).

**Key bindings (one-line descriptions)**
- Byte packing helpers `b0/b1/b2/b3/dw0..dw7`, `bitsOfSingle/bitsOfDouble`, `align`, `maximumMethodsPerDotNetType`.
- `getUncodedToken (tab) idx` = `(tab.Index <<< 24) ||| idx`; `markerForUnicodeBytes` (ECMA-335 II.24.2.4 trailing byte); `checkFixup32/applyFixup32` for `CodeChunk` deferred patching.
- Heap accessors: `GetUserStringHeapIdx`, `GetBytesAsBlobIdx`, `GetStringHeapIdx`, `GetGuidIdx`, `GetStringHeapIdxOption`.
- Row generation (the "Gen*" family): `GenTypeDefPass1/3/4`, `GetTypeDefAsRow`, `GetIdxForTypeDef`, `GetAssemblyRefAsRow`, `GetTypeRefAsTypeRefRow`, `getMethodRefInfoAsMemberRef...`, `GenMethodDefAsRow`, `GenMethodDefPass3/Pass4`, `GenMethodSpecInfoAsMethodSpecIdx`, `GetProperty/GenEventMethodSemanticsPass3`, `GenNestedExportedTypePass3`, `GenPdbImport/GenPdbImports`, `GenILMethodBody`, `GenFieldDefAsFieldDefRow`, `GenFieldSpecAsMemberRefRow`, `GenGenericParamAsGenericParamRow`, `GenParamAsParamRow`, `GenReturnAsParamRow/Pass3`, `GetMethodDefSigAsBytes`, `GetLocalSigAsStandAloneSigIdx`, `GetCallsigAsStandAloneSigRow`, `GetSecurityDeclRow`, `GetCustomAttrDataAsBlobIdx`, `GetResourceAsManifestResourceRow`, `GetNativeTypeAsBlobIdx` (native-type blob marshalling), `GetFieldInitAsBlobIdx`, `GetVariantTypeAsInt32`.
- Type encoding: `EmitTypeSpec`, `EmitArrayShape`, `EmitTypeInfoAsTypeDefOrRefEncoded`, `getTypeDefOrRefAsUncodedToken`, `hasthisToByte`, `callconvToByte`.
- Row utilities: `hashRow`, `equalRows`, `rowElemCompare`, `TableRequiresSorting`, `SortTableRows`.
- Metadata/PE writeup: `GenModule`, `generateIL` (builds the full code/data/resource chunk layout), `writeILMetadataAndCode` (writes the `.NET metadata` blob — the `#~` stream with heap, the code section, fixups, PDB), `writePdb`, `writeBinaryAux`, `writeBinaryFiles`, `writeBinaryInMemory`, and the public entry points `WriteILBinaryFile` / `WriteILBinaryInMemory`.

**Significant internal logic**
- Tables are built over `SharedRow`/`UnsharedRow` entries keyed by content hash + row contents; `FindOrAddSharedEntry`/`AddSharedEntry`/`AddUnsharedEntry` drive deduplication.
- The 4-pass `Gen*` scheme: Pass 1 creates/collects TypeDefs, Pass 2 fills the table rows (methods/fields/params/properties/events), Pass 3 fills TypeRows and their custom-attribute rows (including nested types and method spec rows), Pass 4 fills the remaining rows that depend on other tables.
- `cenv` is the single mutable state threaded through all `Gen*` calls to avoid re-creating table entries for identically-defined references.
- `ILTokenMappings` holds per-module cross-references (assembly refs, type refs, method refs, field refs, method-specs) keyed by content so that repeated references to the same entity produce the same row.
- `maximumMethodsPerDotNetType = 0xfff0` guards against the ECMA-335 `maximum methods per type` limit at `0x3FFFFFFF`-like row counts.
- `msdosHeader` is a literal `.NET PE DOS header` byte array embedded in the emitted file.
- `writeILMetadataAndCode` is the single big function that (a) builds the `#~` table heap (valid/sorted masks, row counts, row data using `RowElement`/coded-index tag constants from `BinaryConstants`), (b) arranges the IL code section in aligned 4-byte chunks, (c) applies the `CodeChunk` fixups (32-bit label and token patching), (d) lays out native resources, (e) builds the CLR header, and (f) optionally writes a PDB via `writePdb`.
- Strong-name signing: `options.signer` (from `ILStrongNameSigner`) is used for full / delay-signing; if only a public key is available the compiler emits a delay-signed assembly and prints guidance on `sn -Vr`.

**Cross-references**
- `ilwrite.fsi` (contract), `il.fs` (ILModuleDef, ILType, ILMethodDef, ILAttribute, ...), `BinaryConstants.fs` (TableName, RowElement tag constants, opcode constants), `ILPdbWriter.fs` (`writePdb`, `PdbModuleCustomDebugInfo`, `PdbMethodCustomDebugInfo`), `ilsupp.fsi` / `ilsign.fsi` / `ilnativeres.fsi` (platform-specific support, strong-name signer, native resources), `EncMethodDebugInformation.fs` (producer of the EnC CDI rows in `options`), `DeltaIndexSizing.fs` / `DeltaTableLayout.fs` / `DeltaMetadataEncoding.fs` (delta-owning mirrors of the same ECMA-335 table/coded-index machinery)

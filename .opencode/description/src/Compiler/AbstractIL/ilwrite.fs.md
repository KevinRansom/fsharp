# ilwrite.fs

## Pipeline role

The IL writer side of the AbstractIL layer. This module turns an `ILModuleDef` back into bytes: it generates the ECMA-335 metadata tables, heaps, code, and then serializes a complete classic PE file (MS-DOS header through CLI header, sections and import stubs). It is the counterpart to `ilread.fs`, coordinating a four-pass generation (`GenTypeDefsPass1..4`) over the type definitions, encoding method bodies in tiny/fat formats with SEH tables and branch fixups, emitting PDB support data, and finally laying out a 2/3-section PE image with embedded/external portable PDB debug-directory entries and strong-name signing.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.ILBinaryWriter` (module `internal`)
- Uses: `System`, `System.Collections.Generic`, `System.IO`, `Internal.Utilities` (`ReadOnlyByteMemory`), `FSharp.Compiler.Text`, `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.AbstractIL.Diagnostics`, `FSharp.Compiler.AbstractIL.BinaryConstants`, `FSharp.Compiler.AbstractIL.Support`, `FSharp.Compiler.AbstractIL.StrongNameSign` (`ILStrongNameSigner`), `FSharp.Compiler.AbstractIL.ILPdbWriter`, `Internal.Utilities.Library` (ByteBuffer), `FSharp.Compiler.DiagnosticsLogger` (`reportTime`, `errorR`, `InternalError`), `FSharp.Compiler.IO`, `FSharp.Compiler.Text.Range`.

## Byte-level helpers

- `b0..b3` — the four little-endian bytes of an `int32` (signature `int -> byte`).
- `dw0..dw7` — the eight little-endian bytes of an `int64`.
- `bitsOfSingle` / `bitsOfDouble` — reinterpret a float as its raw bit pattern.
- `[<Literal>] EmitBytesViaBufferCapacity = 10`.
- `emitBytesViaBuffer f` — `f` a `ByteBuffer`, returns its bytes.

## Ref-to-def resolution helpers

- `exception MethodDefNotFound`.
- `MethodDefIdxExists cenv mref` — true if the method ref points into a locally defined type and its `MethodDefKey` is in `methodDefIdxsByKey`.
- `FindMethodDefIdx cenv mdkey` — looks up the key, and on `KeyNotFoundException` prints diagnostics (enclosing type name, generic arity, near-miss methods) and re-raises.
- `TryGetMethodRefAsMethodDefIdx cenv mref` / `GetMethodRefAsMethodDefIdx` — local `ILMethodRef` to `MethodDef` index as `Result`/raising variants.
- `canGenMethodDef (tdef, cenv, mdef)` — reference-assembly filtering: always true normally; for attributes keeps `IsSpecialName` non-class-initializers; keeps public methods plus any `HideBySig`+static, virtual, abstract, newslot, final or entrypoint methods; internal methods kept only when `hasInternalsVisibleToAttrib`.
- `canGenFieldDef (tdef, cenv, fd)` — keeps struct/attribute fields always; otherwise public or internals-visible.
- `canGenEventDef cenv ev` / `canGenPropertyDef cenv prop` — keep the member only if at least one of its add/remove (resp. get/set) methods actually got a generated `MethodDef` (`MethodDefIdxExists`).

## Row builders and pass-2 table generation

Functions are mutually recursive in a large `let rec ... and ...` block:

- `GetTypeDefAsRow`/`GetTypeOptionAsTypeDefOrRef`/`GetTypeDefAsPropertyMapRow`/`GetTypeDefAsEventMapRow` — build TypeDef, PropertyMap and EventMap rows (Field/Method table start indexes are `Count + 1`).
- `GetKeyForFieldDef tidx fd` — `FieldDefKey (tidx, Name, FieldType)`.
- `GenFieldDefPass2` — add the field key if `canGenFieldDef`.
- `GetKeyForMethodDef cenv tidx mdef` — `MethodDefKey (ilg, tidx, gpCount, Name, Ret.Type, ParameterTypes, IsStatic)`.
- `GenMethodDefPass2` — registers the method and records `cenv.methodDefIdxs[mdef] <- idx` (by reference identity).
- `GetKeyForPropertyDef tidx x` — `PropKey (tidx, Name, PropertyType, Args)`.
- `GenPropertyDefPass2` / `GetKeyForEvent` / `GenEventDefPass2` — register non-dup property/event keys.
- `GetTypeAsImplementsRow`/`GenImplementsPass2` — InterfaceImpl rows.
- `GenTypeDefPass2 pidx enc cenv tdef` — writes the TypeDef row, Nested row, PropertyMap/EventMap rows, assigns InterfaceImpl indexes into `implementsIdxs`, and registers fields/methods/properties/events (`gens` ordered after methods because ref-assembly checks depend on generated MethodDefs). Recurse into nested types.
- `GenTypeDefsPass2` — iteration over the type list.

## Pass-3 metadata-index generators (refs, specs, sigs)

- `GetMethodDefIdx`/`FindFieldDefIdx`/`GetFieldDefAsFieldDefIdx` — index lookup incl. an `InternalError` diagnostic for a missing local field.
- `MethodRefInfoAsMemberRefRow`, `GetMethodRefInfoAsBlobIdx`, `GetMethodRefInfoAsMemberRefIdx` — MemberRef rows and their CallSig blobs (`GetCallsigAsBytes` from `ilsupp`).
- `GetMethodRefInfoAsMethodRefOrDef isAlwaysMethodDef` — picks `mdor_MethodDef` when the type is local and not varargs (falling back to `mdor_MemberRef` on `MethodDefNotFound`), else `mdor_MemberRef`.
- MethodSpec: `GetMethodSpecInfoAsMethodSpecIdx` (writes the GENERICINST blob), `GetMethodDefOrRefAsUncodedToken`, `GetMethodSpecInfoAsUncodedToken`/`GetMethodSpecAsUncodedToken`, `GetMethodRefInfoOfMethodSpecInfo`, `GetMethodSpecAsMethodDefOrRef`/`GetMethodSpecAsMethodDef`, `InfoOfMethodSpec`.
- Overrides: `GetOverridesSpecAsMemberRefIdx`, `GetOverridesSpecAsMethodDefOrRef`.
- Custom-attr method refs: `GetMethodRefAsMemberRefIdx`, `GetMethodRefAsCustomAttribType` (cat_MethodDef/cat_MemberRef).
- Custom attrs: `GetCustomAttrDataAsBlobIdx` (empty data writes index 0), `GetCustomAttrRow`, `GenCustomAttrPass3Or4`, `GenCustomAttrsPass3Or4`.
- Security decls: `GetSecurityDeclRow` (uses `ILSecurityActionMap`), `GenSecurityDeclPass3`, `GenSecurityDeclsPass3` → Permission table.
- FieldSpec: `GetFieldSpecAsMemberRefRow`, `GetFieldSpecAsMemberRefIdx`, `EmitFieldSpecSig`, `GetFieldSpecSigAsBytes`/`AsBlobIdx`, `GetFieldSpecAsFieldDefOrRef`, `GetFieldDefOrRefAsUncodedToken` (Field vs MemberRef).
- CallSigs: `GetCallsigAsBlobIdx`, `GetCallsigAsStandAloneSigRow`, `GetCallsigAsStandAloneSigIdx` → StandAloneSig.
- Locals: `EmitLocalSig`, `GetLocalSigAsBlobHeapIdx`, `GetLocalSigAsStandAloneSigIdx`.

## Code buffer and instruction emission

- `type ExceptionClauseKind = FinallyClause | FaultClause | TypeFilterClause of int32 | FilterClause of int` and `type ExceptionClauseSpec = int * int * int * int * ExceptionClauseKind` (tryStart, trySize, handlerStart, handlerSize, kind).
- `[<Literal>] CodeBufferCapacity = 200`.
- `CodeBuffer` (record, `IDisposable`) — `{ code; reqdBrFixups; availBrFixups; reqdStringFixupsInMethod; seh; seqpoints }`:
  - `Create` allocates buffers; `EmitExceptionClause` prepends to `seh`.
  - `EmitSeqPoint` records a `PdbDebugPoint` when `cenv.generatePdb` (document index 0-based).
  - `EmitByte/UInt16/Int32/Int64`/`EmitUncodedToken` forward to the backing `ByteBuffer`.
  - `RecordReqdStringFixup` writes a 0xdeadbeef placeholder, recorded at the code position.
  - `RecordReqdBrFixups` records instruction + position + targets and writes placeholders (0x11, switch count for `i_switch`, 0xdeadbbbb per 4-byte target); `RecordReqdBrFixup` single-target form.
  - `RecordAvailBrFixup` stores `label -> code position`.
- `module Codebuf`:
  - `binaryChop p (arr: 'T[])`.
  - `applyBrFixups origCode origExnClauses origReqdStringFixups origAvailBrFixups origReqdBrFixups origSeqPoints origScopes` — the two-phase branch narrowing: copies non-branching runs, decides short/long form per fixup (short only when the original-code relative offset fits in a signed byte, a safe approximation since code only shrinks), records `adjuster` map for every address, and rewrites the adjusted exception clauses, sequence-point offsets, scopes and string fixups, sanity-checking placeholders (0x98 small / 0xf00dd00f large).
  - `type SEHTree = Node of ExceptionClauseSpec option * SEHTree list`.
  - `encodingsForNoArgInstrs` built from `noArgInstrs.Force()`, with `encodingsOfNoArgInstr`.
  - Instruction emitters: `emitInstrCode` (two-byte prefix when > 0xFF), `emitTypeInstr`, `emitMethodSpecInfoInstr`, `emitMethodSpecInstr`, `emitFieldSpecInstr`, `emitShortUInt16Instr`, `emitShortInt32Instr`, `emitTailness`, `emitVolatility`, `emitConstrained`, `emitAlignment`.
  - `tryPrimitiveAsBasicType ilg ty` — maps primitive `ILType`s to `DT_*` element types.
  - `emitInstr cenv codebuf env instr` — the big instruction matcher: no-arg instructions, `I_brcmp`/`I_br` (with short-optional), `I_seqpoint`, `I_leave`, tail/volatile/constrained prefixes on the call family, `I_newobj`/`I_ldftn`/`I_ldvirtftn`, `I_calli` (StandAloneSig token), short arg/loc loads, `I_cpblk`/`I_initblk`, `AI_ldc` for I4 (short or long)/I8/R4/R8, `I_ldind`/`I_stelem`/`I_ldelem`/`I_stind` element-type tables, `I_switch`, field opcodes, `I_ldtoken` (Type/Method/Field coding), `I_ldstr` (string fixup), `I_box`/`I_unbox`/`I_unbox_any`, `I_newarr`/`I_stelem_any`/`I_ldelem_any`/`I_ldelema` (degrading multi-dimensional array ops to synthesized `Get`/`Set`/`Address` call instructions), `I_castclass`/`I_isinst`/`I_refanyval`/`I_mkrefany`/`I_initobj`/`I_ldobj`/`I_stobj`/`I_cpobj`/`I_sizeof`, `EI_ldlen_multi` (synthesized `GetLength` call); anything else `failwith`s.
  - `mkScopeNode`, `rangeInsideRange`, `lranges_of_clause`, `labelsToRange`, `labelRangeInsideLabelRange`, `findRoots` (tree reconstruction of nested SEH/local scopes), `makeSEHTree`, `makeLocalsTree`, `emitExceptionHandlerTree`, `emitCode` (emits instructions tracking `pc2pos`/labels, compresses `I_br` to the next instruction, builds the SEH tree emitting clauses inside-out, unshadows local scopes).
  - `EmitMethodCode cenv importScope localSigs env nm code` — runs `emitCode`, applies fixups, produces `(stringFixups, exnClauses, code, seqPoints, rootScope)`.

## Method bodies

- `GetFieldDefTypeAsBlobIdx` — FIELD callconv-sig blob (used for local-sig entries referenced by the PDB).
- `GenPdbImport` / `GenPdbImports` — map `ILDebugImport`/`ILDebugImports` to `PdbImport`/`PdbImports` with a `cenv.pdbImports` memo cache.
- `GenILMethodBody mname cenv env il`:
  - When generating a PDB, writes a fake StandAloneSig per local (FIELD-coded) and builds `localSigs`.
  - Chooses **Tiny format** when `Locals` empty, `MaxStack <= 8`, no SEH and `codeSize < 64` (1-byte header `codeSize <<< 2 ||| e_CorILMethod_TinyFormat`, string fixups rooted at +1).
  - Otherwise **Fat format**: flags (MoreSects/InitLocals), fixed 0x30 header byte, MaxStack, code size, local token; then a small or fat (24-byte) exception-handling clause table when SEH exists.
  - Returns `(localToken, (headerOffset, stringFixups), code, seqpoints, scopes)`.
- `ilMethodBodyThrowNull` — a prebuilt `ldnull; throw` body substituted for real bodies when emitting reference assemblies.

## Field/param/generic/member row generation (pass 3/4)

- `GetFieldDefAsFieldDefRow`/`GetFieldDefSigAsBlobIdx`/`GenFieldDefPass3` — Field row, custom attrs, and optional FieldRVA (into `cenv.data`), FieldMarshal, Constant, FieldLayout rows.
- Generic params: `GetGenericParamAsGenericParamRow` (flags from variance/constraints; ECMA v1 adds a deprecated empty TypeDefOrRefOrSpec column when `mdVersionMajor = 1`), `GenTypeAsGenericParamConstraintRow`, `GenGenericParamConstraintPass4`, `GenGenericParamPass3` (collect), `GenGenericParamPass4` (attrs + constraints).
- Params/returns: `GetParamAsParamRow` (flags In/Out/Optional/HasDefault/HasFieldMarshal), `GenParamPass3`, `GenReturnAsParamRow`, `GenReturnPass3`.
- Methods: `GetMethodDefSigAsBytes`/`GenMethodDefSigAsBlobIdx`, `GenMethodDefAsRow` (records the entrypoint into `cenv.entrypoint`, emits the body code, adds the PDB method record `MethToken`/`RootScope`/`DebugRange`/`DebugPoints`, computes the code address for the RVA; `MethodBody.Native` fails), `GenMethodImplPass3`, `GenMethodDefPass3` (return, params, attrs, security decls, generic params, and PInvoke `ImplMap` flags from calling convention/char encoding/char best-fit/throw-on-unmappable/no-mangle/last-error), `GenMethodDefPass4`.
- Properties: `GenPropertyMethodSemanticsPass3`, `GetPropertySigAsBlobIdx`/`GetPropertySigAsBytes`, `GetPropertyAsPropertyRow`, `GenPropertyPass3` (Property row + MethodSemantics 0x0001 setter/0x0002 getter + Constant + attrs).
- Events: `GenEventMethodSemanticsPass3` (kinds 0x0008 add/0x0010 remove/0x0020 fire/0x0004 other), `GenEventAsEventRow`, `GenEventPass3`.

## Resources, module generation, exports, manifest

- `GetResourceAsManifestResourceRow`/`GenResourcePass3` — ManifestResource rows; embedded locals are 8-byte aligned in `cenv.resources` with a 4-byte length prefix (`Data(alignedOffset, true)`); `File` and `Assembly` locations become Implementation entries.
- `GenTypeDefPass3`/`GenTypeDefsPass3` — interface-impl attrs, properties, events, fields, methods, method impls, optional ClassLayout, security decls, custom attrs, generic params; and `GenTypeDefPass4`/`GenTypeDefsPass4` — method + type generic params (GenericParam table must be sorted by owner before pass 4).
- `timestamp = absilWriteGetTimeStamp ()`.
- Exported types: `GenNestedExportedTypePass3`, `GenNestedExportedTypesPass3`, `GenExportedTypePass3` (uses `GetScopeRefAsImplementationElem`), `GenExportedTypesPass3`.
- Manifest: `GetManifestAsAssemblyRow` (assembly longevity flags, retargetable, public key), `GenManifestPass3` (Assembly row, security decls, attrs, exported types, `EntrypointElsewhere` into `cenv.entrypoint`), `newGuid`/`deterministicGuid` (MVID synthesis, `0xa7 0x45 0x03 0x83 ...` tail), `GetModuleAsRow` (stores `cenv.moduleGuid`).
- `rowElemCompare`/`TableRequiresSorting`/`SortTableRows` — stable row sort using `sortedTableInfo`.
- `GenModule cenv modul` — the orchestrator: Module row, resources, `destTypeDefsWithGlobalFunctionsFirst`, then Pass 1/2/3, module custom attrs, sorts the GenericParam table, Pass 4, each step wrapped in `reportTime`.

## Generation constants and `generateIL`

- `[<Literal>] CodeChunkCapacity = 40000`, `DataCapacity = 200`, `ResourceCapacity = 200`.
- `generateIL (requiredDataFixups, desiredMetadataVersion, generatePdb, ilg, emitTailcalls, deterministic, referenceAssemblyOnly, referenceAssemblyAttribOpt, allGivenSources, m, cilStartAddress, normalizeAssemblyRefs)`:
  - Computes `hasInternalsVisibleToAttrib`; optionally prepends the `ReferenceAssemblyAttribute` when emitting a reference assembly.
  - Builds a 64-entry table array (shared `MetadataTable<SharedRow>` for AssemblyRef/MemberRef/ModuleRef/File/TypeRef/TypeSpec/MethodSpec/StandAloneSig/GenericParam, unshared otherwise).
  - Constructs the `cenv` record (string/US/GUID/blob heaps as `MetadataTable`s, `documents`, `pdbinfo`, `methodDefIdxs` by reference, `implementsIdxs` structurally, code/data/resources buffers, `%entrypoint`).
  - Runs `GenModule`, emits debug documents, computes the entry-point token (0 for DLLs), builds `pdbData`, and returns `(strings, userStrings, blobs, guids, tables, entryPointToken, code, requiredStringFixups, data, resources, pdbData, mappings)`.
  - `mappings` — token-map record with `TypeDefTokenMap`, `FieldDefTokenMap`, `MethodDefTokenMap`, `PropertyTokenMap`, `EventTokenMap` (each `getUncodedToken` based).

## Tables+blobs to physical metadata

- `chunk sz next`/`emptychunk next`/`nochunk next` — chunk-address allocator; `count f arr`.
- `module FileSystemUtilities` — `progress` from the `FSharp_DebugSetFilePermissions` environment variable.
- `[<Literal>] TableCapacity = 20000`, `MetadataCapacity = 500000`.
- `writeILMetadataAndCode (...)`: calls `generateIL`, lays out code (4-aligned), the 0x10 metadata header, the `v4.x.x` version string, five stream headers (`#~`, `#Strings`, `#US`, `#GUID`, `#Blob`), computes heap "bigness" (> 0xFFFF), the `valid`/`sorted` 64-bit bitvectors (`sorted1 = 0x3301fa00`; `sorted2` marks GenericParam/GenericParamConstraint when present), string/blob/user-string address tables, sorts tables, then in `codedTables`: for each table column it picks the correct coded-index width via `codedBigness` (tdor/tomd/hc/hca-5bit/hfm/hds/mrp-3bit/hs/mdor/mf/i-2bit/cat/rs), emitting UShort/ULong/Data/DataResources/Guid/Blob/String/SimpleIndex/tagged values into `tablesBuf` (FieldRVA data references recorded into `requiredDataFixups`).
- Assembles the metadata byte array: magic `0x424a5342` "BSJB", 1.1 version, `#~`/`#Strings`/`#US`/`#GUID`/`#Blob` streams (each with a leading 0x00 terminator and 4-byte padding), user strings with `markerForUnicodeBytes`, GUID stream, blob stream; returns `(entryPointToken, code, codePadding, metadata, data, resources, requiredDataFixups, pdbData, mappings, guidStart)`.
- Fixups: applies `requiredStringFixups` into the code (`0xdeadbeef` placeholder, must be at an `i_ldstr`), and later (`dataRva` patching done in the PE writer) the data-section references.

## PE writer

- `msdosHeader : byte[]` — the standard 0x80-byte MS-DOS stub (MZ header + "This program cannot be run in DOS mode").
- `writeInt64`/`writeInt32`/`writeInt32AsUInt16`/`writeDirectory`/`writeBytes` — little-endian `BinaryWriter` helpers.
- `writePdb (...)` — post-PE PDB fixups: optional `logDebugInfo` dump; collects `IMAGE_DEBUG_DIRECTORY` entries (`idd`) from `pdbInfoOpt` (returned by `generatePortablePdb`), including embedded-PDB (compressed) and portable-PDB code paths and `pdbBytes` capture for the in-memory case; rewrites the binary's debug directory (Characteristics, Timestamp, versions, Type, SizeOfData, `AddressOfRawData` via `textV2P`) and raw debug data, then applies strong-name signing (with an error message on `SignFile` failure) and deletes the output file on failure.
- `type options` (record) — the writer configuration: `ilg`, `outfile`, `pdbfile`, `portablePDB`, `embeddedPDB`, `embedAllSource`, `embedSourceList`, `allGivenSources`, `sourceLink`, `checksumAlgorithm`, `signer`, `emitTailcalls`, `deterministic`, `dumpDebugInfo`, `referenceAssemblyOnly`, `referenceAssemblyAttribOpt`, `referenceAssemblySignatureHash`, `pathMap`, `moduleCustomDebugInfoRows` (hot-reload baseline side channel), `methodCustomDebugInfoRows` (per-method EnC CDI).
- `writeBinaryAux (stream, options, modul, normalizeAssemblyRefs)` — builds the whole PE in-memory:
  - Strong-name handling: uses the provided signer, else delay-signs from the manifest public key (`ILStrongNameSigner.OpenPublicKey`).
  - Section/geometry computation: `.mvid` (only when `referenceAssemblyAttribOpt.IsSome`), `.text`, `.rsrc`, `.reloc` (entrypoint stub absent on ARM/ARM64); chunks for MS-DOS header, PE signature, file/optional header, section headers; IAT, CLI header (0x48 bytes, aligned to 16 on Itanium), then `writeILMetadataAndCode` gets `cilStartAddress`.
  - Further `.text` layout: code, metadata, strong-name signature space, resources, raw data, import table (`_CorExeMain`/`_CorDllMain` name-hint stub + entrypoint code `0xFF 0x25 rel32`), debug directory/data/checksum/embedded-PDB/deterministic chunks; `.rsrc` with native resources linked via `linkNativeResources`; `.reloc` base-reloc table with the entrypoint fixup block (DIR64/HIGHLOW) and Itanium global-pointer relocation.
  - `desiredMetadataVersion` derived from `modul.MetadataVersion` or the primary assembly reference version (mapping 2.0 to "2.0.50727.0").
  - Deterministic build: hashes the code, data and metadata into `deterministicId`, validates the sentinel GUID bytes `[4uy;3uy;2uy;1uy]` at `guidStart`, overwrites the MVID, writes a high-bit-set timestamp, and updates `pdbData`.
  - Writes PE file/directories: `0x4550` signature, machine type, `numSections`, time-date stamp, optional header (0x10b/0x20b magic, `peOptionalHeaderByteByCLRVersion`, section sizes, entry point, image base, alignments, subsystem, DLL characteristics incl. high-entropy VA, stack/heap reserve+commit, 16 data directories incl. import table, CLI header, debug directory, relocation table), section headers for `.mvid`/`.text`/`.rsrc`/`.reloc`, and all section bytes with padding.
  - Applies `requiredDataFixups` (checks `0xdeaddddd`, computes the final RVA from `rawdataChunk.addr` or the resource offset).
- `writeBinaryFiles (options, modul, normalizeAssemblyRefs)` — opens output via `FileSystem` shims, runs `writeBinaryAux`, deletes output on failure, reopens for `writePdb`, ignores the returned PDB bytes; returns `mappings`.
- `writeBinaryInMemory (options, modul, normalizeAssemblyRefs)` — same to a `MemoryStream`, forcing `referenceAssemblyOnly = false`, returning `(bytes, pdbBytes)`.
- Entry points: `WriteILBinaryFile (options, inputModule, normalizeAssemblyRefs)` and `WriteILBinaryInMemory (options, inputModule, normalizeAssemblyRefs)`.

## Significant internal logic

- Four-pass generation: pass 1 assigns type-def indexes (`GetIdxForTypeDef`), pass 2 emits TypeDef/Nested/map rows and registers field/method/property/event keys (methods before properties/events so ref-assembly existence checks work), pass 3 emits the bulk rows (methods, fields, param, property/event + MethodSemantics, generic params, resources, manifest), pass 4 re-emits generic-param rows (with constraints/attrs) after the GenericParam table has been sorted by owner.
- Code is emitted once, then `applyBrFixups` iteratively narrows branches to their short forms based on original-code offsets (safe because code only shrinks), adjusting exception clauses, scopes, sequence points and string fixups with a per-run `adjuster`.
- Ref-assembly emission (`referenceAssemblyOnly`) suppresses bodies (replaced by `ldnull; throw`), filters members via `canGen*`, and injects the `ReferenceAssemblyAttribute`.
- Deterministic output: deterministic MVID/timestamp from code+data+metadata hashes, and the PDB content id; the `.mvid` section stores the deterministic GUID when emitting reference assemblies.
- The PE is always written as a managed IL-only image with a classic RVA 0x2000/0x200 alignment layout, delimited import table organized per-platform (Itanium differs in alignment and global-pointer reloc), and the CLI header flags encode IL-only/32-bit/preferred32/strong-name bits.
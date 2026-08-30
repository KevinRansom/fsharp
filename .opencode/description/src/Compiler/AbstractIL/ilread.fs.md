# ilread.fs

## Pipeline role

Part of the AbstractIL layer. This module is "the big binary reader": it parses .NET PE binaries (MS-DOS/PE/CLI headers plus the ECMA-335 metadata tables and heaps) directly from raw bytes and reconstructs the Abstract IL AST (`ILModuleDef`, `ILTypeDef`, `ILMember*`, method bodies including exception clauses and sequence points) as lazy, cached, seek-based structures. It is the workhorse used by fsc, fsi, FSharp.Compiler.Service and the IDE to load referenced assemblies and existing IL. Reading is deliberately defensive and low-allocation: binary reads happen by absolute offset (RVAs mapped to physical locations via section headers), sorted tables are searched by binary chop, and virtually everything is wrapped in `InterruptibleLazy`/memoized caches so unneeded parts of an assembly are never materialized. The public surface is `OpenILModuleReader` (+ `FromBytes`/`FromStream`) returning an `ILModuleReader`.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.ILBinaryReader` (public); plus an `[<AutoOpen>] module Shim` at the end.
- Uses: `System`, `System.Collections.Concurrent`, `System.Collections.Generic`, `System.Diagnostics`, `System.IO`, `System.Text`, `Internal.Utilities.Collections`, `Internal.Utilities.Library` (`Tables.memoize`, `AgedLookup`, `Lock`, `Zmap`-adjacent helpers), `FSharp.Compiler.AbstractIL.Diagnostics`, `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.AbstractIL.BinaryConstants` (table indices, element-type/call-conv constants, `TableNames`), `FSharp.Compiler.AbstractIL.Support` (e.g. `unlinkResource`, `ILSecurityActionRevMap`, `ILVariantTypeRevMap`, `ILNativeTypeMap`), `FSharp.Compiler.DiagnosticsLogger`, `FSharp.Compiler.IO` (`FileSystem`, `ByteMemory`), `FSharp.Compiler.Text.Range`, `System.Reflection`, `System.Reflection.PortableExecutable` (`PEReader`), `FSharp.NativeInterop`.

## Environment switches

- `checking = false`, `logging = false` (debug-only).
- `noStableFileHeuristic` (`FSharp_NoStableFileHeuristic` env var), `alwaysMemoryMapFSC` (`FSharp_AlwaysMemoryMapCommandLineCompiler`), `stronglyHeldReaderCacheSize` (default 30, overridable via `FSharp_StronglyHeldBinaryReaderCacheSize`).
- `singleOfBits`/`doubleOfBits` — bit-pattern re-interpretation helpers.

## Primitive readers / token helpers

- `align alignment n`, `i32ToUncodedToken tok` -> `(TableName, rid)`.
- `TaggedIndex<'T>` (`[<Struct>]`) — a `(tag, index)` pair; active pattern `(|TaggedIndex|)`; `tokToTaggedIdx f nbits tok` decodes an inline table index (1..5 bits) into `TaggedIndex(f tag, idx)`.
- `uncodedTokenToTypeDefOrRefOrSpec` / `uncodedTokenToMethodDefOrRef` — map a token to the coded-index tag DU.
- `Statistics` record + `stats` + `GetStatistics()` — counters for raw/mmap/weak/byte files.
- `BinaryView = ReadOnlyByteMemory`.

## Binary file access types

- `BinaryFile` (interface) — `abstract GetView: unit -> BinaryView`.
- `RawMemoryFile(fileName, obj, addr, length)` / `(fileName, holder, bmem)` — a view over a raw memory chunk owned by an `obj` (e.g. Roslyn metadata snapshots in VS); keeps the holder alive.
- `ByteMemoryFile(fileName, view)` — view over any `ByteMemory`.
- `ByteFile(fileName, bytes)` (`[<DebuggerDisplay>]`) — a strongly-held `byte[]`.
- `PEFile(fileName, peReader)` — backed by a `System.Reflection.PortableExecutable.PEReader`; caches a weak `ByteMemory` over `GetEntireImage()`, disposes the `PEReader` in the finalizer (weak self-reference avoids a GC cycle).
- `WeakByteFile(fileName, chunk)` (`[<DebuggerDisplay>]`) — weakly holds the bytes and re-reads from the backing file on demand, checking `GetLastWriteTimeShim` against the stamp at construction (raises `FSComp.SR.ilreadFileChanged` if the file changed). Default for "stable" binaries in FCS; not used by VS.
- Seek primitives over a view: `seekReadByte/Bytes/Int32/UInt16/Int64/Single/Double/SByte`, `seekReadByteAsInt32`, `seekReadUInt16AsInt32`, `seekReadCompressedUInt32` (ECMA compressed integers), `seekCountUtf8String`, `seekReadUTF8String`, `seekReadBlob`, `seekReadUserString`, `seekReadUncodedToken`.

## Signature-pointer primitives (no cursor, by `byte[]` + index)

- `sigptrGetByte/Bool/SByte/UInt16/Int16/Int32/UInt32/UInt64/Int64/Single/Double/ZInt32`, folding helpers `sigptrFold`/`sigptrFoldStruct`/`sigptrFoldAcc`, `sigptrGetBytes`, `sigptrGetString`. `sigptrCheck` enforces bounds when `checking`.

## Instruction decode tables

- `ILInstrPrefixesRegister` (`[<NoEquality; NoComparison>]`) — mutable accumulating prefixes `{ al; tl; vol; ro; constrained }`.
- Prefix-validity wrappers `noPrefixes`, `volatileOrUnalignedPrefix`, `volatilePrefix`, `tailPrefix`, `constraintOrTailPrefix`, `readonlyPrefix` — each `failwith` if a prefix that is illegal for the instruction is present.
- `ILInstrDecoder` (DU) — one case per operand shape (u16/u8, i64, i32, r4/r8, field, method, labels, string, switch, token, sig, type, invalid), each a function `ILInstrPrefixesRegister -> ... -> ILInstr`.
- `mkStind`/`mkLdind` builders; `instrs ()` — the opcode -> decoder association list (branches -> `I_brcmp`, constrained call -> `I_callconstraint`, `calli` -> tail, `ldelema`/arrays -> readonly, etc.). Array pseudo-methods are NOT decoded into `I_ldelem_any` here (the reader converts array `Get`/`Set`/`Address`/`.ctor` calls in `seekReadTopCode`).
- `oneByteInstrs`/`twoByteInstrs` — lazy (`fillInstrs`) 256-entry tables so startup doesn't build them; a leading `0xfe` selects the two-byte table; `getOneByteInstr`/`getTwoByteInstr`.

## Table-row schema and search infrastructure

- `RowElementKind` (DU: scalars, heap indexes, and all coded-index kinds) and `RowKind = RowKind of RowElementKind list`; `kind*` constants give the exact per-table layout (Module, TypeRef, TypeDef, Field, Method, Param, InterfaceImpl, MemberRef, Constant, CustomAttribute, FieldMarshal, DeclSecurity, ClassLayout, FieldLayout, StandAloneSig, Event[Map], Property[Map], MethodSemantics, MethodImpl, ModuleRef, TypeSpec, ImplMap, FieldRVA, Assembly, AssemblyRef, FileRef, ExportedType, ManifestResource, Nested, GenericParam, MethodSpec, GenericParamConstraint).
- Sorted-table key comparers: `hcCompare`, `hsCompare`, `hcaCompare`, `mfCompare`, `hdsCompare`, `hfmCompare`, `tomdCompare`, `simpleIndexCompare`.
- Cache keys (`[<Struct>]` DUs): `TypeDefAsTypIdx`, `TypeRefAsTypIdx`, `BlobAsMethodSigIdx`, `BlobAsFieldSigIdx`, `BlobAsPropSigIdx`, `BlobAsLocalSigIdx`, `MemberRefAsMspecIdx`, `MethodSpecAsMspecIdx`, `MemberRefAsFspecIdx`, `CustomAttrIdx`, `GenericParamsIdx`.
- `mkCacheGeneric lowMem ...` — returns `id` under `lowMem` (or `reduceMemoryUsage`), else a lazily-initialized `ConcurrentDictionary<_, _>` with a `STATISTICS` hit counter.
- `seekReadIndexedRows (numRows, rowReader, keyFunc, keyComparer, binaryChop, rowConverter)` — binary-chop if the table is sorted, else linear scan; a `CHECKING` build cross-checks binary vs linear results.
- `seekReadOptionalIndexedRow` / `seekReadIndexedRow` (+ "multiple rows found" warning).
- `ISeekReadIndexedRowReader<'RowT,'KeyT,'T>` (interface, `'RowT: struct`, byref-based) and `seekReadIndexedRowsRange`/`seekReadIndexedRowsByInterface` — byref/struct variant (used for CustomAttribute lookup and `seekReadRowRangeForTypeDef` map rows).

## Reader data structures

- `MethodData = MethodData of enclTy: ILType * ILCallingConv * name * argTys * retTy * methInst` and `VarArgMethodData` (adds `ILVarArgs`).
- `PEReader` (`[<NoEquality; NoComparison; RequireQualifiedAccess>]`, record) — the PE context: `fileName`, `entryPointToken`, `pefile`, text/data segment physical loc/size, `anyV2P: string * int32 -> int32`, `metadataAddr`, `sectionHeaders`, native-resources/managed-resources/strongname/vtable-fixups addresses, `noFileOnDisk`.
- `ILMetadataReader` (record) — the giant reader context: `sorted` bitmap, `mdfile`, optional `pectxtCaptured` (only when reading full PE incl. code for static linking), `entryPointToken`, `dataEndPoints`, heap physical locations, `getNumRows`, cached heap readers (`readUserStringHeap`, `readStringHeap` (+`memoizeString`), `readBlobHeap`), `rowAddr`, the bigness flags (`tableBigness`, `rsBigness`, `tdorBigness`, `tomdBigness`, `hcBigness`, `hcaBigness`, `hfmBigness`, `hdsBigness`, `mrpBigness`, `hsBigness`, `mdorBigness`, `mfBigness`, `iBigness`, `catBigness`, strings/guids/blobs bigness), cached row readers, and the per-table custom-attr/security-decl reader functions.

## Row and heap readers

- Advancing readers: `seekReadUInt16Adv`, `seekReadInt32Adv`, `seekReadUInt16AsInt32Adv`, `seekReadIdx`, `seekReadTaggedIdx`, and the coded-index readers `seekReadResolutionScopeIdx`, `seekReadTypeDefOrRefOrSpecIdx`, `seekReadTypeOrMethodDefIdx`, `seekReadHasConstantIdx`, `seekReadHasCustomAttributeIdx`, `seekReadHasFieldMarshalIdx`, `seekReadHasDeclSecurityIdx`, `seekReadMemberRefParentIdx`, `seekReadHasSemanticsIdx`, `seekReadMethodDefOrRefIdx`, `seekReadMemberForwardedIdx`, `seekReadImplementationIdx`, `seekReadCustomAttributeTypeIdx`, `seekReadStringIdx`, `seekReadGuidIdx`, `seekReadBlobIdx`, plus `seekReadUntaggedIdx`.
- Per-row readers `seekRead*Row` for every table (Module, TypeRef, TypeDef, Field, Method, Param, InterfaceImpl, MemberRef, Constant, CustomAttribute, FieldMarshal, Permission, ClassLayout, FieldLayout, StandAloneSig, EventMap/Event, PropertyMap/Property, MethodSemantics, MethodImpl, ModuleRef, TypeSpec, ImplMap, FieldRVA, Assembly, AssemblyRef, File, ExportedType, ManifestResource, Nested, GenericParam, GenericParamConstraint, MethodSpec). Cached wrappers follow the `seekReadXRow = ctxt.seekReadXRow` / `seekReadXRowUncached ctxtH` pattern using an initialization hole (`getHole ctxtH`).
- Heap readers: `readUserStringHeapUncached` (Unicode), `readStringHeapUncached` (UTF-8 NUL-terminated), `readBlobHeapUncached` (bounds-checked against `blobsStreamSize`, empty for index 0), and typed blob readers `readBlobHeapAsBool/SByte/Int16/Int32/Int64/Byte/UInt16/UInt32/UInt64/Single/Double`.

## Data-extent logic (rvaToData)

- Long comment block documents the heuristic for raw data embedded in the text section (mscorlib-style field inits): metadata is never double-used; data runs from a Field/Resource RVA to the next boundary, method RVA, metadata start, section end, or native resources.
- `readNativeResources pectxt` — yields `ILNativeResource.In/F.Out` (unlinking when the PE was read from bytes, `noFileOnDisk`).
- `getDataEndPointsDelayed pectxt ctxtH` (`InterruptibleLazy`) — collects FieldRVA + in-assembly ManifestResource start points plus method RVAs and section/CLI boundaries, then sorts/distincts.
- `rvaToData ctxt pectxt nm rva` — reads the bytes from `anyV2P rva` up to the first end point.

## AST reconstruction (large mutually-recursive `seekRead*` group)

- `seekReadModule ctxt canReduceMemory pectxtEager pevEager peinfo ilMetadataVersion idx` — root: reads the Module row, native resources, assembly manifest (if any), module custom-attr reader, type defs (`mkILTypeDefsGroupedComputed`), sub-system/platform/alignment/header `peinfo` fields, and manifest resources. Note: eager contexts are not captured by lazily-computed results.
- `seekReadAssemblyManifest`, `seekReadAssemblyRef (+Uncached)`, `seekReadModuleRef`, `seekReadFile`, `seekReadClassLayout`.
- Flag decoders: `typeAccessOfFlags`, `typeLayoutOfFlags` (Sequential/Explicit pull ClassLayout), `isTopTypeDef`.
- `typeDefReader ctxtH` — the big `ILTypeDefStored` provider: recomputes the TypeDef row, determines "kind" from the extends token (interface flag, `typeKindByNames` for delegation-style names, extra name reads for TypeDef/TypeRef parents), computes `ILTypeDefAdditionalFlags` incl. `CanContainExtensionMethods` by searching the type's CustomAttribute rows for `System.Runtime.CompilerServices.ExtensionAttribute` (both `cat_MethodDef` and `cat_MemberRef` forms), builds super type/layout/nested/methods/fields/interfaces/method-impls/properties/events, and registers the type custom-attr reader.
- `seekReadTopTypeDefEntries` — yields pre-type-defs grouped by split namespace (names left to the pre-type-def so un-imported namespaces cost nothing); `seekReadNestedTypeDefs` (Nested-table indexed rows; nested types carry no namespace).
- `seekReadInterfaceImpls`, `seekReadGenericParams (+Uncached)` (variance/constraint flags incl. `HasAllowsRefStruct` 0x0020), `seekReadGenericParamConstraints`.
- Type readers: `seekReadTypeDefAsType (+Uncached)`, `seekReadTypeDefAsTypeRef` (walks enclosing chain via the Nested table), `seekReadTypeRef (+Uncached)`, `seekReadTypeRefAsType (+Uncached)`, `seekReadTypeDefOrRef` (TypeDef/TypeRef/TypeSpec dispatch), `seekReadTypeDefOrRefAsTypeRef`, `seekReadMethodRefParent` (TypeRef/ModuleRef/MethodDef/TypeSpec), `seekReadMethodDefOrRef (+NoVarargs)`, `seekReadCustomAttrType`, `seekReadImplAsScopeRef`, `seekReadTypeRefScope`, `seekReadOptionalTypeDefOrRef`, `seekReadSuperType`.
- Signature decoding: `sigptrGetTypeDefOrRefOrSpecIdx`; `sigptrGetTy` — the full ELEMENT_TYPE decoder (primitive types via `PrimaryAssemblyILGlobals`, `WITH` generic instantiation, `CLASS`/`VALUETYPE`, `VAR`/`MVAR` with `numTypars` offset, `BYREF`/`PTR`/`SZARRAY`/`ARRAY` with shape/rank/lobounds, `CMOD_REQD/OPT` -> `ILType.Modified`, `FNPTR` calling-sig, `TYPEDBYREF`, `SENTINEL`); `sigptrGetVarArgTys`, `sigptrGetArgTys` (handles the vararg sentinel), `sigptrGetLocal` (`PINNED`); `readBlobHeapAsMethodSig (+Uncached)` (returns `generic, genarity, cc, retTy, argTys, varargs`), `readBlobHeapAsType`, `readBlobHeapAsFieldSig (+Uncached)`, `readBlobHeapAsPropertySig (+Uncached)`, `readBlobHeapAsLocalsSig (+Uncached)`, `byteAsHasThis`, `byteAsCallConv`.
- Member refs/specs: `seekReadMemberRefAsMethodData (+Uncached)` (parent type arg count feeds the sig read), `seekReadMemberRefAsMethDataNoVarArgs`, `seekReadMethodSpecAsMethodData (+Uncached)` (GC`GENCINST` blob), `seekReadMemberRefAsFieldSpec (+Uncached)`.
- `seekReadMethodDefAsMethodData (+Uncached)` — comments explain the "extremely annoying" aspect: given a method token, binary-chop the TypeDef table (`seekMethodDefParent`) to find its owning type, then build formal generic instantiations for the enclosing type and the method.
- `seekReadFieldDefAsFieldSpec (+Uncached)` — same technique over field ranges.
- `seekReadMethod` — reads flags/impl-flags/code RVA, builds the `MethodBody` (`Native` for codetype 1 + PInvoke flag, PInvoke via `seekReadImplMap`, `Abstract` for internalcall/abstract/unmanaged/other codetypes, RVA-read IL body when `pectxtCaptured` is set, else `NotAvailable` = metadata only), params via `seekReadParams`/`seekReadParamExtras` (marshal, default via Constant, in/out/optional, custom attrs, return attrs for `seq = 0`), entry point detection.
- `seekReadMethodImpls` + `seekReadRowRangeForTypeDef` (map/impl tables keyed by TypeDef in first column — types with no rows share the empty table), `seekReadMultipleMethodSemantics`/`OptionalMethodSemantics`/`MethodSemantics` (event/property accessors by flags 0x0001/2/4/8/0x10/0x20).
- `seekReadEvent(s)`, `seekReadProperty` (with the "ThisConv on the property is not reliable — take it from the getter/setter" note), `seekReadProperties` — PropertyMap/EventMap-relative ranges.

## Custom attributes, security declarations, constants, P/Invoke

- `customAttrsReaderFn ctxtH tag` — byref/struct indexed scan of the CustomAttribute table by parent (`hcaCompare`), converted via `seekReadCustomAttr (+Uncached)` = `ILAttribute.Encoded(method, data, elements=[])`.
- `securityDeclsReader ctxtH tag`/`seekReadSecurityDecl` — Permission table rows mapped through `ILSecurityActionRevMap`.
- `seekReadConstant` — Constant table keyed by `HasConstant` parent; decodes each element type into `ILFieldInit.*` (string via the Blob heap as Unicode; `CLASS`/`OBJECT` -> `Null`).
- `seekReadImplMap` — PInvoke metadata: calling convention/char-encoding/char-best-fit/throw-on-unmappable/NoMangle/LastError/name/`Where` module ref.

## Method-body and code reading

- `seekReadTopCode ctxt pev mdv numTypars sz start` — reads a linear bytecode stream into AbsIL: builds raw-offset -> label and label -> IL index maps, tracks sequence points, decodes prefixes (`unaligned.`/`volatile.`/`readonly.`/`constrained.`/`tail.`) into the register, dispatches through the one/two-byte opcode tables, reads operands (short/long branches resolved relative to the next instruction, switch targets, tokens for fields/methods/types/strings/standalone sigs), rewrites array pseudo-method calls into the generalized instructions (`Get`->`I_ldelem_any`, `Set`->`I_stelem_any`, `Address`->`I_ldelema`, `.ctor`->`I_newarr`), and returns `(instrs, rawToLabel, lab2pc)`.
- `seekReadMethodRVA pectxt ctxt (nm, noinline, aggressiveinline, numTypars) rva` — reads a fat/tiny method header, locals token (StandAloneSig), code via `seekReadTopCode`, and (fat only) the EH sections: fat and tiny clause formats, each with a documented WORKAROUND that the clause count is `size / 24` (or `/12`) rather than `(size - 4) / 24` because CCI/the C# compiler emit multiples of the size; clauses sharing a range are merged in a dictionary (`sehMap`) and output as `ILExceptionSpec { Range; Clause }` (TypeCatch/FilterCatch/Finally/Fault).
- `int32AsILVariantType` and `sigptrGetILNativeType` — native-type blobs: fixed sys string, fixed array, safearray, custom marshaller (guid/names/cookie), and arrays with optional element type/param count/additive.
- `seekReadManifestResources` — local/in-module/in-assembly resource locations using `ByteStorage` (respecting `canReduceMemory`), eager reads only.
- `seekReadNestedExportedTypes` / `seekReadTopExportedTypes` — ExportedType rows with their nested children grouped by parent.

## PE + metadata opening

- `openMetadataReader (fileName, mdfile, metadataPhysLoc, peinfo, pectxtEager, pevEager, pectxtCaptured, reduceMemoryUsage)` — the heart: validates the BSJB magic, reads the version string, locates streams (`#~` (falling back to `#-` and then the first stream), `#Strings`, `#US`, `#GUID`, `#Blob`), defines the 64-entry `tableKinds`, reads heap-size/valid/sorted bitmaps and row counts, computes all bigness flags (per-table and per-coded-index, via the `>= 0x10000 >> nbits` test), row sizes, physical table locations, `rowAddr`, all the caches, builds the `ctxt` record (using an init hole `ctxtH = ref None` so uncached functions can reference the context), reads the module, and returns `(ilModule, ilAssemblyRefs)` (refs lazy).
- `openPEFileReader (fileName, pefile, noFileOnDisk)` — cracks headers: MS-DOS `e_lfanew` at 0x3c, PE signature `0x4550`, machine/platform, optional header size (0xe0 x86 / 0xf0 x64), DLL flag, section headers (`(virtAddr, virtSize, physLoc)`), `anyV2P` RVA->physical mapper built from section headers, CLI header fields (`ilOnly`, `only32`/`is32bitpreferred`, entry point token, resources/strongname/vtable pairs), building `pectxt` and the `peinfo` triple. 64-bit fields after the data directory use `x64adjust = headerSizeOpt - 0xe0`.
- `openPE (fileName, pefile, reduceMemoryUsage, noFileOnDisk)` and `openPEMetadataOnly (fileName, peinfo, pectxtEager, pevEager, mdfile, reduceMemoryUsage)` — metadata-only passes the metadata as `0`-offset `mdfile` and captures no PE context.

## Public reader surface, caching, shims

- `ILReaderMetadataSnapshot = obj * nativeint * int`; `ILReaderTryGetMetadataSnapshot = string * DateTime -> ILReaderMetadataSnapshot option`; `MetadataOnlyFlag`/`ReduceMemoryFlag` (`[<RequireQualifiedAccess>]`); `ILReaderOptions { pdbDirPath; reduceMemoryUsage; metadataOnly; tryGetMetadataSnapshot }`.
- `ILModuleReader` (interface: `ILModuleDef`, `ILAssemblyRefs`, `IDisposable` — dispose only matters when memory mapping is used) and `ILModuleReaderImpl`.
- Global mutable caches: `ILModuleReaderCacheKey = string * DateTime * bool * ReduceMemoryFlag * MetadataOnlyFlag`; `ilModuleReaderCache1` (an `AgedLookup` holding up to `stronglyHeldReaderCacheSize` readers strongly, guarded by `ilModuleReaderCache1Lock`) and `ilModuleReaderCache2` (a `ConcurrentDictionary` of weak references to still-alive readers); `ClearAllILModuleReaderCache ()`.
- `stableFileHeuristicApplies`, `createByteFileChunk` (uses `WeakByteFile` only when reducing memory AND the stable-file heuristic applies, else `ByteFile`), `getBinaryFile` (creates the memory-mapped-file `RawMemoryFile` with a finalizing holder, updating stats).
- `OpenILModuleReaderFromBytes` (no file on disk), `OpenILModuleReaderFromStream` (via `System.Reflection.PortableExecutable.PEReader` with `PrefetchEntireImage`), and `OpenILModuleReader fileName opts` — the primary entry point: pseudo-normalizes the path, checks cache1 (strong, lock-guarded) then cache2 (weak), and constructs via two regimes:
  - Reduce-memory mode (FCS applications, devenv, fsi): metadata-only path asks `tryGetMetadataSnapshot` for the metadata section (else reads just the metadata chunk), uses a short-lived PE-file reader, and opens via `openPEMetadataOnly`; non-metadata-only reads all bytes held strongly/weakly. PDB-enabled reads (`pdbDirPath.IsSome`) never use the cache because the object is `IDisposable`.
  - fsc.exe regime (no memory reduction, leak-tolerant): memory-maps only stable files (`alwaysMemoryMapFSC` or heuristic), else `ByteFile`; opens via `openPE`.
- `Shim` module (`[<AutoOpen>]`): `IAssemblyReader` (abstract `GetILModuleReader`), `DefaultAssemblyReader`, and a mutable `AssemblyReader` global so callers can plug in an alternative reader implementation.

## Significant internal logic

- Everything is seek/offset based with shared heap caches; sorted tables are binary-searched and the comparisons are coded-index-aware (e.g. `hcaCompare` uses the tag to order by table when the rid matches).
- The `typeDefReader` is recomputed (not captured) inside its lazy closure because it is the most heavily allocated suspension in all of AbsIL; the per-table uncached readers take the context through an initialization hole to avoid retention cycles.
- Method/field tokens are reverse-mapped to their owning type by binary-chopping the TypeDef table over member ranges.
- Instruction streams are decoded with a lazily-built two-level opcode table and a mutable prefix register; branches become `ILCodeLabel`s resolved through raw-offset maps, and `buildILCode` (from il.fs) converts the linear stream with EH clauses into AbsIL nested code.
- PDB/debug information is treated as optional streaming input (sequence points injected into the instruction list between prefix scanning and decode); raw code is read from the PE only when `pectxtCaptured` is supplied.
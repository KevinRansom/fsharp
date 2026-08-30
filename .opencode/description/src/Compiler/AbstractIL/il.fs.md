# il.fs

## Pipeline role

The core Abstract IL AST definition and construction library for the F# compiler. This module defines nearly every data structure used to represent .NET metadata and IL in-memory (scopes, type refs/specs, types, method refs/specs, fields, attributes, instructions, exception clauses, method bodies, members, type defs, exported types, resources, module and assembly manifests), together with namespace name splitting, a minimal SHA1 (for public-key tokens), primitive constructors (`mkIL*`), metadata-index bookkeeping (locally named `NoMetadataIdx` = -1), IL type instantiation and re-scoping, custom-attribute encode/decode, permission-set encoding, signature-speaking primitives, `ILGlobals`, reference-collection walkers, and utility operations on code.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.IL` (module level; `#nowarn "49"; #nowarn "343"; #nowarn "346"`)
- Uses: `FSharp.Compiler.IO` (`Bytes`, `ByteStorage`), `Internal.Utilities.Library`, `Internal.Utilities` (`InterruptibleLazy`, `notlazy`, `lazyMap`, `UniqueStampGenerator`, `DelayInitArrayMap`, `DelayInitValue`), `FSharp.Compiler.AbstractIL.Diagnostics` (`dprintn`), `System.Runtime.InteropServices` visible types (`TypeAttributes`, `MethodAttributes`, etc. via `System.Reflection`).

## Global state / logging

- `logging = false`; if on, prints a warning.
- `lazyMap` — avoids introducing laziness when the leaf is already computed.
- `memoizeNamespaceTable`, `memoizeNamespaceRightTable`, `memoizeNamespacePartTable`, `memoizeNamespaceArrayTable` — `ConcurrentDictionary` memo caches (concurrency-safe) for namespace splitting.
- `AssemblyRefUniqueStampGenerator = UniqueStampGenerator<AssemblyRefData>()` — intern table for assembly references.
- `codeLabelCount` (ref) with `Interlocked.Increment` in `generateCodeLabel ()`.

## Name splitting utilities

- `splitNameAt nm idx`, `splitNamespaceAux`, `splitNamespace`, `splitNamespaceToArray`, `splitILTypeName`, `splitILTypeNameWithPossibleStaticArguments` (handles the `,"1.0"` static-argument suffix used by provided types), `splitTypeNameRightAux`/`splitTypeNameRight`.

## LazyOrderedMultiMap

- `LazyOrderedMultiMap<'Key,'Data>` — ordered keyed list with a lazily-built lookup `Dictionary` (keys -> reversed entries); members `Entries()`, `Add`, `Filter`, indexer `Item`.

## SHA1 module

- `SHA1` submodule: `f`, `k0to19`..`k60to79`, `k`, `SHAStream` record (stream/pos/eof), `rotLeft32`, `shaAfterEof` (padding + 64-bit bit-length), `shaRead8`, `shaRead32`, `sha1Hash`, `sha1HashBytes` (produces bytes from registers 3 and 4), `sha1HashInt64`.
- Top-level `sha1HashBytes`, `sha1HashInt64`.

## Core value/types

- `ILVersionInfo` (`[<Struct>]`) — Major/Minor/Build/Revision `uint16`.
- `Locale = string`.
- `PublicKey` (DU) — `PublicKey | PublicKeyToken` with `IsKey`, `Key`, `KeyToken`, `ToToken()` (SHA1 for full keys), `KeyAsToken`.
- `AssemblyRefData` — name/hash/publicKeyInfo/retargetable/version/locale.
- `ILAssemblyRef` — interned by `UniqueStamp` (computed from data with key->token normalized); members `Name`..`Locale`, `UniqueStamp`, `UniqueIgnoringVersionStamp`, `EqualsIgnoringVersion`; `Create`, `FromAssemblyName`; `QualifiedName` (assembly display string with Version/Culture/PublicKeyToken/Retargetable).
- `ILModuleRef` record — `name`, `hasMetadata`, `hash`; `Create`.
- `ILScopeRef` (DU, `RequireQualifiedAccess`) — `Local | Module | Assembly | PrimaryAssembly`; `IsLocalRef`, `QualifiedName`.
- `ILArrayBound = int32 option`, `ILArrayBounds`, `ILArrayShape` (`ILArrayShape of ILArrayBounds list`; `Rank`, `SingleDimensional`, `FromRank`), `ILArrayShapeStatics`.
- `ILArgConvention` / `ILThisConvention` / `ILCallingConv` + `ILCallingConvStatics` (intern table for all 18 combos).
- `ILBoxity` — `AsObject | AsValue`.
- `ILTypeRef` (record with precomputed `hashCode` and a cached memo `asBoxedType`) — `ComputeHash`, `Create`, `Scope`/`Enclosing`/`Name`, `ApproxId`, `AsBoxedType`; custom equality/comparison `EqualsWithPrimaryScopeRef`; `FullName`, `BasicQualifiedName`, `QualifiedName`, `DebugText`.
- `ILTypeSpec` — `tspecTypeRef` + `tspecInst`; same accessors, `BasicQualifiedName`, `EqualsWithPrimaryScopeRef`.
- `ILType` (DU, `RequireQualifiedAccess`) — `Void | Array | Value | Boxed | Ptr | Byref | FunctionPointer | TypeVar | Modified`; `BasicQualifiedName`, `QualifiedName`, `TypeSpec`, `Boxity`, `TypeRef`, `IsNominal`, `GenericArgs`, `IsTyvar`.
- `ILCallingSignature` record + `ILGenericArgs`/`ILTypes` abbreviations; `mkILCallSig`, `mkILBoxedType`.
- `ILMethodRef` — `mrefParent`, callconv, generic arity, name, args, return; `Create`, `GetCallingSignature`, `FullName`.
- `ILFieldRef`, `ILMethodSpec` (ref + declaring type + method inst), `ILFieldSpec`.

## Debug info

- `ILGuid = byte[]`; `ILPlatform` (`X86 | AMD64 | IA64 | ARM | ARM64`); `ILSourceDocument`; `ILDebugPoint`; `ILAttribElem` and `ILAttributeNamedArg`; `ILAttribute` (`Encoded | Decoded`); `ILAttributes` (`[<Struct>]`).

## Well-known attribute flags

- `WellKnownILAttributes` (`[<Flags>]`) — 27 recognized + `NotComputed`; `ILAttributesStored` caches memoized `Reader | Given` custom attrs and lazily-computed well-known flags (`HasWellKnownAttribute`, `GetOrComputeWellKnownFlags`).

## Instructions

- `ILCodeLabel = int`; `ILBasicType` (`DT_R`..); `ILToken` (`ILType | ILMethod | ILField`); `ILConst` (`I4 | I8 | R4 | R8`); `ILTailcall`, `ILAlignment`, `ILVolatility`, `ILReadonly`, `ILVarArgs`; `ILComparisonInstr` (`BI_beq`..); `ILInstr` (the full opcode DU; `AI_*` arithmetic, `I_*` members/calls/branches/fields/objects/arrays/refany/etc., `EI_ilzero`/`EI_ldlen_multi` extensions); `ILExceptionClause` (`Finally | Fault | FilterCatch | TypeCatch`); `ILExceptionSpec`; `ILLocalDebugMapping`, `ILLocalDebugInfo`; `ILCode`; `ILLocal`, `ILDebugImport`/`ILDebugImports`; `ILMethodBody` (IsZeroInit, MaxStack, NoInlining, AggressiveInlining, Locals, Code, DebugRange, DebugImports).

## Members

- `ILMemberAccess`, `ILFieldInit` (+ `AsObject`), `ILNativeType` (marshal types incl. `Array`, `SafeArray`), `ILNativeVariant`, `ILSecurityAction`, `ILSecurityDecl`, `ILSecurityDecls` (struct) / `ILSecurityDeclsStored` (Reader/Given with `GetSecurityDecls metadataIndex`).
- PInvoke enums: `PInvokeCharBestFit`, `PInvokeThrowOnUnmappableChar`, `PInvokeCallingConvention`, `PInvokeCharEncoding`, `PInvokeMethod` record.
- `ILParameter` (Name/Type/Default/Marshal/IsIn/IsOut/IsOptional/CustomAttrsStored/MetadataIndex), `ILReturn`, `ILOverridesSpec` (`OverridesSpec of ILMethodRef * ILType`), `ILMethodVirtualInfo` (IsFinal/IsNewSlot/IsCheckAccessOnOverride/IsAbstract), `MethodBody` (`IL of InterruptibleLazy | PInvoke | Abstract | Native | NotAvailable`), `MethodCodeKind`, `ILGenericVariance`, `ILGenericParameterDef` (with constraint flags incl. `HasAllowsRefStruct`) .

## Member access helpers

- `memberAccessOfFlags` (bit7 of flags), `convertMemberAccess`, `conditionalAdd`, `NoMetadataIdx = -1`, `InterfaceImpl` record (Idx/Type/CustomAttrsStored), `typesOfILParams`.

## Class definitions

- `ILMethodDef` (primary ctor keeps `LazyBody`; secondary ctor with stored attrs; `With` update fn; flags `IsStatic`..`IsMustRun`; helpers `WithHideBySig`, `WithFinal`, `WithAccess`, etc.; `Code`, `MethodBody`, `Locals`).
- `MethodDefMap`; `ILMethodDefs` (inherits `DelayInitArrayMap`, dictionary keyed on Name; `FindByName`, `FindByNameAndArity`, `TryFindInstanceByNameAndCallingSignature`).
- `ILEventDef` (+ `With`, `IsSpecialName`/`IsRTSpecialName`); `ILEventDefs` (`ILEvents of LazyOrderedMultiMap`).
- `ILPropertyDef` (+ `With`, name/accessors/propertyType/init/args); `ILPropertyDefs`.
- `convertFieldAccess`; `ILFieldDef` (name/fieldType/attributes/data/literalValue/offset/marshal/customAttrsStored/metadataIndex; `With`, `WithAccess`, `WithLiteralDefaultValue`, `WithFieldMarshal`, access flags); `ILFieldDefs` (`ILFields of LazyOrderedMultiMap`).
- `ILMethodImplDef`/`ILMethodImplDefs`/`MethodImplsMap`.
- `ILTypeDefLayout` (Auto/Sequential/Explicit + `ILTypeDefLayoutInfo`), `ILTypeInit` (BeforeField/OnAny), `ILDefaultPInvokeEncoding`, `ILTypeDefAccess`.
- Flag conversion helpers: `typeAccessOfFlags`, `typeEncodingOfFlags`, `ILTypeDefAdditionalFlags` (`[<Flags>]`, Class..CanContainExtensionMethods), `typeKindFlags`, `resetTypeKind`, `HasFlag` active pattern, `typeKindByNames`, `typeKindOfFlags`, `convertTypeAccessFlags`, `convertTypeKind`, `convertLayout`, `convertEncoding`, `convertToNestedTypeAccess`, `convertInitSemantics`.
- `ILTypeDef` (full member collections: name/attributes/layout/implements (lazy)/genericParams/extends (lazy)/methods/nestedTypes/fields/methodImpls/events/properties/additionalFlags/securityDeclsStored/customAttrsStored/metadataIndex; three constructors, `With`, kind/access/layout literals, `IsKnownToBeAttribute`, `CanContainExtensionMethods`, `IsClass/IsStruct/IsInterface/IsEnum/IsDelegate`, access flags `IsAbstract/IsSealed/IsComInterop/Encoding/IsStructOrEnum`).
- `ILTypeDefs` (DelayInitArrayMap with `ILPreTypeDef[]` + optional `ILPreNamespace[]`, namespace-grouped lazy realization under `Monitor`; `AllPreTypeDefs`, `TryFindPreTypeDef`, `AsArray`, `AsList`, `FindByName`, `ExistsByName`), `ILPreTypeDef` (interface: Name/GetTypeDef), `ILPreNamespace` (abstract class: Name/ComputeTypes/ComputeNamespaces, lazily realized Types/Namespaces + name dictionaries), `ILPreTypeDefImpl` (name/type via `ILTypeDefStored.Reader`), `ILTypeDefStored`.
- `ILNestedExportedType`, `ILExportedTypeOrForwarder`, `ILExportedTypesAndForwarders`, `ILResourceAccess`, `ILResourceLocation` (Local `ByteStorage`/File/Assembly), `ILResource`, `ILResources`, `ILAssemblyLongevity`, `ILAssemblyManifest`, `ILNativeResource`, `ILModuleDef`.

## Primitive constructors

- Type refs/specs: `mkILNestedTyRef`, `mkILTyRef`, `mkILTySpec`, `mkILNonGenericTySpec`, `mkILTyRefInTyRef`, `mkILTy`, `mkILNamedTy`, `mkILValueTy`, `mkILBoxedTy`, `mkILNonGenericValueTy/BoxedTy`, `mkSimpleAssemblyRef`, `mkSimpleModRef`.
- Global functions: `typeNameForGlobalFunctions = "<Module>"`, `mkILTypeForGlobalFunctions`, `isTypeNameForGlobalFunctions`.
- Method/field spec constructors: `mkILMethRef`, `mkILMethSpecForMethRefInTy`, `mkILMethSpec`, `mkILMethSpecInTypeRef`, `mkILMethSpecInTy`, `mkILNonGeneric*`/instance/static/ctor variants (`mkILCtorMethSpec`, `mkILCtorMethSpecForTy`), `mkILFieldRef`, `mkILFieldSpec`, `mkILFieldSpecInTy`, `andTailness`.
- Code: `formatCodeLabel`, `generateCodeLabel`, `instrIsRet`, `nonBranchingInstrsToCode`.
- Types/typars: `mkILTyvarTy`, `mkILSimpleTypar`, `stripILGenericParamConstraints`, `genericParamOfGenericActual`, `mkILFormalTypars`, `mkILFormalGenericArgs`, `mkILFormalBoxedTy`, `mkILFormalNamedTy`.
- Type tables: `mkRefForNestedILTypeDef`, `mkILPreTypeDefRead`, `mkILPreTypeDefGiven`, `mkILPreNamespaceComputed`, `mergePreNamespaces`/`combinePreNamespaces`, `groupEntriesByNamespace` (range-based grouping: each namespace a contiguous run), `ILPreNamespaceOfRange`, `mkILTypeDefsComputed`, `mkILTypeDefsOfNamespace`, `mkILTypeDefsGroupedComputed`, `addILTypeDef`, `mkILTypeDefsFromArray`, `mkILTypeDefs`, `emptyILTypeDefs`, `emptyILInterfaceImpls`.
- Methods: `mkILMethodsFromArray`, `mkILMethods`, `mkILMethodsComputed`, `emptyILMethods`.
- Module defaults: `defaultSubSystem = 3`, `defaultPhysAlignment = 512`, `defaultVirtAlignment = 0x2000`, `defaultImageBase = 0x034f0000`.
- Arrays: `mkILArrTy`, `mkILArr1DTy`, `isILArrTy`, `destILArrTy`.
- `tname_*` literals for well-known BCL type names; `ILGlobals(primaryScopeRef, equivPrimaryAssemblyRefs, fsharpCoreAssemblyScopeRef)` with memoized primitives (`typ_Object`..`typ_UIntPtr`, `typ_ByteArray`, `typ_StringArray`), `primaryAssemblyName`, `IsPossiblePrimaryAssemblyRef`, `mkILGlobals`.
- Common instructions (cached arrays): `mkNormalCall`, `mkNormalCallvirt`, `mkNormalNewobj`, `mkLdarg`, `mkLdarg0`, `mkLdloc`, `mkStloc`, `mkLdcInt32`; `ecmaPublicKey`.
- Type predicate helpers: `isILBoxedTy`, `isILValueTy`, `stripILModifiedFromTy`, `isBuiltInTySpec`, `isILBoxedBuiltInTy`, `isILValueBuiltInTy`, `isILObjectTy`, `isILStringTy`, `isILTypedReferenceTy`, `isILSByteTy`..`isILDoubleTy`.

## Transformation utilities

- Re-scoping: `rescopeILScopeRef`, `rescopeILTypeRef`, `rescopeILTypeSpec`, `rescopeILType`, `rescopeILTypes`, `rescopeILCallSig`, `rescopeILMethodRef`, `rescopeILFieldRef`.
- Instantiation: `instILTypeSpecAux`, `instILTypeAux` (handles `TypeVar` h n shifting under `numFree`), `instILGenericArgsAux`, `instILCallSigAux`, `instILType`.
- Params/locals/returns: `mkILParam`(+Named/Anon), `mkILReturn`, `mkILLocal`; extension `ILFieldSpec.ActualType`.
- Bodies + field instructions: `mkILMethodBody`, `mkMethodBody`, `mkILVoidReturn`, `methBodyNotAvailable`/`Abstract`/`Native`, `mkILCtor` (path `notlazy`), `mkCallBaseConstructor`, `mkNormalStfld/Stsfld/Ldsfld/Ldfld/Ldflda`, `ILFieldInstr` active pattern, `mkNormalLdobj/Stobj`, `mkILNonGenericEmptyCtor`, `mkILStaticMethod`(+NonGeneric), `mkILClassCtor`, `mkILGenericVirtualMethod`(+NonGeneric variants), `mkILGenericNonVirtualMethod`(+NonGeneric instance).
- Code transforms: `ilmbody_code2code`, `mdef_code2code`, `appendInstrsToCode` (splices before `I_ret`), `prependInstrsToCode` (keeps a leading sequence point), `appendInstrsToMethod`/`prependInstrsToMethod`, `cdef_cctorCode2CodeOrCreate` (creates `.cctor`; renames multiple `.cctor`s to `cctor_renamed_N` and synthesizes a dispatcher to resolve FS2014).
- Reference builders: `mkRefToILMethod`, `mkRefToILField`, `mkRefForILMethod`, `mkRefForILField`, `prependInstrsToClassCtor`.
- Fields: `mkILField`, `mkILInstanceField`, `mkILStaticField`, `mkILStaticLiteralField`, `mkILLiteralField`.
- `ILLocalsAllocator` — allocates fresh local indexes from a `preAlloc` base.
- Collection constructors: `mkILFields(Lazy)`, `mkILEvents(Lazy)`, `mkILProperties(Lazy)`, `addExportedTypeToTable`, `mkILExportedTypes(Lazy)`, `addNestedExportedTypeToTable`, `mkTypeForwarder`, `mkILNestedExportedTypes(Lazy)`, `mkILResources`, `addMethodImplToTable`, `mkILMethodImpls(Lazy)`.
- Storage/member ctors: `mkILStorageCtorWithParamNames` (+ simple variants), `addParamNames`, `mkILGenericClass`, `mkRawDataValueTypeDef`, `mkILSimpleClass`, `mkILTypeDefForGlobalFunctions`, `destTypeDefsWithGlobalFunctionsFirst`, `mkILSimpleModule` (default manifest with SHA1 hashalg 0x8004), `buildILCode`.
- Delegates/enums: `mkILDelegateMethods`, `mkCtorMethSpecForDelegate`, `ILEnumInfo`, `getTyOfILEnumInfo`, `computeILEnumInfo`.

## Signature-reading primitives

- `sigptr_get_byte/u8/i8/u16/i16/i32/u32/i64/u64`, `float32OfBits`/`floatOfBits`, `sigptr_get_ieee32/ieee64`, `sigptr_get_intarray`, `sigptr_get_string`, `sigptr_get_z_i32` (4-bit packed int), `sigptr_get_serstring`, `sigptr_get_serstring_possibly_null` (0xFF null marker).

## Misc / assembly helpers

- `mkRefToILAssembly`, `z_unsigned_int` (compressed int encoding), `string_as_utf8_bytes`, byte extractors `b0`-`b3`, `dw0`-`dw7`, little-endian byte writers `u8AsBytes`..`ieee64AsBytes`, ELEMENT_TYPE tags `et_BOOLEAN`..`et_SZARRAY`, `formatILVersion`, `parseILVersion` (ACcepts `*` wildcards: build = days since 2000-01-01, revision = seconds since midnight / 2), `compareILVersions`, `DummyFSharpCoreScopeRef`, `PrimaryAssemblyILGlobals`.

## Custom attributes

- Encode: `encodeCustomAttrString`, `encodeCustomAttrElemType` (maps IL types to ELEMENT_TYPE tags; enums -> `0x55` + qualified name), `encodeCustomAttrElemTypeForObject`, `encodeCustomAttrPrimValue` (bool/string/char/number/type handling incl. `0xFF` null), `encodeCustomAttrValue`, `encodeCustomAttrNamedArg` (field/property prefix `0x53`/`0x54`), `encodeCustomAttrArgs`, `encodeCustomAttr`, `mkILCustomAttribMethRef`, `mkILCustomAttribute`, `getCustomAttrData`.
- Permission sets: `mkPermissionSet` (blob layout: `.` marker, count, then per-attribute qualified name + property count/named args).
- Decode: `ILTypeSigParser` (char scanner `ParseType`/`ParseTypeSpec`; parses `Type` generic arity `\`n[` children, array ranks, assembly-qualified scope via `FromAssemblyName`), `decodeCustomAttrElemType` (incl. `0x50` type, `0x51` tagged object, `0x55` enum), `decodeILAttribData` (validates prolog `0x01 0x00`, parses fixed args, named count, named args; wraps genuine enums as `ILAttribElem.Enum`).

## Reference collection

- `ILReferences`/`ILReferencesAccumulator`; the full `refsOfIL*` walker family: scope refs, type refs, types, type specs, call sigs, generic params, method refs, field refs, override specs, method/field specs, tokens, custom-attr elems/attrs, varargs, instrs, code (incl. TypeCatch), method bodies, locals, params, returns, method/event/property/field defs, method impls, type defs (recursive), exported types, resource locations/resources, module, manifest.
- `computeILRefs ilg modul`.

## Unscoping / resolution

- `unscopeILTypeRef`..`unscopeILCallSig` — rebind scopes to `Local`.
- `resolveILMethodRefWithRescope r td mref` — resolves an `ILMethodRef` against a type (calling conv + parameter types + arity + return), with clear failure messages; `resolveILMethodRef = resolveILMethodRefWithRescope id`; `mkRefToILModule`.
- `ILEventRef` / `ILPropertyRef` record wrappers (declaring type ref + name).

## Significant internal logic

- Assembly references are interned through `UniqueStampGenerator` using the public-key-token-normalized data, so `ILAssemblyRef` equality is stamp equality and never materializes hash collisions.
- `ILTypeDefs`/`ILPreNamespace` realize on demand with monitor-guarded volatile fields, and `groupEntriesByNamespace` produces a single pre-grouped layout so namespaces are contiguous ranges (memory-critical design noted in comments).
- The SHA1 implementation exists to derive public-key tokens without the full crypto stack.
- Custom attribute encoding/decoding follows ECMA-335 Partition II §23.3 including `0x55` enum, `0x50`/`0x51` type/object tags and compressed ints.
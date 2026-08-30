# il.fsi

**Purpose**
Contract for the core abstract IL algebra — "the 'unlinked' view of .NET metadata and code, central to the Abstract IL library" (`FSharp.Compiler.AbstractIL.IL`, a `rec` module, public). Declares every type CodeGen produces (IlxGen) and that the emitters consume: `ILModuleDef`, `ILAssemblyManifest`, `ILTypeDef`, `ILMethodDef`, `ILFieldDef`, `ILType`, `ILTypeRef`, `ILTypeSpec`, `ILMethodRef`, `ILMethodSpec`, `ILFieldRef`, `ILFieldSpec`, `ILCode`, `ILInstr`, `ILMethodBody`, `ILAttributes`, `ILParameter`, `ILGenericParameterDef`, `ILGlobals`, etc.

**Namespace / module**
- `FSharp.Compiler.AbstractIL` (module `FSharp.Compiler.AbstractIL.IL` — public)

**TypeDefs declared (full list, in file order)**
- `PrimaryAssembly` (internal union) — Mscorlib | System_Runtime | NetStandard; `Name`, `IsPossiblePrimaryAssembly`.
- `ILGuid = byte[]`.
- `ILPlatform` (internal struct-union) — X86 | AMD64 | IA64 | ARM | ARM64.
- `ILSourceDocument` (sealed class) — `Language/Vendor/DocumentType : ILGuid option`, `File: string`; `Create`.
- `ILDebugPoint` (internal sealed) — `Document, Line, Column, EndLine, EndColumn`.
- `PublicKey` (union) — `PublicKey of byte[]` | `PublicKeyToken of byte[]`; `IsKey`, `IsKeyToken`, `Key`, `KeyToken`, `KeyAsToken`.
- `ILVersionInfo` (struct) — `Major/Minor/Build/Revision : uint16`.
- `ILAssemblyRef` (sealed) — `Create(name, hash, publicKey, retargetable, version, locale)`, `FromAssemblyName`; `Name`, `QualifiedName`, `Hash : byte[] option`, `PublicKey : PublicKey option`, `Retargetable`, `Version : ILVersionInfo option`, `Locale`, `EqualsIgnoringVersion`, `IComparable`.
- `ILModuleRef` (sealed) — `Create(name, hasMetadata, hash)`; `Name`, `HasMetadata`, `Hash`.
- `ILScopeRef` (union) — `Local | Module of ILModuleRef | Assembly of ILAssemblyRef | PrimaryAssembly`; `IsLocalRef`, `QualifiedName`.
- `ILArgConvention` (union) — Default | CDecl | StdCall | ThisCall | FastCall | VarArg.
- `ILThisConvention` (union) — Instance | InstanceExplicit | Static.
- `ILCallingConv` — private `Callconv of ILThisConvention * ILArgConvention`; `IsInstance/IsInstanceExplicit/IsStatic`, `ThisConv`, `BasicConv`, shared instances `Instance`/`Static`, `Create`.
- `ILArrayBound` (internal = `int32 option`), `ILArrayBounds` (internal).
- `ILArrayShape` — `Rank`, `SingleDimensional`, `FromRank`.
- `ILBoxity` (internal) — AsObject | AsValue.
- `ILGenericVariance` — NonVariant | CoVariant | ContraVariant.
- `ILTypeRef` (sealed) — `Create(scope, enclosing, name)`; `Scope`, `Enclosing`, `Name`, `FullName`, `BasicQualifiedName`, `QualifiedName`, `IComparable`.
- `ILTypeSpec` (sealed) — `Create(typeRef, instantiation)`; `TypeRef`, `GenericArgs`, `Scope`, `Enclosing`, `Name`, `FullName`.
- `ILType` (union) — `Void | Array of ILArrayShape * ILType | Value of ILTypeSpec | Boxed of ILTypeSpec | Ptr of ILType | Byref of ILType | FunctionPointer of ILCallingSignature | TypeVar of uint16 | Modified of bool * ILTypeRef * ILType`; `TypeSpec`, `Boxity`, `TypeRef`, `IsNominal`, `GenericArgs`, `IsTyvar`, `BasicQualifiedName`, `QualifiedName`.
- `ILCallingSignature` (struct) — `{ CallingConv; ArgTypes: ILTypes; ReturnType: ILType }`.
- `InterfaceImpl` — `{ Idx; Type: ILType; CustomAttrsStored: ILAttributesStored }`.
- `ILGenericArgs = ILType list`, `ILTypes = ILType list`.
- `ILMethodRef` (sealed) — `Create(enclosingTypeRef, callingConv, name, genericArity, argTypes, returnType)`; `DeclaringTypeRef`, `CallingConv`, `Name`, `GenericArity`, `ArgCount`, `ArgTypes`, `ReturnType`, `GetCallingSignature`, `IComparable`.
- `ILFieldRef` (struct) — `{ DeclaringTypeRef; Name; Type }`.
- `ILMethodSpec` (sealed) — `Create(ILType * ILMethodRef * ILGenericArgs)`; `MethodRef`, `DeclaringType`, `GenericArgs`, `CallingConv`, `GenericArity`, `Name`, `FormalArgTypes`, `FormalReturnType`.
- `ILFieldSpec` (struct) — `{ FieldRef; DeclaringType }`; `DeclaringTypeRef`, `Name`, `FormalType`, `ActualType`.
- `ILCodeLabel` (internal = int).
- `ILBasicType` (internal) — DT_R | DT_I1 | DT_U1 | DT_I2 | DT_U2 | DT_I4 | DT_U4 | DT_I8 | DT_U8 | DT_R4 | DT_R8 | DT_I | DT_U | DT_REF.
- `ILToken` (internal) — ILType | ILMethod of ILMethodSpec | ILField of ILFieldSpec.
- `ILConst` (internal) — I4 | I8 | R4 | R8.
- `ILTailcall` (internal) — Tailcall | Normalcall.
- `ILAlignment` (internal) — Aligned | Unaligned1 | Unaligned2 | Unaligned4.
- `ILVolatility` (internal) — Volatile | Nonvolatile.
- `ILReadonly` (internal) — ReadonlyAddress | NormalAddress.
- `ILVarArgs` (internal) = `ILTypes option`.
- `ILComparisonInstr` (internal) — BI_beq | BI_bge | BI_bge_un | BI_bgt | BI_bgt_un | BI_ble | BI_ble_un | BI_blt | BI_blt_un | BI_bne_un | BI_brfalse | BI_brtrue.
- `ILInstr` (internal, ~100-case union) — `AI_add...AI_or`, `AI_nop`, `AI_ldc of ILBasicType * ILConst`, `I_ldarg/ldarga(I_starg)/ldloc(I_stloc/ldloca) of uint16`, `I_ldind/stind of ILAlignment * ILVolatility * ILBasicType`, control transfer (`I_br`, `I_jmp`, `I_brcmp of ILComparisonInstr * ILCodeLabel`, `I_switch`, `I_ret`), method call (`I_call/callvirt/callconstraint/calli`, with `ILTailcall * ILVarArgs`, `I_ldftn`, `I_newobj`), exceptions (`I_throw`, `I_endfinally`, `I_endfilter`, `I_leave`, `I_rethrow`), object instructions (`I_ldsfld/ldfld/ldsflda/ldflda/stsfld/stfld`, `I_ldstr`, `I_isinst`, `I_castclass`, `I_ldtoken`, `I_ldvirtftn`), value type instructions (`I_cpobj`, `I_initobj`, `I_ldobj/stobj`, `I_box`, `I_unbox`, `I_unbox_any`, `I_sizeof`), generalized array instructions (`I_ldelem/stelem of ILBasicType`, `I_ldelema of ILReadonly * bool * ILArrayShape * ILType`, `I_ldelem_any/stelem_any of ILArrayShape * ILType`, `I_newarr of ILArrayShape * ILType`, `I_ldlen`), `System.TypedReference` (`I_mkrefany`, `I_refanytype`, `I_refanyval`), `I_break`, `I_seqpoint of ILDebugPoint`, `I_arglist`, `I_localloc`, `I_cpblk`, `I_initblk`, `EI_ilzero`, `EI_ldlen_multi`.
- `ILExceptionClause` (internal) — Finally | Fault | FilterCatch | TypeCatch.
- `ILExceptionSpec` (internal) — `{ Range: ILCodeLabel * ILCodeLabel; Clause: ILExceptionClause }`.
- `ILLocalDebugMapping` (internal) — `{ LocalIndex; LocalName }`.
- `ILLocalDebugInfo` (internal) — `{ Range; DebugMappings: ILLocalDebugMapping list }`.
- `ILCode` (internal) — `{ Labels: Dictionary<ILCodeLabel, int>; Instrs: ILInstr[]; Exceptions: ILExceptionSpec list; Locals: ILLocalDebugInfo list }`.
- `ILFieldInit` (union) — String | Bool | Char | Int8...UInt64 | Single | Double | Null; `AsObject`.
- `ILNativeVariant` (internal) — 35 cases for COM native variants (Empty, Null, Variant, Currency, Decimal, Date, BSTR, LPSTR, LPWSTR, IUnknown, IDispatch, SafeArray, Error, HRESULT, CArray, UserDefined, Record, FileTime, Blob, Stream, Storage, StreamedObject, StoredObject, BlobObject, CF, CLSID, Void, Bool, Int8..UInt64, PTR, Array, Vector, Byref, Int, UInt).
- `ILNativeType` (union) — 35 cases for COM native marshalling types (Empty, `Custom of ILGuid * string * string * byte[]`, FixedSysString, FixedArray, Currency, LPSTR, LPWSTR, LPTSTR, LPUTF8STR, ByValStr, TBSTR, LPSTRUCT, Struct, Void, Bool, Int8...UInt64, `Array of ILNativeType option * (int32 * int32 option) option`, Int, UInt, Method, AsAny, BSTR, IUnknown, IDispatch, Interface, Error, `SafeArray of ILNativeVariant * string option`, ANSIBSTR, VariantBool).
- `ILLocal` (internal) — `{ Type: ILType; IsPinned: bool; DebugInfo: (string * int * int) option }`.
- `ILLocals` (internal) = `ILLocal list`.
- `ILDebugImport` (union) — `ImportType of ILType` | `ImportNamespace of string`.
- `ILDebugImports` — `{ Parent: ILDebugImports option; Imports: ILDebugImport[] }`.
- `ILMethodBody` (internal) — `{ IsZeroInit; MaxStack; NoInlining; AggressiveInlining; Locals: ILLocals; Code: ILCode; DebugRange: ILDebugPoint option; DebugImports: ILDebugImports option }`.
- `ILMemberAccess` (union) — Assembly | CompilerControlled | FamilyAndAssembly | FamilyOrAssembly | Family | Private | Public.
- `ILAttribElem` (union) — String option | Bool | Char | SByte | Int16 | Int32 | Int64 | Byte | UInt16 | UInt32 | UInt64 | Single | Double | Null | Type of ILType option | TypeRef of ILTypeRef option | Array of ILType * ILAttribElem list | `Enum of enumType: ILType * value: ILAttribElem`.
- `ILAttributeNamedArg` = `string * ILType * bool * ILAttribElem`.
- `ILAttribute` (union) — `Encoded of method: ILMethodSpec * data: byte[] * elements: ILAttribElem list` | `Decoded of method * fixedArgs * namedArgs`; `Method`, `Elements`, `WithMethod`.
- `ILAttributes` (struct) — `AsArray`, `AsList`, `Empty`.
- `WellKnownILAttributes` (flags) — IsReadOnly, IsUnmanaged, IsByRefLike, Extension, Nullable, ParamArray, AllowNullLiteral, ReflectedDefinition, AutoOpen, InternalsVisibleTo, CallerMemberName, CallerFilePath, CallerLineNumber, IDispatchConstant, IUnknownConstant, RequiresLocation, SetsRequiredMembers, NoEagerConstraintApplication, DefaultMember, Obsolete, CompilerFeatureRequired, Experimental, RequiredMember, NullableContext, AttributeUsage, NotNullIfNotNull, OverloadResolutionPriority, NotComputed.
- `ILAttributesStored` (sealed struct) — `CustomAttrs: ILAttributes`, `HasWellKnownAttribute(flag, compute)`, `CreateReader(idx, f)`, `CreateGiven(attrs)`.
- `ILParameter` — `{ Name: string option; Type; Default: ILFieldInit option; Marshal: ILNativeType option; IsIn; IsOut; IsOptional; CustomAttrsStored; MetadataIndex }`; `CustomAttrs`.
- `ILParameters` = `ILParameter list`.
- `ILReturn` — `{ Marshal: ILNativeType option; Type; CustomAttrsStored; MetadataIndex }`; `CustomAttrs`, `WithCustomAttrs`.
- `ILSecurityAction` (internal) — Request | Demand | Assert | Deny | PermitOnly | LinkCheck | InheritCheck | ReqMin | ReqOpt | ReqRefuse | PreJitGrant | PreJitDeny | NonCasDemand | NonCasLinkDemand | NonCasInheritance | LinkDemandChoice | InheritanceDemandChoice | DemandChoice.
- `ILSecurityDecl` (internal) — `ILSecurityDecl of ILSecurityAction * byte[]`.
- `ILSecurityDecls` (internal) — `AsList: unit -> ILSecurityDecl list`.
- `ILSecurityDeclsStored` (internal).
- `PInvokeCallingConvention` (internal) — None | Cdecl | Stdcall | Thiscall | Fastcall | WinApi.
- `PInvokeCharEncoding` (internal) — None | Ansi | Unicode | Auto.
- `PInvokeCharBestFit` (internal) — UseAssembly | Enabled | Disabled.
- `PInvokeThrowOnUnmappableChar` (internal) — UseAssembly | Enabled | Disabled.
- `PInvokeMethod` (internal) — `{ Where: ILModuleRef; Name; CallingConv; CharEncoding; NoMangle; LastError; ThrowOnUnmappableChar; CharBestFit }`.
- `ILOverridesSpec` (internal) — `OverridesSpec of ILMethodRef * ILType`; `MethodRef`, `DeclaringType`.
- `MethodBody` (union) — `IL of InterruptibleLazy<ILMethodBody>` | `PInvoke of Lazy<PInvokeMethod>` | Abstract | Native | NotAvailable.
- `ILGenericParameterDef` — `{ Name; Constraints: ILTypes; Variance: ILGenericVariance; HasReferenceTypeConstraint; HasNotNullableValueTypeConstraint; HasDefaultConstructorConstraint; HasAllowsRefStruct; CustomAttrsStored; MetadataIndex }`; `CustomAttrs`.
- `ILGenericParameterDefs` = `ILGenericParameterDef list`.
- `ILMethodDef` — `Name; Attributes: MethodAttributes; ImplAttributes: MethodImplAttributes; CallingConv; Parameters: ILParameters; Return: ILReturn; Body: MethodBody; SecurityDecls; IsEntryPoint; GenericParams; CustomAttrs; MetadataIndex; CustomAttrsStored; ParameterTypes: ILTypes`; plus accessors: `IsIL`, `Code: ILCode option`, `Locals`, `MaxStack`, `IsZeroInit`, `IsClassInitializer`, `IsConstructor`, `IsStatic`, `IsNonVirtualInstance`, `IsVirtual`, `IsFinal`, `IsNewSlot`, `IsCheckAccessOnOverride`, `IsAbstract`, `MethodBody: ILMethodBody`, `GetCallingSignature`, `Access: ILMemberAccess`, `IsHideBySig`, `IsSpecialName`, `IsUnmanagedExport`, `IsReqSecObj`, `HasSecurity`, `IsManaged`, `IsForwardRef`, `IsInternalCall`, `IsPreserveSig`, `IsSynchronized`, `IsNoInline`, `IsAggressiveInline`, `IsMustRun`; internal `With` + `WithSpecialName/WithHideBySig/WithFinal/WithAbstract/WithVirtual/WithAccess/WithNewSlot/WithSecurity/WithPInvoke/WithPreserveSig/WithSynchronized/WithNoInlining/WithAggressiveInlining/WithRuntime`.
- `ILMethodDefs` (sealed class, `inherit DelayInitArrayMap<ILMethodDef, string, ILMethodDef list>`) — `AsArray`, `AsList`, `FindByName`, `TryFindInstanceByNameAndCallingSignature`.
- `ILFieldDef`, `ILFieldDefs`.
- `ILEventDef`, `ILEventDefs`.
- `ILPropertyDef`, `ILPropertyDefs`.
- `ILMethodImplDef`, `ILMethodImplDefs`.
- `ILTypeDefLayout` (union) — Auto | Sequential | Explicit.
- `ILTypeDefLayoutInfo` (internal).
- `ILTypeInit` (union) — Init | NoInit.
- `ILDefaultPInvokeEncoding` (union) — BestFit | NoBestFit.
- `ILTypeDefAccess` (union) — NotAccessible | Internal | Public.
- `ILTypeDefs` (sealed class, `inherit DelayInitArrayMap<ILTypeDef, string, ILTypeDef list>`) — `AsArray`, `AsList`, `FindByName`, etc.
- `ILTypeDefAdditionalFlags` (flags) — AbstractClass | SealedClass | Class | Interface | Struct | Forwarder; active pattern `(|HasFlag|_|)`.
- `ILTypeDef` — `Name; Access: ILTypeDefAccess; Attributes...; Namespace; Layout: ILTypeDefLayout; GenericParams; Extends: ILType option; InterfaceImplementations: InterfaceImpl[]; Fields: ILFieldDefs; Methods: ILMethodDefs; Events: ILEventDefs; Properties: ILPropertyDefs; MethodImpls: ILMethodImplDefs; CustomAttrs; SecurityDecls; NestedTypes: ILTypeDefs; ExportedTypes: ILNestedExportedTypes; TypeInit: ILTypeInit; DefaultPInvokeEncoding: ILDefaultPInvokeEncoding; AdditionalFlags: ILTypeDefAdditionalFlags; CustomSecurityDeclsStored; CustomAttrsStored; ...` (see `il.fsi`:1574).
- `ILPreTypeDef`, `ILPreNamespace`.
- `ILPreTypeDefImpl` (internal), `ILTypeDefStored` (internal).
- `ILNestedExportedTypes` (sealed class), `ILNestedExportedType`, `ILExportedTypeOrForwarder` (union), `ILExportedTypesAndForwarders` (sealed class).
- `ILResourceAccess` (internal) — Public | Private.
- `ILResourceLocation` (internal) — Embedded | Manifest.
- `ILResource` (internal) — `{ Name; Location: ILResourceLocation; Access: ILResourceAccess; Data: Lazy<byte[]> }`.
- `ILResources` (sealed class).
- `ILAssemblyLongevity` (union) — Strong | Weak | NotStrong.
- `ILAssemblyManifest` — `Flags; Version: ILVersionInfo; Name: string; PublicAndOptionalKey: byte[] option; Culture: string; NestedExportedTypes: ILNestedExportedTypes; ManifestResources: ILResources; Files: (string * byte[] option) list; TypeForwards: ILExportedTypesAndForwarders; CustomAttrs`.
- `ILNativeResource` — `{ Name; Language; Data: Lazy<byte[]> }`.
- `ILModuleDef` — `Name; IsDLL; Manifest: ILAssemblyManifest option; TypeDefs: ILTypeDefs; Resources: ILResources; CustomAttrs; ...` (see `il.fsi`:1933).
- `ILGlobals` (internal) — the global type table: `PrimaryAssembly, PrimaryPlatform, Version, StringTy, ObjectTy, ArrayTy, ...` (see `il.fsi`:2017).
- `PrimaryAssemblyILGlobals` (val) — the default `ILGlobals` instance.
- `ILGenericArgsList` (internal) = `ILType list`.
- `ILLocalsAllocator` (internal).
- `ILEnumInfo` (internal) — `{ UtcType; FieldDefs }`.
- `ILEventRef` (internal), `ILPropertyRef` (internal).
- `ILReferences` — `{ AssemblyRefs: ILAssemblyRef[]; ... }`.

**Public API surface (selected vals)** — 221 `val` bindings in the module. Grouping:
- Type constructors: `mkILGlobals`, `mkILTyvarTy`, `mkILNestedTyRef`, `mkILTyRef`, `mkILTyRefInTyRef`, `mkILNonGenericTySpec`, `mkILTySpec`, `mkILTy`, `mkILNamedTy`, `mkILBoxedTy`, `mkILValueTy`, `mkILNonGenericBoxedTy`, `mkILNonGenericValueTy`, `mkILBoxedType`, `mkILArrTy`, `mkILArr1DTy`, `isILArrTy`, `destILArrTy`, `mkILMethRef`, `mkILMethSpec`, `mkILMethSpecForMethRefInTy`, `mkILInstanceMethSpecInTy`, `mkILNonGenericInstanceMethSpecInTy`, `mkILStaticMethSpecInTy`, `mkILNonGenericStaticMethSpecInTy`, `mkILCtorMethSpecForTy`, `mkILNonGenericCtorMethSpec`, `mkILFieldRef`, `mkILFieldSpec`, `mkILFieldSpecInTy`, `mkILCallSig`, `mkILFormalBoxedTy`, `mkILFormalNamedTy`, `mkILFormalTypars`, `mkILFormalGenericArgs`, `mkILSimpleTypar`, `stripILGenericParamConstraints`.
- Instruction constructors: `mkLdcInt32`, `mkLdcLong`, `mkLdfld`, `mkLdsfld`, `mkLdflda`, `mkLdsflda`, `mkLdobj`, `mkStobj`, `mkLdstr`, `mkBr`, `mkJmp`, `mkBrcmp`, `mkSwitch`, `mkRet`, `mkLdarg0`, `mkLdarg1`, `mkLdarg2`, `mkLdarg3`, `mkLdarga0`, `mkLdarga1`, `mkLdarga2`, `mkLdarga3`, `mkLdarg`, `mkLdarga`, `mkStarg`, `mkLdloc`, `mkStloc`, `mkLdloca`, `mkLdind`, `mkStind`, `mkLdcInt32`, `mkLdcLong`, `mkLdcSingle`, `mkLdcDouble`, `mkCall`, `mkNormalCall`, `mkCallvirt`, `mkNormalCallvirt`, `mkCallconstraint`, `mkNewobj`, `mkNormalNewobj`, `mkLdftn`, `mkLdvirtftn`, `mkThrow`, `mkReThrow`, `mkEndFinally`, `mkEndFilter`, `mkLeave`, `mkIsinst`, `mkUnBox`, `mkUnboxAny`, `mkCastclass`, `mkLdlen`, `mkLdelem`, `mkStelem`, `mkLdelema`, `mkLdelemAny`, `mkStelemAny`, `mkNewarr`, `mkInitobj`, `mkCpobj`, `mkSizeOf`, `mkRefanytype`, `mkRefanyval`, `mkLdtoken`, `mkInitblk`, `mkCpblk`, `mkArglist`, `mkLocalloc`, `mkNop`, `mkBreak`, `mkDup`, `mkPop`, `mkRet`, `mkRetVoid`, `mkSeqpoint`, `mkSeqDebugInfo`, `mkSeqPoint`.
- Active patterns: `(|ILFieldInstr|_|)`.
- Rescope helpers: `rescopeILScopeRef`, `rescopeILTypeRef`, `rescopeILTypeSpec`, `rescopeILType`, `rescopeILMethodRef`, `rescopeILFieldRef`.
- Name parsing: `splitNamespace`, `splitILTypeName`, `splitILTypeNameWithPossibleStaticArguments`, `splitTypeNameRight`, `typeNameForGlobalFunctions`, `isTypeNameForGlobalFunctions`.
- Type kind helpers: `typeKindByNames`, `isILObjectTy`, `isILStringTy`, `isILInt32Ty`, etc. (16 of them: SByte/Byte/Int16/UInt16/Int32/UInt32/Int64/UInt64/IntPtr/UIntPtr), `isILBoolTy`, `isILCharTy`, `isILTypedReferenceTy`, `isILSingleTy`, `isILDoubleTy`, `stripILModifiedFromTy`, `instILTypeAux`, `instILType`, `getTyOfILEnumInfo`, `computeILEnumInfo`, `compareILVersions`, `parseILVersion`, `formatILVersion`, `sha1HashInt64`, `sha1HashBytes`, `ecmaPublicKey`.
- Well-known type name constants: `tname_String`, `tname_Type`, `tname_Bool`.
- Module/assembly helpers: `mkILSimpleModule`, `mkRefForNestedILTypeDef`, `mkRefForILMethod`, `mkRefForILField`, `mkRefToILMethod`, `mkRefToILField`, `mkRefToILAssembly`, `mkRefToILModule`, `mkILResources`, `mkILTypeDefsOfNamespace`, `mkILTypeDefsGroupedComputed`, `addILTypeDef`, `mkTypeForwarder`, `mkILNestedExportedTypes`, `mkILNestedExportedTypesLazy`, `mkILExportedTypes`, `mkILExportedTypesLazy`, `emptyILResources`.
- Compute helpers: `computeILRefs`, `emptyILRefs`, `NoMetadataIdx`.

**Significant notes**
- `ILMethodDefs` / `ILTypeDefs` / `ILNestedExportedTypes` / `ILExportedTypesAndForwarders` are `DelayInitArrayMap` (name-indexed, lazy-initialized) collections — this is how the binary reader keeps its metadata "relative" to each module (see `ilread.fsi`).
- `ILAttribute` can be `Encoded` (raw blob, e.g. read from binary) or `Decoded` (parsed args); `decodeILAttribData` performs the conversion.
- `ILGlobals` is the per-assembly "primary type table" — String, Object, Array, etc. — used to canonicalize the well-known types.
- The module is `module rec` so that `ILX` (`ilx.fs`) can reference the types while the types themselves reference `ILX` types in their records.

**Cross-references**
- `il.fs` (implementation), `ilx.fs` (ILX extensions), `ilbinary.fs` (opcode / table-name constants), `ilread.fs` (binary reader), `ilwrite.fs` (binary writer), `ilreflect.fs` (Reflection.Emit writer), `ilmorph.fs` (morphism functions), `ilascii.fs` (ASCII instruction tables)

# ilbinary.fsi

**Purpose**
Shared binary constants and small types used by both the binary IL reader (`ilread.fs`) and writer (`ilwrite.fs`). Provides the ECMA-335 metadata `TableName`, all eleven coded-index `Tag` structs with their constants and tag constructors, the ECMA-335 element-type codes (`et_*`), the full set of `i_*` IL opcode constants, native-type / variant-type / security-action maps, and the CorILMethod flags and ExceptionClause opcodes.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.BinaryConstants`)

**Structs declared**
- `TableName` — `{ Index: int }` with `FromIndex`; one value per ECMA-335 metadata table (`TableNames.Module`, `TableNames.TypeRef`, `TypeDef`, `Field`, `FieldPtr`, `Method`, `MethodPtr`, `Param`, `ParamPtr`, `InterfaceImpl`, `MemberRef`, `Constant`, `CustomAttribute`, `FieldMarshal`, `Permission`, `ClassLayout`, `FieldLayout`, `StandAloneSig`, `EventMap`, `EventPtr`, `Event`, `PropertyMap`, `PropertyPtr`, `Property`, `MethodSemantics`, `MethodImpl`, `ModuleRef`, `TypeSpec`, `ImplMap`, `FieldRVA`, `ENCLog`, `ENCMap`, `Assembly`, `AssemblyProcessor`, `AssemblyOS`, `AssemblyRef`, `AssemblyRefProcessor`, `AssemblyRefOS`, `File`, `ExportedType`, `ManifestResource`, `Nested`, `GenericParam`, `GenericParamConstraint`, `MethodSpec`, `UserStrings`).
- Coded-index tag structs (each a `of int32` with a `Tag` member):
  - `TypeDefOrRefTag` (`tdor_TypeDef/TypeRef/TypeSpec`)
  - `HasConstantTag` (`hc_FieldDef/ParamDef/Property`)
  - `HasCustomAttributeTag` (20 `hca_*` constants; note `hca_MethodSpec/hca_GenericParamConstraint` are present on the .fs but omitted in the .fsi tail)
  - `HasFieldMarshalTag` (`hfm_FieldDef/ParamDef`)
  - `HasDeclSecurityTag` (`hds_TypeDef/MethodDef/Assembly`)
  - `MemberRefParentTag` (`mrp_TypeRef/ModuleRef/MethodDef/TypeSpec`)
  - `HasSemanticsTag` (`hs_Event/Property`)
  - `MethodDefOrRefTag` (`mdor_MethodDef/MemberRef`)
  - `MemberForwardedTag` (`mf_FieldDef/MethodDef`)
  - `ImplementationTag` (`i_File/AssemblyRef/ExportedType`)
  - `CustomAttributeTypeTag` (`cat_MethodDef/MemberRef`)
  - `ResolutionScopeTag` (`rs_Module/ModuleRef/AssemblyRef/TypeRef`)
  - `TypeOrMethodDefTag` (`tomd_TypeDef/MethodDef`)
- `mk*Tag` constructors (e.g. `mkTypeDefOrRefOrSpecTag: int32 -> TypeDefOrRefTag`) for each coded index.

**Key binding groups (one-line descriptions)**
- `sortedTableInfo: (TableName * int) list` — tables that must be sorted by first column, with sort order.
- Element-type codes: `et_END, et_VOID, et_BOOLEAN, et_CHAR, et_I1/U1/I2/U2/I4/U4/I8/U8/R4/R8, et_STRING, et_PTR, et_BYREF, et_VALUETYPE, et_CLASS, et_VAR, et_ARRAY, et_WITH, et_TYPEDBYREF, et_I, et_U, et_FNPTR, et_OBJECT, et_SZARRAY, et_MVAR, et_CMOD_REQD, et_CMOD_OPT, et_SENTINEL, et_PINNED`.
- Opcode constants: `i_nop, i_break, i_ldarg_0..3, i_ldloc_0..3, i_stloc_0..3, i_ldarg_s, i_ldarga_s, i_starg_s, i_ldloc_s, i_ldloca_s, i_stloc_s, i_ldnull, i_ldc_i4_m1..8, i_ldc_i4_s, i_ldc_i4, i_ldc_i8, i_ldc_r4, i_ldc_r8, i_dup, i_pop, i_jmp, i_call, i_calli, i_ret, i_br_s, ...` (full ECMA-335 II.13 opcode set including `i_unaligned/volatile/constrained/readonly/tail`, `i_ldtoken`, `i_callvirt`, `i_newobj`, `i_box`, `i_newarr`, `i_ldlen`, `i_ldelema`, `i_ldelem_*`, `i_stelem_*`, `i_refanyval`, `i_mkrefany`, `i_ldftn`, `i_ldvirtftn`, `i_ldarga`, `i_starga`, `i_ldloca`, `i_localloc`, `i_endfilter`, `i_constrained`, `i_readonly`, `i_tail`, `i_initobj`, `i_cpblk`, `i_initblk`, `i_rethrow`, `i_sizeof`, `i_refanytype`, `i_ldelem_any`, `i_stelem_any`, `i_unbox_any`, `i_switch`, `i_br*`, `i_br*_un`, `i_brtrue/un`, `i_bge/un`, `i_bgt/un`, `i_ble/un`, `i_blt/un`, `i_bne/un`, `i_ceq, i_cgt, i_cgt_un, i_clt, i_clt_un`, `i_leave`, `i_leave_s`, `i_nop`...).
- `noArgInstrs: Lazy<(int * ILInstr) list>`, `isNoArgInstr: ILInstr -> bool`.
- `ILCmpInstrMap / ILCmpInstrRevMap: Lazy<Dictionary<ILComparisonInstr, int>>` — ECMA-335 → internal comparison opcodes and back.
- Native types: `nt_VOID, nt_BOOLEAN, nt_I1..nt_R8, nt_SYSCHAR, nt_VARIANT, nt_CURRENCY, nt_PTR, nt_DECIMAL, nt_DATE, nt_BSTR, nt_LPSTR, nt_LPWSTR, nt_LPTSTR, nt_FIXEDSYSSTRING, nt_OBJECTREF, nt_IUNKNOWN, nt_IDISPATCH, nt_STRUCT, nt_INTF, nt_SAFEARRAY, nt_FIXEDARRAY, nt_INT, nt_UINT, nt_NESTEDSTRUCT, nt_BYVALSTR, nt_ANSIBSTR, nt_TBSTR, nt_VARIANTBOOL, nt_FUNC, nt_ASANY, nt_ARRAY, nt_LPSTRUCT, nt_CUSTOMMARSHALER, nt_ERROR, nt_MAX`.
- Variant types (`vt_EMPTY, vt_NULL, vt_I2, vt_I4, vt_R4, vt_R8, vt_CY, vt_DATE, vt_BSTR, vt_DISPATCH, vt_ERROR, vt_BOOL, vt_VARIANT, vt_UNKNOWN, vt_DECIMAL, vt_I1, vt_UI1, vt_UI2, vt_UI4, vt_I8, vt_UI8, vt_INT, vt_UINT, vt_VOID, vt_HRESULT, vt_PTR, vt_SAFEARRAY, vt_CARRAY, vt_USERDEFINED, vt_LPSTR, vt_LPWSTR, vt_RECORD, vt_FILETIME, vt_BLOB, vt_STREAM, vt_STORAGE, vt_STREAMED_OBJECT, vt_STORED_OBJECT, vt_BLOB_OBJECT, vt_CF, vt_CLSID, vt_VECTOR, vt_ARRAY, vt_BYREF`).
- Maps: `ILNativeTypeMap/RevMap`, `ILVariantTypeMap/RevMap`, `ILSecurityActionMap/RevMap`.
- CorILMethod flags: `e_CorILMethod_TinyFormat`, `e_CorILMethod_FatFormat`, `e_CorILMethod_FormatMask`, `e_CorILMethod_MoreSects`, `e_CorILMethod_InitLocals`, `e_CorILMethod_Sect_EHTable`, `e_CorILMethod_Sect_FatFormat`, `e_CorILMethod_Sect_MoreSects`.
- Exception clause kinds: `e_COR_ILEXCEPTION_CLAUSE_EXCEPTION/FILTER/FINALLY/FAULT`.
- Calling-convention constants: `e_IMAGE_CEE_CS_CALLCONV_FASTCALL/STDCALL/THISCALL/CDECL/VARARG`, `e_IMAGE_CEE_CS_CALLCONV_FIELD/LOCAL_SIG/GENERICINST/PROPERTY/INSTANCE/INSTANCE_EXPLICIT/GENERIC`.

**Cross-references**
- `il.fs` (ILInstr, ILComparisonInstr, ILNativeType, ILNativeVariant, ILSecurityAction)
- `ilbinary.fs` (implementation)
- `ilread.fs`, `ilwrite.fs`, `DeltaIndexSizing.fs`, `DeltaTableLayout.fs`, `DeltaMetadataEncoding.fs`, `DeltaMetadataSerializer.fs` (all consumers of the table/tag/opcode constants)

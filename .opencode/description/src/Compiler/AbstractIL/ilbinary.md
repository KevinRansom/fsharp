# ilbinary.fs

**Purpose**
Implementation of the `BinaryConstants` module shared by both the binary IL reader (`ilread.fs`) and the binary IL writer (`ilwrite.fs`). Defines the ECMA-335 metadata `TableName` values, the eleven coded-index tag structs with their constants and tag constructors, and the constant values used throughout metadata emission and reading: element-type codes, the full ECMA-335 IL opcode set, native-type / variant-type maps, the CorILMethod flags and exception-clause constants, and the managed calling-convention flags.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.BinaryConstants`)

**Structs declared**
- `TableName(idx: int)` — `{ Index }` + `FromIndex n`; the 45 ECMA-335 metadata tables (Module = 0 through GenericParamConstraint = 44; `UserStrings = 0x70` — Partition III userstring token encoding).
- Coded-index tag structs (each `of int32` with a `Tag` member):
  - `TypeDefOrRefTag` (`tdor_TypeDef/TypeRef/TypeSpec`)
  - `HasConstantTag` (`hc_FieldDef=0x0`, `hc_ParamDef=0x1`, `hc_Property=0x2`)
  - `HasCustomAttributeTag` (22 values: `hca_MethodDef..hca_MethodSpec`, including `hca_GenericParam=0x13`, `hca_GenericParamConstraint=0x14`, `hca_MethodSpec=0x15`)
  - `HasFieldMarshalTag` (`hfm_FieldDef/ParamDef`)
  - `HasDeclSecurityTag` (`hds_TypeDef/MethodDef/Assembly`)
  - `MemberRefParentTag` (`mrp_TypeRef=0x1`/`mrp_ModuleRef=0x2`/`mrp_MethodDef=0x3`/`mrp_TypeSpec=0x4`)
  - `HasSemanticsTag` (`hs_Event=0x0`/`hs_Property=0x1`)
  - `MethodDefOrRefTag` (`mdor_MethodDef/MemberRef/MethodSpec` — note 0x2 present in .fs, absent in .fsi)
  - `MemberForwardedTag` (`mf_FieldDef/MethodDef`)
  - `ImplementationTag` (`i_File/AssemblyRef/ExportedType`)
  - `CustomAttributeTypeTag` (`cat_MethodDef=0x2`/`cat_MemberRef=0x3`)
  - `ResolutionScopeTag` (`rs_Module/ModuleRef/AssemblyRef/TypeRef`)
  - `TypeOrMethodDefTag` (`tomd_TypeDef/MethodDef`)
- `mk*Tag` constructors for each of the above (validate against the allowed set and return the cached constant when possible — "nb. avoid reallocation").
- `sortedTableInfo: (TableName * int) list` — ECMA-335 II.22 sorted tables with sort column: InterfaceImpl(0), Constant(1), CustomAttribute(0), FieldMarshal(0), Permission(1), ClassLayout(2), FieldLayout(1), MethodSemantics(2), MethodImpl(0), ImplMap(1), FieldRVA(1), Nested(0), GenericParam(2), GenericParamConstraint(0).

**Public API surface (selected)**
- Element-type codes: `et_END=0x00` through `et_PINNED=0x1B` (all the `et_*` BYTE constants from ECMA-335 II.23.1.16).
- Full ECMA-335 IL opcode set: `i_nop=0x00, i_break=0x01, i_ldarg_0..3, i_ldloc_0..3, i_stloc_0..3, i_ldarg_s, i_ldarga_s, i_starg_s, i_ldloc_s, i_ldloca_s, i_stloc_s, i_ldnull, i_ldc_i4_m1..8, i_ldc_i4_s, i_ldc_i4, i_ldc_i8, i_ldc_r4, i_ldc_r8, i_dup, i_pop, i_jmp, i_call, i_callvirt, i_calli, i_ret, i_br_s.../br, ... brfalse/brtrue/un, beq/un, bge/un, bgt/un, ble/un, blt/un, bne_un/un, br, br_s, ... (full branch set), i_switch, i_ldind_* (all data types), i_stind_*, i_add..i_sub/un, i_mul/ovf/ovf_un, i_rem/un, i_and, i_or, i_xor, i_shl, i_shr, i_shr_un, i_neg, i_not, i_conv_i1/i2/i4/i8/r4/r8/u4/u8/un/i, i_conv_ovf_*_un, i_conv_ovf_*, i_cpobj, i_ldobj, i_ldstr, i_newobj, i_castclass, i_isinst, i_unbox, i_throw, i_ldfld, i_ldflda, i_stfld, i_ldsfld, i_ldsflda, i_stsfld, i_stobj, i_box, i_newarr, i_ldlen, i_ldelema, i_ldelem_*, i_stelem_*, i_refanyval, i_ckfinite, i_mkrefany, i_ldtoken, i_ldftn, i_ldvirtftn, i_ldarg, i_ldarga, i_starg, i_ldloc, i_ldloca, i_stloc, i_localloc, i_endfilter, i_unaligned, i_volatile, i_constrained, i_readonly, i_tail, i_initobj, i_cpblk, i_initblk, i_rethrow, i_sizeof, i_refanytype, i_ldelem_any, i_stelem_any, i_unbox_any`.
- `noArgInstrs: Lazy<(int * ILInstr) list>` — the instruction set with no type/operand arguments, keyed by opcode for quick lookup.
- `isNoArgInstr: ILInstr -> bool`.
- `ILCmpInstrMap / ILCmpInstrRevMap: Lazy<Dictionary<ILComparisonInstr, int>>` — ECMA-335 `i_ceq/cgt/cgt_un/clt/clt_un` ↔ internal `ILComparisonInstr` (CmpEq/CmpGt/CmpLt) maps.
- Native-type codes `nt_VOID..nt_MAX` (ECMA-335 II.23.1.18) and variant-type codes `vt_EMPTY..vt_BYREF` (ECMA-335 I.5.5).
- `ILNativeTypeMap/RevMap: Lazy<(byte * ILNativeType) list>` — byte ↔ `ILNativeType` maps for field-marshalling.
- `ILVariantTypeMap/RevMap: Lazy<(ILNativeVariant * int32) list>`.
- `ILSecurityActionMap/RevMap: Lazy<(ILSecurityAction * int) list>`.
- CorILMethod flags: `e_CorILMethod_TinyFormat=0x2`, `e_CorILMethod_FatFormat=0x3`, `e_CorILMethod_FormatMask=0x3`, `e_CorILMethod_MoreSects=0x8`, `e_CorILMethod_InitLocals=0x10`, `e_CorILMethod_Sect_EHTable=0x1`, `e_CorILMethod_Sect_FatFormat=0x2`, `e_CorILMethod_Sect_MoreSects=0x40`.
- Exception clause kinds: `e_COR_ILEXCEPTION_CLAUSE_EXCEPTION=1`, `e_COR_ILEXCEPTION_CLAUSE_FILTER=2`, `e_COR_ILEXCEPTION_CLAUSE_FINALLY=6`, `e_COR_ILEXCEPTION_CLAUSE_FAULT=4`.
- Calling-convention constants (calling-convention flags on signatures): `e_IMAGE_CEE_CS_CALLCONV_FASTCALL=1, STDCALL=2, THISCALL=3, CDECL=4, VARARG=8`, `FIELD=0x20, LOCAL_SIG=0x10, GENERICINST=0x20, PROPERTY=0x10, INSTANCE=0, INSTANCE_EXPLICIT=3, GENERIC=0x10`.

**Significant internal logic**
- `mk*Tag` constructors pattern-match over the valid tag set and return the preallocated struct value for a hit (avoids reallocation); invalid values raise `invalidArg`.
- The sorted-table list is the ECMA-335 II.22 "the following tables are required to be sorted" list; the trailing `EventMap` sort is commented out (observed not in practice).

**Cross-references**
- `ilbinary.fsi` (contract)
- `il.fs` (ILInstr, ILComparisonInstr, ILNativeType, ILNativeVariant, ILSecurityAction)
- `ilread.fs`, `ilwrite.fs`, `DeltaIndexSizing.fs`, `DeltaTableLayout.fs`, `DeltaMetadataEncoding.fs`, `DeltaMetadataSerializer.fs`, `EncMethodDebugInformation.fs` (all consumers)

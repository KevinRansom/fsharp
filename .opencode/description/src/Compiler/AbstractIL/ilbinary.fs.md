# ilbinary.fs

## Pipeline role

Part of the AbstractIL layer, this file defines the binary constants and tag tables shared by the metadata binary reader and writer: ECMA-335 table indices, coded-index tags, ELEMENT_TYPE codes, IL opcode byte values, native-type and variant-type codes, CorILMethod flags, call-convention codes, and the reverse maps used by `ilread.fs`/`ilwrite.fs`. It is the single source of truth for the wire-level encodings (it is the `.fs` implementation behind the `ilbinary.fsi` signature, module `FSharp.Compiler.AbstractIL.BinaryConstants`).

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.BinaryConstants` (module `internal`)
- Uses: `FSharp.Compiler.AbstractIL.IL` (for `ILNativeType`, `ILNativeVariant`, `ILSecurityAction`, `ILConst`, and `ILInstr` constructors such as `I_ret`, `AI_add`, `I_stelem`, `I_ldelem`, `I_stloc`, `I_ldloc`, `I_ldarg`, `AI_conv`, `AI_conv_ovf`, `mkStloc`, `mkLdloc`, `mkLdarg`, `mkLdcInt32`), `Internal.Utilities.Library`.

## Types

- `TableName(idx: int)` — `[<Struct>]`; a metadata table with `Index` and static `FromIndex`. `TableNames` module lists `Module`(0), `TypeRef`(1), `TypeDef`(2), `FieldPtr`(3), `Field`(4), `MethodPtr`(5), `Method`(6), `ParamPtr`(7), `Param`(8), `InterfaceImpl`(9), `MemberRef`(10), `Constant`(11), `CustomAttribute`(12), `FieldMarshal`(13), `Permission`(14), `ClassLayout`(15), `FieldLayout`(16), `StandAloneSig`(17), `EventMap`(18), `EventPtr`(19), `Event`(20), `PropertyMap`(21), `PropertyPtr`(22), `Property`(23), `MethodSemantics`(24), `MethodImpl`(25), `ModuleRef`(26), `TypeSpec`(27), `ImplMap`(28), `FieldRVA`(29), `ENCLog`(30), `ENCMap`(31), `Assembly`(32), `AssemblyProcessor`(33), `AssemblyOS`(34), `AssemblyRef`(35), `AssemblyRefProcessor`(36), `AssemblyRefOS`(37), `File`(38), `ExportedType`(39), `ManifestResource`(40), `Nested`(41), `GenericParam`(42), `MethodSpec`(43), `GenericParamConstraint`(44), plus `UserStrings` = `TableName 0x70` (special encoding of embedded UserString tokens).
- `TypeDefOrRefTag` (`[<Struct>]`) — with values `tdor_TypeDef`(0x0), `tdor_TypeRef`(0x1), `tdor_TypeSpec`(0x2) and `mkTypeDefOrRefOrSpecTag`.
- `HasConstantTag` (`[<Struct>]`) — `hc_FieldDef`(0x0), `hc_ParamDef`(0x1), `hc_Property`(0x2), `mkHasConstantTag`.
- `HasCustomAttributeTag` (`[<Struct>]`) — 22 values `hca_MethodDef`(0x0) .. `hca_MethodSpec`(0x15), `mkHasCustomAttributeTag` (fallback constructs the tag directly).
- `HasFieldMarshalTag` (`[<Struct>]`) — `hfm_FieldDef`(0x0), `hfm_ParamDef`(0x1).
- `HasDeclSecurityTag` (`[<Struct>]`) — `hds_TypeDef`(0x0), `hds_MethodDef`(0x1), `hds_Assembly`(0x2).
- `MemberRefParentTag` (`[<Struct>]`) — `mrp_TypeRef`(0x1), `mrp_ModuleRef`(0x2), `mrp_MethodDef`(0x3), `mrp_TypeSpec`(0x4).
- `HasSemanticsTag` (`[<Struct>]`) — `hs_Event`(0x0), `hs_Property`(0x1).
- `MethodDefOrRefTag` (`[<Struct>]`) — `mdor_MethodDef`(0x0), `mdor_MemberRef`(0x1), `mdor_MethodSpec`(0x2).
- `MemberForwardedTag` (`[<Struct>]`) — `mf_FieldDef`(0x0), `mf_MethodDef`(0x1).
- `ImplementationTag` (`[<Struct>]`) — `i_File`(0x0), `i_AssemblyRef`(0x1), `i_ExportedType`(0x2).
- `CustomAttributeTypeTag` (`[<Struct>]`) — `cat_MethodDef`(0x2), `cat_MemberRef`(0x3), `mkILCustomAttributeTypeTag`.
- `ResolutionScopeTag` (`[<Struct>]`) — `rs_Module`(0x0), `rs_ModuleRef`(0x1), `rs_AssemblyRef`(0x2), `rs_TypeRef`(0x3).
- `TypeOrMethodDefTag` (`[<Struct>]`) — `tomd_TypeDef`(0x0), `tomd_MethodDef`(0x1).

## Values — sorted table info

- `sortedTableInfo` — the CLR V1 sorted bit-vector's per-table sort column: `(InterfaceImpl,0)`, `(Constant,1)`, `(CustomAttribute,0)`, `(FieldMarshal,0)`, `(Permission,1)`, `(ClassLayout,2)`, `(FieldLayout,1)`, `(MethodSemantics,2)`, `(MethodImpl,0)`, `(ImplMap,1)`, `(FieldRVA,1)`, `(Nested,0)`, `(GenericParam,2)`, `(GenericParamConstraint,0)`.

## Values — ELEMENT_TYPE codes (`et_*`)

`et_END`(0x00) through `et_SZARRAY`(0x1D), `et_MVAR`(0x1e), `et_CMOD_REQD`(0x1F), `et_CMOD_OPT`(0x20), `et_SENTINEL`(0x41), `et_PINNED`(0x45).

## Values — IL opcode byte values (`i_*`)

One constant per opcode (0x00 `nop` .. 0x2A `ret`, branch family 0x2B..0x45, ldind/stind family 0x46..0x57, arithmetic 0x58..0x66, conv family 0x67..0x76, 0x79 `unbox`..0x8E `ldlen`, ldelem/stelem 0x90..0xA5, conv.ovf 0xB3..0xBA, 0xC2..0xC6, 0xD0..0xE0, and the two-byte `0xFE**` family: `arglist` 0xFE00, `ceq`..`clt_un` 0xFE01..0xFE05, `ldftn`/`ldvirtftn` 0xFE06/0xFE07, `ldarg`..`stloc` 0xFE09..0xFE0E, `localloc` 0xFE0F, `endfilter` 0xFE11, `unaligned`/`volatile`/`tail` 0xFE12/0xFE13/0xFE14, `initobj` 0xFE15, `constrained` 0xFE16, `cpblk`/`initblk` 0xFE17/0xFE18, `rethrow` 0xFE1A, `sizeof` 0xFE1C, `refanytype` 0xFE1D, `readonly` 0xFE1E).
- `mk_ldc i = mkLdcInt32 i`, `noArgInstrs` (lazy) — maps opcode values to the equivalent one-byte/short-form instruction constructors (`ldc.i4.0..8`, `ldc.i4.m1`, `stloc/ldloc/ldarg.0..3`, arithmetic, conversions, ldelem/stelem, etc.).
- `isNoArgInstr i` — predicate for the same no-operand instructions (used to decide when the short encoding can be used).

## Values — branch instruction maps

- `ILCmpInstrMap` (lazy) — `BI_*` (branch info) to full-opcode for the comparison/branch instructions (`beq`, `bgt[.un]`, `bge[.un]`, `ble[.un]`, `blt[.un]`, `bne_un`, `brfalse`, `brtrue`).
- `ILCmpInstrRevMap` (lazy) — same but to the short (`_s`) opcodes.

## Values — native type codes (`nt_*`)

From corhdr.h: `nt_VOID`(0x1) .. `nt_LPUTF8STR`(0x30), `nt_MAX`(0x50).
- `ILNativeTypeMap` (lazy) — native-type code to `ILNativeType` (Currency, BSTR, LPSTR, LPWSTR, LPTSTR, LPUTF8STR, IUnknown, IDispatch, ByValStr, TBSTR, LPSTRUCT, Interface, Struct, Error, Void, Bool, Int8..UInt64, Int, UInt, ANSIBSTR, VariantBool, Method, AsAny).
- `ILNativeTypeRevMap` (lazy) — reversed.

## Values — variant type codes (`vt_*`)

From hs.h: `vt_EMPTY`(0) .. `vt_BYREF`(0x4000), `vt_ARRAY`(0x2000), `vt_VECTOR`(0x1000).
- `ILVariantTypeMap` (lazy) — `ILNativeVariant` to `vt_*`.
- `ILVariantTypeRevMap` (lazy) — reversed.

## Values — security actions

- `ILSecurityActionMap` (lazy) — `ILSecurityAction` (Request, Demand, Assert, Deny, PermitOnly, LinkCheck, InheritCheck, ReqMin, ReqOpt, ReqRefuse, PreJitGrant, PreJitDeny, NonCasDemand, NonCasLinkDemand, NonCasInheritance, LinkDemandChoice, InheritanceDemandChoice, DemandChoice) to integer codes 0x0001..0x0012.
- `ILSecurityActionRevMap` (lazy) — reversed.

## Values — CorILMethod and exception clause flags

- `e_CorILMethod_TinyFormat`(0x02), `e_CorILMethod_FatFormat`(0x03), `e_CorILMethod_FormatMask`(0x03), `e_CorILMethod_MoreSects`(0x08), `e_CorILMethod_InitLocals`(0x10).
- `e_CorILMethod_Sect_EHTable`(0x1), `e_CorILMethod_Sect_FatFormat`(0x40), `e_CorILMethod_Sect_MoreSects`(0x80).
- `e_COR_ILEXCEPTION_CLAUSE_EXCEPTION`(0x0), `_FILTER`(0x1), `_FINALLY`(0x2), `_FAULT`(0x4).

## Values — call conventions

- `e_IMAGE_CEE_CS_CALLCONV_*`: `CDECL`(0x01), `STDCALL`(0x02), `THISCALL`(0x03), `FASTCALL`(0x04), `VARARG`(0x05), `FIELD`(0x06), `LOCAL_SIG`(0x07), `PROPERTY`(0x08), `GENERICINST`(0x0a), `GENERIC`(0x10), `INSTANCE`(0x20), `INSTANCE_EXPLICIT`(0x40).

## Significant internal logic

- All maps are `lazy` and paired with explicit reverse maps so the reader and writer stay symmetric.
- Tag tables mirror ECMA-335 II.24.2.6; the `mk*Tag` constructors normalize raw integers to the canonical `[<Struct>]` tag wrappers (deduplicated to avoid re-allocation for the common values).
- The opcode constants are the raw CLI byte values; short-form no-arg encodings are derived via `isNoArgInstr` rather than a separate table.
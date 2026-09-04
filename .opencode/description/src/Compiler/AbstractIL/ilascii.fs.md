# ilascii.fs

## Pipeline role

Part of the AbstractIL layer. This module is the ASCII/textual vocabulary shared by the IL assembly printer and the IL disassembler/assembler: it defines tables mapping textual instruction mnemonics (e.g. `ldc.i4.0`, `conv.ovf.u8.un`) to `ILInstr` constructors and back. `ilprint.fs` and `ilpars.fsy`/`illex.fsl` consume these tables.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.AsciiConstants` (module `internal`)
- Uses: `Internal.Utilities.Collections` (for `HashMultiMap`), `Internal.Utilities.Library`, `FSharp.Compiler.AbstractIL.IL` (for `ILInstr`, constructors such as `I_ret`, `AI_add`, `mkLdcInt32`, `I_ldelema`, etc., and `ILConst`).
- Full public module name used elsewhere: `FSharp.Compiler.AbstractIL.AsciiConstants`.

## Values

- `noArgInstrs` (lazy `(string list * ILInstr) list`) — table of parsing and pretty-printing data for the fixed no-argument instructions: canonical short forms (`ldc.i4.0..8`, `ldc.i4.M1`/`m1`, `stloc.0..3`, `ldloc.0..3`, `ldarg.0..3`), `ret`, arithmetic/logic (`add`, `add.ovf[.un]`, `and`, `div[.un]`, `ceq`, `cgt[.un]`, `clt[.un]`, `mul[.ovf[.un]]`, `rem`, `shl`, `shr[.un]`, `sub[.ovf[.un]]`, `xor`, `or`, `neg`, `not`), conversions (`conv.*`, `conv.ovf.*`, `conv.ovf.*.un` over `DT_I1..DT_U`), `ldelem`/`stelem` type forms, stack ops (`ldnull`, `dup`, `pop`), `ckfinite`, `nop`, `break`, `arglist`, `endfilter`, `endfinally`, `refanytype`, `localloc`, `throw`, `ldlen`, `rethrow`.

## DEBUG-only values

- `wordsOfNoArgInstr`, `isNoArgInstr` (module functions, `#if DEBUG`) — built from a `HashMultiMap` inverting `noArgInstrs`.

## Type abbreviations

- `NoArgInstr = unit -> ILInstr`
- `Int32Instr = int32 -> ILInstr`
- `Int32Int32Instr = int32 * int32 -> ILInstr`
- `Int64Instr = int64 -> ILInstr`
- `DoubleInstr = ILConst -> ILInstr`
- `MethodSpecInstr = ILMethodSpec * ILVarArgs -> ILInstr`
- `TypeInstr = ILType -> ILInstr`
- `IntTypeInstr = int * ILType -> ILInstr`
- `ValueTypeInstr = ILType -> ILInstr` (note: different interpretation of types vs `TypeInstr`)
- `StringInstr = string -> ILInstr`
- `TokenInstr = ILToken -> ILInstr`
- `SwitchInstr = ILCodeLabel list * ILCodeLabel -> ILInstr`
- `InstrTable<'T> = (string list * 'T) list`
- `LazyInstrTable<'T> = Lazy<InstrTable<'T>>`

## Functions

- `mk_stind (nm, dt)` / `mk_ldind (nm, dt)` — build `stind.*`/`ldind.*` entries yielding `I_stind (Aligned, Nonvolatile, dt)` / `I_ldind (Aligned, Nonvolatile, dt)`.
- `NoArgInstrs` (lazy table of `NoArgInstr`) — `noArgInstrs` plus `stind.{u,i,i1,i2,i4,i8,u1,u2,u4,u8,r4,r8,ref}`, `ldind.{i,i1,i2,i4,i8,u1,u2,u4,u8,r4,r8,ref}`, `cpblk`, `initblk`.
- `Int64Instrs` — `ldc.i8` (`AI_ldc (DT_I8, ILConst.I8)`).
- `Int32Instrs` — `ldc.i4` and `ldc.i4.s`.
- `Int32Int32Instrs` — `ldlen.multi` (`EI_ldlen_multi`).
- `DoubleInstrs` — `ldc.r4`, `ldc.r8`.
- `StringInstrs` — `ldstr`.
- `TokenInstrs` — `ldtoken`.
- `TypeInstrs` — `ldelema`, `ldelem.any`, `stelem.any`, `newarr`, `castclass`, `ilzero` (`EI_ilzero`), `isinst`, `initobj.any`, `unbox.any`.
- `IntTypeInstrs` — `ldelem.multi`, `stelem.multi`, `newarr.multi`, `ldelema.multi` (rank as first argument).
- `ValueTypeInstrs` — `cpobj`, `initobj`, `ldobj`, `stobj`, `sizeof`, `box`, `unbox`.

## Significant internal logic

- All tables are `lazy` so they are built only on demand, and are keyed as `(string list * constructor)` pairs so both the printer (which needs the word list for a given instruction) and the parser (which needs to look text up) can share one source of truth.
- Mnemonic lists are normalized lists of lowercase tokens; instruction constructors are functions so parameterized forms (`I_ldelema`, `AI_ldc`, ...) can be specialized per table.
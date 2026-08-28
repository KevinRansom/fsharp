# ilascii.fs

**Purpose**
Defines the parsing and pretty-printing tables for the ILASM/ASCII IL instruction set. Each lazy instruction table maps a list of mnemonic words (e.g. `["ldc"; "i4"; "0"]`, `["ldc"; "i8"]`, `["ldstr"]`, `["initblk"]`) to a constructor function that builds the corresponding `ILInstr` node in the abstract IL tree.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.AsciiConstants`)

**TypeDefs declared**
- Delegate types: `NoArgInstr`, `Int32Instr`, `Int32Int32Instr`, `Int64Instr`, `DoubleInstr`, `MethodSpecInstr`, `TypeInstr`, `IntTypeInstr`, `ValueTypeInstr`, `StringInstr`, `TokenInstr`, `SwitchInstr`.
- `InstrTable<'T> = (string list * 'T) list`; `LazyInstrTable<'T> = Lazy<InstrTable<'T>>`.

**Key bindings (one-line descriptions)**
- `noArgInstrs` — lazy list of (mnemonic, `ILInstr`) pairs for no-argument instructions: `ldc i4 0..8/-1`, `stloc/ldloc/ldarg 0..3`, `ret/add/and/div.../ceq/cgt/clt.../conv.../stelem.../ldelem.../mul.../rem.../shl/shr.../sub.../xor/or/neg/not/ldnull/dup/pop/ckfinite/nop/break/arglist/endfilter/endfinally/refanytype/localloc/throw/ldlen/rethrow`.
- `wordsOfNoArgInstr`, `isNoArgInstr` (DEBUG only; built from a `HashMultiMap` over `mk` and mnemonic).
- `mk_stind`, `mk_ldind` — helpers wrapping `I_stind`/`I_ldind` with `Aligned, Nonvolatile`.
- `NoArgInstrs` — composed lazy table: `noArgInstrs` plus `stind/ldind` for all data types plus `cpblk`, `initblk`.
- `Int64Instrs` — `ldc i8` → `AI_ldc(DT_I8, ILConst.I8 x)`.
- `Int32Instrs` — `ldc i4`, `ldc i4.s` → `mkLdcInt32`.
- `Int32Int32Instrs` — `ldlen multi` → `EI_ldlen_multi`.
- `DoubleInstrs` — `ldc r4` / `ldc r8` → `AI_ldc(DT_R4/R8, x)`.
- `StringInstrs` — `ldstr` → `I_ldstr`.
- `TokenInstrs` — `ldtoken` → `I_ldtoken`.
- `TypeInstrs` — `ldelema`, `ldelem any` / `stelem any` / `newarr` / `castclass` / `ilzero` / `isinst` / `initobj any` / `unbox any`.
- `IntTypeInstrs` — rank-n `ldelem multi` / `stelem multi` / `newarr multi` / `ldelema multi` (construct `ILArrayShape.FromRank`).
- `ValueTypeInstrs` — `cpobj` / `initobj` / `ldobj` / `stobj` / `sizeof` / `box` / `unbox`.

**Cross-references**
- `il.fs` (ILInstr, ILConst, ILArrayShape, DT_*, ILToken)
- `ilascii.fsi` (contract), `illex.fsl` (F# lexer source for the ASCII parser)

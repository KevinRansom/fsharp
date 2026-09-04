# ilascii.fsi

**Purpose**
Interface contract for the ILASM/ASCII-IL lexer/pretty-printer tables: typed instruction-table aliases and the lazy instruction tables (`NoArgInstrs`, `Int32Instrs`, `Int32Int32Instrs`, `Int64Instrs`, `DoubleInstrs`, `StringInstrs`, `TokenInstrs`, `TypeInstrs`, `IntTypeInstrs`, `ValueTypeInstrs`) plus, in DEBUG, helper `wordsOfNoArgInstr`/`isNoArgInstr` for instruction reverse lookup.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.AsciiConstants`)

**TypeDefs declared (delegate type aliases)**
- `NoArgInstr = unit -> ILInstr`
- `Int32Instr = int32 -> ILInstr`
- `Int32Int32Instr = int32 * int32 -> ILInstr`
- `Int64Instr = int64 -> ILInstr`
- `DoubleInstr = ILConst -> ILInstr`
- `MethodSpecInstr = ILMethodSpec * ILVarArgs -> ILInstr`
- `TypeInstr = ILType -> ILInstr`
- `IntTypeInstr = int * ILType -> ILInstr`
- `ValueTypeInstr = ILType -> ILInstr` (note: different interpretation of the type arg than `TypeInstr`)
- `StringInstr = string -> ILInstr`
- `TokenInstr = ILToken -> ILInstr`
- `SwitchInstr = ILCodeLabel list * ILCodeLabel -> ILInstr`
- `InstrTable<'T> = (string list * 'T) list`
- `LazyInstrTable<'T> = Lazy<InstrTable<'T>>`

**Public API surface**
- The lazy table values (see Purpose).
- `wordsOfNoArgInstr: ILInstr -> string list` and `isNoArgInstr: ILInstr -> bool` (DEBUG only) — reverse-lookup helpers built from the `noArgInstrs` table.

**Cross-references**
- `ilascii.fs` (implementation), `illex.fsl` (consumes the tables to build `kwdInstrTable`), `ilpars.fsy` (consumes the produced `ILInstr` constructors)

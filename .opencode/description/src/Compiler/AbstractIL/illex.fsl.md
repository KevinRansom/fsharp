# illex.fsl

**Purpose**
F# lexer source (fsl) for the ASCII/ILASM-format IL language parser. Emits the token stream consumed by `ilpars.fsy`: it recognizes punctuation (`,, ., *, !, &, parens, brackets, <, >, ::, +, ...`), integer literals (decimal, hex `0x`, negative), the special `int32[...]` ellipses/array-literal form (`VAL_INT32_ELLIPSES`), floating-point literals, type keywords, instruction keywords (dot-joined like `ldc.i4`, `initobj.any`, `newarr.multi`), and identifiers/dotted names.

**Namespace(s)**
- (fsl file — no explicit namespace; tokens and helpers live in the generated lex module within `FSharp.Compiler.AbstractIL`)

**Key bindings (one-line descriptions)**
- `lexeme`, `lexemeChar` — LexBuffer convenience helpers.
- `unexpectedChar` — raises `Parsing.RecoverableParseError` on illegal characters.
- `keywords` — lazy keyword table for IL type/keyword tokens: `void→VOID, bool, bytearray, char, class, default, explicit, float32, float64, instance, int, int16/32/64/8, method, native, object, string, uint, uint16/32/64/8, unmanaged, unsigned, value, valuetype, vararg`.
- `kwdInstrTable` — `HashMultiMap` combining `keywords` PLUS all `AsciiConstants` lazy instruction tables (NoArg/Int32/Int32Int32/Int64/Double/Type/IntType/ValueType/String/Token) mapping dot-joined mnemonics (e.g. `"ldc.i4"`) to token constructors `INSTR_NONE/INSTR_I/INSTR_I32_I32/INSTR_I8/INSTR_R/INSTR_TYPE/INSTR_INT_TYPE/INSTR_VALUETYPE/INSTR_STRING/INSTR_TOK`.
- `kwdOrInstr s` — lookup keyword or instruction (throws if absent).
- `evalDigit ch` — char → digit value.
- `kwdOrInstrOrId s` — lookup keyword/instruction else `VAL_ID s`.
- `rule token` — the main tokenizer rule described above (with comment on why two-digit hex-looking words are re-interpreted).

**Significant internal logic**
- Instruction keywords are matched as a specific list of base mnemonics followed by `.xxx` suffix (e.g. `conv.r4`, `cgt.un`, `ldind.ref`), keeping the token grammar tight.
- Dotted identifiers are lexed as `VAL_DOTTEDNAME` for fully-qualified type names.

**Cross-references**
- `ilascii.fs` (AsciiConstants tables feeding `kwdInstrTable`)
- `ilpars.fsy` (the parser `kwdOrInstr`/`kwdOrInstrOrId` emit tokens for)

# ilpars.fsy

**Purpose**
Menhir/YACC grammar file for the ASCII/ILASM-format IL type and instruction parser (`.fsy`). Takes the token stream produced by `illex.fsl` and builds an `ILType` (the `ilType` start symbol) or an `ILInstr array` (the `ilInstrs` start symbol) from the abstract IL tree, including the full algebra of type references (class names, generic type args, array bounds, byref/ptr).

**Namespace(s)**
- (fsy file — generated code lives in `FSharp.Compiler.AbstractIL`)

**TypeDefs declared (in the prologue)**
- `ResolvedAtMethodSpecScope<'T>` (union) — `ResolvedAtMethodSpecScope of (ILGenericParameterDefs -> 'T)`; defers resolution of a type against the enclosing generic-parameter context.
- `noMethodSpecScope x`, `resolveMethodSpecScope g x`, `resolveMethodSpecScopeThen g =` — combinators for the deferred scope.
- `resolveCurrentMethodSpecScope obj` — forces the scope using `mkILEmptyGenericParams`.

**Tokens/Non-terminals (selected)**
- `%type` declarations: `name1 : string`, `typ : ILType ResolvedAtMethodSpecScope`, `ilInstrs : ILInstr array`, `ilType : ILType`.
- Start symbols: `ilType: typ EOF`, `ilInstrs: instrs2 EOF`.
- Instruction productions map the `INSTR_*` keyword tokens to `ILInstr` constructors via the typed token values (`($1 ())`, `($1 $2)`, etc.).
- Type productions (`typ:`) cover `STRING`, `OBJECT`, `CLASS typeNameInst`, `VALUETYPE`, array shapes (`typ LBRACK bound list RBRANK`), `typ AMP` (byref), `typ STAR` (ptr), primitive types (`BOOL/INT8..UINT64/NATIVE INT`), and generic type variables `BANG int32` (`!n` → `ILType.TypeVar`).
- Bounds grammar (`bound:`) for multi-dim arrays: `EMPTY, int32, int32 ELLIPSES int32, int32 ELLIPSES, VAL_INT32_ELLIPSES [int32]` — resolving `int32[0...,0...]` and `int32[0...]` forms.
- `className` / `slashedName` — support `name::name` (`DCOLON`) and `a/b/c` (`SLASH`) nested-type names; bracketed `LBRACK name RBRACK` → `ILScopeRef.PrimaryAssembly`, bare → `ILScopeRef.Local`.
- `opt_actual_tyargs` — trailing `<t1, t2, ...>` (resolved through the deferred scope).
- `callConv` / `callKind` — `INSTANCE`/`EXPLICIT`/`DEFAULT`/`VARARG` mapping to `ILThisConvention`/`ILArgConvention`.

**Significant internal logic**
- All nontrivial type results are wrapped as `ResolvedAtMethodSpecScope` so the parser can be used both standalone (empty generic params) and embedded (real params).

**Cross-references**
- `illex.fsl` (token source)
- `ilascii.fs` (INSTR_* token value types and instruction tables)
- `il.fs` (ILType, ILInstr, ILMethodSpec, ILCallingConv, ILArrayShape, PrimaryAssemblyILGlobals)

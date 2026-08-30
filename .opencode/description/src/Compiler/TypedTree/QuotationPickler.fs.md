# QuotationPickler.fs

## Pipeline role

`module internal FSharp.Compiler.QuotationPickler`. Serializes the compiler's expression/type specifications (the `ExprData`/`TypeData` AST subset) into a compact binary format "compatible with those read by Microsoft.FSharp.Quotations", and consequently with the corresponding picklers in FSharp.Core (`QuotationPickler` there). Used to emit reflected definitions (`ReflectedDefinitions`-named resources) and to translate quotations between the compiler's typed tree and `Expr` — the format is stabilized by explicit numeric byte tags for each `CombOp`/`ExprData` case. The pickled payload is a two-phase, string-table-compressed byte buffer.

## Headers, module, opens

- Copyright header (Microsoft, `License.txt`).
- `module internal FSharp.Compiler.QuotationPickler`.
- Opens `System`, `System.Text` (`Encoding.UTF8`), `FSharp.Compiler.IO` (`ByteBuffer`), `Internal.Utilities.Collections` (`HashMultiMap`), `Internal.Utilities.Library.Extras`.

## AST specification types (stable data, not F# typed-tree nodes)

- `mkRLinear mk (vs, body)` — right-linear fold over a binding list (`List.foldBack`).
- `TypeVarData = { tvName: string }`.
- `NamedTypeData = Idx of int | Named of tcName: string * tcAssembly: string` — a type by table index or by name/assembly.
- `TypeCombOp = ArrayTyOp of rank: int | FunTyOp | NamedTyOp of NamedTypeData`.
- `TypeData = VarType of int | AppType of TypeCombOp * TypeData list`.
  - Builders: `mkVarTy`, `mkFunTy (x1,x2)`, `mkArrayTy (n,x)`, `mkILNamedTy (r,l)`.
- `CtorData = { Parent: NamedTypeData; ArgTypes: TypeData list }`.
- `MethodData = { Parent: NamedTypeData; Name: string; ArgTypes: TypeData list; RetType: TypeData; NumGenericArgs: int }`.
- `ValData = { Name: string; Type: TypeData; IsMutable: bool }`.
- `PropInfoData = NamedTypeData * string * TypeData * TypeData list`.
- `CombOp` — the combinator opcode union: `AppOp`, `CondOp`, `ModuleValueOp`/`ModuleValueWOp` (with witness-name + witness count), `LetRecOp`, `LetRecCombOp`, `LetOp`, `RecdMkOp`/`RecdGetOp`/`RecdSetOp`, `SumMkOp`/`SumFieldGetOp`/`SumTagTestOp`, `TupleMkOp`/`TupleGetOp`, `UnitOp`, `BoolOp`/`StringOp`/`SingleOp`/`DoubleOp`/`CharOp`/`SByteOp`/`ByteOp`/`Int16Op`/`UInt16Op`/`Int32Op`/`UInt32Op`/`Int64Op`/`UInt64Op`, `PropGetOp`/`PropSetOp`, `FieldGetOp`/`FieldSetOp`, `CtorCallOp`, `MethodCallOp`/`MethodCallWOp`, `CoerceOp`, `NewArrayOp`, `DelegateOp`, `SeqOp`, `ForLoopOp`, `WhileLoopOp`, `NullOp`, `DefaultValueOp`, `AddressOfOp`, `ExprSetOp`, `AddressSetOp`, `TypeTestOp`, `TryFinallyOp`, `TryWithOp`.

  The W-suffixed ops (`ModuleValueWOp`, `MethodCallWOp`) attach user-instance-resolution constraint witnesses (`nmW`, `nWitnesses`).

- `ExprData` — "Represents specifications of a subset of F# expressions": `AttrExpr of ExprData * ExprData list`, `CombExpr of CombOp * TypeData list * ExprData list`, `VarExpr of int`, `QuoteExpr of ExprData`, `LambdaExpr of ValData * ExprData`, `HoleExpr of TypeData * int`, `ThisVarExpr of TypeData`, `QuoteRawExpr of ExprData`.

## Expression builder functions (`mk*`)

Either simple constructors (`mkVar`, `mkHole`, `mkQuote`, `mkQuoteRaw40`, `mkLambda`) or `CombExpr`-building helpers with the type args on the side:

- `mkApp a b`; `mkCond(x1,x2,x3)`; `mkModuleValueApp(tcref, nm, isProp, tyargs, args)`; `mkModuleValueWApp(…, nmW, nWitnesses, …)`; `mkTuple (ty, x)`; `mkLet ((v,e), b)` — `CombExpr(LetOp, [], [e; mkLambda(v,b)])` preserving source order (nb. comment); `mkUnit ()`; `mkNull ty`; `mkLetRecRaw`/`mkLetRecCombRaw`/`mkLetRec` (bindings converted to nested lambdas feeding `LetRecCombOp`); `mkRecdMk`/`mkRecdGet`/`mkRecdSet`; `mkUnion`/`mkUnionFieldGet`/`mkUnionCaseTagTest`; `mkTupleGet (ty, n, e)`; `mkCoerce`, `mkTypeTest`, `mkAddressOf`, `mkAddressSet`, `mkVarSet` (→`ExprSetOp`), `mkDefaultValue`, `mkThisVar ty`, `mkNewArray (ty, args)`.

  Constant builders all take an explicit type: `mkBool`, `mkString`, `mkSingle`, `mkDouble`, `mkChar`, `mkSByte`, `mkByte`, `mkInt16`, `mkUInt16`, `mkInt32`, `mkUInt32`, `mkInt64`, `mkUInt64` (`CombExpr(<ConstOp> v, [ty], [])`).

  Control/structure builders: `mkSequential (e1,e2)`, `mkIntegerForLoop`, `mkWhileLoop`, `mkTryFinally(e1,e2)`, `mkTryWith(e1, vf, ef, vh, eh)` (handlers become lambdas), `mkDelegate (ty, e)`, `mkPropGet`/`mkPropSet`, `mkFieldGet`/`mkFieldSet`, `mkCtorCall`, `mkMethodCall`, `mkMethodCallW`.

- `mkAttributedExpression(e, attr)` and `isAttributedExpression e` — the `AttrExpr` wrapper held on the side.

## Constants

- `SerializedReflectedDefinitionsResourceNameBase = "ReflectedDefinitions"` — base name for the emitted resource.
- `[<Literal>] PickleBufferCapacity = 100000` — "Arbitrary value" used as the initial `ByteBuffer` capacity.

## `module SimplePickle`

Primitive binary writing over `FSharp.Compiler.IO.ByteBuffer`:

- `Table<'T when 'T: not null>` — string-intern table: `{ tbl: HashMultiMap<'T,int>; mutable rows: 'T list; mutable count: int }` with `Create`, `AsList` (reversed rows), `Count`, `Add` (assigns next index), `FindOrAdd`, `Find`, `ContainsKey`. NOTE: comment says "This should be Dictionary".
- `QuotationPickleOutState = { os: ByteBuffer; ostrings: Table<string> }`.
- Basic writers: `p_byte`, `p_bool`, `p_void`, `p_unit`, `prim_pint32` (4 raw bytes via `Bits.b0..b3`), `p_int32` (CLR-metadata-style compression: `0..0x7F` → 1 byte; `0x80..0x3FFF` → 2 bytes; else `0xFF` prefix + raw 4 — "halves the size of pickled data"), `p_bytes`, `p_memory` (`ReadOnlyMemory<byte>`), `prim_pstring` (UTF8 length-prefixed), `p_int`, and all scalar adapters `p_int8`, `p_uint8`, `p_int16`, `p_uint16`, `puint32`, `p_int64`, `p_uint64`, `p_double`, `p_single`, `p_char` (via `bits_of_float32`/`bits_of_float` `BitConverter` helpers).
- Tuple writers `p_tup2 … p_tup5` and list marker writer `p_list` (0 = end, 1 = cons) — all recursion-friendy for the circular pickling scheme.
- `puniq tbl key st` — prints `tbl.FindOrAdd key`; `p_string` uses the `ostrings` table.
- `pickle_obj p x` — the two-phase driver:
  1. Phase 1: run `p x st1` writing the body into a `ByteBuffer` and interning strings into `st1.ostrings`; capture the string list and phase1 bytes.
  2. Phase 2: write `(stringTab, phase1bytes)` via `p_tup2 (p_list prim_pstring) p_memory` into a fresh state.
  3. Return `byte[]`, disposing both `ByteBuffer`s (they are pooled/array-pool-backed).

## Format-specific writers (after `open SimplePickle`)

- `p_assemblyref = p_string`.
- `p_NamedType` — `Idx n` encodes as `(string n, "")` (so `Named("", "")` round-trips as an index); `Named (nm,a)` as `(nm,a)`.
- `p_tycon` — tag 1 `FunTyOp`, 2 `NamedTyOp`, 3 `ArrayTyOp` (+rank).
- `p_type`/`p_types` — `p_byte 0` for `VarType` (+index), `p_byte 1` for `AppType` (tycon + typed list).
- `p_varDecl`, `p_recdFieldSpec`, `p_ucaseSpec` (each `p_tup2 p_NamedType p_string`), `p_MethodData` (tup5), `p_CtorData` (tup2), `p_PropInfoData` (tup4).
- `p_CombOp` — stable numeric tags 0..51: 0 `CondOp`, 1 `ModuleValueOp`, 2 `LetRecOp`, 3 `RecdMkOp`, 4 `RecdGetOp`, 5 `SumMkOp`, 6 `SumFieldGetOp`, 7 `SumTagTestOp`, 8 `TupleMkOp`, 9 `TupleGetOp`, 10 unused, 11 `BoolOp`, 12 `StringOp`, 13 `SingleOp`, 14 `DoubleOp`, 15 `CharOp`, 16 `SByteOp`, 17 `ByteOp`, 18 `Int16Op`, 19 `UInt16Op`, 20 `Int32Op`, 21 `UInt32Op`, 22 `Int64Op`, 23 `UInt64Op`, 24 `UnitOp`, 25 `PropGetOp`, 26 `CtorCallOp`, 27 unused, 28 `CoerceOp`, 29 `SeqOp`, 30 `ForLoopOp`, 31 `MethodCallOp`, 32 `NewArrayOp`, 33 `DelegateOp`, 34 `WhileLoopOp`, 35 `LetOp`, 36 `RecdSetOp`, 37 `FieldGetOp`, 38 `LetRecCombOp`, 39 `AppOp`, 40 `NullOp`, 41 `DefaultValueOp`, 42 `PropSetOp`, 43 `FieldSetOp`, 44 `AddressOfOp`, 45 `AddressSetOp`, 46 `TypeTestOp`, 47 `TryFinallyOp`, 48 `TryWithOp`, 49 `ExprSetOp`, 50 `MethodCallWOp` (two `MethodData` + witness count), 51 `ModuleValueWOp` (witness name + count first).
- `p_expr` — tags 0..7: `CombExpr` (op + types + expr list), `VarExpr`, `LambdaExpr`, `HoleExpr`, `QuoteExpr`, `AttrExpr`, `ThisVarExpr`, `QuoteRawExpr`.

## Method-base data & public entry points

- `ModuleDefnData = { Module: NamedTypeData; Name: string; IsProperty: bool }`.
- `MethodBaseData = ModuleDefn of ModuleDefnData * (string * int) option | Method of MethodData | Ctor of CtorData` — the `(name, witnesses)` option marks the witness-carrying variants.
- `let pickle = pickle_obj p_expr` — standalone expression pickler.
- `p_MethodBase` — tags 0 (module definition), 1 (method), 2 (ctor), 3 (module definition with witnesses).
- `let PickleDefns = pickle_obj (p_list (p_tup2 p_MethodBase p_expr))` — the top-level "definition bodies" pickler (methods paired with their raw expression bodies).

## Cross-references

- `TypedTree.fs` / `TypedTreePickle.fs` (typed-tree pickling machinery in the same folder; `TypedTreePickle.fs` handles the full tree, this file the quotation subset).
- FSharp.Core's `Microsoft.FSharp.Quotations` reader (format compatibility documented in the file header comment).
- `FSharp.Compiler.IO.ByteBuffer` (output sink).
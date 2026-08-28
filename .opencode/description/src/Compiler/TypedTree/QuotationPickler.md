# QuotationPickler.fs

**Purpose**: Pickles F# quotations (and reflected definitions) into the stable binary quotation format consumed by `Microsoft.FSharp.Quotations` / FSharp.Core's de-pickling. Provides `ExprData`/`TypeData` spec types, `mk*` constructors for building them, and the serialization pipeline (two-phase: expression bytes + a string table, using CLR-metadata-style integer compression) used to emit `ReflectedDefinitionAttribute` payloads and quotation literals.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.QuotationPickler`).

**Declared types**:
- `TypeData` — `VarType of int` | `AppType of TypeCombOp * TypeData list`; `TypeCombOp = ArrayTyOp rank | FunTyOp | NamedTyOp NamedTypeData`.
- `NamedTypeData` — `Idx of int` (F# 4.0+ reference into the embedded table of type definition refs) | `Named of tcName * tcAssembly` (F# 3.0+ named type in an assembly).
- `TypeVarData` — `{ tvName }`.
- `CtorData`, `MethodData`, `ValData`, `PropInfoData`, `ModuleDefnData` — descriptor records for record/union/constructor/method/value references inside a quotation.
- `ExprData` — `AttrExpr` | `CombExpr of CombOp * TypeData list * ExprData list` | `VarExpr` | `QuoteExpr` | `LambdaExpr` | `HoleExpr` | `ThisVarExpr` | `QuoteRawExpr`; `MethodBaseData = ModuleDefn | Method | Ctor`.
- `CombOp` — the big enumeration of all quotation nodes (`AppOp`, `CondOp`, `ModuleValueOp(W)`, `LetRecOp(LetRecCombOp)`, `LetOp`, `RecdMk/GetSetOp`, `SumMkOp/SumFieldGetOp/SumTagTestOp`, `TupleMkOp/TupleGetOp`, literals `BoolOp` … `UInt64Op`, `PropGet/PropSet`, `FieldGet/FieldSet`, `CtorCallOp`, `MethodCallOp(W)`, `CoerceOp`, `NewArrayOp`, `DelegateOp`, `SeqOp`, `ForLoopOp/WhileLoopOp`, `NullOp`, `DefaultValueOp`, `AddressOfOp`, `ExprSetOp/AddressSetOp`, `TypeTestOp`, `TryFinallyOp`, `TryWithOp`).
- `SimplePickle.Table<'T>` — string/dedup table (HashMultiMap + row list + counter); `SimplePickle.QuotationPickleOutState` — `{ os: ByteBuffer; ostrings: Table<string> }`.

**Public API surface** (per .fsi):
- Type constructors: `mkVarTy`, `mkFunTy`, `mkArrayTy`, `mkILNamedTy`.
- Expression constructors: `mkVar`, `mkThisVar`, `mkHole`, `mkApp`, `mkLambda`, `mkQuote`, `mkQuoteRaw40`, `mkCond`, `mkModuleValueApp`, `mkModuleValueWApp`, `mkLetRec`, `mkLet`, `mkRecdMk/Get/Set`, `mkUnion`, `mkUnionFieldGet`, `mkUnionCaseTagTest`, `mkTuple`, `mkTupleGet`, `mkCoerce`, `mkNewArray`, `mkTypeTest`, `mkAddressSet`, `mkVarSet`, `mkUnit`, `mkNull`, `mkDefaultValue`, literals `mkBool/String/Single/Double/Char/SByte/Byte/Int16/UInt16/Int32/UInt32/Int64/UInt64`, `mkAddressOf`, `mkSequential`, `mkIntegerForLoop`, `mkWhileLoop`, `mkTryFinally`, `mkTryWith`, `mkDelegate`, `mkPropGet/Set`, `mkFieldGet/Set`, `mkCtorCall`, `mkMethodCall`, `mkMethodCallW`, `mkAttributedExpression`.
- `pickle: (ExprData -> byte[])`; `isAttributedExpression: ExprData -> bool`; `PickleDefns: ((MethodBaseData * ExprData) list -> byte[])`; `SerializedReflectedDefinitionsResourceNameBase = "ReflectedDefinitions"`.

**Internal helpers**: `SimplePickle` picklers over `ByteBuffer` — `p_byte`, `p_bool`, `p_int32` (CLR-metadata 1/2/4-byte compression, "halves the size of pickled data"), `p_bytes/p_memory`, `p_string` (string-table dedup via `puniq`/`ostrings`), `p_list`, `pickle_obj` (two-phase: phase-1 expression bytes + string table, phase-2 wrapper containing the string table then the bytes, then both buffers disposed). `p_CombOp` / `p_expr` / `p_type` / `p_MethodBase` encode each node with a discriminant byte. `mkRLinear` folds let-rec bindings into nested lambdas.

**Significant internal logic**: Serialization is a binary format with tag-byte discriminated nodes and a shared string table; `Idx` type refs embed the index into the assembly's table of type definition references (F# 4.0+), while `Named` is the legacy (F# 3.0+) form. `mkLetRec` is desugared to `LetRecOp(LetRecCombOp(body::es))` nested under lambdas, i.e. `mkLetRec [v1,e1...; body]` = `let rec (v1..vn) in body`. `mkLet ((v,e),b)` rewrites to `CombExpr(LetOp,[],[e; mkLambda(v,b)])` preserving source order. `QuoteRawExpr`/`mkQuoteRaw40` only work with FSharp.Core 4.4.0.0+. Strings are UTF-8 in the buffer.

**Cross-references**: `QuotationPickler.fsi` (contract), `F# Core Quotations` (consumer of this format), `ReflectedDefinitionAttribute` emission (see `WellKnownAttribs` `ReflectedDefinitionAttribute` flag), `FSharpQuotations.DeBruijn`-style var numbering (`VarExpr of int`).

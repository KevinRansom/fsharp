# QuotationPickler.fsi

**Purpose**: Compilation interface for the quotation pickler — "code to pickle out quotations in the quotation binary format". Declares the spec types (`TypeData`, `ExprData`, `ValData`, `CtorData`, `MethodData`, `ModuleDefnData`, `MethodBaseData`, `PropInfoData`), all the `mk*` expression/type constructors, and the entry points `pickle`, `PickleDefns`, and the `SerializedReflectedDefinitionsResourceNameBase` ("ReflectedDefinitions") resource-name constant.

**Namespace(s)**: `FSharp.Compiler` — `module internal FSharp.Compiler.QuotationPickler`. `#nowarn "1178"` (type providers disabled in this module).

**Declared types (signatures)**:
- `TypeData` (opaque), `TypeVarData = { tvName: string }`
- `NamedTypeData = Idx of int | Named of tcName: string * tcAssembly: string`
- `ExprData` (opaque); `ValData = { Name; Type: TypeData; IsMutable }`
- `CtorData = { Parent; ArgTypes }`; `MethodData = { Parent; Name; ArgTypes; RetType; NumGenericArgs }`; `ModuleDefnData = { Module; Name; IsProperty }`; `MethodBaseData = ModuleDefn | Method | Ctor`
- `PropInfoData = NamedTypeData * string * TypeData * TypeData list`

**Public API surface** (all `mk*` in order of the .fsi):
`mkVarTy`, `mkFunTy`, `mkArrayTy`, `mkILNamedTy`, `mkVar`, `mkThisVar`, `mkHole`, `mkApp`, `mkLambda`, `mkQuote`, `mkQuoteRaw40` (FSharp.Core 4.4.0.0+), `mkCond`, `mkModuleValueApp`, `mkModuleValueWApp`, `mkLetRec`, `mkLet`, `mkRecdMk`, `mkRecdGet`, `mkRecdSet`, `mkUnion`, `mkUnionFieldGet`, `mkUnionCaseTagTest`, `mkTuple`, `mkTupleGet`, `mkCoerce`, `mkNewArray`, `mkTypeTest`, `mkAddressSet`, `mkVarSet`, `mkUnit`, `mkNull`, `mkDefaultValue`, `mkBool`/`mkString`/`mkSingle`/`mkDouble`/`mkChar`/`mkSByte`/`mkByte`/`mkInt16`/`mkUInt16`/`mkInt32`/`mkUInt32`/`mkInt64`/`mkUInt64`, `mkAddressOf`, `mkSequential`, `mkIntegerForLoop`, `mkWhileLoop`, `mkTryFinally`, `mkTryWith`, `mkDelegate`, `mkPropGet`, `mkPropSet`, `mkFieldGet`, `mkFieldSet`, `mkCtorCall`, `mkMethodCall`, `mkMethodCallW`, `mkAttributedExpression`.

**Entry points**:
- `val pickle: (ExprData -> byte[])`
- `val isAttributedExpression: ExprData -> bool`
- `val PickleDefns: ((MethodBaseData * ExprData) list -> byte[])`
- `val SerializedReflectedDefinitionsResourceNameBase: string`

**Notes**: The internal `SimplePickle` module and all serialization internals (`p_*` functions, `ByteBuffer` state, two-phase encoding with a string table) are implementation-only and not exposed by this interface.

**Cross-references**: `QuotationPickler.fs` (implementation), `WellKnownAttribs` (`ReflectedDefinitionAttribute`), FSharp.Core `Quotations` module (de-pickles this format).

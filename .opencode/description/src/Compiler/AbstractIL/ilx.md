# ilx.fs

**Purpose**
The "ILX" extension of the AbstractIL algebra: F# discriminated unions (with helper methods) used by CodeGen to represent the source-level discriminated-union type before erasure (`IlxUnionInfo`, `IlxUnionCase`, `IlxUnionSpec`), and F# closures (lambda closures / thunks) before erasure (`IlxClosureInfo`, `IlxClosureRef`, `IlxClosureSpec`, `IlxClosureLambdas`, `IlxClosureFreeVar`). The types are "pre-erasure" — i.e., they carry the information (case fields, free vars, closure code) that the erasure pass consumes in order to generate the F# `FSharpUnion`/`FSharpFunc` IL.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILX.Types`)

**Types declared (per `ilx.fsi`)**
- `IlxUnionCaseField` (sealed, `new: ILFieldDef -> IlxUnionCaseField`) — one field of a union case; `Name`, `Type`, `ILField`, `LowerName` (a lowercase form for use as a field/parameter name).
- `IlxUnionCase` (record) — `{ altName; altFields: IlxUnionCaseField[]; altCustomAttrs: ILAttributes }`; members: `Name`, `FieldDefs`, `FieldDef idx`, `IsNullary`, `FieldTypes`.
- `IlxUnionHasHelpers` (union) — `NoHelpers | AllHelpers | SpecialFSharpListHelpers | SpecialFSharpOptionHelpers`.
- `IlxUnionRef` (union) — `IlxUnionRef(boxity, ILTypeRef, IlxUnionCase[], IsNullPermitted, HasHelpers)`.
- `IlxUnionSpec` (union) — `IlxUnionSpec of IlxUnionRef * ILGenericArgs`; members: `DeclaringType`, `Boxity`, `TypeRef`, `GenericArgs`, `Alternatives` / `AlternativesArray`, `IsNullPermitted`, `HasHelpers`, `Alternative idx`, `FieldDef idx fidx`.
- `IlxClosureLambdas` (union) — `Lambdas_forall (ILGenericParameterDef, rest) | Lambdas_lambda (ILParameter, rest) | Lambdas_return ILType` — the pre-erasure lambda shape of the closure.
- `IlxClosureApps` (union) — `Apps_tyapp (ILType, rest) | Apps_app (ILType, rest) | Apps_done ILType` — type applications at a callsite.
- `IlxClosureFreeVar` (record) — `{ fvName; fvCompilerGenerated: bool; fvType: ILType }`.
- `IlxClosureRef` (union) — `IlxClosureRef of ILTypeRef * IlxClosureLambdas * IlxClosureFreeVar[]`.
- `IlxClosureSpec` (union) — `IlxClosureSpec of IlxClosureRef * ILGenericArgs * ILType * useStaticField: bool`; static `Create`; members: `TypeRef`, `ILType`, `ClosureRef`, `FormalLambdas`, `FormalFreeVars`, `GenericArgs`, `Constructor : ILMethodSpec`, `GetStaticFieldSpec() : ILFieldSpec`, `UseStaticField : bool`.
- `IlxClosureInfo` (record) — the full pre-erasure closure: `{ cloStructure; cloFreeVars; cloCode: InterruptibleLazy<ILMethodBody>; cloUseStaticField }`.
- `IlxUnionInfo` (record) — the full pre-erasure union: `{ UnionCasesAccessibility; HelpersAccessibility; HasHelpers; GenerateDebugProxies; DebugDisplayAttributes; UnionCases; IsNullPermitted; DebugPoint; DebugImports }`.

**Public API surface (per `ilx.fsi`)**
- `instAppsAux (n) (inst) (apps)` — instantiate a `IlxClosureApps` tree with `inst` (using `instILTypeAux`).
- `destTyFuncApp apps` — deconstruct a single `Apps_tyapp` node.
- `mkILFormalCloRef (gparams) (csig) (useStaticField)` — make a formal (pre-erasure) closure spec.
- `mkLowerName nm` — compute the "lower-case-or-underscore-prefixed" name for a union-case field.
- `actualTypOfIlxUnionField (cuspec) idx fidx` — the actual (instantiated) type of a union-case field.
- `mkILFreeVar (name, compgen, ty)` — make a free var.

**Cross-references**
- `ilx.fsi` (contract), `il.fs` (ILFieldDef, ILType, ILTypeRef, ILGenericArgs, ILMethodBody, ILMethodSpec, ILFieldSpec, ILBoxity, ILMemberAccess, ILAttribute, ILDebugPoint, ILDebugImports, ILAttributes, ...)

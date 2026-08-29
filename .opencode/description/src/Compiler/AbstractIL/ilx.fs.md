# ilx.fs

## Pipeline role

Part of the AbstractIL layer, this module defines the ILX extension of the IL algebra — the F#-specific abstractions embedded in the IL type system: unions (`IlxUnionSpec`), closures/F# functions (`IlxClosureSpec`, `IlxClosureInfo`), and the lambda/application forms that describe the abstract shape of F# function types. ILX-generated method bodies are lowered to plain IL by the code generator (`IlxGen`), and this module exposes the "spec" records that tie the descriptive forms to concrete `ILTypeRef`s.

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.ILX.Types` (module `internal`)
- Uses: `FSharp.Compiler.AbstractIL.IL` (for `ILFieldDef`, `ILAttributes`, `ILType`, `ILTypeRef`, `ILGenericArgs`, `ILBoxity`, `ILGenericParameterDef`, `ILParameter`, `ILMethodBody`, `ILMemberAccess`, `ILAttribute`, `ILDebugPoint`, `ILDebugImports`, plus constructors `mkILNamedTy`, `mkILBoxedType`, `mkILTySpec`, `mkILCtorMethSpecForTy`, `mkILFormalBoxedTy`, `mkILFormalTypars`, `mkILFieldSpecInTy`, `instILType`, `instILTypeAux`, `mkILFormalGenericArgs`), `Internal.Utilities.Library` (for `String.uncapitalize`, `InterruptibleLazy`).

## Functions

- `mkLowerName (nm: string) : string` — computes a field/parameter name for ILX union fields: lowercases the field name, prefixing `_` when the name is already lower-case.

## Types

- `IlxUnionCaseField` (sealed class, wraps an `ILFieldDef`) — the IL field behind one case field of an F# union:
  - Members: `ILField` (the underlying `ILFieldDef`), `Type`, `Name`, `LowerName` (from `mkLowerName`), `ToString()` returning the field name.
- `IlxUnionCase` (record) — one case ("alternative") of an F# union:
  - Fields: `altName: string`, `altFields: IlxUnionCaseField[]`, `altCustomAttrs: ILAttributes`.
  - Members: `FieldDefs`, `FieldDef n`, `Name`, `IsNullary` (no fields), `FieldTypes`, `ToString()`.
- `IlxUnionHasHelpers` (discriminated union) — which compiled helper members a union carries:
  - `NoHelpers`, `AllHelpers`, `SpecialFSharpListHelpers`, `SpecialFSharpOptionHelpers`.
- `IlxUnionRef` (single-case DU) — `IlxUnionRef of boxity: ILBoxity * ILTypeRef * IlxUnionCase[] * bool * IlxUnionHasHelpers`. The `bool` is `hasHelpers`-completion-of-case-list; the last element is the helper set.
- `IlxUnionSpec` (single-case DU with members) — `IlxUnionSpec of IlxUnionRef * ILGenericArgs`, i.e. an instantiated union:
  - Members: `DeclaringType` (the constructed `ILType`), `Boxity`, `TypeRef`, `GenericArgs`, `AlternativesArray`, `IsNullPermitted`, `HasHelpers` (`IlxUnionHasHelpers`), `Alternatives`, `Alternative idx`, `FieldDef idx fidx`, `ToString()`.
- `IlxClosureLambdas` (DU) — the abstract function shape of an F# function type:
  - `Lambdas_forall of ILGenericParameterDef * IlxClosureLambdas` — generic parameter prefix.
  - `Lambdas_lambda of ILParameter * IlxClosureLambdas` — domain parameter prefix.
  - `Lambdas_return of ILType` — codomain (return type).
- `IlxClosureApps` (DU) — the abstract application shape of an F# function type:
  - `Apps_tyapp of ILType * IlxClosureApps`
  - `Apps_app of ILType * IlxClosureApps`
  - `Apps_done of ILType`
- `IlxClosureFreeVar` (record) — a captured variable of a closure:
  - `fvName: string`, `fvCompilerGenerated: bool`, `fvType: ILType`.
- `mkILFreeVar (name, compgen, ty)` — constructs an `IlxClosureFreeVar`.
- `IlxClosureRef` (single-case DU) — `IlxClosureRef of ILTypeRef * IlxClosureLambdas * IlxClosureFreeVar[]`; the unsurrounded description of a closure class.
- `IlxClosureSpec` (single-case DU with members) — `IlxClosureSpec of IlxClosureRef * ILGenericArgs * ILType * useStaticField: bool`; a closure plus its generic instantiation and the `useStaticField` flag (optimization for the closure's environment to be a static field):
  - Members: `TypeRef`, `ILType`, `ClosureRef`, `FormalFreeVars`, `FormalLambdas`, `GenericArgs`.
  - Static member `Create(cloref, inst, useStaticField)` — builds a spec, using `mkILBoxedType (mkILTySpec (tref, inst))` for the IL type.
  - `Constructor` — the closure's constructor method spec (arguments are the free var types).
  - `UseStaticField` — reads the flag.
  - `GetStaticFieldSpec()` — asserts `UseStaticField` and returns the `"@_instance"` field spec of the closure type.
  - `ToString()`.
- `IlxClosureInfo` (record) — the full ILX closure class definition:
  - `cloStructure: IlxClosureLambdas`, `cloFreeVars: IlxClosureFreeVar[]`, `cloCode: InterruptibleLazy<ILMethodBody>` (the compiled body, lazily computed), `cloUseStaticField: bool`.
- `IlxUnionInfo` (record) — the full ILX union class definition:
  - `UnionCasesAccessibility: ILMemberAccess`, `HelpersAccessibility: ILMemberAccess`, `HasHelpers: IlxUnionHasHelpers`, `GenerateDebugProxies: bool`, `DebugDisplayAttributes: ILAttribute list`, `UnionCases: IlxUnionCase[]`, `IsNullPermitted: bool`, `DebugPoint: ILDebugPoint option`, `DebugImports: ILDebugImports option`.
  - `ToString()` returns `"<union info>"`.

## Functions (continued)

- `destTyFuncApp input` — extracts the first type-application step from an `IlxClosureApps`, failing otherwise.
- `instAppsAux n inst apps` / `instLambdasAux n inst lambdas` — recursive generic-instantiation (`instILTypeAux`) of the apps/lambdas forms; the lambda form also instantiates parameter types via record update.
- `mkILFormalCloRef gparams csig useStaticField` — builds a formal closure spec using formal generic args starting at index 0.
- `actualTypOfIlxUnionField (cuspec: IlxUnionSpec) idx fidx` — the instantiated (`instILType`) type of a union case field.

## Significant internal logic

- The `Lambdas_*`/`Apps_*` forms are the abstract description of F# function types before lowering; `IlxClosureSpec`/`IlxUnionSpec` map them to real `ILTypeRef`s so IL can reference closure classes and union types.
- `GetStaticFieldSpec`/`useStaticField` support the optimization where a closure environment is a single static field; `ilx.fs` only provisions the spec, the lowerer decides when to apply it.
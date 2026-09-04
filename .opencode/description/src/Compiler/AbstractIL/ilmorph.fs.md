# ilmorph.fs

## Pipeline role

Part of the AbstractIL layer. This module defines the standard morphisms (structure-preserving transformations) over the IL AST: mapping functions over IL instructions, types, method/field specs, custom attributes, method bodies, and whole type definitions/modules. The `F#` IL producer and various passes use these to rename type references, relocate scopes, substitute type variables, and clone paths of an assembly. It is the implementation behind `FSharp.Compiler.AbstractIL.Morphs` (module `internal`).

## Namespaces and modules

- Module: `FSharp.Compiler.AbstractIL.Morphs`
- Uses: `System.Collections.Generic`, `Internal.Utilities.Library`, `FSharp.Compiler.AbstractIL.IL`.

## Mutable flag

- `morphCustomAttributeData` (mutable bool) with `enableMorphCustomAttributeData()` / `disableMorphCustomAttributeData()` — when enabled, `cattr_ty2ty` attempts to decode/re-encode attribute data so element and named-argument types are also mapped; failures back out to mapping only the method.

## Instruction-code morphisms

- `code_instr2instr f (code: ILCode)` — maps `f` over every instruction (1:1), keeping the code record shape.
- `code_instr2instrs f (code: ILCode)` — maps `f` over instructions *expanding* to instruction lists; rebuilds the label table via an `adjust` dictionary (old instruction index -> new index, from the growing buffer). Uses an oversized dictionary to reduce collisions.
- `code_instr2instr_ty2ty (finstr, fTy) (code: ILCode)` — maps instructions and also rewrites `TypeCatch` exception clauses with `fTy`.

## Type morphisms

- `morphILTypeRefsInILType f x` + `tspec_tref2tref f tspec` — recursively map `f: ILTypeRef -> ILTypeRef` over an `ILType` (applies to `Ptr`, `FunctionPointer` calling signature, `Byref`, `Boxed`, `Value`, `Array` element, `Modified` both typename ref and inner type; `TypeVar` and `Void` unchanged; type specs rebuilt with mapped generic args).
- `ty_scoref2scoref_tyvar2ty (fscope, fTyvar) ty` and companions `tspec_scoref2scoref_tyvar2ty`, `callsig_scoref2scoref_tyvar2ty`, `tys_scoref2scoref_tyvar2ty`, `morphILScopeRefsInILTypeRef fscope` — map scope refs via `fscope` and type variables via `fTyvar` in one pass (used for relocating types across modules and for formal/factual type substitution).
- `callsig_ty2ty f (callsig: ILCallingSignature)` — maps arg/return types of a calling signature.
- `gparam_ty2ty f gf` / `gparams_ty2ty f gfs` — map generic parameter constraints.
- `tys_ty2ty f x` — list map for types.
- `mref_ty2ty f (x: ILMethodRef)` — maps a method ref by rebuilding its enclosing type ref, calling conv, name, generic arity, arg and return types (the enclosing type ref is derived by mapping the boxed declaring type and taking `.TypeRef`).
- `mspec_ty2ty (factualTy, fformalTy) (x: ILMethodSpec)` — maps a method spec: the formal (scope) types of the method ref via `fformalTy (Choice1Of2 x)`, the declaring type and generic args via `factualTy`.
- `fref_ty2ty f fref` — maps a field ref's declaring type ref and field type.
- `fspec_ty2ty (factualTy, fformalTy) fspec` — maps a field spec's field ref (using `fformalTy (Choice2Of2 fspec)`) and declaring type.
- `celem_ty2ty f celem` — maps the type(s) inside `ILAttribElem` attribute elements (`Type`, `TypeRef`, `Array` element type + element list, `Enum` underlying type).
- `cnamedarg_ty2ty f` — maps named-argument `(name, type, isProp, elem)` tuples.
- `cattr_ty2ty f (c: ILAttribute)` — maps a custom attribute's constructor method spec and (when enabled) its decoded element data.
- `cattrs_ty2ty f (cs: ILAttributes)` — maps a whole `ILAttributes` collection.
- `fdef_ty2ty fTyInCtxt (fdef: ILFieldDef)` — maps a field's type and custom attrs.

## Body and member morphisms

- `morphILLocal f l` — maps a local's type.
- `morphILVarArgs f (varargs: ILVarArgs)` — maps varargs option.
- `morphILTypesInILInstr (factualTy, fformalTy) i` — maps types in an instruction, including the token-carrying instructions `I_calli/I_call/I_callvirt/I_callconstraint/I_newobj/I_ldftn/I_ldvirtftn`, field access (`I_ldfld/I_ldsfld/I_ldsflda/I_ldflda/I_stfld/I_stsfld`), and type-operand instructions (`castclass, isinst, initobj, cpobj, stobj, ldobj, box, unbox, unbox_any, ldelem_any, stelem_any, newarr, ldelema, sizeof`) plus `I_ldtoken` (type/method/field tokens). The context-aware functions are applied per-instruction via `Some i`.
- `morphILReturn f r` / `morphILParameter f p` — map return/parameter type and custom attrs.
- `morphILMethodDefs f (m: ILMethodDefs)` / `morphILFieldDefs f (fdefs: ILFieldDefs)` — collection morphisms via `mkILMethods`/`mkILFields`.
- `morphILTypeDefs isInKnownSet f (tdefs: ILTypeDefs)` — collection morphism with de-duplication: types in the "known set" (by name) are never duplicated, everything else may be (keyed by `(index+1, name)`).
- `morphILLocals f locals` — list morphism.
- `morphILDebugImport`/`morphILDebugImports` — map `ImportType` debug imports; namespaces pass through.
- `ilmbody_instr2instr_ty2ty fs (ilmbody: ILMethodBody)` — maps code, locals, and debug imports of an IL method body.
- `morphILMethodBody fMethBody (x: MethodBody)` — maps only `MethodBody.IL` method bodies (eagerly).
- `ospec_ty2ty f (OverridesSpec(mref, ty))` — maps an override spec.
- `mdef_ty2ty_ilmbody2ilmbody fs (md: ILMethodDef)` — maps a method def in context: generic params, body, parameters, return, and custom attrs.
- `mdefs_ty2ty_ilmbody2ilmbody fs mdefs` — method-def collection morphism.
- `mimpl_ty2ty f mimpl` — maps a method-impl (`Overrides` and `OverrideBy`).
- `edef_ty2ty f (edef: ILEventDef)` — maps event type, add/remove/fire/other methods, custom attrs.
- `pdef_ty2ty f (pdef: ILPropertyDef)` — maps setter/getter, property type, args, custom attrs.
- `pdefs_ty2ty f` / `edefs_ty2ty f` / `mimpls_ty2ty f` — collection morphisms.
- `tdef_ty2ty_ilmbody2ilmbody_mdefs2mdefs isInKnownSet enc fs (tdef: ILTypeDef)` — the recursive type definition morphism: mapimplements, generic params, extends, methods, nested types (with the enclosing `enc` context), fields, method impls, events, properties, custom attrs.
- `tdefs_ty2ty_ilmbody2ilmbody_mdefs2mdefs` — the type-def collection morphism (respecting the known set).
- `manifest_ty2ty f (m: ILAssemblyManifest)` — maps a manifest's custom attrs.

## Module-level morphisms

- `morphILTypeInILModule_ilmbody2ilmbody_mdefs2mdefs isInKnownSet (fTyInCtxt, fMethodDefs) modul` — maps an entire module: type defs (with the module context), module custom attrs, and manifest.
- `morphILInstrsAndILTypesInILModule isInKnownSet fs modul` — combines instruction-level and type-level morphism by wiring the code/type contexts through module/type/method contexts.
- `morphILInstrsInILCode f ilcode` — alias for `code_instr2instrs`.
- `morphILTypeInILModule isInKnownSet fTyInCtxt modul` — type-only module morphism (instructions unchanged).
- `morphILTypeRefsInILModuleMemoized isInKnownSet f modul` — type-ref morphism with `Tables.memoize` over types (the classic whole-assembly scope rename).
- `morphILScopeRefsInILModuleMemoized isInKnownSet f modul` — scope-ref morphism via `morphILScopeRefsInILTypeRef` memoized.

## Significant internal logic

- There are two paired type morphisms: the simple `*_ty2ty f` family (single `ILType -> ILType` function) and the context-aware `formal_scopeCtxt = Choice<ILMethodSpec, ILFieldSpec>` family used by `mspec_ty2ty`/`fspec_ty2ty`/`morphILTypesInILInstr`, where `fformalTy` maps the *formal* (declaring) types of specs and `factualTy` maps the *factual* types elsewhere — the distinction is vital when renaming a whole assembly.
- `morphILTypeDefs` implements a correctness rule: definitions in the well-known set must not be duplicated, so `isInKnownSet` (typically set to names such as `<Module>` or user-defined known names) plus index-based keys drive `Array.distinctBy`.
- A remark comments that some of these functions could be unified under one hierarchy using reflection; they remain intentionally separate static functions.
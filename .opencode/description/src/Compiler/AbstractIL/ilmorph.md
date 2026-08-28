# ilmorph.fs

**Purpose**
Provides the "IL rewrites" (morphs) for the abstract IL tree — functions that map each sub-construct of particular ILTypeDefs/ILMethods/ILTypes, threading the context in which the item occurs (module, enclosing type, containing method) so the compiler can rewrite types/scope refs, instructions, and custom attributes across an `ILModuleDef`.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.Morphs`)

**Key bindings (one-line descriptions)**
- `morphCustomAttributeData` / `enableMorphCustomAttributeData` / `disableMorphCustomAttributeData` — global flag + accessors gating whether morphing re-encodes custom-attribute payload data.
- `code_instr2instr f` — applies `f` to every instruction in an `ILCode`.
- `code_instr2instrs f` — applies a `ILInstr -> ILInstr list` transform, rebuilding the instruction list and remapping all code labels via an adjust map.
- `code_instr2instr_ty2ty (finstr, fTy)` — instruction morph + rewriting of exception-clause catch types.
- `morphILTypeRefsInILType` / `tspec_tref2tref` — recursively rewrite `ILScopeRef`s inside an `ILType`/`ILTypeSpec` (Ptr, Byref, Boxed, Value, Array, Modified, FunctionPointer; TypeVar left alone).
- `ty_scoref2scoref_tyvar2ty` / `tspec_scoref2scoref_tyvar2ty` / `callsig_scoref2scoref_tyvar2ty` / `tys_scoref2scoref_tyvar2ty` — rewrite scope refs and type vars in types and calling signatures.
- `callsig_ty2ty`, `gparam_ty2ty`, `gparams_ty2ty`, `tys_ty2ty` — type-morph helpers over calling signatures and generic params.
- `mref_ty2ty` — rewrite `ILMethodRef` (declaring type + arg/return types).
- `mspec_ty2ty` / `fspec_ty2ty` — rewrite `ILMethodSpec` / `ILFieldSpec` with factual vs. formal type contexts (`formal_scopeCtxt = Choice<ILMethodSpec, ILFieldSpec>`).
- `fref_ty2ty` — rewrite `ILFieldRef` declaring type and type.
- `celem_ty2ty` / `cnamedarg_ty2ty` / `cattr_ty2ty` / `cattrs_ty2ty` — rewrite custom-attribute payloads (type refs, named args; optionally re-decode/re-encode data when the global flag is set — dev11 defensive fallback on decode failure).
- `fdef_ty2ty` — `ILFieldDef` field type + custom attrs.
- `morphILLocal` / `morphILVarArgs` — rewrite local types and optional var-arg lists.
- `morphILTypesInILInstr (factualTy, fformalTy)` — rewrite types/method-specs/field-specs in `I_call/i/callvirt/callconstraint/newobj/ldfld/stfld/castclass/isinst/initobj/cpobj/stobj/ldobj/box/unbox/unbox_any/ldelem_any/stelem_any/newarr/ldelema/sizeof/ldtoken`, all with the per-instruction contextual type functions.
- `morphILReturn` / `morphILParameter` — `ILReturn`/`ILParameter` type + custom-attr morph.
- `morphILMethodDefs` / `morphILFieldDefs` — bulk `mkILMethods`/`mkILFields`.
- `morphILTypeDefs isInKnownSet` — `Array.distinctBy` known-set names first, then map; non-known-set items keep their index in the key so they aren't deduped by name.
- `morphILLocals`, `morphILDebugImport` (ImportType only; ImportNamespace untouched), `morphILDebugImports`.
- `ilmbody_instr2instr_ty2ty` — morph `ILMethodBody` code/locals/debug-imports.
- `morphILMethodBody` — force `MethodBody.IL` laziness (eager) and wrap back into `InterruptibleLazy`.
- `ospec_ty2ty` — `OverridesSpec` morph.
- `mdef_ty2ty_ilmbody2ilmbody` — `ILMethodDef` generic params, body, parameters, return, custom attrs.
- `fdefs_ty2ty`, `mdefs_ty2ty_ilmbody2ilmbody`.
- `mimpl_ty2ty` — `ILMethodImpl` (Overrides + OverrideBy).
- `edef_ty2ty` / `edefs_ty2ty`, `pdef_ty2ty` / `pdefs_ty2ty` — `ILEventDef` / `ILPropertyDef` morph.
- `tdef_ty2ty_ilmbody2ilmbody_mdefs2mdefs` / `tdefs_ty2ty_ilmbody2ilmbody_mdefs2mdefs` — recursive `ILTypeDef`/`ILTypeDefs` morph (implements, extends, nested types, fields/methods, method impls, events, properties, custom attrs; known-set dedup preserved).
- `manifest_ty2ty` — `ILAssemblyManifest` custom-attr morph.
- `morphILTypeInILModule_ilmbody2ilmbody_mdefs2mdefs` — top-level `ILModuleDef` morph (TypeDefs + custom attrs + manifest) given per-context type+method transforms.
- `morphILInstrsAndILTypesInILModule` — compose instruction + type morphs over a module.
- `morphILInstrsInILCode` — alias for `code_instr2instrs`.
- `morphILTypeInILModule` — module-level type morph with instruction rewriting derived from the same type function.
- `morphILTypeRefsInILModuleMemoized` — module-level type-ref morph with per-`ILType` memoization via `Tables.memoize`.
- `morphILScopeRefsInILModuleMemoized` — module-level scope-ref morph (via `morphILScopeRefsInILTypeRef` + memoization).

**Significant internal logic**
- The contextual type function signature: `ILModuleDef -> (ILTypeDef list * ILTypeDef) option -> ILMethodDef option -> ILType -> ILType`; `enc` accumulates the enclosing type chain for nested types.
- `formal_scopeCtxt = Choice<ILMethodSpec, ILFieldSpec>` distinguishes method-constraint vs. field-constraint generic-type resolution during `mspec`/`fspec` morphs.

**Cross-references**
- `il.fs` (ILType, ILMethodDef, ILTypeDef, ILModuleDef, ILInstr, ILCustomAttr, ...)
- `ilmorph.fsi` (contract)

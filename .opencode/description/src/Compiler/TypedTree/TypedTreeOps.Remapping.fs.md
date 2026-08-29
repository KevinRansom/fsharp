# TypedTreeOps.Remapping.fs

> Pipeline role: Signature and expression remapping/copying, plus expression shape queries. `SignatureOps` implements module-signature application — mapping the signature's public entities/values onto the corresponding implementation entities (the "repackage" mechanism used by `ModuleOrNamespaceExpr` copying). `ExprFreeVars` provides `accFreeVarsExpr` on expressions. `ExprRemapping` contains the core `remapExpr`/`copyExpr`/`instExpr` engine that deep-copies an `Expr` tree through a `Remap` environment, replacing typars, val refs, tycon refs, union-case/field refs and instantiations — the operation at the heart of signature matching, `.NET` import, generic expansion, and the optimizer's cloning. `ExprAnalysis` supplies `remarkExpr` (range-rebasing after inlining) and simple shape queries.
> Namespace: `FSharp.Compiler.TypedTreeOps`

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.SignatureOps` (`[<AutoOpen>]`, internal, declared at line 36)

Helpers for implementing module/namespace signature application:

- `wrapModuleOrNamespaceType id cpath mtyp` — build a public `ModuleOrNamespace` binding for a signature module.
- `wrapModuleOrNamespaceTypeInNamespace id cpath mtyp` / `wrapModuleOrNamespaceContentsInNamespace isModule id cpath mexpr` — namespace-wrapping binding builders producing `TMDefRec(false, [], [], [...], range)`.
- `type ModuleOrNamespaceRemapping`? — the `mapNestedModuleOrNamespaceType`-family.
- `remapScope`-building: `ModuleSymbolicRemappingInfo` (the `mrpi` record seen at line 101: `mkRepackageRemapping mrpi` and `moduleVars=` remaps module locals/CLI-module-qualified names), `ModuleHiddenIfaces` (`mhi`).
- `addValRemap v vNew tmenv` (line 96), `mkRepackageRemapping` (101).
- `accEntityRemap (msigty) (entity) (mrpi, mhi)` (113) — walked per signature entity; matches entities by name, mapping signed tycon → implementation tycon and (for freevar entities) remaps nested refs. Handles nested module structure (`accSubEntityRemap`), record fields (`rfref`), union cases (`ucref`), and val mappings.
- `valLinkageAEquiv g aenv (v1: Val) (v2: Val)` (211) — linkage (compiled-name + module path) equivalence used during remap construction.
- `remapModuleOrNamespaceType`, `mapModuleOrNamespaceType` wrappers; `moduleOrNamespaceTypeOf` etc.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.ExprFreeVars` (declared at line 791)

Free-variable gathering over `Expr` for specific consumers:

- `accFreeVarsExpr` (state threaded through `ExprFolder`-style walk), `accFreeVarsBindings`, decision-tree walkers, with stack-guard variants.
- `freeVarsOfExpr`, `freeVarsOfBindings`, `freeVarsOfDecisionTree` entry points seeded with `CollectAll`-style options.
- `freeVarsInModuleOrNamespaceTypeAndRemap`, `freeVarsInModuleOrNamespaceContents`; genesis `getReadyFreeVarsOf'`.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.ExprRemapping` (declared at line 1330)

The deep remap engine. Environment: `type RemapState?` — actually a context record:

- `type remapCtx = { g: TcGlobals; stackGuard: StackGuard }` (seen constructed at every public entry as `{ g = g; stackGuard = StackGuard("RemapExprStackGuardDepth") }`).
- `type ValCopyFlag = CloneAll | CloneAllAndMarkValsAsCompilerGenerated` | (whatever) — the flag controls whether copied generated vals are also marked compiler-generated.

**Core functions**:

- `remapExpr g (compgen: ValCopyFlag) (tmenv: Remap) expr`.
- `remapExprImpl ctxt compgen tmenv expr` — the big structural walker over `Expr`:
  - `Expr.Val` (`mkExprAddrOfExpr`-style val remapped via `tmenv.valRemap`, plus `ValDeref` bypass), `Expr.Const`, `Expr.Quote` (remaps inside quotations, resetting data bindings), `Expr.App`/`TyApp`/`Lambda`/`TyLambda`/`TyChoose`/`Let`/`LetRec`/`Match`/`DecisionTree`/`Switch`/`Sequential`/`ObjExpr`/`StaticRecdExpr` — each rebuilt recursively; linearized cores (`mkLinearMatch` etc.) handled structurally.
  - Typar handling during `Let`: `let typarsR = remapTypars ...` retains stamps for non-instantiated typars; trait solutions folded per `removeTraitSolutions`.
  - Bindings via `remapBind`/`remapValsInBind`?; `Bind` remaps val, type, and defn; keeps `ValReprInfo` if not compgen.
  - `remapImplFile` for `TImplFile`: modules, namespaces, open decls, module bindings; `remapSignature`/`remapCcuSig`-adjacent helpers for `TAssemblySignature`.
- `remapPossibleForallTy g tmenv ty` (2446) — instantiates a polymorphic type for "possible forall" sites (used by member-flag propagation).
- Entry points:
  - `copyModuleOrNamespaceType g compgen mtyp` (2455) — signature-copy through `copyAndRemapAndBindModTy`.
  - `copyExpr g compgen e` (2464) — deep copy with `Remap.Empty`.
  - `copyImplFile g compgen e` (2473) — deep copy of a whole implementation file.
  - `instExpr g tpinst e` (2482) — instantiate (substitute typars) an expression.
- `copyAndRemapAndBindModTy`/`copyAndRemapAndBindModTyToFreshSigScope`/`remapModuleOrNamespaceType`/`mapModuleOrNamespaceType`-family — module-level remapping that binds implementation refs; `bindTyparsToTys`-style where a list of typars is flexibly substituted.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.ExprAnalysis` (`[<AutoOpen>]`, internal, declared at line 2491)

**Range rebasing — `remarkExpr`/`remarkBind`/`remarkBinds`/`remarkBindings`** (lines 2495+): adjusts the ranges of an inlined lambda body to the callsite (`m`) — pattern: propagate `m` down through `Lambda`/`TyLambda`/`TyChoose`/`LetRec`/`Let`/`Match`/`DecisionTree`/`ObjExpr` etc., only changing the `range` slots, so debug info for inlined code points at the call.

**Shape queries**: `isLinearBind`? trivial `isTrivial`, `isVarFreeInExpr`? etc. participating in `Linearize`/escaping analyses (`accFreeVars` hooked to `ExprFolder`).

---

## Related

- Builds on: `ExprConstruction` (`Expr`s), `TypeRemapping` (`Remap`, `TyparMap`), `SignatureOps`-adjacent `Remap` records, `ExprFreeVars`.
- Used by: signature matching (`TcSignature`, `Import`), `.NET` import (`TcImports`), generics instantiation in `CheckExpressions`, `IsUnusedValue`/optimizer cloning, and `IlxGen` lambda lifting.
# TypedTreeOps.Remap.fs

> Pipeline role: Type-remapping infrastructure. Defines the `Remap` environment (typar substitution + val/tycon reference maps), the `TypeRemapping` module with `remapType`/`remapTypes`, and the `TypeEquivalence` module implementing type equivalence & unification between two typed trees (used heavily by signature matching, `Import`, and value-restriction checking). Measure-rewriting for types with unit-of-measure instantiations also lives here.
> Namespace: `FSharp.Compiler.TypedTreeOps`

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.TypeRemapping` (`[<AutoOpen>]`, internal, declared at line 37)

**Foundation helpers (lines 40–45)**:

- `let inline compareBy (x | null) (y | null) [`[<InlineIfLambda>]` func]` — stamp-based null-tolerant comparator reused to define the map orders.

**Data structures (lines 47–150)**:

- `type StampMap<'T>` (treated by `Internal.Utilities.Collections`) and `type ValMap<'T>` / `type TyconRefMap<'T>` wrapped as empty-capable immutable maps keyed by stamp.
- `[<NoEquality; NoComparison>] type TyparMap<'T> = TPMap of StampMap<'T>` with `Item` (indexer by `Typar`), `ContainsKey`, `TryFind`, `Values` members.
- `type ValRemap = ValMap<ValRef>` (line 121), `[<NoEquality; NoComparison>] type TyconRefRemap = TyconRefMap<TyconRef>`.
- `[<NoEquality; NoComparison>] type Remap = { tpinst: TyparInstantiation; valRemap: ValRemap; tyconRefRemap: TyconRefRemap; removeTraitSolutions: bool }` (lines 127–139) — `emptyRemap` default and `static member Remap.Empty` (lines 141–150).

**Substitution and metavariable instantiation**:

- `addTyconRefRemap tcref1 tcref2 tmenv`, `isRemapEmpty remap`.
- `mkTyparInst typars tys`; `generalizeTypar`/`generalizeTypars`; `instTyparRef`/`instTyparRefAux`.
- `remapTyconRef`, `remapUnionCaseRef`, `remapRecdFieldRef` — re-write the `TyconRef` through `tcmap` map.
- `let emptyTyconRefRemap: TyconRefRemap = TyconRefMap<_>.Empty`, `let emptyTyparInst = ([]: TyparInstantiation)`.

**Type remapping (the core loop, lines 182–262)**:

- `rec remapTypeAux (tyenv: Remap) (ty: TType) : TType` — structural walk:
  - strips typar equations (`stripTyparEqns`), substitutes *rigid* typars via `instTyparRef`, applies `tpinst` substitution.
  - rebuilt `TType_app` nodes: remaps tycon & instantiation (`tinstR`), also applies to `anonInfo` tuple info (`remapTupInfoAux`).
  - trait solutions (`TR_false/true`) — either dropped (if `removeTraitSolutions`) or re-instantiated.
  - byref/app/var/m-call cases rebuilt with remapped components.
- `remapTypesAux` folds over lists; `remapType tyenv ty` and `remapTypes (tyenv: Remap) (tys)` public entry points.
- `remapTyconRefAux`? foldable; plus `linearizeType`-driven helpers.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.MeasureOps`/`TypeBuilders`/`TypeAbbreviations`/`TypeDecomposition` (lines 522/745/890/932)

Type-shape work in this file accompanying `TypeRemapping`: `MeasureOps` rewrites measure (`[<Measure>]`) type-argument structure; `TypeBuilders` (formerly `TTypeBuilding`) constructs concrete `TType`s; `TypeAbbreviations` expands abbreviations; `TypeDecomposition` holds the `tryDestAppTy`-style destructors:

- `tryDestAppTy`, `destAppTy`, `tryAppTyLinear`, `destAppTyBothDirections`, `destAnyTyparTy`, `destTyparTy`, `tryDestTyparTy`.
- `destIntTy`, `destTupTy`/`tryDestTupTy`, `destAnonInfoTup`, `destByrefTy`, `destArrayTy`, `rankOfArrayTy`, `destRecdRef`, `destUnionRef`, `destFunTy`/`tryDestFunTy`, `destNativePtrTy`, `destOptionTy`, `destDateTimeOffsetTy`,...
- `stripTyparEqns`/`stripTyEqnsAndMeasureEqns`/`stripTyEqnsMeasureEqnsForEquiv`/`stripTyEqnsUngeneric` etc.
- Name-of type decomposition helpers: `nameOfTy`, `nameOfTyRef`, `nameOfEntityTy`.
- Tycon-info helpers: `rankOfArrayTyconRef`, `isArrayTyconRef`...

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.TypeEquivalence` (line 1423)

Equivalence between types as they appear in different modules/compilations, plus `TraitWitnessInfo` handling for the stabilized witness table:

- `EmptyTraitWitnessInfoHashMap`/`byIdTraitWitnessInfoHashMap` — stamp-keyed maps caching trait witness comparisons keyed on member IDs (for better complexity when comparing many witnesses).
- `typeEquiv`, `typeEquivAux` (handles `TR_show`??/typars by id, `traitSlns` folding, measure type args by equivalence), `tysAEquiv`.
- `kindEquiv`/`kindEquivAux`; `traitWitnessInfoREquiv`/`TraitWitnessInfo` id-compare; `memberInfoEquiv`.
- `typarsAEquiv`, `valAEquiv_ignoreRefEq`-family; `entityAEquiv`; entry `typeEquivWithActualTypars`? or just `typeEquiv`.
- Integration with remap: `entityRemapAEquiv`, `useOfTraitSolutionsAEquiv`.

---

## Related

- Builds on: `TypedTree`, `TypedTreeBasics`.
- Used by: `Remapping` (expression copy through a `Remap`), signature matching (`TcSignature`/`Import`), value restrictions in `CheckDeclarations`, and `EraseUnusedEntities`/optimizer passes that must rebuild types with instantiated typars.
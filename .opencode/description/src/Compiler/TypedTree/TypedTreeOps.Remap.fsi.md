# TypedTreeOps.Remap.fsi

**Purpose**: Contract for the type-level `Remap` toolkit. Defines the `Remap` type (a `TyconRefMap<TyconRef>` tycon-identity map plus a `TyparInstantiation` typar→type binding) and the library of functions to build, apply, compose, and invert it, plus the `MeasureOps`, `TypeBuilders`, `TypeAbbreviations`, `TypeDecomposition`, and `TypeEquivalence` modules used across checking and codegen.

**Namespace(s)**: `FSharp.Compiler.TypedTreeOps`.

**Modules (signatures)**:
- `module TypeRemapping` — core: `emptyTyconRefRemap`, `emptyTyparInst`, `emptyRemap`, `addTyconRefRemap`, `isRemapEmpty`, `instTyparRef`, `remapTyconRef/UnionCaseRef/RecdFieldRef`, `mkTyparInst`, `generalizeTypar(s)`, `remap{Type,Measure,TupInfo,Types,TyparConstraints}Aux`, `remapTraitInfo`, `bindTypars`, `copyAndRemapAndBindTypars(Full)`, `remapValLinkage`, `remapNonLocalValRef`, `remapValRef`, `remapType(s|Full)`, `remapParam`, `remapSlotSig`, `mkInstRemap`, `instType(s)`, `instTrait`, `instTyparConstraints`, `instSlotSig`, `copySlotSig`, `decoupleTraitSolutions`, `mkTyparToTyparRenaming`, `mkTycon(Ref)Inst`, and helper `inline compareBy`.
- `module MeasureOps` — `tyconRefEq/valRefEq`, `reduceTyconRefAbbrevMeasureable`, `stripUnitEqnsFromMeasure(Aux)`, `Measure{Expr,Con,Var}Exponent`, `MeasureConExponentAfterRemapping`, `ListMeasure{Var,Con}Occs(WithNonZeroExponents)(AfterRemapping)`, `MeasurePower(ProdOpt)`/`ProdMeasures`, `isDimensionless`, `destUnitParMeasure`, `isUnitParMeasure`, `normalizeMeasure`, `tryNormalizeMeasureInType`.
- `module TypeBuilders` — `mkForallTy(IfNeeded)`, `(+->)`, `mkFunTy`, `mkIteratedFunTy`, `mkNativePtrTy`, `mkByrefTy(WithFlag|In|Out|2|WithInference)`, `mkVoidPtrTy`, `mkArrayTy`, `maxTuple`, `goodTupleFields`, `isCompiledTupleTyconRef`, `mkCompiledTupleTyconRef`, `mkCompiledTupleTy`, `mkOuterCompiledTupleTy`.
- `module TypeAbbreviations` — `applyTyconAbbrev`, `reduceTyconAbbrev(Ref)`, `reduceTycon(Ref)` `MeasureableOrProvided`.
- `module TypeDecomposition` — the full `is*Ty` / `dest*Ty` / `try*Ty` / `strip*` / `mk*Ty` family (see `TypedTreeOps.Remap.md` for the full list; all take `TcGlobals` first where applicable).
- `module TypeEquivalence` — `EmptyTraitWitnessInfoHashMap`; the `*AEquiv(Aux)` family taking `Erasure`, `TcGlobals`, and `TypeEquivEnv`: `traitsAEquiv(Aux)`, `traitKeysAEquiv(Aux)`, `returnTypesAEquiv(Aux)`, `typarConstraintsAEquiv(Aux)`, `typarConstraintSetsAEquiv(Aux)`, `typarsAEquiv(Aux)`, `tcrefAEquiv`, `typeAEquiv(Aux)`, `anonInfoEquiv`, `structnessAEquiv`, `measureAEquiv`, `typesAEquiv(Aux)`, `typeEquiv(Aux)`, `typeAEquiv`, `typeEquiv`, `isConstraintAllowedAsExtra`, `typarsAEquivWithAddedNotNullConstraintsAllowed`, `measureEquiv`, `traitsAEquiv`, `traitKeysAEquiv`, `typarConstraintsAEquiv`, `typarsAEquiv`.

**Key invariants**: `remapType ≡ remapTypeAux`; `instType ≡ mkInstRemap inst |> remapType`; `generalizeTypar(s)` produces a `TyparInstantiation` binding fresh typars to their measure/type; `typeEquiv` is structural alpha-equivalence modulo the erasure and the env.

**Cross-references**: `TypedTreeBasics.fsi`, `TypedTree.fs`/`.fsi`, `Checker.fs`/`Unify.fs`, `SignatureOps` (`TypedTreeOps.Remapping.fsi`), `IlxGen.fs` (instance application).

# TypedTreeBasics.fsi

**Purpose**: Contract for the "basic property functions" (old-style) over the typed tree: value basics (`typeOfVal`, `nameOfVal`, `arityOfVal`, the `ValReprInfo` module), reference constructors and active patterns (`ERef*`/`VRef*`/`ValDeref`/`ERefLocal|ERefNonLocal`/`VRefLocal|VRefNonLocal`), nullness helpers (`Known*Nullness`, `combineNullness`, `*NullnessToTy`), tuple-type helpers (`mkTupInfo`, `mkRaw*TupleTy`), equality helpers (`typarEq`, `valEq`, `ccuEq`, the `prim*RefEq` family), public-path/accessibility logic (`canAccess*`, `taccess*`, `accessSubstPaths`, `compPathOfCcu`, `rescopePubPath`), and type stripping (`stripTyparEqns`, `stripUnitEqns`, `AbbrevOrAppTy`, `ILTyconRawMetadata`).

**Namespace(s)**: `FSharp.Compiler` — `module internal FSharp.Compiler.TypedTreeBasics`.

**Key signatures** (see `TypedTreeBasics.md` for the full list):
- `module ValReprInfo`: `unnamedTopArg1/unnamedTopArg/unitArgData`, `unnamedRetVal`, `selfMetadata`, `emptyValData: ValReprInfo`, `IsEmpty`, `InferTyparInfo`, `InferArgReprInfo(s)`, `HasNoArgs`.
- `val typeOfVal: Val -> TType`, `typesOfVals`, `nameOfVal`, `arityOfVal: Val -> ValReprInfo`, `tryGetArityOfValForDisplay: Val -> ValReprInfo option`, `arityOfValForDisplay`.
- `val tupInfoRef/tupInfoStruct: TupInfo`, `mkTupInfo: bool -> TupInfo`, `structnessDefault: bool`, `mkRawRefTupleTy`/`mkRawStructTupleTy`.
- `val typarEq/typarRefEq: Typar * Typar -> bool`, `valEq`, `ccuEq`.
- `val (|ValDeref|): ValRef -> Val`, `mkRecdFieldRef`, `mkUnionCaseRef`, `mkModuleUnionCaseRef`, `ERefLocal/ERefNonLocal/ERefNonLocalPreResolved`, `(|ERefLocal|ERefNonLocal|)`, `mkLocalTyconRef`, `mkNonLocalEntityRef`, `mkNestedNonLocalEntityRef`, `mkNonLocalTyconRef(PreResolved)`, `VRefLocal/VRefNonLocal/VRefNonLocalPreResolved`, `(|VRefLocal|VRefNonLocal|)`, `mkNonLocalValRef(PreResolved)`, `ccuOfValRef`, `ccuOfTyconRef`.
- Nullness: `NewNullnessVar: unit -> Nullness`, `KnownAmbivalentToNull`/`KnownWithNull`/`KnownWithoutNull: Nullness`, `combineNullness`, `tryAddNullnessToTy`/`addNullnessToTy`.
- Types: `mkTyparTy`, `copyTypars: bool -> Typar list -> Typar list`, `tryShortcutSolvedUnitPar`, `stripUnitEqnsAux`/`stripTyparEqnsAux` (internal), `replaceNullnessOfTy`, `stripTyparEqns`, `stripUnitEqns`, `(|AbbrevOrAppTy|_|)`, `(|ILTyconRawMetadata|_|)`.
- Refs: `mkLocalValRef`, `mkLocalModuleRef`, `mkLocalEntityRef`, `mkNonLocalCcuRootEntityRef`, `mkNestedValRef`, `rescopePubPathToParent`/`rescopePubPath`, `valRefInThisAssembly`, `tyconRefUsesLocalXmlDoc`, `entityRefInThisAssembly`.
- Comparison: `arrayPathEq`, `nonLocalRefEq`, `nonLocalRefDefinitelyNotEq`, `pubPathEq`, `fslibRefEq`, `fslibEntityRefEq`, `fslibValRefEq`, `primEntityRefEq`, `primUnionCaseRefEq`, `primValRefEq`.
- Accessibility: `fullCompPathOfModuleOrNamespace`, `inline canAccessCompPathFrom`, `canAccessFromOneOf`, `canAccessFrom`, `canAccessFromEverywhere/Somewhere`, `isLessAccessible`, `accessSubstPaths`, `compPathOfCcu`, `taccessPublic/taccessPrivate/compPathInternal/taccessInternal: CompilationPath`, `combineAccess`.

**Notes**: The `ValReprInfo` module in the .fsi is the metadata-on-values namespace (arg/return names for display); `taccessPrivate`/`taccessInternal` are the canonical accessibilities. The .fs also contains `#if DEBUG` size asserts for the flag types (`ValFlags` 8 bytes, `EntityFlags` 8, `TyparFlags` 4), not part of the contract.

**Cross-references**: `TypedTreeBasics.fs` (implementation), `TypedTree.fs`/`.fsi` (the tree types), `CompilerGlobalState.fs`, `Checker.fs`/`Unify.fs`, `TcGlobals.fs`.

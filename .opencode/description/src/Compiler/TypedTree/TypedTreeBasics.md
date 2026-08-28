# TypedTreeBasics.fs

**Purpose**: "Defines the typed abstract syntax trees used throughout the F# compiler" — in practice this module contains the *basic property functions* (old-style) over checked trees: convenience accessors for values (`typeOfVal`, `nameOfVal`, `arityOfVal`), the `ValReprInfo` helper module (default/unnamed argument metadata for values), tuple-type helpers, reference constructors and equality checks (`ValRef`/`EntityRef`/`UnionCaseRef`/public-path and accessibility logic), nullness helpers, and type stripping helpers (`stripTyparEqns`, `stripUnitEqns`).

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.TypedTreeBasics`).

**Declared types**:
- `<module ValReprInfo>` — `unnamedTopArg1`, `unnamedTopArg`, `unitArgData`, `unnamedRetVal`, `selfMetadata`, `emptyValData: ValReprInfo`; helpers `IsEmpty`, `InferTyparInfo` (build `TyparReprInfo` list from typars), `InferArgReprInfo`, `InferArgReprInfos`, `HasNoArgs`.

**Public/used API surface** (module internal; see .fsi for the contract):
- Value basics: `typeOfVal`, `typesOfVals`, `nameOfVal`, `arityOfVal`, `tryGetArityOfValForDisplay`, `arityOfValForDisplay`, `tupInfoRef`/`tupInfoStruct`, `mkTupInfo`, `structnessDefault`, `mkRawRefTupleTy`, `mkRawStructTupleTy`.
- Equality: `typarEq`, `typarRefEq` (rigidity-insensitive), `valEq`, `ccuEq`.
- Active pattern: `(|ValDeref|)` — dereference a local `ValRef`.
- Reference constructors: `mkRecdFieldRef`, `mkUnionCaseRef`, `mkModuleUnionCaseRef`, `ERefLocal`, `ERefNonLocal`, `ERefNonLocalPreResolved`, `mkLocalTyconRef`, `mkNonLocalEntityRef`, `mkNestedNonLocalEntityRef`, `mkNonLocalTyconRef`, `mkNonLocalTyconRefPreResolved`, `VRefLocal`, `VRefNonLocal`, `VRefNonLocalPreResolved`, `mkNonLocalValRef`, `mkNonLocalValRefPreResolved`, `mkLocalValRef`, `mkLocalModuleRef`, `mkLocalEntityRef`, `mkNonLocalCcuRootEntityRef`, `mkNestedValRef`; active patterns `(|ERefLocal|ERefNonLocal|)`, `(|VRefLocal|VRefNonLocal|)`.
- CCU helpers: `ccuOfValRef`, `ccuOfTyconRef`, `rescopePubPathToParent`, `rescopePubPath`, `valRefInThisAssembly`, `tyconRefUsesLocalXmlDoc`, `entityRefInThisAssembly`.
- Nullness: `NewNullnessVar`, `KnownAmbivalentToNull`, `KnownWithNull`, `KnownWithoutNull`, `combineNullness`, `tryAddNullnessToTy`, `addNullnessToTy`.
- Types: `mkTyparTy`, `copyTypars`, `tryShortcutSolvedUnitPar`, `stripUnitEqnsAux`, `stripTyparEqnsAux`, `replaceNullnessOfTy`, `stripTyparEqns` (remove `TTypar` equation constraints), `stripUnitEqns` (remove unit measure equations), active patterns `(|AbbrevOrAppTy|_|)`, `(|ILTyconRawMetadata|_|)`.
- Comparison of nonlocal refs: `arrayPathEq`, `nonLocalRefEq`, `nonLocalRefDefinitelyNotEq`, `pubPathEq`, `fslibRefEq`, `fslibEntityRefEq`, `fslibValRefEq`, `primEntityRefEq`, `primUnionCaseRefEq`, `primValRefEq`.
- Paths/accessibility: `fullCompPathOfModuleOrNamespace`, `canAccessCompPathFrom`, `canAccessFromOneOf`, `canAccessFrom`, `canAccessFromEverywhere/Somewhere`, `isLessAccessible`, `accessSubstPaths`, `compPathOfCcu`, `taccessPublic`, `taccessPrivate`, `compPathInternal`, `taccessInternal`, `combineAccess`.

**Internal helpers**: `#if DEBUG` asserts that `sizeof<ValFlags>`, `sizeof<EntityFlags>` are 8 bytes and `TyparFlags` is 4 bytes (layout invariants relied on for hashing/performance).

**Significant internal logic**: `stripTyparEqnsAux`/`stripUnitEqnsAux` are used when simplifying types for display or canonicalization (they strip measure/unit equalities that the unifier has solved). The "prim*RefEq" functions are F#-library identity comparisons used throughout unification and codegen; `rescopePubPath` handles the case of viewing an entity from another CCU (the `viewedCcu` rescopes the `PublicPath`). `ValReprInfo.unitArgData = [[]]` is the canonical empty (unit) parameter list; `emptyValData` is the default for values with no metadata.

**Cross-references**: `TypedTreeBasics.fsi` (contract), `TypedTree.fs` (the `Val`, `Typar`, `ValRef`, `EntityRef`, `TType`, `Nullness`, `CcuThunk`, `Accessibility`, `CompilationPath`, `PublicPath` types), `CompilerGlobalState.fs`, `TcGlobals.fs`, `Checker.fs`/`Unify.fs` (heavy users), `PrettyTypes` (display paths).

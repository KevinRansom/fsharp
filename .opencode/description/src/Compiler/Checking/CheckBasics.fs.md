# CheckBasics.fs

**Purpose**: Implementation of the shared foundation types and per-file state used across the Checking phase (`CheckBasics`, `CheckDeclarations`, `CheckExpressions`, `CheckPatterns`). It defines `TcEnv` (the scoping environment), `TcFileState` (the per-file compgen state holding the constraint solver, info reader, name resolver, forward call pointers), constructor-checking info, and ungeneralizable-item tracking that powers the value restriction.

**Namespace(s)**: `module internal FSharp.Compiler.CheckBasics`

**Types declared** (implementation mirrors the .fsi):
- `PrelimValReprInfo`, `PrelimMemberInfo`, `CheckConstraints` (`CheckCxs`/`NoCheckCxs`), `ExplicitTyparInfo` (declared typars + whether additional polymorphism is inferred), `ArgAndRetAttribs`.
- `PrelimVal1` — first-phase result of preparing a value bound by a pattern (id, explicit typar info, prelim type, prelim repr info, member info, mutability, inline flag, base/this info, arg/ret attributes, visibility, isCompGen).
- `UnscopedTyparEnv`, `TcPatLinearEnv`, `TcPatPhase2Input`, `TcPatValFlags` — pattern-checking context/flow types.
- `SafeInitData` (`SafeInitField` / `NoSafeInitInfo`) and `CtorInfo` — safe-constructor-initialization tracking for object expression / implicit constructor checking (`ctorShapeCounter`, `safeThisValOpt`, `safeInitInfo`, `ctorIsImplicit`, with `InitialExplicit` / `InitialImplicit`).
- `UngeneralizableItem` — wraps a thunk computing the free type variables of a binding, with memoized flags: mutable `willNeverHaveFreeTypars`, `cachedFreeLocalTycons`, `cachedFreeTraitSolutions` (see `CheckBasics.fs:153-184`).
- `TcEnv` — the per-scope checking environment: `eNameResEnv`, `eUngeneralizableItems`, `ePath`/`eCompPath`/`eAccessPath`, derived `eAccessRights : AccessorDomain`, `eInternalsVisibleCompPaths`, `eModuleOrNamespaceTypeAccumulator`, `eContextInfo`, `eFamilyType`, `eCtorInfo`, `eCallerMemberName`, `eLambdaArgInfos`, `eIsControlFlow`, `eInObjectExpr`, `eCachedImplicitYieldExpressions` (avoids exponential re-checking of nested implicit-yield expressions), `eUseBoundValStamps` (suppresses duplicate `Dispose` warnings, #12300). Members: `DisplayEnv`, `NameEnv`, `AccessRights`.
- `TcFileState` — per-file state: `g`, `mutable recUses`, `stackGuard`, `createsGeneratedProvidedTypes`, `isScript`, `amap`, `synArgNameGenerator`, `tcSink`, `thisCcu`, `css : ConstraintSolverState`, `compilingCanonicalFslibModuleType`, `isSig`, `haveSig`, `niceNameGen`, `infoReader`, `nameResolver`, `conditionalDefines`, `namedDebugPointsForInlinedCode`, `isInternalTestSpanStackReferring`, `diagnosticOptions`, `argInfoCache`, `inheritResolutionFailed` (avoid duplicate FS0039), plus forward-call fields `TcPat`, `TcSimplePats`, `TcSequenceExpressionEntry`, `TcArrayOrListComputedExpression`, `TcComputationExpression` (resolved by mutual pass with the expression checker), and `static member Create`.

**Constructor / helper functions**:
- `TcFileState.Create` — builds the state from `TcGlobals`, `ImportMap`, `CcuThunk`, and the forward-calling functions (`TcBasics.fs:261-356` creates `infoReader = InfoReader(g, amap)` and `nameResolver = NameResolver(g, amap, infoReader, instantiationGenerator)` with `instantiationGenerator = FreshenTypars g m tpsorig`).

**Significant internal logic**:
- The forward-call fields break the cyclic dependency between `CheckPatterns` / expression checking modules and the per-file state; `Create` takes the entry points so no module cycles arise.
- `recUses` collects uses of mutually-recursive values so recursive type applications can be fixed up after typar inference (consumed by `CheckDeclarations`).
- Ungeneralizable items are revisited as constraints get solved; the value restriction check (`CheckValueRestriction` in CheckDeclarations) relies on `GetFreeTyvars`.
- `eCachedImplicitYieldExpressions` is a `HashMultiMap<range, SynExpr * TType * Expr>` keyed by source range to avoid exponential blowup of nested `[` `]` implicit yieldders.

**Cross-references**: `CheckBasics.fsi` (contract), `ConstraintSolver.fs` (`css` state), `InfoReader.fs`, `NameResolution.fs`/`NameResolver`, `CheckDeclarations.fs` (main consumer), `CheckPatterns.fs`, `TypedTree.fsi` (`PrelimVal1`-related types).

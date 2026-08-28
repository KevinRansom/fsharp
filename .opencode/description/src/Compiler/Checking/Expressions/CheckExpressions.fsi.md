# CheckExpressions.fsi

**Purpose**
Public contract (internal module) for the central F# expression checker. Declares the checking
exceptions, the value-spec and binding machinery, and the full `Tc*` entry-point surface used to convert
`SynExpr`/`SynPat`/`SynType` into checked TAST (`Expr`, `Val`, `Pattern`, `Typars`). This is the API the
rest of the compiler (declaration checking, quotation translation, pattern matching, attribute checking)
relies on.

**Namespace(s)**
`module internal FSharp.Compiler.CheckExpressions`

**Exceptions declared** (representative groups)
- Function/application: `FunctionExpected`, `NotAFunction`, `NotAFunctionButIndexer`, `BakedInMemberConstraintName`.
- Recursion/letrec: `Recursion`, `RecursiveUseCheckedAtRuntime`, `LetRecEvaluatedOutOfOrder`, `LetRecCheckedAtRuntime`, `LetRecUnsound`.
- Data: `TyconBadArgs`, `UnionCaseWrongArguments`, `UnionCaseWrongNumberOfArgs`, `FieldsFromDifferentTypes`, `FieldGivenTwice`, `MissingFields`, `UnionPatternsBindDifferentNames`.
- Values/statements: `UnitTypeExpected`, `UnitTypeExpectedWithEquality`, `UnitTypeExpectedWithPossibleAssignment`, `UnitTypeExpectedWithPossiblePropertySetter`, `FunctionValueUnexpected`, `VarBoundTwice`, `ValueRestriction`, `ValNotMutable`, `ValNotLocal`.
- Coercions: `InvalidRuntimeCoercion`, `IndeterminateRuntimeCoercion`, `IndeterminateStaticCoercion`, `RuntimeCoercionSourceSealed`, `CoercionTargetSealed`, `UpcastUnnecessary`, `TypeTestUnnecessary`, `StaticCoercionShouldUseBox`.
- Classes/objects: `SelfRefObjCtor`, `VirtualAugmentationOnNullValuedType`, `NonVirtualAugmentationOnNullValuedType`, `UseOfAddressOfOperator`, `DeprecatedThreadStaticBindingWarning`, `IntfImplIn(Intrinsic|Extrinsic)Augmentation`, `OverrideIn(Intrinsic|Extrinsic)Augmentation`, `NonUniqueInferredAbstractSlot`, `StandardOperatorRedefinitionWarning`.
- Misc: `InvalidInternalsVisibleToAssemblyName`, `InvalidAttributeTargetForLanguageElement`.

**Key types (supporting the API)**
- `ImplicitlyBoundTyparsAllowed`, `PrelimVal2`, `MemberOrValContainerInfo`, `ContainerInfo`, `NewSlotsOK`, `OverridesOK`, `DeclKind`, `WarnOnIWSAM`, `IsObjExprBinding`, `RecDefnBindingInfo`, `ValSpecResult`, `NormalizedBinding*Rhs`, `RecursiveBindingInfo`, `CheckedBindingInfo`, `ValScheme`, `NormalizedRecBindingDefn`, `Pre/Post(Generalization)RecursiveBinding`, `PostSpecialValsRecursiveBinding`, `RecursiveUseFixupPoints`, `TcCanFail`, `TcTrueMatchClause`, `PreInitializationGraphEliminationBinding`.

**Core entry points (representative signatures)**
- `TcFieldInit: range -> ILFieldInit -> Const`; `TcConst: ... -> Const`.
- `TcExpr : cenv -> ty: OverallTy -> env: TcEnv -> tpenv -> synExpr: SynExpr -> Expr * UnscopedTyparEnv` — check a syntactic expression (with error recovery).
- `TcExprOfUnknownType`, `TcExprFlex`, `TcExprUndelayed`, `TcStmtThatCantBeCtorBody`, `TcLinearExprs`, `TryTcStmt`, `TcPropagatingExprLeafThenConvert`.
- `TcMatchPattern: ... -> Pattern * Expr option * Val list * TcEnv * UnscopedTyparEnv` — check a match pattern.
- `EliminateNullnessFromInputType: g -> inputTy -> pat: Pattern -> whenExprOpt -> TType` — narrow the input type for subsequent clauses.
- `CheckTupleIsCorrectLength`; `RecordNameAndTypeResolutions`.
- `TcLetBindings: ... -> ModuleOrNamespaceContents list * TcEnv * UnscopedTyparEnv`; `TcLetrecBinding`; `TcLetrecBindings`; `TcLetrecAdjustMemberForSpecialVals`; `TcLetrecComputeCtorSafeThisValBind`.
- `TcNewExpr` (`new X()` / inheritance); `TcNameOfExpr`.
- `TcAndPublishValSpec` / `TcValSpec` — spec-check a value binding; `TcVal` — the central value/curried-args checker.
- `TcAttributes`, `TcAttributesCanFail`, `TcAttributesWithPossibleTargets` — attribute checking (incl. can-fail for recursive groups).
- `TcType`, `TcTypeOrMeasureAndRecover`, `TcTypeAndRecover`; `TcTyparDecls`, `TcTyparConstraints`; `TcRuntimeTypeTest`.
- `TranslateSynValInfo` / `TranslatePartialValReprInfo` — syn→typed value representations.
- `MakeAndPublishVal`, `MakeAndPublishSimpleVals`, `MakeAndPublishBaseVal`, `MakeAndPublishSafeThisVal`, `MakeMemberDataAndMangledNameForMemberVal`, `MakeCheckSafeInit`, `AnalyzeAndMakeAndPublishRecursiveValue`, `EliminateInitializationGraphs`, `CheckRecursiveInlineGroup`, `FixupLetrecBind`.
- `PublishValueDefn(MaybeInclCompilerGenerated)`, `PublishTypeDefn`, `PublishModuleDefn`.
- `ChooseCanonicalDeclaredTyparsAfterInference`, `ChooseCanonicalValSchemeAfterInference`, `ComputeIsComplete`, `NonGenericTypeScheme`, `SetTyparRigid`, `permitInferTypars`, `dontInferTypars`.
- `ComputeAccessRights`, `ComputeAccessAndCompPath`; `LocateEnv`; `GetCurrAccumulatedModuleOrNamespaceType`; `MakeInnerEnv(WithAcc)(ForTyconRef)`; `GetInstanceMemberThisVariable`.
- `ConvertArbitraryExprToEnumerable`, `UnifyTupleTypeAndInferCharacteristics`, `CheckRecdExprDuplicateFields`, `BuildFieldMap`, `CheckTupleIsCorrectLength`.
- `TcPatLongIdentActivePatternCase`, `ConvSynPatToSynExpr`, `(|BinOpExpr|_|): SynExpr -> (Ident * SynExpr * SynExpr) voption`, `TcProvidedTypeAppToStaticConstantArgs` (`#if !NO_TYPEPROVIDERS`).

**Significant notes**
- The fsi documents the exception set as "some of the exceptions arising from type checking. These should
  be moved to use DiagnosticsLogger" — i.e. the exception-based diagnostics are a legacy surface being
  migrated.
- `TcVal` is deliberately the shared workhorse (also used by `QuotationTranslator`,
  `PostInferenceChecks`, `MethodCalls.BuildMethodCall` and `CheckExpressionsOps.LightweightTcValForUsingInBuildMethodCall`).
- `TcCanFail` / `TcAttributesCanFail` support recursive groups where attribute checking "may succeed in a
  later phase of type realization" (forward-referenced attribute types).
- `TcTrueMatchClause` distinguishes real match clauses from synthesized ones (e.g. the `null` clause)
  affecting value-restriction and unused warnings.
- `TcLinearExprs` processes linear `let` sequences tail-recursively, invoking a caller-supplied
  `bodyChecker` for the non-linear tail.

**Cross-references**
- `CheckExpressions.fs` — implementation of all of the above (~13k lines).
- `CheckExpressionsOps.fsi`(less/none) — actually see `CheckExpressionsOps.fs` for helpers used *by* this module.
- `CheckBasics.fsi` (Checking dir) — `TcFileState`, `TcEnv`, `OverallTy`-supporting types, `PrelimVal*`.
- `MethodCalls.fsi` / `MethodOverrides.fsi` (Checking dir) — call/override machinery invoked from `TcVal`/`TcNewExpr`.
- `PatternMatchCompilation.fsi` — the `Pattern` / `DecisionTree` / `MatchClause` types produced/checked here.
- `QuotationTranslator.fsi` — consumes checked expressions via the same `TcValF`-style value function.
- `NameResolution.fsi` — name-resolution + results-sink plumbing used throughout `Tc*`.

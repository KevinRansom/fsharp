# CheckExpressions.fs

**Purpose**
The central expression checker of the F# compiler: converts syntactic expressions (`SynExpr`) into
checked, typed tree expressions (`Expr`) with left-to-right, constraint-driven, generalizing type
inference. Handles the full expression surface — applications and currying, dot-get/dot-set, member and
method calls (via overload resolution), `new` and object expressions, patterns/matches, `let`/`let rec`
(bindings, safe-init, value restriction), records, tuples, arrays/lists, computation expressions,
attributes, quotations, type tests/coercions, operators, and all the expression-specific error/warning
conditions. A very large module (~13,600 lines) that is the heart of the Checking phase.

**Namespace(s)**
`module internal FSharp.Compiler.CheckExpressions`

**Exceptions declared** (all in this module; see `.fsi` for the full set)
- `FunctionExpected`, `NotAFunction`, `NotAFunctionButIndexer` — function-application errors.
- `Recursion`, `RecursiveUseCheckedAtRuntime`, `LetRecEvaluatedOutOfOrder`, `LetRecCheckedAtRuntime`, `LetRecUnsound` — recursive-binding errors.
- `TyconBadArgs`, `UnionCaseWrongArguments`, `UnionCaseWrongNumberOfArgs`, `FieldsFromDifferentTypes`, `FieldGivenTwice`, `MissingFields` — constructor/record errors.
- `UnitTypeExpected*` (several variants, incl. property-setter/assignment suggestions), `FunctionValueUnexpected`, `VarBoundTwice`, `UnionPatternsBindDifferentNames` — statement/value errors.
- `ValueRestriction` — value restriction (eager generalization) diagnostic.
- `ValNotMutable`, `ValNotLocal` — assignment errors.
- Coercion family: `InvalidRuntimeCoercion`, `IndeterminateRuntimeCoercion`, `IndeterminateStaticCoercion`, `StaticCoercionShouldUseBox`, `RuntimeCoercionSourceSealed`, `CoercionTargetSealed`, `UpcastUnnecessary`, `TypeTestUnnecessary`.
- Object/class: `SelfRefObjCtor`, `VirtualAugmentationOnNullValuedType`, `NonVirtualAugmentationOnNullValuedType`, `IntfImplInIntrinsicAugmentation`, `IntfImplInExtrinsicAugmentation`, `OverrideInIntrinsicAugmentation`, `OverrideInExtrinsicAugmentation`, `NonUniqueInferredAbstractSlot`.
- `UseOfAddressOfOperator`, `DeprecatedThreadStaticBindingWarning`, `StandardOperatorRedefinitionWarning`, `BakedInMemberConstraintName`, `InvalidInternalsVisibleToAssemblyName`, `InvalidAttributeTargetForLanguageElement`.

**Core checking entry points** (the `and`-recursive `Tc*` family)
- `TcExpr` — the main entry: check `SynExpr` under an `OverallTy` to `Expr` (wraps error recovery).
- `TcExprNoRecover` — inner unchecked entry.
- `TcExprOfUnknownType`, `TcExprFlex`, `TcExprFlex2`, `TcExprUndelayed(NoType)`, `TcExprThen`, `TcExprThenSetDynamic`, `TcExprThenDynamic` (`?` dynamic members), `TcExprsNoFlexes`, `TcExprsWithFlexes`, `TcStmtThatCantBeCtorBody`, `TcExprThatIs/CantBe/CanBeCtorBody`, `TcExprOfUnknownTypeThen` — the variant checking functions for different contexts.
- `TcExprMatch` / `TcExprMatchLambda` — match and `function` expressions (feeds `PatternMatchCompilation` via `CheckExpressionsOps.CompilePatternForMatch`).
- `TcExprTypeAnnotated`, `TcExprTypeTest` — typed and `:?>`-tested expressions.
- `TcVal` — the workhorse: check a value/function/member (curried args, member data, safe init, genericity), producing `Val` + `Expr`.
- `TcValSpec`, `TcAndPublishValSpec` — spec-check a value binding and publish it as a symbol.
- `TcNewExpr` — `new X(...)` / inheritance expressions (drives method-override checking with `MethodOverrides`).
- `TcNameOfExpr`, `TcTyparConstraints`, `TcTyparDecls`, `TcType(AndRecover|OrMeasureAndRecover)`, `TcConst`, `TcAttributes*`, `TcFieldInit`, `TcMatchPattern`, `TcLetBindings`, `TcLetrecBinding(s)`, `TcLetrecAdjustMemberForSpecialVals`, `TcProvidedTypeAppToStaticConstantArgs` (`#if !NO_TYPEPROVIDERS`), `TcRuntimeTypeTest`.
- Dispatch helpers for expression kinds: `TcExprApplication`, `TcExprDotGet`/`TcExprDotSet`/`TcExprDotGetOrSet`, member/property/field/indexer cases, `TcExprRecord*`, `TcExprNewRecord`, `TcExprArray*`, `TcExprSeq`/computed expressions, `TcExprQuote`/`TcExprReflectedDefinition`, `TcExprOp` (operators), `TcExprDelegate`, `TcExprAddressOf*/ValueSet`, `TcExprStaticOptimization`, `TcExprForEach`/`TcExprFor` — one function per `SynExpr` case (a huge set; see the dispatch table near `TcExprNoRecover`).

**Type/environment machinery**
- `TcEnv`, `AddLocalVal(s)(Primitive)`, `AddDeclaredTypars`, `MakeInnerEnv(WithAcc)For(TyconRef)`, `LocateEnv`, `GetCurrAccumulatedModuleOrNamespaceType`.
- Generalization: `ChooseCanonicalDeclaredTyparsAfterInference`, `ChooseCanonicalValSchemeAfterInference`, `ComputeIsComplete`, `NonGenericTypeScheme`, `unionGeneralizedTypars`, `SetTyparRigid`, `permitInferTypars` / `dontInferTypars`.
- Publishing symbols: `PublishValueDefn(MaybeInclCompilerGenerated)`, `PublishTypeDefn`, `PublishModuleDefn`, `MakeAndPublish(Simple|Base|SafeThis)Val`, `MakeMemberDataAndMangledNameForMemberVal`, `MakeCheckSafeInit`, `EliminateInitializationGraphs`, `CheckRecursiveInlineGroup`, `FixupLetrecBind`.
- Access/compile path: `ComputeAccessRights`, `ComputeAccessAndCompPath`, `ExprContainerInfo`, `ContainerInfo` machinery.
- `ConvertArbitraryExprToEnumerable`, `UnifyTupleTypeAndInferCharacteristics`, `CheckRecdExprDuplicateFields`, `BuildFieldMap`, `CheckTupleIsCorrectLength`, `RecordNameAndTypeResolutions`, `EliminateNullnessFromInputType` (pattern-guard nullness narrowing), `ConvSynPatToSynExpr`, `TcPatLongIdentActivePatternCase`, `(|BinOpExpr|_|)`.

**Significant internal logic**
- `TcExprNoRecover` is a large match over every `SynExpr` case dispatching to a `TcExpr*` function; each
  builds a checked `Expr` and threads the `UnscopedTyparEnv` (which accumulates declared typars for later
  generalization).
- Value checking (`TcVal`) performs: argument-group checking, member-data construction
  (`InferGenericArityFromTyScheme`), safe-init for object-expression methods (`MakeCheckSafeInit`,
  `GetInstanceMemberThisVariable`), value-restriction detection, and publication as a `Val`.
- Overloaded member/constructor dispatch goes through `ConstraintSolver.ResolveOverloadingForCall` using
  the `MethodCalls.CalledMeth` machinery, with `OverloadResolutionRules.findDecidingRule` for ranking and
  `OverloadResolutionCache` for memoization.
- `let rec` checking splits into pre-check (recursive group collection, `uncheckedRecBindsTable`),
  constraint accumulation, and post-generalization fixups (`FixupLetrecBind`,
  `AnalyzeAndMakeAndPublishRecursiveValue`); `CheckRecursiveInlineGroup` handles mutually-inline groups.
- Error recovery: `try/catch FSharpDiagnosticError` around each sub-check reports the diagnostic and
  synthesizes a dummy typed result so checking can continue (`errorRecovery`); `TcExpr` itself is the
  recovery boundary.
- Object expressions drive `MethodOverrides.DispatchSlotChecking` (`GetSlotImplSets`,
  `CheckDispatchSlotsAreImplemented`, `CheckOverridesAreAllUsedOnce`) and `SafeInit` analysis.

**Cross-references**
- `CheckExpressions.fsi` — public contract (the full `Tc*` surface, exceptions, env helpers).
- `CheckExpressionsOps.fs` (sibling) — shared helpers: `TcVal` for use in `BuildMethodCall`,
  `CompilePatternForMatch`, `FreshenPossibleForallTy`, `ConvertArbitraryExprToEnumerable`,
  `InferGenericArityFromTyScheme`.
- `CheckBasics.fs` (Checking dir) — `TcFileState`, `TcEnv`, `PrelimVal*`, `CtorInfo`, decl kinds.
- `CheckPatterns.fs` (Checking dir) — pattern checking producing input to `TcMatchPattern`/patterns.
- `MethodCalls.fs`, `MethodOverrides.fs` (Checking dir) — call construction and override checking.
- `ConstraintSolver.fs` (Checking dir) — the inference engine threaded throughout.
- `CheckSequenceExpressions.fs`, `CheckArrayOrListComputedExpressions.fs`, `CheckComputationExpressions.fs` (sibling dir) — expression-family checkers invoked from this module.
- `QuotationTranslator.fs` (Checking dir) — checks quotations' bodies via `TcVal`-style functions.
- `NameResolution.fsi` (Checking dir) — name resolution + results-sink plumbing.

# ConstraintSolver.fs

**Purpose**: The core of the F# type-checker's constraint solving (part of the Checking phase). Implements incremental Hindley–Milner-style type inference with .NET generics: primary constraints are **type equations** (`ty1 = ty2`), **subsumption inequations** (`ty1 :> ty2`), and **trait (SRTP) constraints**; plus .NET-generic constraints (static/dynamic req, measures, enum/delegate/structural constraints). Constraints are immediately processed into a normal form (bindings on inference variables) and the solver state is kept in imperative mutations to inference type variables. Supports "undo" mode for can-unify predicates in overload resolution and SRTP solving, though back-tracking is limited and intentional non-solvability for some overloading/SRTP cases is by design (see module header comment, lines 3-41).

**Namespace(s)**: `module internal FSharp.Compiler.ConstraintSolver`

**Core types** (see .fsi for contracts):
- `ContextInfo` — why a type equation was added (IfExpression, OmittedElseBranch, RecordFields, CollectionElement, DowncastUsedInsteadOfUpcast, NullnessCheckOfCapturedArg, MemberAccessOnNullable, …) — drives context-sensitive diagnostics (e.g. "downcast could be an upcast").
- `ObjArgInfo` — receiver info for dotted member access on a nullable receiver (targeted nullness warnings).
- `OverloadInformation` / `OverloadResolutionFailure` (`NoOverloadsFound` | `PossibleCandidates`) — failure reporting for method overload resolution.
- `OverallTy` — `MustEqual of TType` | `MustConvertTo of isMethodArg * TType`, with `Commit: TType`; the "expected type" passed into expression checking.
- A family of diagnostic `exception`s: `ConstraintSolverTupleDiffLengths`, `ConstraintSolverInfiniteTypes` (occurs check), `ConstraintSolverTypesNotInEqualityRelation`, `ConstraintSolverTypesNotInSubsumptionRelation`, `ConstraintSolverMissingConstraint`, the `ConstraintSolverNullnessWarning*` family, `ConstraintSolverError`, `ErrorFromApplyingDefault`, `ErrorFromAddingTypeEquation`, `ErrorsFromAddingSubsumptionConstraint`, `ErrorFromAddingConstraint`, `UnresolvedConversionOperator`, `UnresolvedOverloading`, `NonRigidTypar`, `ArgDoesNotMatchError`.
- `TcValF = ValRef -> ValUseFlag -> TType list -> range -> Expr * TType` — captured value-freshening function.
- `ConstraintSolverState` (lines 216+ of .fsi) — `{ g; amap; InfoReader; TcVal; mutable ExtraCxs : HashMultiMap<Stamp, TraitConstraintInfo * range>; PostInferenceChecksPreDefaults : ResizeArray<unit->unit>; PostInferenceChecksFinal : ...; WarnWhenUsingWithoutNullOnAWithNullTarget }` with `static member New`, `PushPostInferenceCheck`, `GetPostInferenceChecksPreDefaults/Final`. `ExtraCxs` stores all unsolved/un-generalized trait constraints indexed by free type variable.
- `Trace` / `OptionalTrace` — optional tracing for constraint solving.

**Key public API** (implemented here; signatures in .fsi):
- Constraint adding: `AddCxTypeEqualsType` (+ `UndoIfFailed`, `UndoIfFailedOrWarnings`, `MatchingOnlyUndoIfFailed`, `WithContext` variants), `AddCxTypeMustSubsumeType` (+ variants), `AddCxMethodConstraint`, `AddCxTypeDefnNotSupportsNull`, `AddCxTypeUseSupportsNull`, `AddCxTypeCanCarryNullnessInfo`, `AddCxTypeMustSupportComparison/Equality/DefaultCtor`, `AddCxTypeIsReferenceType/ValueType/Unmanaged/Enum/Delegate`, `AddCxTyparDefaultsTo`, `SolveTypeAsError`, `ApplyTyparDefaultAtPriority`.
- Solving: `ChooseTyparSolutionAndSolve` (line 4308), `UpdateStaticReqOfTypar` (4021), `EliminateConstraintsForGeneralizedTypars` (4037), `CheckDeclaredTypars` (4318), `CanonicalizePartialInferenceProblem` (4330), `SolveTyparsEqualTypes` (4371).
- Overload resolution: `ResolveOverloadingForCall` (line 3959) — entry point to resolve overloading for an entire call (delegates into the overload machinery, `UnifyUniqueOverloading` at 3971).
- Trait witness codegen: `CodegenWitnessExprForTraitConstraint` (+`WillRequireWitnessArgs`), `CodegenWitnessesForTyparInst`, `CodegenWitnessArgForTraitConstraint` (lines 4250-4307, with `CreateCodegenState` helper at 4250).
- Measures (units of measure): `SimplifyMeasuresInTypeScheme` (line 943+), `UnifyMeasures` (803), `UnifyMeasureWithOne` (784), `SimplifyMeasure` (809), `SimplifyMeasuresInType/InTypes/InConstraint(s)`, `GetMeasureVarGcdInType(s)`, `NormalizeExponentsInTypeScheme` (907).
- `FreshenTypar`, `FreshenAndFixupTypars`, `FreshenTypeInst`, `FreshMethInst`, `FreshenMethInfo` (lines 108-130) — typar/type/method instantiation for freshened copies (used when resolving overload candidates).
- `BakedInTraitConstraintNames` (line 470) — the set of F# built-in SRTP constraint names.
- `IsApplicableMethApprox` (4342) — approximate check whether a method is applicable for overload filtering.
- `NewCompGenTypar/NewAnonTypar/NewNamedInferenceMeasureVar/NewInferenceMeasurePar/NewErrorTypar/NewErrorType` (88-106) — inference-variable constructors.

**Core solving loop (internal)**:
- `MakeConstraintSolverEnv` (line 363) — wraps `cenv/css/m/denv` into the `ConstraintSolverEnv` used by the core unification functions.
- `TransactStaticReq` / `SolveTypStaticReqTypar` / `SolveTypStaticReq` (693-727), `TransactDynamicReq`/`SolveTypDynamicReq` (729-741), `TransactIsCompatFlex`/`SolveTypIsCompatFlex` (743-753) — static-requirement solving.
- `occursCheck` (line 388) — infinite-type detection.
- Typar preference: `PreferUnifyTypar` (629), `FindPreferredTypar` (672).
- `SolveTyparEqualsTypePart1` (line 980, rec) — the heart of `tp = ty` solving (part of the multi-part unification for typar-type equalities).
- Error recovery helpers: `CollectThenUndo` (521), `FilterEachThenUndo` (527), `IgnoreFailedMemberConstraintResolution` (577), `PostponeOnFailedMemberConstraintResolution` (597) — used in SRTP/overload paths.
- Type-shape predicates: `isNativeIntegerTy`, `IsIntegerOrIntegerEnumTy`, `IsNumericOrIntegralEnumType`, `IsRelationalType`, `IsAddSubModType`, `IsBitwiseOpType`, `IsBinaryOpOtherArgType`, `IsSignType` (419-470) — constrain which types may flow into `printf`-style and language-op positions.
- `UndoIfFailed` / `UndoIfFailedOrWarnings` (4064/4081) — the limited undo machinery.

**Significant internal logic** (from the module header and code):
1. Any solution that is found must be sound (no logic skipped).
2. Processing of constraints is algorithmic and must proceed in a definite fixed order; once resolutions start in a particular order they must continue in that order — this is why overload resolution uses candidate filtering + can-unify probes rather than full backtracking.
3. Backtracking/undo is limited to SRTP solving, method overloading, and ad-hoc cases (e.g. printf format strings); some overloading/SRTP combinations are intentionally unsolvable.

**Cross-references**: `ConstraintSolver.fsi` (contract), `CheckBasics.fsi` (`TcFileState.css` holds a `ConstraintSolverState`), `InfoReader.fs` (member sets for trait/overload resolution), `MethodCalls.fs` / `OverloadResolutionRules.fs` / `OverloadResolutionCache.fs` (overload machinery), `TypeRelations.fs` / `TypeHierarchy.fs` (type structure checks), `NameResolution.fs` (type-directed name resolution queries the solver state), `PostInferenceChecks.fs` (runs the `PostInferenceChecks*` queues).

# ConstraintSolver.fsi

**Purpose**: Public contract of the F# compiler's constraint solver. Declares the solver state (`ConstraintSolverState`), the context-overload/trait constraint vocabulary, the `OverallTy` expected-type abstraction, the full set of `AddCx*` constraint-adders, the trait-witness codegen entry points, overload-resolution entry points, and the diagnostic exceptions the solver raises. Implementation-specific unification internals are not part of the contract.

**Namespace(s)**: `module internal FSharp.Compiler.ConstraintSolver`

**Types declared**:
- `ContextInfo` ([<RequireQualifiedAccess>], lines 21-71) — why a type equation was added: `NoContext`, `IfExpression`, `OmittedElseBranch`, `ElseBranchResult`, `RecordFields`, `TupleInRecordFields`, `CollectionElement`, `ReturnInComputationExpression`, `YieldInComputationExpression`, `RuntimeTypeTest`, `DowncastUsedInsteadOfUpcast`, `FollowingPatternMatchClause`, `PatternMatchGuard`, `SequenceExpression`, `NullnessCheckOfCapturedArg`, `MemberAccessOnNullable of ObjArgInfo`.
- `ObjArgInfo` — `{ ObjExprRange: range; MemberName: string; BindingName: string option }` (targeted nullness warnings).
- `OverloadInformation` — `{ methodSlot: CalledMeth<Expr>; infoReader: InfoReader; error: exn }`.
- `OverloadResolutionFailure` — `NoOverloadsFound` | `PossibleCandidates` (with `OverloadResolutionRules.IncomparableConcretenessInfo option`).
- `OverallTy` — `MustEqual of TType` | `MustConvertTo of isMethodArg * TType`; `member Commit : TType`.
- Exceptions (lines 106-211): `ConstraintSolverTupleDiffLengths`, `ConstraintSolverInfiniteTypes`, `ConstraintSolverTypesNotInEqualityRelation`, `ConstraintSolverTypesNotInSubsumptionRelation`, `ConstraintSolverMissingConstraint`, `ConstraintSolverNullnessWarningEquivWithTypes`, `ConstraintSolverNullnessWarningWithTypes`, `ConstraintSolverNullnessWarningWithType`, `ConstraintSolverNullnessWarning`, `ConstraintSolverNullnessWarningOnDotAccess`, `ConstraintSolverError`, `ErrorFromApplyingDefault`, `ErrorFromAddingTypeEquation`, `ErrorsFromAddingSubsumptionConstraint`, `ErrorFromAddingConstraint`, `UnresolvedConversionOperator`, `UnresolvedOverloading`, `NonRigidTypar`, `ArgDoesNotMatchError`.
- `TcValF` (line 214) — the captured value-freshening function type.
- `ConstraintSolverState` (line 216) — `{ g; amap; InfoReader; TcVal; mutable ExtraCxs : HashMultiMap<Stamp, TraitConstraintInfo * range>; PostInferenceChecksPreDefaults : ResizeArray<unit->unit>; PostInferenceChecksFinal : ...; WarnWhenUsingWithoutNullOnAWithNullTarget : string option }`; `static member New`; `PushPostInferenceCheck`, `GetPostInferenceChecksPreDefaults`, `GetPostInferenceChecksFinal`. `ExtraCxs` holds the unsolved/un-generalized trait constraints indexed by free type variable (removed when a solution is found).
- `Trace` ([<Sealed>]) / `OptionalTrace` (`NoTrace` | `WithTrace of Trace`).

**Public API surface** (val contracts):
- `BakedInTraitConstraintNames : Set<string>` (line 253).
- `SimplifyMeasuresInTypeScheme : TcGlobals -> bool -> Typars -> TType -> TyparConstraint list -> Typars` (line 262).
- `ResolveOverloadingForCall : DisplayEnv -> ConstraintSolverState -> range -> ObjArgInfo option -> string -> CallerArgs<Expr> -> AccessorDomain -> CalledMeth<Expr> list -> permitOptArgs -> OverallTy -> CalledMeth<Expr> option * OperationResult<unit>` (line 265) — entry point to resolve overload for an entire call.
- `UnifyUniqueOverloading` (line 278) — variant over `CalledMeth<SynExpr>` for signature/constraints unification.
- `UpdateStaticReqOfTypar`, `EliminateConstraintsForGeneralizedTypars`, `CheckDeclaredTypars` (lines 291-297).
- `AddCxTypeEqualsType` / `...UndoIfFailed` / `...UndoIfFailedWithContext` / `...UndoIfFailedOrWarnings` / `...MatchingOnlyUndoIfFailed` (lines 299-308); `AddCxTypeMustSubsumeType` / `...UndoIfFailed` / `...MatchingOnlyUndoIfFailed` (lines 310-316).
- `AddCxMethodConstraint` (318), `AddCxTypeDefnNotSupportsNull` (320), `AddCxTypeUseSupportsNull` (322), `AddCxTypeCanCarryNullnessInfo` (324), `AddCxTypeMustSupportComparison` (326), `...Equality` (328), `...DefaultCtor` (330), `AddCxTypeIsReferenceType` (332), `...ValueType` (334), `...Unmanaged` (336), `...Enum` (338), `...Delegate` (340), `AddCxTyparDefaultsTo` (343), `SolveTypeAsError` (345), `ApplyTyparDefaultAtPriority` (347).
- Trait witness codegen (lines 350-378): `CodegenWitnessExprForTraitConstraint`, `CodegenWitnessExprForTraitConstraintWillRequireWitnessArgs`, `CodegenWitnessesForTyparInst`, `CodegenWitnessArgForTraitConstraint`.
- `ChooseTyparSolutionAndSolve : ConstraintSolverState -> DisplayEnv -> Typar -> unit` (379); `IsApplicableMethApprox : TcGlobals -> ImportMap -> range -> MethInfo -> TType -> bool` (381); `CanonicalizePartialInferenceProblem : ConstraintSolverState -> DisplayEnv -> range -> Typars -> unit` (383); `SolveTyparsEqualTypes : TcGlobals -> ConstraintSolverState -> range -> TypeInst -> TypeInst -> unit` (385).

**Implementation-only (in the .fs)**: `NewCompGenTypar`/`NewAnonTypar`/`NewNamedInferenceMeasureVar`/`NewInferenceMeasurePar`/`NewErrorTypar`/`NewErrorType`, `FreshenTypar`/`FreshenAndFixupTypars`/`FreshenTypeInst`/`FreshMethInst`/`FreshenMethInfo`, `MakeConstraintSolverEnv`, `occursCheck`, `PreferUnifyTypar`/`FindPreferredTypar`, the `Transact*/SolveTyp*` family, `UnifyMeasures`/`SimplifyMeasures*`/`GetMeasureVarGcdInType*`/`NormalizeExponentsInTypeScheme`, the `Is*Type` shape predicates, `SolveTyparEqualsTypePart1`, `CollectThenUndo`/`FilterEachThenUndo`/`IgnoreFailedMemberConstraintResolution`/`PostponeOnFailedMemberConstraintResolution`, `UndoIfFailed*`, `CreateCodegenState`.

**Cross-references**: `ConstraintSolver.fs` (implementation), `CheckBasics.fsi` (holds a `ConstraintSolverState`), `InfoReader.fsi`, `MethodCalls.fsi`/`OverloadResolutionRules.fsi`/`OverloadResolutionCache.fsi`, `TypeRelations.fsi`/`TypeHierarchy.fsi`, `PostInferenceChecks.fsi` (consumes the PostInferenceChecks queues), `NameResolution.fsi`, `AccessibilityLogic.fsi` (`AccessorDomain`).

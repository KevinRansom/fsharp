# TypeRelations.fsi

**Purpose**
Public contract (internal module) for the "primary relations on types and signatures, with the exception
of constraint solving and method overload resolution." Declares the feasible equivalence/subsumption
relations, the typar-solution choosing and grounding entry points, the lambda deconstruction / arity
adjustment helpers, and the "single feasible type" inference used for upcasts.

**Namespace(s)**
`module internal FSharp.Compiler.TypeRelations`

**Types declared**
- `CanCoerce` (`[Struct; NoComparison]`) — `CanCoerce | NoCoerce` (the `canCoerce` discriminator in `TypeFeasiblySubsumesType`).

**Public API surface** (signatures as declared)
- `TypeDefinitelySubsumesTypeNoCoercion: ndeep: int -> g: TcGlobals -> amap: ImportMap -> m: range -> ty1: TType -> ty2: TType -> bool` — implements `:> b` without coercion based on finalized (no type variable) types.
- `TypesFeasiblyEquivalent: stripMeasures: bool -> ndeep: int -> g -> amap: 'a -> m -> ty1 -> ty2 -> bool` — the feasible equivalence relation (part of the language spec).
- `TypesFeasiblyEquiv: ndeep -> g -> amap: 'a -> m -> ty1 -> ty2 -> bool` — the same, `stripMeasures=false`.
- `TypesFeasiblyEquivStripMeasures: g -> amap: 'a -> m -> ty1 -> ty2 -> bool` — the same, `stripMeasures=true`.
- `TypeFeasiblySubsumesType: ndeep -> g -> amap -> m -> ty1 -> canCoerce: CanCoerce -> ty2 -> bool` — the feasible coercion relation (part of the language spec).
- `ChooseTyparSolutionAndRange: g -> amap -> tp: Typar -> TType * range` — choose a solution for a letrec / generalized-binding `Expr.TyChoose` typar; also used by the pattern-match compiler for generalized bindings (e.g. `let ([], x) = ([], [])`).
- `ChooseTyparSolution: g -> amap -> tp -> TType`.
- `IterativelySubstituteTyparSolutions: g -> tps: Typars -> solutions: TTypes -> TypeInst` — ground out mutually-referential solutions.
- `ChooseTyparSolutionsForFreeChoiceTypars: g -> amap -> e: Expr -> Expr` — eliminate `Expr.TyChoose` nodes.
- `tryDestLambdaWithValReprInfo: g -> amap -> valReprInfo: ValReprInfo -> lambdaExpr: Expr * ty: TType -> (Typars * Val option * Val option * Val list list * Expr * TType) option` — break a lambda apart according to a given `ValReprInfo`.
- `destLambdaWithValReprInfo: (same shape -> non-optional tuple)` — same, but errors if the lambda doesn't decompose.
- `IteratedAdjustLambdaToMatchValReprInfo: g -> amap -> valReprInfo -> lambdaExpr: Expr -> Typars * Val option * Val option * Val list list * Expr * TType` — adjust an iterated lambda's arity to match the `ValReprInfo`.
- `FindUniqueFeasibleSupertype: g -> amap -> m -> ty1 -> ty2 -> TType option` — "Single Feasible Type" inference: the unique supertype of `ty2` for which `ty2 :> ty1` might feasibly hold.

**Significant notes**
- The doc comments distinguish the three strength levels: `TypeDefinitelySubsumesTypeNoCoercion` is
  *approximate* (used for warnings and codegen optimizations); `TypesFeasiblyEquivalent` and
  `TypeFeasiblySubsumesType` are the *spec-defined* relations used by constraint solving.
- `ChooseTyparSolutionAndRange` doc gives the canonical example: `let ([], x) = ([], [])` — `x` gets the
  generalized type `list<'T>`.
- `IterativelySubstituteTyparSolutions` doc: solutions can refer to each other (e.g. `'a = Expr<'b>`,
  `'b = int`), so they must be grounded by repeated instantiation.
- `FindUniqueFeasibleSupertype` is the entry point for the "Single Feasible Type" rule that F# applies at
  upcast/coercion sites where a unique target is expected.

**Cross-references**
- `TypeRelations.fs` — implementation (the `TTypeCacheKey` + per-TcGlobals subsumption cache, the
  `IteratedAdjustArityOfLambdaBody` fold, the constraint-LUB folding in `ChooseTyparSolutionAndRange`).
- `TypeHierarchy.fsi` — the hierarchy queries these relations use.
- `ConstraintSolver.fsi` (sibling) — the constraint-solver uses these relations inside its solving loop.
- `MethodCalls.fsi` / `OverloadResolutionRules.fsi` — the call/overload machinery built on top.
- `PostInferenceChecks.fs` / `QuotationTranslator.fs` — both call the `destLambda` /
  `IteratedAdjustLambda` functions on TAST.

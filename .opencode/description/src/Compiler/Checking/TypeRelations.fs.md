# TypeRelations.fs

**Purpose**
Implements the "primary relations on types and signatures" — the spec'd type equivalence and subsumption
relations (feasible equivalence, feasible subsumption, definite subsumption without coercion), together
with supporting machinery: typar-solution choosing and grounding for free-choice typars (letrec / pattern
generalization), lambda deconstruction to a given `ValReprInfo` (method/arity adjustment), and the
"single feasible type" inference used for upcasting/coercion sites. These relations are the decision
procedural core that constraint solving and overload resolution build on, but are usable independently on
finalized / approximately-equivalent types.

**Namespace(s)**
`module internal FSharp.Compiler.TypeRelations`

**Types declared**
- `CanCoerce` (`[Struct; NoComparison]`) — `CanCoerce | NoCoerce`.
- `TTypeCacheKey` (private struct) — `TTypeCacheKey of TypeStructure * TypeStructure * CanCoerce`; `static member TryGetFromStrippedTypes` builds the key from two `TType_app` types. Pairs with the subsumption cache (see below).

**Public API surface** (see `.fsi`)
- `TypeDefinitelySubsumesTypeNoCoercion: ndeep -> g -> amap -> m -> ty1 -> ty2 -> bool` — approximate "definitely subsumes" (no coercion). Documented uses: `IsDiscrimSubsumedBy` (redundant `isinst` warnings), `TcRuntimeTypeTest` (redundant type-test warnings), `TcExnDefnCore` (bad exception abbreviation), `GenCoerce` (omit unnecessary `castclass`/`isinst`).
- `TypesFeasiblyEquivalent: stripMeasures -> ndeep -> g -> amap -> m -> ty1 -> ty2 -> bool` — feasible equivalence (language spec).
- `TypesFeasiblyEquiv: ndeep -> g -> amap -> m -> ty1 -> ty2 -> bool` — `stripMeasures=false` shortcut.
- `TypesFeasiblyEquivStripMeasures: g -> amap -> m -> ty1 -> ty2 -> bool` — `stripMeasures=true, ndeep=0`.
- `TypeFeasiblySubsumesType: ndeep -> g -> amap -> m -> ty1 -> canCoerce -> ty2 -> bool` — feasible coercion relation (language spec).
- `ChooseTyparSolutionAndRange: g -> amap -> tp -> TType * range` — pick a solution for a typar (LUB over its constraints); returns type + range.
- `ChooseTyparSolution: g -> amap -> tp -> TType` — convenience wrapper; warns `csCodeLessGeneric` for anon typars solved to `Measure.One`.
- `IterativelySubstituteTyparSolutions: g -> tps -> solutions -> TypeInst` — ground out mutually-referential solutions (e.g. `'a = Expr<'b>, 'b = int`), cut off at 40 iterations.
- `ChooseTyparSolutionsForFreeChoiceTypars: g -> amap -> e -> Expr` — eliminate `Expr.TyChoose` nodes by choosing solutions for the free typars actually used in the body.
- `tryDestLambdaWithValReprInfo: g -> amap -> valReprInfo -> (Expr * TType) -> (Typars * Val option * Val option * Val list list * Expr * TType) option` — deconstruct a (possibly `TyLambda`/`TyChoose`-wrapped) lambda to the given val repr.
- `destLambdaWithValReprInfo` — same, but errors (`typrelInvalidValue`) instead of returning `None`.
- `IteratedAdjustLambdaToMatchValReprInfo: g -> amap -> valReprInfo -> Expr -> Typars * Val option * Val option * Val list list * Expr * TType` — iterated-arity adjustment for a series of lambdas forming one method.
- `FindUniqueFeasibleSupertype: g -> amap -> m -> ty1 -> ty2 -> TType option` — single-feasible-type inference for upcasts: the unique supertype of `ty2` that `ty1` feasibly subsumes.

**Internal helpers**
- `stripAll` — strip type equations (+ measures when requested).
- `getTypeSubsumptionCache` — per-`TcGlobals` (via `WeakMap`) LRU cache of `TTypeCacheKey -> bool` for `TypeFeasiblySubsumesType` (OneOff: no eviction; else 65536/75% headroom). Gated on `LanguageFeature.UseTypeSubsumptionCache`.
- `TypeFeasiblySubsumesTypeWithSupertypeCheck` — the supertype-chain half of feasible subsumption.
- `IteratedAdjustArityOfLambdaBody` — fold `AdjustArityOfLambdaBody` (from `TypedTreeOps`) across a series of lambda arities.

**Significant internal logic and relations**
- The three relations have different "strengths" and uses, deliberately distinct:
  - *Definitely subsumes, no coercion* is approximate and for optimizations/warnings (see the comment in-source).
  - *Feasibly equivalent* is the core spec equivalence used inside subsumption and by constraint solving.
  - *Feasibly subsumes* adds the super-type/interface walk and the `obj`-subtype rule.
- `TypesFeasiblyEquivalent` recurses over `TType_app` (same tycon + arg-wise equivalence), `TType_anon`
  (struct flag, assembly, sorted names), `TType_tuple`, `TType_fun`, `TType_measure`, and treats any
  type-variable side as equivalent. Depth is capped at 100 to catch accidental recursive hierarchies.
- `TypeFeasiblySubsumesType` consults the per-TcGlobals subsumption cache for `TType_app` pairs (keyed by
  structural type signatures) when the language feature is on; otherwise computes directly. This is a
  significant performance optimization for large generic hierarchies.
- `ChooseTyparSolutionAndRange` folds over the typar's constraints to a LUB (join), erroring
  (`typrelCannotResolveImplicitGenericInstantiation`, `...AmbiguityInPrintf`, `...InEnum`, `...InDelegate`,
  `...InUnmanaged`) when the join is undefined; `SupportsNull` raises nullness, `SupportsComparison`
  joins with `IComparable`, `IsNonNullableStruct` joins with `int`.
- `IterativelySubstituteTyparSolutions` grounds out solutions by repeated instantiation, cut at 40
  (comment explains no cycle is expected in the solution equations; the bound is safety for error recovery).
- `tryDestLambdaWithValReprInfo` / `destLambdaWithValReprInfo` strip `Expr.Lambda`/`Expr.TyLambda`/
  `Expr.TyChoose` to produce the `(typars, ctorThisVal, baseVal, vs, body, retTy)` shape used by
  `PostTypeCheckSemanticChecks` (the .fs comment notes it must be callable before free-choice typars are
  eliminated in that pass).

**Cross-references**
- `TypeRelations.fsi` — public contract.
- `TypeHierarchy.fsi` — `GetSuperTypeOfType` / `GetImmediateInterfacesOfType` are the hierarchy primitives
  these relations build on.
- `ConstraintSolver.fs` (sibling) — constraint solving uses `TypesFeasiblyEquivalent` /
  `TypeFeasiblySubsumesType` in the relation-adding code.
- `OverloadResolutionRules.fs` (sibling) — the concreteness comparisons reuse the same type structure as
  `TTypeCacheKey`.
- `MethodCalls.fsi` — `TypeDirectedConversionUsed` and TDC adjustments interact with the coercion relation.
- `PostInferenceChecks.fs` / `QuotationTranslator.fs` — both call `destLambdaWithValReprInfo` /
  `IteratedAdjustLambdaToMatchValReprInfo` on TAST.
- `Utilities/Caches.fsi` — the generic cache used for the subsumption memoization.

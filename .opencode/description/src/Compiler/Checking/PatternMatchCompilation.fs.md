# PatternMatchCompilation.fs

**Purpose**
Implements the F# pattern match compiler: takes the typed (`Pattern`) form of match clauses produced by
pattern checking (see `CheckPatterns.fs`) and compiles them into a `DecisionTree` — the optimized form
used by codegen (discriminated tests, switch tests, subsumes/succeeds-based tree refinement). Handles
completeness checking (incomplete match errors, never-matched rules, enumeration of missing cases),
guard clauses, and the tricky "nasty" generic bindings where the input is a generalized (poly) type
(`let ([], x) = ([], [])`, `let x, y = [], []`).

**Namespace(s)**
`module internal FSharp.Compiler.PatternMatchCompilation`

**Modules / Types declared** (see `PatternMatchCompilation.fsi`)
- `ActionOnFailure` — what the decision tree should do for an incomplete match: `ThrowIncompleteMatchException` (default), `IgnoreWithWarning`, `Throw`, `Rethrow`, `FailFilter`.
- `Pattern` — the typed pattern tree: `TPat_const`, `TPat_wild`, `TPat_as`, `TPat_disjs`, `TPat_conjs`, `TPat_query` (active pattern), `TPat_unioncase`, `TPat_exnconstr`, `TPat_tuple`, `TPat_array`, `TPat_recd`, `TPat_null`, `TPat_isinst`, `TPat_error`; `Range` member.
- `PatternValBinding = PatternValBinding of Val * GeneralizedType` — bound value (possibly with a generalized type scheme) per pattern variable.
- `MatchClause = MatchClause of Pattern * Expr option (guard) * DecisionTreeTarget * range`; members `GuardExpr`, `Pattern`, `Range`, `Target`, `BoundVals`.
- `SubExprOfInput` — helper for "nasty" generic bindings: `SubExpr of (TyparInstantiation -> Expr -> Expr) * (Expr * Val)` — accessors to extract a subexpression of a poly input.
- Exceptions: `MatchIncomplete` (carries `isComputationExpression`, a counter-example `(RichText * bool)`, range), `MatchIncompleteForLoopHint` (wrapper adding a for-loop hint), `RuleNeverMatched` (dead clause), `EnumMatchIncomplete`.

**Public API surface**
- `CompilePattern: TcGlobals -> DisplayEnv -> ImportMap -> (ValRef -> ValUseFlag -> TTypes -> range -> Expr * TType) -> InfoReader -> range (match expr) -> range (incomplete-match reporting) -> bool (warnUnused) -> ActionOnFailure -> Val * Typars * Expr option (input expr) -> MatchClause list -> TType (input type) -> TType (result type) -> DecisionTree * DecisionTreeTarget list * Bindings` — the main entry point. Compiles a match into a decision tree, targets, and any auxiliary bindings (e.g. for poly inputs and value-restriction fixes).
- `ilFieldToTastConst: ILFieldInit -> Const` — convert an IL field initializer into a TAST constant (for IL-backed enum/typed constants in patterns).

**Internal helpers (notable)**
- `BindSubExprOfInput` / `GetSubExprOfInput` — produce bindings/expressions that access sub-parts of a
  generalized input expression (needed for `let x, y = [], []` style poly matches); see the long comment
  block around them in the source.
- Subsumption/success relations over patterns: `patSubsumesPat`, `patSucceedsPat`-style predicates that
  drive the decision-tree "succeeds/failed" refinement. (These are private `let rec` definitions in the .fs.)
- `compilePattern...` family — the recursive pattern-to-`DecisionTree` compilation, producing
  `DecisionTest` nodes for union cases, null tests, typed tests, and array/record/tuple access.
- `makeDiscriminatedTest`, `makeEnumCaseTest`-style helpers build the `DecisionTestDiscriminated` /
  `DecisionTestEnum` test nodes.
- Completeness diagnostics: builds the missing-case `RichText` (via `NicePrint`-style rendering of union
  cases) and counter-examples, raises `MatchIncomplete` / `EnumMatchIncomplete`.
- `checkForNeverMatchedRules` (private) — dead-code detection producing `RuleNeverMatched`.

**Significant internal logic**
- The pattern compiler is a classic "decision tree construction" algorithm: it walks clauses, splitting on
  the input's constructors. For disjunctive/conjunctive patterns it uses `succeeds`/`subsumes` relations to
  prune and to decide where guard clauses and failure actions attach.
- Guards (`when` clauses) and `ActionOnFailure` are attached as `DecisionTreeTarget` continuations rather
  than being spliced into the tree.
- Incomplete matches produce a `MatchIncomplete` exception carrying a *counter-example* (the minimal input
  that would fall through) — this is the data behind `FSCase.InsufficientlyGeneral` and the newer
  missing-case list in messages. `MatchIncompleteForLoopHint` lets callers (e.g. the for-over-expr
  compiler) add a hint that a for-loop was the original source.
- `ActionOnFailure.Rethrow` is used for `try/with`-compilation (the `rethrow` case in a catch-all),
  `Throw` for `try with e -> e` and the `ThrowIncompleteMatchException` for the default behavior.
- Value-restriction and poly-input handling: `PatternValBinding` carries a `GeneralizedType` scheme; when
  the input expression's type is a generalized type function, `BindSubExprOfInput`/`SubExprOfInput` build
  the intermediate lambda bindings (`let v2 = \Gamma ['a,'b]. ([] : 'a, [] : 'b)` style).

**Cross-references**
- `PatternMatchCompilation.fsi` — public contract.
- `CheckPatterns.fs` (sibling) — produces `SynPat` -> typed patterns that feed `Pattern`.
- `CheckExpressionsOps.fs` (Expressions dir) — `CompilePatternForMatch` wraps `CompilePattern` for `TcExprMatch`.
- `ConstraintSolver.fs` (sibling) — the pattern compiler runs within constraint-solver state;
  subsumption/success relations share the type-relations utilities.
- `TypeRelations.fs` / `TypeHierarchy.fs` — subsumption checks used during pattern matching.
- `Optimize/TailCall` (Optimize dir) — consumes the produced `DecisionTree`; `MatchIncomplete` surfaces
  through the FSI/diagnostics layers.

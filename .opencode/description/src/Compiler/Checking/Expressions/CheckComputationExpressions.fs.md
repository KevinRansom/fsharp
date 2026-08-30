# CheckComputationExpressions.fs

**Purpose**
Typechecks computation expressions (`builder { ... }`, query expressions, async/observable/async!-style
builders) during the Checking phase. Resolves the builder, collects the builder's custom operations
(`[<CustomOperation>]` and intrinsic names: `Zero`, `One`, `Return`, `ReturnFrom`, `Bind`, `CombineWith`,
`Delay`, `TryWith`, `TryFinally`, `While`, `For`, `Using`, `ForSource`, `FromSource`, etc.), and performs
a syntactic translation of the computation body into a sequence of builder method calls
(`Return`/`Bind`/`TryWith`/... desugaring), before the translated expression is typechecked by
`TcExpr*`. Handles both the initial and subsequent passes of the translation and the "source expression"
machinery (`FromSource`/`ForSource`) for query expressions.

**Namespace(s)**
`module internal FSharp.Compiler.CheckComputationExpressions`

**Types declared**
- `cenv = TcFileState` — checker file state alias.
- `CompExprTranslationPass` (`[RequireQualifiedAccess; Struct]`) — `Initial | Subsequent`; flags the first vs. a later pass through a comp expr.
- `CustomOperationsMode` — `Allowed | Denied`; whether custom operations are available in the current context (e.g. denied inside `for` loops in some grammars).
- `ComputationExpressionContext<'a>` — the per-translation state: `cenv`, `env`, `tpenv`, custom-operation method tables indexed by keyword and by method name, `sourceMethInfo`, `builderValName`, `ad`, `builderTy`, `isQuery`, `tailCall`, `enableImplicitYield`, `origComp`, `mWhole`, `emptyVarSpace` (lazy env for the empty/`Zero`/`One` variables), `deferredCustomOpSinks`.

**Entry point**
- `TcComputationExpression : cenv -> env -> overallTy -> tpenv -> mWhole: range * interpExpr: Expr * builderTy: TType * comp: SynExpr -> Expr * UnscopedTyparEnv` — exposed via the `.fsi`; checks the computation expression given the (resolved) builder expression, its type, and the syntactic body.

**Notable helpers**
- `noTailCall` — clear the tail-call flag in the context.
- `TryFindIntrinsicOrExtensionMethInfo` — look up a builder method (or extension method) of the builder type by name.
- `IgnoreAttribute` — attribute handler used during custom-op discovery.
- `arbPat` / `arbKeySelectors` — synthetic `_missingVar` pattern and `_keySelectors/_keySelector2` expressions used when translating query operators with missing selectors.
- `addBindDebugPoint` — preserve `DebugPointAtBinding` information through the translation.
- `mkSynDelay2`, `mkSynCall` — synthesize `builder.Method(args)` calls (marked synthetic so the language service doesn't pick them up).
- `mkSourceExpr` / `mkSourceExprConditional` — wrap `let!`/`yield!`/`use!` source expressions in `builder.Source(...)` for query expressions.
- `checkCustomOperation...` family and `DeferredCustomOpSink` usage (via `CheckComputationExpressionsCustomOps.fs`) — capture the resolved overload of an overloaded custom operation at the keyword range (fixes #11612 / #15206, language-service issue for `[<CustomOperation>]` members with overloads).
- The large `and`-recursive `tcExpr`-style translation functions that perform the `SynExpr -> SynExpr` desugaring pass over the computation body, threading the context.

**Significant internal logic**
- The translation is a *syntactic* rewrite (still `SynExpr`) into a nested `Return`/`Bind`/... term over
  the builder value; only afterwards is the result fed to `TcExpr` in `CheckExpressions.fs`. This keeps the
  language service seeing the original comp expr while the checked tree has the builder-call form.
- `emptyVarSpace` lazily computes the `Zero`/`One`/empty-builder variables so they can be referenced
  without being pre-evaluated (important for builders where these differ from each other — the F# spec
  "empty builder" rules).
- Implicit `yield` (`enableImplicitYield`) is allowed when the comp expr contains no explicit `yield`
  (statement-position values are interpreted as yields, per spec).
- `isQuery` switches on query-specific rules (`FromSource`, `ForSource`, `Join`/`GroupBy`/`SortBy` custom
  operations, `Source` wrapping).
- Custom operation discovery builds the two lookup tables (by keyword and by method name) used throughout
  the translation; the deferred-sink mechanism from `CheckComputationExpressionsCustomOps.fs` ensures the
  resolved overload (not just the fallback) is reported at the keyword range.

**Cross-references**
- `CheckComputationExpressions.fsi` — the small public contract (the single `TcComputationExpression`).
- `CheckComputationExpressionsCustomOps.fs` (sibling) — `DeferredCustomOpSink` + capture machinery.
- `CheckSequenceExpressions.fs` (sibling) — the `seq`-specific checker (no builder) that this module
  parallels; `CheckArrayOrListComputedExpressions.fs` sits above both.
- `CheckExpressions.fs` (sibling) — dispatches `SynExpr.CompExpr`/`SynExpr.CompExprWithBuilder` to
  `TcComputationExpression`; provides `TcExpr` used after the translation.
- `CheckBasics.fs` (Checking dir) — `TcFileState`, `TcEnv`, `UnscopedTyparEnv`.
- `NameResolution.fsi` — builder + custom-op member lookup (`AllMethInfosOfTypeInScope`, `TcResultsSink`).

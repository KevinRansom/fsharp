# CheckSequenceExpressions.fs

**Purpose**
Typechecks *sequence expressions* (the `seq { ... }` / `for x in e do ...` / `yield!` body) and the
"simple semicolon sequence" form that underlies `[ a; b; c ]` list literals. Unlike general computation
expressions, sequence expressions have *no builder*: the checker directly generates calls into the `Seq.*`
library and its state-machine helpers (later detected by state-machine compilation), and it performs
"ienumerable extraction" on the argument of `for`. Also applies the legacy peephole
`"for x in e1 do yield e2" → "e1 |> Seq.map (fun x -> e2)"` transformation, which is visible in
quotations and must be preserved.

**Namespace(s)**
`module internal FSharp.Compiler.CheckSequenceExpressions`

**Entry point**
- `TcSequenceExpression : cenv: TcFileState -> env: TcEnv -> tpenv: UnscopedTyparEnv -> comp: SynExpr -> overallTy: OverallTy -> m: range -> Expr * UnscopedTyparEnv` — typecheck a sequence expression body.
- `TcSequenceExpressionEntry : cenv -> env -> overallTy -> tpenv -> hasBuilder: bool * comp: SynExpr -> m -> Expr * UnscopedTyparEnv` — dispatch entry point: the `[n .. m]` range shorthand (via `RewriteRangeExpr`) is checked directly through `TcExpr`; otherwise the body is delegated to `TcSequenceExpression`.

**Active patterns** (used by `CheckArrayOrListComputedExpressions.fs`)
- `(|SimpleSemicolonSequence|_|) cenv -> synExpr -> SynExpr list voption` — recognizes a plain `e1; e2; ...` sequence (no loops/computation), enabling the direct list/array constructor fast path (and the uint16/byte parser-table optimization).

**Significant internal logic**
- The element type is a fresh inference typar (`genEnumElemTy`) unified with `overallTy`; when it is not
  yet nominal, `flex` is set to allow subsumption at `yield` (nominal element types are checked exactly).
- `enableImplicitYield` (via `YieldFree`) turns on the "implicit yield at statement position" rule when
  the body has no explicit `yield` (spec'd behavior).
- `for x in e` checks `e` of unknown type, runs `ConvertArbitraryExprToEnumerable` (shared with
  `CheckExpressionsOps.fs`) to get a canonical enumerable, then checks the loop-pattern and body; the
  `SeqFor`/`SeqMap`/`SeqConcat`-style TAST is built directly from `TcVal`-style calls into `Seq.*`
  intrinsics (not a builder).
- The peephole `"seq { for x in e1 -> e2 } = "e1 |> Seq.map (fun x -> e2)` is applied when the loop body
  is a single `yield` of the body expression and the loop variable is a wild-binding (detected via the
  `TPat_as(TPat_wild _, ...)` + `seq_singleton` check in-source). Debug points (`spFor`,
  `spIn`) are attached to the resulting lambda so they can be recovered by
  `LowerComputedListOrArraySeqExpr` in the optimizer.
- `yield!`/`use!` and nested loops are handled via the `SeqDelay`/`SeqAppend`-style combinators:
  the local `mkSeqDelayedExpr` helper (in this file) plus the shared `mkSeq*` builders from
  `CheckExpressionsOps.fs` (`mkSeqEmpty`, `mkSeqAppend`, `mkSeqCollect`, `mkSeqTryWith`, ...).
- The resulting tree is later recognized by state-machine compilation (the doc comment notes "these are
  later detected by state machine compilation").

**Cross-references**
- `CheckSequenceExpressions.fs` (this file) — the entry used by:
  - `CheckArrayOrListComputedExpressions.fs` (sibling) — the list/array comprehension path above `TcSequenceExpression` and `SimpleSemicolonSequence`.
  - `CheckExpressions.fs` (sibling) — dispatches `SynExpr.SeqExpr`/`SimpleSequence` here.
- `CheckExpressionsOps.fs` (sibling) — `ConvertArbitraryExprToEnumerable`, `mkSeqDelay*`, `RewriteRangeExpr`.
- `CheckBasics.fs` (Checking dir) — `TcFileState`, `TcEnv`, `UnscopedTyparEnv`, `TcExprFlex`.
- `CheckPatterns.fs` (Checking dir) — `TcMatchPattern` for the `for x in e` loop-pattern check.
- `PatternMatchCompilation.fs` (Checking dir) — pattern checking for the loop body (via `TcMatchPattern`).
- `Optimize` (Optimize dir) — `LowerComputedListOrArraySeqExpr` recovers the debug points attached here
  during state-machine lowering.

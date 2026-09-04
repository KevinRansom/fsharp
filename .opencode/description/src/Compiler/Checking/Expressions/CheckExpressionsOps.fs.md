# CheckExpressionsOps.fs

**Purpose**
Shared low-level helpers for the expression checkers in this directory. Provides typar
freshening/fixup, a lightweight value-instantiation helper for method-call building, the bridge from
match checking into pattern-match compilation, the "simple semicolon sequence" recognizer (for plain
`[1; 2; 3]` list literals), the `[n .. m]` range-shorthand rewriter, fast integer for-loop elimination,
the `Seq.*`-monad combinator builders used by `CheckSequenceExpressions.fs`, and the struct-byref-capture
fixup for object expressions.

**Namespace(s)**
`module internal FSharp.Compiler.CheckExpressionsOps`

**Notable functions**
- `TryAllowFlexibleNullnessInControlFlow : bool (isFirst) -> TcGlobals -> TType -> unit` — set flexible nullness on a control-flow typar (used when checking nullness).
- `CopyAndFixupTypars : g -> m -> rigid -> Typars -> Typar list * TyparInstantiation * TTypes` — thin wrapper over `FreshenAndFixupTypars`.
- `FreshenPossibleForallTy : g -> m -> rigid -> TType -> Typars * Typars * TTypes * TType` — freshen a `forall` type, normalizing declared typars for equi-recursive inference.
- `LightweightTcValForUsingInBuildMethodCall : g -> ValRef -> ValUseFlag -> TTypes -> range -> Expr * TType` — simplified `TcVal` used in `BuildMethodCall`-style calls (typechecking of provided methods and the optimizer); handles byref deref, literal values, instantiation, and type-arg application.
- `CompilePatternForMatch : cenv -> env -> mExpr -> mMatch -> warnOnUnused -> actionOnFailure -> (Val * Typars * Expr option) -> clauses -> inputTy -> resultTy -> ...` — invokes `PatternMatchCompilation.CompilePattern` (with the lightweight TcVal threaded in), then `mkAndSimplifyMatch` + `mkLetsBind`.
- `CompilePatternForMatchClauses` — clause-oriented variant avoiding a dummy `matchValue` binding in the common single-`as`-pattern case.
- `UnifyTypes (inline)` — unify two types in the constraint solver (with error reporting).
- `RewriteRangeExpr : SynExpr -> SynExpr option` — recognize `[ n .. m ]` / `[ n .. step .. m ]` and elaborate to the `SeqOp`/`op_Range` form (used by the list/array and sequence checkers).
- `YieldFree cenv expr` — true when a comprehension body contains no `yield` (drives implicit-yield enabling).
- `IsSimpleSemicolonSequenceElement`, `TryGetSimpleSemicolonSequenceOfComprehension`, `(|SimpleSemicolonSequence|_|)` — recognize a plain `e1; e2; ...` sequence (a "simple semicolon sequence"), enabling the list/array fast path (`acceptDeprecated` allows `[ if g then t else e ]` with a parenthesization suggestion).
- `elimFastIntegerForLoop` — rewrite `for i = start to|downTo finish` as a `for` over a range pseudo-enumerable.
- `mkSeqEmpty` / `mkSeqUsing` / `mkSeqAppend` / `mkSeqDelay` / `mkSeqCollect` / `mkSeqFromFunctions` / `mkSeqFinally` / `mkSeqTryWith` — `Seq.*` monad-algebra combinator builders; each unifies the expected element/result type (`UnifyTypes`) and wraps in `mkCallSeq*` (e.g. `mkSeqUsing` adds the `IDisposable` subsumption constraint).
- `mkSeqExprMatchClauses`, `compileSeqExprMatchClauses` — compile a match-clause body (for `match!`-style seq expressions) via `CompilePatternForMatchClauses` with `ThrowIncompleteMatchException`.
- `mkOptionalParamTyBasedOnAttribute` — choose `ValueOption<'T>` vs `Option<'T>` for optional parameters based on `[<Struct>]` and the `SupportValueOptionsAsOptionalParameters` feature.
- `AnalyzeObjExprStructCaptures` — detect struct-instance captures in object expressions (excluding method params, module/member bindings, ctors); return `(shouldTransform, structCaptures, methodParamStamps)`.
- `TransformObjExprForStructByrefCaptures` — avoid illegal byref fields in the closure class by extracting captured struct-instance values into local bindings (`let x$captured = x in ...`) and remapping references in the object expression.

**Significant internal logic**
- The module is the shared "ops" layer used by `CheckExpressions.fs`, `CheckSequenceExpressions.fs`,
  `CheckArrayOrListComputedExpressions.fs`, and `CheckComputationExpressions.fs` (and, for
  `LightweightTcValForUsingInBuildMethodCall`, by the optimizer).
- `CompilePatternForMatch` / `CompilePatternForMatchClauses` centralize the bridge into
  `PatternMatchCompilation`, threading `ActionOnFailure` and the `LightweightTcVal` used to re-reference
  values during pattern compilation.
- `RewriteRangeExpr` keeps the range-shorthand elaboration in one place so list/array and sequence
  comprehensions produce identical code.
- `YieldFree` and `SimpleSemicolonSequence` implement the spec'd "implicit yield" fast paths and the
  plain-list-literal fast path (including the uint16/byte parser-table optimization in
  `CheckArrayOrListComputedExpressions.fs`).
- The struct-byref-capture fixup (`AnalyzeObjExprStructCaptures` / `TransformObjExprForStructByrefCaptures`)
  is the code-level defense against F# 9's "struct instance method captures in object expressions"
  creating illegal byref fields in the closure class; it's a no-op unless a struct context is active and
  some free variable is a struct-instance capture.

**Cross-references**
- `CheckExpressions.fs` (sibling) — primary consumer of `CompilePatternForMatch(Clauses)`,
  `FreshenPossibleForallTy`, `UnifyTypes`, the struct-byref-capture fixup.
- `CheckSequenceExpressions.fs` (sibling) — uses `YieldFree`, `RewriteRangeExpr`, the `mkSeq*` builders,
  `compileSeqExprMatchClauses`.
- `CheckArrayOrListComputedExpressions.fs` (sibling) — uses `RewriteRangeExpr` and
  `SimpleSemicolonSequence`.
- `PatternMatchCompilation.fs` (Checking dir) — the `CompilePattern` engine `CompilePatternForMatch`
  bridges to; the `ActionOnFailure` type.
- `TypedTree/TypedTreeOps.ExprOps.fs` — the `mkCallSeq*` / `mkCoerce*` / `mkLet` primitives used by the
  builders and transform helpers.
- `NameResolution.fsi` (Checking dir) — `TcValF`-style value-function conventions.

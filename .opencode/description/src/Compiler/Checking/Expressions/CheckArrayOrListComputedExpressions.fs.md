# CheckArrayOrListComputedExpressions.fs

**Purpose**
Typechecks F# **array and list computed expressions** (`[ ... ]` / `[| ... |]`) in the Checking phase:
simple semicolon-separated literals (`[1; 2; 3]`), and comprehension forms (`[ for ... in ... do ... ]`,
`[ yield ... ]`, `[ yield! ... ]`, etc.). It unifies the element type, compiles the body either via the
`Seq`-monad path (`TcSequenceExpression`) or the simple-literal fast path (`TcExprUndelayed`), and wraps
the result in `mkCallSeq*` / `mkCoerceExpr` to produce the final list/array expression.

**Namespace(s)**
`module internal FSharp.Compiler.CheckArrayOrListComputedExpressions`

**Public API surface**
- `TcArrayOrListComputedExpression : cenv: TcFileState -> env: TcEnv -> overallTy: OverallTy -> tpenv: UnscopedTyparEnv -> (isArray: bool * comp: SynExpr) -> m: range -> Expr * UnscopedTyparEnv` — the single public entry. Takes a flag + the syntactic comprehension body and returns a checked `Expr` with the overall list/array type.

**Significant internal logic**
- **Range shorthand** (`[n .. m]`, `[n .. step .. m]`): detected via `RewriteRangeExpr`. A fresh element
  typar `genCollElemTy` is made, the collection type is `mkArrayType`/`mkListTy genCollElemTy`, unified
  with `overallTy`, then the range expression is checked at `seq<genCollElemTy>`, coerced, wrapped in
  `mkCallSeq` (skipped when compiling FSharp.Core itself — `seq` may not be defined), coerced to the
  target, and finally converted via `mkCallSeqToArray`/`mkCallSeqToList`.
- **Simple semicolon sequence** (`[1; 2; 3]`): recognized by `(|SimpleSemicolonSequence|_|)` from
  `CheckExpressionsOps.fs`. For arrays, an extra fast path folds all-`UInt16` or all-`Byte` element lists
  into a single `SynConst.UInt16s`/`SynConst.Bytes` constant (optimization used for parser tables);
  otherwise a plain `SynExpr.ArrayOrList` is synthesized and checked with `TcExprUndelayed`.
  A `LanguageFeature.ReallyLongLists` gate / 500-element cap (`tcListLiteralMaxSize`) bounds plain list
  literals.
- **Comprehension bodies** (for-loops, `yield`, `yield!`, etc.): a fresh element typar is created and
  the collection type is unified with `overallTy`. `TcPropagatingExprLeafThenConvert` is used so that the
  element type can be type-directed (e.g. `[ yield 1; ... ]` targeting `seq<int64>`). The comprehension
  is checked at `seq<genCollElemTy>` via `TcSequenceExpression` (from the sibling module), coerced,
  wrapped by `mkCallSeq`, coerced to the collection type, and finally converted by
  `mkCallSeqToArray`/`mkCallSeqToList`.
- When compiling FSharp.Core itself, the `mkCallSeq` wrap is omitted (comment in-source: "`seq` may not
  yet be defined").

**Cross-references**
- `CheckSequenceExpressions.fs` (sibling) — `TcSequenceExpression` (the `Seq`-monad path this module
  delegates comprehension bodies to).
- `CheckExpressionsOps.fs` (sibling) — `RewriteRangeExpr`, `SimpleSemicolonSequence` recognizer,
  `TcPropagatingExprLeafThenConvert`, `mkCallSeq*`/`mkCoerceExpr`/`mkCoerceIfNeeded`/`mkArrayType`/
  `mkListTy` / `mkSeqTy` helpers.
- `CheckExpressions.fs` (sibling) — dispatches `SynExpr.Comprehension`/`SynExpr.SimpleSequence`
  (computed-list/array) to this module; provides `TcExpr`/`TcExprUndelayed` used in the fast path.
- `CheckBasics.fs` (Checking dir) — `TcFileState`, `TcEnv`, `UnscopedTyparEnv`, `MustEqual`, and the
  `OverallTy` conventions used by `TcPropagatingExprLeafThenConvert`.
- `ConstraintSolver.fs` (Checking dir) — `UnifyTypes`/`TcPropagatingExprLeafThenConvert` are constraint
  solver operations called by the sequence/array check.

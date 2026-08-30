# TypedTreeOps.Transforms.fs

> Pipeline role: Expression transformations over the typed tree. Contains the XmlDoc signature-string generator (`XmlDocSignatures`), the generic bottom-up rewriter with pre/post interceptors (`Rewriting`), decision-tree rewrites (`RewriteDecisionTree`), the tuple representation optimizer (`TupleCompilation` — unboxed SRTP-forced tuple elimination, `mkCompiledTuple`/`mkOptimizedRangeLoop`), hoisting of module/namespace contents (`CompilationPath` handling), and the constant-folding evaluator (`ConstantEvaluation` — `EvalLiteralExprOrAttribArg`, literal attribute arg equality) plus the `DetectAndOptimizeForEachExpression` query-expression recognizer. This is effectively "peephole/rewrite" infrastructure.
> Namespace: `FSharp.Compiler.TypedTreeOps`

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.XmlDocSignatures` (`[<AutoOpen>]`, internal, declared at line 38)

Builds the C#-style signature strings used in XML doc lookup (the `"F:Ns.T.M(...)"`-style identifiers):

- `commaEncs`/`angleEnc` encoders; `ticksAndArgCountTextOfTyconRef`.
- `typarEnc g (gtpsType, gtpsMethod) typar` — encodes `` `0 ``/``` ``0 ``` in the doc-ID convention.
- `rec typeEnc g (gtpsType, gtpsMethod) ty` — structural encoding walking `TType`s, including array rank (with indexer suffix `[0:,]`), byref (`'&'`), nativeptr (`'nativeptr<'T>`), app types, and measure annotations.
- `XmlDocArgsEnc`, `buildAccessPath (cp: CompilationPath option)` (130), `prependPath`.
- `XmlDocSigOfVal g full path (v: Val)` (143) — the val→doc-signature generator: resolves parent typar counts, witness infos, arg infos, return type; `XmlDocSigOfTycon`, `XmlDocSigOfUnionCase`? / `XmlDocSigOfRecdField`? maintained on the Node.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.Rewriting` (declared at line 719)

Generic bottom-up rewriter:

- `[<NoEquality; NoComparison>] type ExprRewritingEnv` (726): `PreIntercept: ((Expr -> Expr) -> Expr -> Expr option) option`, `PostTransform: Expr -> Expr option`, `PreInterceptBinding: ((Expr -> Expr) -> Binding -> Binding option) option`, `RewriteQuotations: bool`, `StackGuard: StackGuard`.
- `and RewriteExpr env expr` (748) — guarded recursion; for linear ops (`LinearOpExpr`/`LinearMatchExpr`/`Let`/`Sequential`/`DebugPoint`) uses `rewriteLinearExpr`; otherwise pre-intercept → structure rewrite (`rewriteExprStructure` — App/Quote/(object expressions)/Match/... rebuilt) → post-process.
- `rewriteBind`, `rewriteBindStructure`, `rewriteBinds`, `rewriteExprs`, `rewriteLinearExpr`, interceptor hooks, and `RewriteDecisionTree`/`RewriteDecisionTreeTargetWithCachedInfo`-style companion used by `mkRewriteTypeLambda` gate etc.
- `rewriteSpecialArithExpr`-adjacent pieces where arithmetic is rewritten for 32-bit target.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.RewriteDecisionTree` (line ~802)

- Uses `ExprRewritingEnv` to rewrite `DecisionTree`/`DecisionTreeTarget` faithfully (incl. cached `DecisionTreeResults`).

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.TupleCompilation` (declared at line ~1120)

Tuple to `mkCompiledTuple`/unboxed-tuple codegen helpers:

- `mkCompiledTuple (g: TcGlobals) (tupInfo: TupInfo) tys m` — creates the boxing tuple or the SRTP/inlined structural-tuple (via `mkCompiledTupleRef`/`mkCompiledTupleTyconRef`) accordingly.
- `mkFastForLoop (g) (range) (v1, v2)`; `mkOptimizedRangeLoop`.
- `mkAnonRecdExpr`-style construction for anonymous records.
- Used at array/list comprehensions and for-loop desugaring sites.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.CompilationPath` / `OpenDeclarationAndCompilationPath`? (module ~2400)

Which `open`-like hoisting is exercised: `mkModuleOrNamespaceExpr`, `CompilationPath`-aware module binding wrapping for `Cryptic`/access-scoping.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.ConstantEvaluation` (declared at line ~2320)

Constant folding over attribute arguments and literals:

- `EvalLiteralExprOrAttribArg`-family: evaluates `Expr.Const`/`Attrib` constructor args to literal values (used by `--testHarness`? actually by the attribute checker and `CastExpression`).
- `EvaledAttribExprEquality`/`AttribArgEquality`; `GetAttrName`? .
- `IsSimpleSyntacticConstantExpr g e` — syntactic constness predicate (also for `UseDecidedEqual` in pattern-match compilation).
- `isSimpleSyntacticConstantExpr`? — plus `DetectAndOptimizeForEachExpression` (line ~2500): pattern-recognizes `Seq.…tryWith`-shaped `for ... in ... do` IR and folds it into optimized `ForEach`-loops using a `SequencePointBinding` when the strategies permit. It inspects `Expr.Match` shapes with `LinearMatchExpr` alternative, `andEvaluateForEach`?/`OptimizeForEach`-like; the optimization contributes to `--nowarn`? in the optimizer.

---

## Related

- Builds on: `ExprConstruction`, `TypeRemapping`, `ExprReduced`, `ExprOps` (`mkForEach`), `Attrib` helpers.
- Used by: `TcSignature` (doc sigs), the optimizer/main loop (`Optimizer` calls `OptimizeImplFile` → `RewriteImplFile` with interceptors; tuple rewriting; constant folding for attribute args), `CheckExpressions` (pattern match compilation for `ForEach` desugaring), `IlxGen`.
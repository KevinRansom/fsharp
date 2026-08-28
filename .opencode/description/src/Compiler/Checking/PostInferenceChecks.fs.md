# PostInferenceChecks.fs

**Purpose**
Implements the set of semantic checks on the TAST (Typed AST / checked `ModuleOrNamespaceContents`) for a
file that can only be performed *after* type inference is complete. The headline duties are: byref/borrow
("Limit") escape analysis (preventing illegal byref escapes, nested-byref rules, resumable-code rules),
re-raise containment checks, null-checks for `match null`, `CheckEscapes`/value-restriction-adjacent checks
on inline/let-bound values, accessibility and internalsvisibleto adjustments of type/val references, safe
initialization (this) checks for classes, and entry-point rules (nothing after the entry point). It runs
analogously to a second traversal over the file's module contents.

**Namespace(s)**
`module internal FSharp.Compiler.PostTypeCheckSemanticChecks`

**Public API surface** (see `.fsi`)
- `CheckImplFile: TcGlobals -> ImportMap -> bool (reportErrors) -> InfoReader -> CompilationPath list (internalsVisibleToPaths) -> CcuThunk -> ConstraintSolver.TcValF -> DisplayEnv -> ModuleOrNamespaceType -> ModuleOrNamespaceContents -> Attribs (extraAttribs) -> (bool * bool) -> bool (isInternalTestSpanStackReferring) -> bool * StampMap<AnonRecdTypeInfo>` — the single public entry point, returning whether checking succeeded plus anonymous-record type info stamps.

**Internal check environment and `Limit` machinery**
- `env` record — per-expression state: bound typars, `argVals`, sig→impl remap info, `quote`/`reflect`
  (quotation/reflected definition) flags, `external` (extern decl flag), `returnScope`, `isInAppExpr`,
  resumability info, etc.
- `Resumable` — `None | ResumableExpr of allowed` — tracks whether we are inside resumable-code
  (state-machine) code.
- `Limit` / `LimitFlags` (nested `module Limit`, exposed in the `.fsi`) — the byref escape "limit"
  abstraction: `scope: int` (how far a Val may legally escape) and `flags: LimitFlags` (`ByRef`,
  `ByRefOfSpanLike`, `ByRefOfStackReferringSpanLike`, `SpanLike`, `StackReferringSpanLike`); combinators
  `NoLimit` and `CombineTwoLimits` (meet of two limits).

**Check family (private `and`-recursive block)**
- Type-level: `CheckType*` (`CheckType`, `CheckTypeAux`, `CheckTypeDeep`, `CheckTypeConstraintDeep`,
  `CheckTraitInfoDeep`) with `PermitByRefExpr` variants (`NoByrefs`, `PermitSpanLike`, `PermitAllByrefs`,
  `NoInnerByrefs`), `CheckForByrefLikeType` / `CheckForByrefType`.
- Escape analysis: `CheckEscapes`, `IsLimitEscapingScope`, `LimitVal`, `GetLimitVal(ByRef)`, `CheckCallLimitArgs`.
- Expression-level: `CheckExpr`, `CheckExprLinear`, `CheckExprs`, `CheckExprOp`, `CheckApplication`,
  `CheckLambdas`, `CheckTyLambda`, `CheckLambda`, `CheckQuoteExpr`, `CheckStructStateMachineExpr`,
  `CheckObjectExpr`, `CheckFSharpBaseCall`, `CheckILBaseCall`, `CheckSpliceApplication`,
  `TryCheckResumableCodeConstructs`, `CheckNoResumableStmtConstructs`, `CheckForOverAppliedExceptionRaisingPrimitive`,
  `CheckNoReraise` (re-raise may only occur in a catch handler; see the notes block at the top of the file).
- Decision trees: `CheckDecisionTree(Target)(s)(Switch)(Test)` — byref checks inside compiled match trees.
- Bindings/vals: `CheckBinding`, `CheckBindings`, `CheckModuleBinding`, `CheckValInfo`, `CheckArgInfo`,
  `CheckValSpec(Aux)`, `CheckMethods`, `CheckMethod`, `CheckInterfaceImpl(s)`,
  `CheckInlineValueIsSufficientlyAccessible`.
- Attributes: `CheckAttrib`, `CheckAttribExpr`, `CheckAttribArgExpr`, `CheckAttribs` — attribute-argument
  restrictions (quotation/inline rules).
- Declarations: `CheckRecdField`, `CheckEntityDefn`, `CheckEntityDefns`, `CheckForDuplicateExtensionMemberNames`,
  `CheckDefnsInModule`, `CheckDefnInModule`, `CheckModuleSpec`, `CheckMultipleInterfaceInstantiations`,
  `CheckInterfaceTypeArgForUnimplementedStaticAbstractMembers`, `CheckNothingAfterEntryPoint`.
- Accessibility: `AdjustAccess`, `AccessInternalsVisibleToAsInternal`, `isLessAccessibleWithVisibility`.

**Significant internal logic**
- The `Limit` type abstracts the CFA-style "how much byref can this escape" computation;
  `CombineTwoLimits` is the meet. The scope integer distinguishes "top-level" (0), "top-level local" (1),
  and deeper let-scope nesting. See the notes in `.fsi` on `Limit.scope`.
- The re-raise safety comments (top of file) justify that a free `TOp.Reraise` can only appear inside a
  try/catch; lambdas and module bindings are rejected.
- `CheckEntityDefn` (large) covers class/interface/record/union/struct/measure/exn/provider definitions,
  including safe-init (`CheckLambdas`/`SafeInitData`), field mutability, and interface instantiation checks.
- `CheckMultipleInterfaceInstantiations` implements the "no multiple instantiations of the same generic
  interface" rule (with DII exceptions when applicable), and
  `CheckInterfaceTypeArgForUnimplementedStaticAbstractMembers` checks static abstract members in
  interface type arguments.
- Accessibility enforcement uses the signature→impl remap info to compute what is hidden by a signature
  (`sigToImplRemapInfo` in `env`), and `internalsVisibleToPaths` to treat `Friends` access as `Internal`.

**Cross-references**
- `PostInferenceChecks.fsi` — public contract (the `Limit` module is re-exported for testing).
- `TailCallChecks.fsi` — a sibling post-check pass (tail-call attribution checks) that traverses TAST
  analogously.
- `CheckDeclarations.fs` (sibling) — drives `CheckImplFile` after inference.
- `MethodOverrides.fsi` — `FinalTypeDefinitionChecksAtEndOfInferenceScope` is a complementary
  end-of-inference-scope check (implemented in MethodOverrides).
- `ConstraintSolver.fsi` (sibling) — `TcValF` type is threaded through both.
- `TypeRelations.fsi` / `TypeHierarchy.fsi` — used for byref-like type classification and interface
  hierarchy queries.
- `QuotationTranslator.fsi` — shares `TcValF` and `CcuThunk` parameter shapes.

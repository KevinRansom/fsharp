# TypedTreeOps.ExprConstruction.fs

> Pipeline role: Provides the core "expression construction" helper library of the typed tree. Constructs `Expr` nodes (`mkApp`, `mkTyApp`, `mkLambda`, `mkLet`, `mkMatch`, `mkDecisionTree`, ...), builds fresh `Val` bindings via the comp-generated naming machinery, computes modal facts about expressions (the `Modes` module: `ExprLhsExpr`, address-of mode decision `ThisIsAUseOfExprLhsExpr`/`use of address of` predicates), remaps type/val references inside expressions, and implements the expression-cleanup/`deftype` normalization used before code generation. It is the workhorse "Construct" library: nearly every compiler phase (Tc, optimizer, ilxgen, quotation pickling) calls into these makers.
> Namespace: `FSharp.Compiler.TypedTreeOps`

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.ExprConstruction` (`[<AutoOpen>]`, internal, declared at line 36)

**Standard orderings (lines 38–45)**: starts with `valOrder` — an `IComparer<Val>` comparing by `Stamp`, used as the order for the many `Zset`/`Map`/cached-folder keys in this file.

**Modal analysis of Vals**:

- `isCompGen` (is compiler-generated), `isCompGenOrGeneratedViaCompiler` predicates.
- `isLocalVal`, `isRefCellVal` etc. tests on `Val`.
- `valOneShots` (caching), `valUseFlag` helpers.

**Expression construction (`Expr` maker functions)** — the large core. Representative signatures:

- `mkApp (g, f, fty, tyargs, args, m)`, `mkTyApp`, `mkTyAppThenApp` ...
- `mkLambda m ctorThisValOpt baseValOpt vs body` (+ ty-lambda `mkTyLambda`).
- `mkLet m v e1 e2` (+ `mkLets`), `mkLetRec`.
- `mkMatch m (e: Expr) (dtree, targets) ty` and the "linearized match" builders `mkLinearMatch` / `mkLinearEngineInlinedMatch` — pattern-match compilation of sequences.
- `mkDecisionTree`, `mkDecisionTreeAnd`, `mkSwitch`, `mkDecisionTreeSuccess`, `mkDecisionTreeTest`.
- `mkTyChoose`, `mkTyChooseOrUnitButGenUnit`.
- `mkConst`, `mkUnit`, `mkString`, `mkArray`, `mkTuple`, `mkNull`, `mkDefault`, `mkBind`, `mkSeq`, `mkDo`, `mkSequential`.
- `mkCallNewObj`, `mkCallUnboundObj`, `mkCallGetProperty`, `mkCallSetProperty`, `mkCallGetMethod`, `mkCallMethod`, `mkCallInstanceMeth`, `mkdir`, structure-vs-lazy type building via `Construct`.
- The `OpenExprWithValueDefs`/mentions module — `OpenExprInEnv` family enabling expression instantiation at member boundaries.

**Fresh val generation** — massive collection of `mkCompGenLocal`-style helpers for generating locals used to hook constructs:

- `mkLocal`, `mkCompGenLocal`, `mkMutable`, `mkCompGenMutable`, `mkLocalWithBuilderRelatedInfo`, `mkLocalGenerated`.
- Domain-specific local/backing-field generation: `mkLocalIVar`, `mkLocalByref`, `mkLocalLinqLambda` ...
- Record field / union case construction helpers: `mkRecordExpr`, `mkUnionExpr`, `mkTuple`, `mkRecdFieldGet`, `mkUnionCaseGet` ...

**The Modes module** (a large internal section) — how addresses and values may be used:

- `Modes` types: `ModeForOutArg`, `AddressUseCritical` / `UseAddrOfCritical` variants; `ExprLhsExpr`.
- `ShouldUseAddrOf`, `CanTakeAddrOf`, `MustTakeAddrOf` combos and `adviseValUse` (recompute val-use flags) used by later optimizer phases.
- `notUsedForInterestingOps`-style helpers guarded by `Val` flags.

**Remapping integration**: small helpers using `TypeRemapping.Remap` to rebuild entity references inside expressions (`remapExpr`-adjacent utilities invoked here rather than defined here).

**Other**: `valReprInfo`-related flag sets (`MemberFlags` formulas), the `unitVal`/`unitType` cache accessors, and `splitFreeVar` machinery used by the later phases.

---

## Related

- Builds on: `TypedTree`, `TypedTreeBasics` (`Construct`, `TTypeBuilding`), `TcGlobals`, `SyntaxTreeOps`.
- Used by: the whole compiler — type checking (`CheckExpressions`), pattern match compilation (`CompilePattern`, `Linearize`), optimizer (`Optimizer`), `IlxGen`/codegen, `QuotationTranslation`, and the interpreter (`SQL45Interpreter`-ish).
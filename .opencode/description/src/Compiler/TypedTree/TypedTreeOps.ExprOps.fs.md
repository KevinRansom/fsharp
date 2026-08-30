# TypedTreeOps.ExprOps.fs

> Pipeline role: "Address-of operations" and expression-folding utilities plus the intrinsic call wrappers. Decides whether an expression must/ can be taken by address (`CanTakeAddressOf*`, `MustTakeAddressOf*`) — critical for codegen where value types held in static/instance fields must be addressed rather than copied. Implements `FoldExpr`/`FoldExprIntercept` — a fast, mode-aware expression folder with intercept points (used for usage-info computation, `isUsedN`, `accFreeVars`, etc.). Contains the FSharp.Core intrinsic call makers `mkCallAdditionChecked`, `mkCallEqualsOperator`, `mkCallSeq*`, `mkStringConcat`, ... — 100+ wrapper functions constructing calls to well-known FSharp.Core functions — and higher-level helpers `mkEnsureFunctionVal`, `mkCallArrayGet`, `mkdir` gadgetry (this module holds the `mkdir`/`ConSplice`-style versions). Also note `mkArray2D/3D/4D` creation and `mkReraise`, and the instance-method builders `mkCallCreateInstance`.
> Namespace: `FSharp.Compiler.TypedTreeOps`

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.AddressOps` (`[<AutoOpen>]`, internal, declared at line 36)

**Mutates mode (lines 39–44)**:

- `type Mutates = AddressOfOp | DefinitelyMutates` — whether an `addrget`-style op **definitely** mutates its target or merely takes a `&` (read-only byref). Feeds into `Val` use-flag propagation and byref escape analysis.

**Read-only/immutable classification (lines 51–97)**:

- `isRecdOrStructTyconRefAssumedImmutable (g) (tcref)` — structural eq, `ReferenceEqualityAttribute`, custom eq.
- `isTyconRefReadOnly g m tcref` — checks for `[<Struct>]`-ness and readonly-ness attributes.
- `isRecdOrStructTyconRefReadOnly`, `isRecdOrStructTyReadOnly` (type-level) — whether address-of would produce a copy.
- These combine into the decision helpers below.

**Address-of permission matrix (lines 100–166)**:

- `CanTakeAddressOf g m isInref ty mut` — top-level decision.
- `CanTakeAddressOfImmutableVal g m vref mut` and the `MustTakeAddressOfVal`, `MustTakeAddressOfByrefGet`, `CanTakeAddressOfByrefGet` pair — vals whose storage is always addressable (generated cells, byref args) vs vals with no backing field (compiler constants like `let x = 1`) where taking address is disallowed.
- `MustTakeAddressOfRecdField (rfref)` / `CanTakeAddressOfRecdFieldRef g m rfref tinst mut` / `CanTakeAddressOfUnionFieldRef g m uref cidx tinst mut`.
- `mkDerefAddrExpr` (line 168) — produces `let byrefReturn = <expr> in &byrefReturn` making byref returns safe.

**`Val`/`Expr` classification helpers**: `fcR`/`fcRO` etc., `exprsOfSeq`, `linearizeExpr`-required generators, and utilities `mkSafeExpr`, `mkEffectfulOp`, and debugger-highlight helpers on expr tokens.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.FederationOfSeqExpressions` (internal, declared at line 283)

Seq-based expression builders used by query and computation expressions — `exprForValRef`, small helpers pairing value references with their defining expressions, and the `mkSeq`-family.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.Intrinsics` — line 392 (`mk` wrappers)

The FSharp.Core intrinsic call makers (top-level in this file, `[<AutoOpen>]`, 181 `mk*` functions). Covered in detail under **Makers** below.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.ExprFolder` (line 518)

- `type ExprFolder<'State>` — record with intercept fields: `exprIntercept`, `valBindingSiteIntercept` (`'State -> bool * Val -> 'State`, bool = 'bound in dtree'), `nonRecBindingsIntercept`, `recBindingsIntercept`, `dtreeIntercept`, `targetIntercept` (returns `'State option`), `tmethodIntercept` (object-expr methods, returns `option`). See usage-info folding adapted from prior passes (lines 543–549).
- `ExprFolder0` — no-op default.
- `type ExprFolders<'State>(folders: ExprFolder<'State>)` — reusable folder object memoizing the recursion closures (`exprFClosure`, `exprNoInterceptFClosure`) and guarding recursion with `StackGuard("FoldExprStackGuardDepth")`.
  - `FoldExpr` / `FoldExprIntercept` — the main entry points returning `'State`.
  - Structured walk: LHS/const/val/etc. short-circuit so interceptors only fire where declared; decision trees are visited via `dtreeIntercept`/`targetIntercept`; object expressions via `tmethodIntercept` + method bodies.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.Makers` (`[<AutoOpen>]`, internal)

High-level call construction — builds guaranteed typ'd `Expr.App`s to well-known FSharp.Core functions (grep-verified list of the ~140 `mkCall*` wrappers):

- **Arithmetic/checked ops**: `mkCallAdditionChecked/Operator`, `mkCallSubtractionChecked/Operator`, `mkCallMultiplyChecked/Operator`, `mkCallDivisionOperator`, `mkCallModulusOperator`, `mkCallUnaryNegChecked/Operator`, `mkCallUnaryNotOperator`, `mkCallEqualsOperator`/`mkCallNotEqualsOperator`, `mkCallBitwiseAnd/Or/XorOperator`, `mkCallShiftLeft/RightOperator`, `mkCallLessThanOperator`/`mkCallLessThanOrEqualsOperator`/`mkCallGreaterThanOperator`/`mkCallGreaterThanOrEqualsOperator`, `mkCallStringOperator` (+ many `mkCallString*`), `mkCallTo*Checked`/`mkCallTo*Operator` for byte/sbyte/int16/int32/int64/&c + uint variants + `intptr`/`uintptr`, `mkCallBox`/`mkCallUnbox`/`mkCallUnboxFast`/`mkCallTypeTest`/`mkCallTypeOf`/`mkCallDefaultOf`.
- **Generic comparison machinery**: `mkCallGenericComparisonWithComparerOuter`, `mkCallGenericEqualityEROuter`, `mkCallGenericEqualityWithComparerOuter`, `mkCallGenericHashWithComparerOuter`, `mkCallGetGenericComparer`, `mkCallGetGenericEREqualityComparer`, `mkCallGetGenericPEREqualityComparer`.
- **Arithmetic-over-lift**: `mkCallLiftValue`, `mkCallLiftValueWithDefn`, `mkCallLiftValueWithName`, `mkCallCreateInstance`, `mkCallBox`.
- **Checked conversion**: `mkCallToIntChecked` etc.; **other**: `mkCallFailInit`, `mkCallFailStaticInit`, `mkCallRaise`, `mkReraise`/`mkReraiseLibCall`, `mkCallIsNull`, `mkCallHash`, `mkCallTypeDefOf`, `mkCallNewDecimal`, `mkCallNewFormat`, `mkCallNewQuerySource`, `mkCallGetQuerySourceAsEnumerable`, `mkCallQuoteToLinqLambdaExpression`, `mkCallCastQuotation`, `mkCallCreateEvent`, `mkCallDispose`, `mkCallCheckThis`, `mkCallSeqGenerated`.
- **Seq**: `mkCallSeq`, `mkCallSeqAppend/Collect/Delay/Empty/Finally/Generated/Map/OfFunctions/Singleton/ToArray/ToList/Using/TryWith`, `mkSeq`.
- **Arrays**: `mkCallArrayGet/Set/Length`, `mkCallArray2DGet/Set`, `mkCallArray3DGet/Set`, `mkCallArray4DGet/Set`, `mkCallSeqToArray`, `mkArray`, `mkString`, `mkStringConcat`, `mkSequential`, `mkCallSeqOfFunctions`.
- **Quotations**: `mkCallDeserializeQuotationFSharp20Plus`, `mkCallDeserializeQuotationFSharp40Plus` — version-dependent `Deserialize` call constructors.

Each wrapper takes `(g: TcGlobals) (m: range) args...` and returns a fully-typed `Expr` checking the target `ValRef` against `g`-cached FSharp.Core methods.

---

## Other internals

- `exprForValRef m vref` (used at several points) — materializer of a `Val` reference into the *defining expression* when the val is a generated bet (rare) else an `Expr.Val` node.
- `IsAddrOf` decompositions and `mkAddrGet`/`mkAddrSet` node constructors.
- `JoinTyparStaticReq` (line 507) — joins two `TyparStaticReq`s.

---

## Related

- Builds on: `TypedTree`, `TypedTreeBasics`, `TcGlobals` (FSharp.Core `ValRef`s), `Construct`.
- Used by: optimizer (address decisions), `IlxGen`, pattern-match compilation (`Linearize`/`CompilePattern`), `QuotationTranslation`, ilxgen/`LocalIlGen`-adjacent code, and `CheckExpressions` (desugared call targets).
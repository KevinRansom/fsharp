# PatternMatchCompilation.fsi

**Purpose**
Public contract for the F# pattern match compiler. Declares the typed `Pattern` tree (the checked form of
a match pattern, prior to decision-tree compilation), the `MatchClause` pairing of pattern/guard/target,
the failure-action enumeration (`ActionOnFailure`), the main `CompilePattern` entry point that emits a
`DecisionTree`, and the exceptions raised for incomplete/never-matched matches.

**Namespace(s)**
`module internal FSharp.Compiler.PatternMatchCompilation`

**Modules / Types declared**
- `ActionOnFailure` — what the decision tree does on an incomplete match: `ThrowIncompleteMatchException`, `IgnoreWithWarning`, `Throw`, `Rethrow`, `FailFilter`.
- `Pattern` (`[NoEquality; NoComparison]`) — typed pattern tree: `TPat_const`, `TPat_wild`, `TPat_as`, `TPat_disjs`, `TPat_conjs`, `TPat_query`, `TPat_unioncase`, `TPat_exnconstr`, `TPat_tuple`, `TPat_array`, `TPat_recd`, `TPat_null`, `TPat_isinst`, `TPat_error`; `Range` member.
- `PatternValBinding of Val * GeneralizedType` — a bound pattern value with its (possibly generalized) type scheme.
- `MatchClause of Pattern * Expr option * DecisionTreeTarget * range` — one clause.
- Internal exceptions: `MatchIncomplete of bool * (RichText * bool) option * range` (computation-expression flag, counter-example, range), `MatchIncompleteForLoopHint of exn` (wrapper adding a for-loop hint), `RuleNeverMatched of range`, `EnumMatchIncomplete of bool * (RichText * bool) option * range`.

**Public API surface**
- `ilFieldToTastConst: ILFieldInit -> Const`.
- `CompilePattern: TcGlobals -> DisplayEnv -> ImportMap -> (ValRef -> ValUseFlag -> TTypes -> range -> Expr * TType) -> InfoReader -> range -> range -> bool (warn on unused) -> ActionOnFailure -> Val * Typars * Expr option -> MatchClause list -> TType (input type) -> TType (result type) -> DecisionTree * DecisionTreeTarget list * Bindings` — compile a match into a decision tree, its targets, and auxiliary bindings. Parameters include the range of the matched-on expression (for reporting), the range to report "incomplete match" on, the input type, and the result type.

**Significant notes**
- The `CompilePattern` signature deliberately threads: (a) the val-function
  `(ValRef -> ValUseFlag -> TTypes -> range -> Expr * TType)` used to re-reference values during
  compilation (the `TcValF` shape also used in `QuotationTranslator`/`PostInferenceChecks`), (b) the
  input/result types so decision-tree tests are typed, and (c) separate ranges for the match expression
  vs. the incomplete-match diagnostic.
- `ActionOnFailure` drives the `DecisionTree` failure continuation: `Throw`/`Rethrow` are used by
  try/with compilation; `ThrowIncompleteMatchException` is the default; `IgnoreWithWarning` suppresses
  the incomplete-match check (e.g. when the match is exhaustive by construction).
- `MatchIncomplete` and `EnumMatchIncomplete` carry an optional counter-example `(RichText * bool)` —
  the second flag is "isShownAsFieldPattern" for record/field pattern messages.

**Cross-references**
- `PatternMatchCompilation.fs` — implementation (subsumes/succeeds relations, decision-tree construction, poly-input bindings).
- `CheckPatterns.fsi` (sibling) — produces the checked patterns that become `Pattern` here.
- `CheckExpressionsOps.fsi`-level caller (`CompilePatternForMatch` in `CheckExpressionsOps.fs`) — bridges `TcExprMatch` to `CompilePattern`.
- `TypedTree` (`DecisionTree`, `DecisionTreeTarget`, `Bindings`) — the output types.
- `QuotationTranslator.fsi` — same `TcValF`-style val-function shape is threaded through quotation translation.

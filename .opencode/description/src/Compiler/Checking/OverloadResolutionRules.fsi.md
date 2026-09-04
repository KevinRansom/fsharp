# OverloadResolutionRules.fsi

**Purpose**
Public contract for the DSL of overload-resolution tiebreaker rules. Declares the resolution context type,
the `TiebreakRuleId` identifiers (stable, spec-anchored, *not* an evaluation order), the "which rule
decided" entry point `findDecidingRule`, and the `OverloadResolutionPriority` pre-filter. Also exposes the
`explainIncomparableMethodConcreteness` diagnostic explainer used for the FS0041 ambiguity message.

**Namespace(s)**
`module internal FSharp.Compiler.OverloadResolutionRules`

**Modules / Types declared**
- `OverloadResolutionContext` — record: `g`, `amap`, `m`, `ndeep` (nesting depth for subsumption checks), `paramDataCache: Dictionary<obj, ParamData list> voption` (per-method cache of `GetParamDatas` results), `srtpCache: Dictionary<obj, bool> voption` (per-method cache of SRTP presence checks). Caches avoid redundant work across pairwise comparisons.
- `IncomparableConcretenessInfo` — `Method1Signature`, `Method1BetterPositions: int list`, `Method2Signature`, `Method2BetterPositions` — the explainer's payload.
- `TiebreakRuleId` (`[RequireQualifiedAccess]`) — 15 stable identifiers matching F# Language Spec §14.4: `NoTDC = 1`, `LessTDC = 2`, `NullableTDC = 3`, `NoWarnings = 4`, `NoParamArray = 5`, `PreciseParamArray = 6`, `NoOutArgs = 7`, `NoOptionalArgs = 8`, `UnnamedArgs = 9`, `PreferNonExtension = 10`, `ExtensionPriority = 11`, `PreferNonGeneric = 12`, `MoreConcrete = 13`, `NullableOptionalInterop = 14`, `PropertyOverride = 15`.

**Public API surface**
- `explainIncomparableMethodConcreteness: OverloadResolutionContext -> InfoReader -> DisplayEnv -> CalledMeth<'T> -> CalledMeth<'T> -> IncomparableConcretenessInfo option` — explain why two methods are incomparable under the concreteness ordering (returns `Some` only when the incomparability is due to mixed concreteness results).
- `findDecidingRule: OverloadResolutionContext -> struct (CalledMeth<Expr> * TypeDirectedConversionUsed * int) -> struct (CalledMeth<Expr> * TypeDirectedConversionUsed * int) -> struct (int * TiebreakRuleId voption)` — evaluate all tiebreaker rules; returns `struct(result, ValueSome ruleId)` if a rule decided, or `struct(0, ValueNone)` if all rules returned 0 (a true tie).
- `filterByOverloadResolutionPriority: TcGlobals -> ('T -> MethInfo) -> 'T list -> 'T list` — apply the `OverloadResolutionPriority` attribute pre-filter: groups methods by declaring type and keeps only the highest priority within each group.

**Significant notes**
- The `.fsi` documents the critical convention: the integer values of `TiebreakRuleId` are *conceptual
  identifiers matching F# Language Spec §14.4* and do **NOT** define evaluation order. Evaluation order is
  the list order of `allTiebreakRules` in `OverloadResolutionRules.fs` (deliberately running `MoreConcrete`
  last). Do not reorder the rules list to match the numeric ids.
- Each candidate is passed as a struct triple `(CalledMeth<Expr> * TypeDirectedConversionUsed * int)` —
  the method, the TDC used, and the warning count — which feeds rules `NoTDC`, `LessTDC`, `NoWarnings`.
- The context caches (`paramDataCache`, `srtpCache`) are thread-unsafe dictionaries used only within a
  single resolution; they survive across pairwise comparisons to avoid repeated `GetParamDatas` calls.

**Cross-references**
- `OverloadResolutionRules.fs` — implementation (rules list, `compareTypeConcreteness`, FS0041 explainer).
- `MethodCalls.fsi` — `CalledMeth`, `TypeDirectedConversionUsed` inputs.
- `OverloadResolutionCache.fsi` — companion memoization of the final winner.
- `ConstraintSolver.fs` (sibling) — call site (`ResolveOverloadingForCall`) and ambiguity reporting.
- `NicePrint.fsi` — signature rendering inside the explainer output.

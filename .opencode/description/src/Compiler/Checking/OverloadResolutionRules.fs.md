# OverloadResolutionRules.fs

**Purpose**
Implements the DSL of overload-resolution tiebreaker rules in the F# checker. Given a set of candidate
`CalledMeth` values (see `MethodCalls.fs`), the rules rank them by applying a fixed sequence of comparisons
(no type-directed conversion, fewer warnings, no param array, precise param array, no out args, no optional
args, unnamed-argument subsumption, extension precedence, non-generic preference, more-concrete types,
nullable/optional interop, property-override precedence). The rules are also the reference for the
"which rule decided" reporting used in ambiguity diagnostics.

**Namespace(s)**
`module internal FSharp.Compiler.OverloadResolutionRules`

**Modules / Types declared**
- `OverloadResolutionContext` — record of resolution context: `g`, `amap`, `m`, `ndeep` (subsumption depth), plus per-comparison caches `paramDataCache` and `srtpCache` (avoid re-computing `GetParamDatas` and SRTP detection across pairwise comparisons).
- `TiebreakRuleId` (`RequireQualifiedAccess`) — stable conceptual identifiers matching F# Language Spec §14.4: `NoTDC=1`, `LessTDC=2`, `NullableTDC=3`, `NoWarnings=4`, `NoParamArray=5`, `PreciseParamArray=6`, `NoOutArgs=7`, `NoOptionalArgs=8`, `UnnamedArgs=9`, `PreferNonExtension=10`, `ExtensionPriority=11`, `PreferNonGeneric=12`, `MoreConcrete=13`, `NullableOptionalInterop=14`, `PropertyOverride=15`.
- `TiebreakRule` — record `{ Id; RequiredFeature: LanguageFeature option; Compare: ctx -> candidate -> other -> int }`.
- `IncomparableConcretenessInfo` — record describing *why* two methods are incomparable under concreteness (both signatures + the positions at which each is better), used by the FS0041 diagnostic explainer.

**Public API surface**
- `findDecidingRule: OverloadResolutionContext -> struct (CalledMeth<Expr> * TypeDirectedConversionUsed * int) -> (same) -> struct (int * TiebreakRuleId voption)` — evaluate all rules in order and return (result, deciding rule) or (0, ValueNone) if all tied.
- `filterByOverloadResolutionPriority: g -> ('T -> MethInfo) -> 'T list -> 'T list` — apply the `OverloadResolutionPriority` pre-filter: group candidates by declaring type, keep only the highest-priority within each group.
- `explainIncomparableMethodConcreteness: ctx -> InfoReader -> DisplayEnv -> CalledMeth<'T> -> CalledMeth<'T> -> IncomparableConcretenessInfo option` — explain concreteness-order ambiguity (FS0041 explainer).

**Internal helpers**
- `foldMap2` / `resolveAggregation` / `aggregateMap2` — pairwise list comparison with dominance aggregation and early-exit on incomparability.
- `isStaticallyResolvedTypeParam`, `paramDataType`, `paramsMentionComparableTypeVar`, `paramsMentionSRTP`, `methodMentionsSRTP` — SRTP detection (shared between `moreConcreteRule`'s firing gate and the FS0041 explainer so they can't drift).
- `compareTypeConcreteness` — structural concreteness comparison (struct: 1 if `ty1` more concrete, -1 if `ty2`, 0 incomparable).
- `compareCond`, `compareTypes`, `compareArg`, `compareArgLists` — argument-level comparisons feeding the unnamed-args and concreteness rules.
- `preferFlagRule` — factory for simple boolean flag rules.
- Individual rules: `noTDCRule`, `lessTDCRule`, `nullableTDCRule`, `noWarningsRule`, `noParamArrayRule`, `preciseParamArrayRule`, `noOutArgsRule`, `noOptionalArgsRule`, `unnamedArgsRule`, `preferNonExtensionRule`, `extensionPriorityRule`, `preferNonGenericRule`, `moreConcreteRule`, `nullableOptionalInteropRule`, `propertyOverrideRule`.
- `getCached`, `getCachedParamData`, `getCachedHasSRTP` — per-context caching helpers.
- `allTiebreakRules` — the ordered list of rules actually evaluated (order here defines evaluation order, *not* the `TiebreakRuleId` numbers).
- `isRuleEnabled` — gates a rule on its `RequiredFeature` (skipped when the language version doesn't support the feature).

**Significant internal logic**
- Evaluation order in `allTiebreakRules` is authoritative; `TiebreakRuleId` values are deliberately *not*
  an ordering — they are stable identifiers matching the language spec so diagnostics can name the deciding
  rule.
- `moreConcreteRule` (spec §14.4 "more concrete") runs **last** deliberately; it is gated by
  `paramsMentionComparableTypeVar` on both sides and requires no SRTP involvement on either side
  (`methodMentionsSRTP`). SRTPs are resolved by constraint solving, not by betterness.
- `compareTypeConcreteness` recurses over `TType_app` (same-constructor argument-wise), tuples, function
  types (dom/rng), and anonymous records; measures and differing tycon refs are treated as incomparable.
- `explainIncomparableMethodConcreteness` mirrors `moreConcreteRule`'s exact firing gate so the FS0041
  detail message only explains cases the rule actually ranks; it decomposes a single same-constructor
  parameter (e.g. `Result<int, 'error>` vs `Result<'ok, string>`) into type-argument positions for a
  per-position explanation.
- Caching: `paramDataCache` (MethInfo -> `ParamData list`) and `srtpCache` (MethInfo -> bool) avoid
  re-doing `GetParamDatas` and SRTP scans in the O(n²) pairwise rule comparisons.

**Cross-references**
- `OverloadResolutionRules.fsi` — public contract.
- `MethodCalls.fs` / `MethodCalls.fsi` — `CalledMeth`, `CallerArgs`, `TypeDirectedConversionUsed` are the
  inputs to every rule.
- `ConstraintSolver.fs` (sibling) — invokes `findDecidingRule` from `ResolveOverloadingForCall` and reports
  the deciding rule in ambiguity diagnostics.
- `OverloadResolutionCache.fs` — optional memoization of the final resolved candidate across invocations.
- `NicePrint.fs` — `richTextOfMethInfo*` rendering used when the rules produce "available overloads" output
  via `explainIncomparableMethodConcreteness`.
- `TypeRelations.fs` / `TypeHierarchy.fs` — subsumption relations used by `compareArg`/`compareArgLists`.

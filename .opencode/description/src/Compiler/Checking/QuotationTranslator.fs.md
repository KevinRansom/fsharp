# QuotationTranslator.fs

**Purpose**
Converts quoted TAST (`Expr`) data structures into the pickled form (`QuotationPickler.ExprData`) used to
serialize F# quotations (`Quote` / `Expr<...>`). Tracks referenced type definitions and type/expression
splices (captured typars and captured values) so they can be emitted as quotation splices, manages the
per-scope `QuotationTranslationEnv` (value→binding maps, witness maps), and handles reflected definitions
(`[<ReflectedDefinition>]`). Also supports witness arguments (F# 4.1+) and the F# 4.0+ "DeserializeEx"
format (integer-indexed type-reference table).

**Namespace(s)**
`module internal FSharp.Compiler.QuotationTranslator`

**Modules / Types declared** (see `.fsi`)
- `QP = QuotationPickler` — alias module.
- `IsReflectedDefinition` (`RequireQualifiedAccess`) — `Yes | No`.
- `QuotationSerializationFormat` — `{ SupportsWitnesses: bool; SupportsDeserializeEx: bool }` — capabilities probed from FSharp.Core (presence of `CallWithWitnesses` / `DeserializeQuoted`).
- `QuotationGenerationScope` — record: `g`, `amap`, `scope: CcuThunk`, `tcVal: ConstraintSolver.TcValF`, accumulators `referencedTypeDefs` (+ index table), `typeSplices`, `exprSplices`, `isReflectedDefinition`, `quotationFormat`, `mutable emitDebugInfoInQuotations`; static `Create`, `member Close` (returns `(ILTypeRef list) * ((TType*range) list) * ((Expr*range) list)`), static `ComputeQuotationFormat`.
- `QuotationTranslationEnv` — per-translation state: `vs: ValMap<int>` (Val→binding index), `numValsInScope`, `tyvs: StampMap<int>` (typar→index), `suppressWitnesses`, `witnessesInScope: TraitWitnessInfoHashMap<int>`, `isinstVals: ValMap<TType*Expr>` (decodes the `let v = isinst e` construct back to `if istype v then unbox v`), `substVals: ValMap<Expr>`; `CreateEmpty`.
- Exceptions: `InvalidQuotedTerm of exn`, `IgnoringPartOfQuotedTermWarning of string * range`.

**Public API surface**
- `ConvExprPublic: QuotationGenerationScope -> bool (suppressWitnesses) -> Expr -> QuotationPickler.ExprData` — the main conversion entry.
- `ConvReflectedDefinition: QuotationGenerationScope -> string (methName) -> Val -> Expr -> QuotationPickler.MethodBaseData * QuotationPickler.ExprData` — convert a `[<ReflectedDefinition>]` member.
- Active patterns (declared in `.fs`, internal): `(|ModuleValueOrMemberUse|_|)`, `(|SimpleArrayLoopUpperBound|_|)`, `(|SimpleArrayLoopBody|_|)`, `(|ObjectInitializationCheck|_|)` — recognize compiler-generated shapes that must be decoded or re-encoded specially.
- `ConvMethodBase` (line ~1278) — convert a method reference (`valRef`/member) into `MethodBaseData`.

**Notable internal logic**
- `ComputeQuotationFormat` probes two FSharp.Core intrinsics (`g.call_with_witnesses_info`,
  `g.deserialize_quoted_FSharp_40_plus_info`) to decide whether witnesses and typed type-ref tables can be
  serialized; this drives compatibility with older FSharp.Core versions at runtime.
- The scope accumulates referenced type defs and splices as conversion proceeds; `Close()` flushes them
  into the lists carried by the pickled `ExprData` (type splices become `ExprData.TyLambda`/`TyConst`
  splices; expr splices become `ExprData.Let`-captured splices).
- `witnessesInScope` tracks trait witnesses so that witness arguments can be elided from the pickled form
  when the runtime supports them (or recorded when `suppressWitnesses` is false).
- `isinstVals` decodes the pattern-compiler's `let v = isinst e in ...` into the more readable istype/unbox
  form in quotations.
- `ConvExprPublic` recurses over `Expr` nodes (val uses, applications, matches/decision trees, lambdas,
  type lambdas, records/unions/tuples, splices, coerces, new/delegates/trait calls), rebuilding the
  `QuotationPickler.Expr` tree; `ConvMethodBase` handles the value/function reference part.
- `verboseCReflect` (`VERBOSE_CREFLECT` env var) enables debug tracing of the conversion.

**Cross-references**
- `QuotationTranslator.fsi` — public contract (active patterns, scope, exceptions).
- `QuotationPickler.fs` (Optimize dir) — the `ExprData`/`MethodBaseData` pickled shapes and `Expr` AST produced.
- `MethodCalls.fsi` — `GenWitnessExpr`/`MethInfo` context for witness handling.
- `PostInferenceChecks.fsi` — shares `ConstraintSolver.TcValF` and `CcuThunk` parameters.
- `ConstraintSolver.fsi` (sibling) — `TraitConstraintInfo`/witness types.
- `NameResolution.fsi` — `CcuThunk` scoping context used by `QuotationGenerationScope`.

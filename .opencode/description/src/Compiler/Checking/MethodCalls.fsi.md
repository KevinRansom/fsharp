# MethodCalls.fsi

**Purpose**
Public contract (internal module) for the F# checker's method-call machinery. Declares the data types that
represent the caller/called argument matching used by overload resolution (`CallerArg`, `CalledArg`,
`AssignedCalledArg`, `CallerArgs`, `CalledMeth`), the type-directed-conversion bookkeeping
(`TypeDirectedConversionUsed`), and the set of functions that adjust caller arguments, build call
expressions, and generate trait witness expressions.

**Namespace(s)**
`module internal FSharp.Compiler.MethodCalls`

**Modules / Types declared**
- `CallerArg<'T>` — one caller-side argument: type, range, `isOpt` (named with `?`), payload `'T` (a `SynExpr` during checking or an `Expr` during codegen); members `CallerArgumentType`, `Expr`, `IsExplicitOptional`, `Range`.
- `CalledArg` — record describing one argument in the called method: `Position`, `IsParamArray`, `OptArgInfo`, `CallerInfo`, `IsInArg`, `IsOutArg`, `ReflArgInfo`, `NameOpt`, `CalledArgumentType`.
- `AssignedCalledArg<'T>` — record pairing a called arg with its caller arg plus `NamedArgIdOpt`.
- `AssignedItemSetterTarget` / `AssignedItemSetter<'T>` — property setter, IL field setter, or record field setter targets.
- `CallerNamedArg<'T>` — named argument identifier + `CallerArg`.
- `CallerArgs<'T>` (struct) — `Unnamed: CallerArg list list` and `Named: CallerNamedArg list list` (list list = curried argument groups); members `ArgumentNamesAndTypes`, `CallerArgCounts`, `CurriedCallerArgs`, `Empty`.
- `TypeDirectedConversionUsed` (`RequireQualifiedAccess`) — `Yes of (DisplayEnv -> exn) * isTwoStepConversion * isNullable | No`, with static `Combine`.
- `CalledMethArgSet<'T>` — per-argument-set matching state.
- `CalledMeth<'T>` — the syntactic match between a caller and a candidate method (large member surface, see below).
- `ArgumentAnalysis` — lambda-propagation result (`NoInfo`, `ArgDoesNotMatch`, `CallerLambdaHasArgTypes`, `CalledArgMatchesType`).
- `FieldNotMutable` — exception for illegal record-field mutation.
- `ProvidedMethodCalls` — module with `BuildInvokerExpressionForProvidedMethodCall` (`#if !NO_TYPEPROVIDERS`).

**Public API surface** (representative signatures)
- `val MapCombineTDCD: ('a -> OperationResult<TypeDirectedConversionUsed>) -> 'a list -> OperationResult<TypeDirectedConversionUsed>` and `MapCombineTDC2D` (2-arg mapper variant).
- `val AdjustRequiredTypeForTypeDirectedConversions: ... -> TType * TypeDirectedConversionUsed * (TType * TType * (DisplayEnv -> unit)) option`.
- `val AdjustCalledArgType: ... -> TType * TypeDirectedConversionUsed * (TType * TType * (DisplayEnv -> unit)) option`.
- `val ExamineMethodForLambdaPropagation: TcGlobals -> range -> CalledMeth<SynExpr> -> AccessorDomain -> (ArgumentAnalysis list list * (Ident * ArgumentAnalysis) list list) option`.
- `val IsBaseCall: Expr list -> bool`.
- `val BuildILMethInfoCall / MakeMethInfoCall / BuildMethodCall: ... -> Expr * TType` — build call expressions from a `MethInfo` (used by optimizer/codegen for trait solutions).
- `val BuildObjCtorCall`, `val BuildNewDelegateExpr`, `val CoerceFromFSharpFuncToDelegate` — constructor and function→delegate conversion building.
- `val AdjustExprForTypeDirectedConversions`, `val AdjustCallerArgExpr` — per-argument expression adjustment.
- `val AdjustCallerArgs: ... -> (Expr -> Expr) * Expr list * 'b option list * AssignedCalledArg<Expr> list * Expr list * (Expr -> Expr) * 'c option list * Expr list * Binding list`.
- `val RecdFieldInstanceChecks / ILFieldStaticChecks / ILFieldInstanceChecks / MethInfoChecks / CheckRecdFieldMutation` — member-level checks.
- `val GenWitnessExpr: ImportMap -> TcGlobals -> range -> TraitConstraintInfo -> Expr list -> Expr option`, `GenWitnessExprLambda`, `GenWitnessArgs` — witness generation for solved trait constraints.

**Notable `CalledMeth` members**
`CalledObjArgTys`, `GetParamArrayElementType`, `HasCorrectObjArgs`, `IsAccessible`, `IsCandidate`,
`AllCalledArgs`, `ArgSets`, `AssignedItemSetters`, `AssignedNamedArgs`, `AssignedUnnamedArgs`,
`AssignsAllNamedArgs`, `AssociatedPropertyInfo`, `AttributeAssignedNamedArgs`,
`CalledReturnTypeAfterByrefDeref`, `CalledReturnTypeAfterOutArgTupling`, `CalledTyArgs`,
`CalledTyparInst`, `CallerObjArgTys`, `CallerTyArgs`, `HasCorrectArity`, `HasCorrectGenericArity`,
`HasOptionalArgs`, `HasOutArgs`, `IsIndexParamArraySetter`, `IsIndexerSetter`, `Method`, `NumArgSets`,
`NumAssignedProps`, `ParamArrayCalledArgOpt`, `ParamArrayCallerArgs`, `TotalNumAssignedNamedArgs`,
`TotalNumUnnamedCalledArgs`, `TotalNumUnnamedCallerArgs`, `UnassignedNamedArgs`,
`UnnamedCalledOptArgs`, `UnnamedCalledOutArgs`, `UsesParamArrayConversion`, `OptionalStaticType`.

**Significant notes**
- The module doc comment explains the `'T` parametricity of `CallerArg`/`CalledMeth`: `'T = SynExpr` when
  checking existence of a viable overload, `'T = Expr` when building the actual call; parametricity helps
  keep overload resolution independent of caller expressions (modulo adhoc conversions such as
  lambda→delegate).
- `TypeDirectedConversionUsed` explicitly records whether/what conversions were used, which the overload
  tiebreakers (see `OverloadResolutionRules.fsi`) compare.

**Cross-references**
- `MethodCalls.fs` — implementation of every binding above.
- `NameResolution.fsi` — `NameResolutionEnv`, `Item`, used by the `CalledMeth` constructor (nameEnv parameter).
- `OverloadResolutionRules.fsi` — ranking rules operating on pairs of `CalledMeth<Expr> * TypeDirectedConversionUsed * warnCount`.
- `OverloadResolutionCache.fsi` — cache keys/results keyed over `CalledMeth list` / `CallerArgs`.
- `ConstraintSolver.fs` (sibling) — drives this module during `ResolveOverloadingForCall`.
- `PostInferenceChecks.fsi` — consumes `ConstraintSolver.TcValF` (the same value-function signature threaded through here).

# MethodCalls.fs

**Purpose**
Implements, in the Checking phase, the logic associated with resolving F# method calls: matching caller
arguments to called arguments (unnamed, named, optional, param array, out args, named setters), adjusting
caller expressions for type-directed conversions and byref/optional/param-array rules, and building the
final `Expr` that performs the call. It is the core used by `ConstraintSolver.ResolveOverloadingForCall`
and by codegen (witness/optimizer) to construct `MakeMethInfoCall`.

**Namespace(s)**
`module internal FSharp.Compiler.MethodCalls`

**Modules / Types declared**
- `CallerArg<'T>` (union + members) — one caller-side argument with its type, range, explicit-optional flag and payload (`SynExpr` or `Expr`).
- `CalledArg` (record + `CalledArg(...)` function) — one argument in the method being called: position, param-array/optional/out/in/reflected info, type.
- `AssignedCalledArg<'T>` (record) — a matched pair of caller arg and called arg (from named or positional assignment), plus property/field/record-field setter targets.
- `AssignedItemSetter<'T>`, `AssignedItemSetterTarget` — resolution of a named setter argument (prop getter/setter, IL field, record field).
- `CallerNamedArg<'T>`, `CallerArgs<'T>` (struct record) — the list of unnamed and named arguments (list list due to curried/tupled argument groups).
- `TypeDirectedConversionUsed` (union) — whether a type-directed conversion (numeric widening, op_Implicit, two-step, nullable) was used; `Combine` merges two uses.
- `CalledMethArgSet<'T>` (record) — per-curried-set argument matching state (assigned/unassigned args, param array).
- `CalledMeth<'T>` (class) — full syntactic match between a caller and a candidate method; central object consumed by the overload resolution rules.
- `ArgumentAnalysis` (union) — lambda-propagation analysis result for a single argument.
- `FieldNotMutable` (exception) — record field mutation not allowed.
- `ProvidedMethodCalls` (module) — `BuildInvokerExpressionForProvidedMethodCall` for type-provider provided methods.

**Public API surface** (see `MethodCalls.fsi` for full signatures)
- `CalledMeth<'T>` — constructor matches all caller/called argument info; members like `IsCandidate`, `IsAccessible`, `HasCorrectArity`, `ArgSets`, `AssignedItemSetters`, `CalledReturnTypeAfterByrefDeref`, `UnassignedNamedArgs`, `UsesParamArrayConversion`, etc.
- `AdjustRequiredTypeForTypeDirectedConversions`, `AdjustCalledArgType` — find applicable adhoc/numeric conversions so a caller arg fits the called arg type.
- `MapCombineTDCD`, `MapCombineTDC2D` — fold solver operations returning `TypeDirectedConversionUsed`, combining results.
- `ExamineMethodForLambdaPropagation` — detect whether lambda arguments can propagate (delegate conversion vs. F# function).
- `MakeMethInfoCall`, `BuildMethodCall`, `BuildILMethInfoCall`, `BuildObjCtorCall` — build the call `Expr` from a `MethInfo`.
- `BuildNewDelegateExpr`, `CoerceFromFSharpFuncToDelegate` — F# function to delegate adhoc conversion.
- `AdjustCallerArgs`, `AdjustCallerArgExpr`, `AdjustExprForTypeDirectedConversions` — produce the final adjusted argument list (optional defaults, byref, param array).
- `ILFieldStaticChecks`, `ILFieldInstanceChecks`, `MethInfoChecks`, `RecdFieldInstanceChecks`, `CheckRecdFieldMutation` — semantic checks on members before the call is accepted.
- `GenWitnessExpr`, `GenWitnessExprLambda`, `GenWitnessArgs` — generate witness expressions/lambdas for solved trait constraints (5 solution kinds).

**Internal helpers / notable**
- `TryFindRelevantImplicitConversion` — searches candidate conversion operators (op_Implicit, numeric widening, two-step, nullable).
- `AdjustDelegateTy`, `mkOptionalSome/None`, `AdjustCalledArgTypeForOptionals` — optional-argument machinery.
- `MakeCalledArgs` — builds `CalledArg` list from a `MethInfo` (including named setters, param arrays).
- `InferLambdaArgsForLambdaPropagation`, `ExamineArgumentForLambdaPropagation` — lambda-propagation heuristics.
- `TakeObjAddrForMethodCall`, `ComputeConstrainedCallInfo` — static dispatch / trait-constraint call computation.
- `GetDefaultExpressionForCalleeSideOptionalArg` / `CallerSideOptionalArg` — default-argument expansion for F# and C-style callers.

**Significant internal logic**
- The `CalledMeth` constructor performs all named-argument-to-called-argument matching, property/field setter
  resolution, out-arg tupling and byref-return dereferencing; the overload resolution rules (see
  `OverloadResolutionRules.fs`) then rank `CalledMeth` instances.
- `AdjustCallerArgs` produces a big tuple including pre/post adjustment functions, extra bindings (for
  optional-default temporaries) and witness args — this is what `ResolveOverloadingForCall` uses to build the final call.
- Type-directed conversion tracking (`TypeDirectedConversionUsed`) feeds the `NoTDC`/`LessTDC` tiebreakers in `OverloadResolutionRules`.
- `GenWitnessExpr` covers five solution kinds: .NET/F# method, F# record field, anonymous record field,
  built-in solution, and provided-method solution.

**Cross-references**
- `MethodCalls.fsi` — public contract for this module.
- `NameResolution.fsi` — `NameResolutionEnv`, `Item` used in `CalledMeth` construction.
- `OverloadResolutionRules.fs` — consumes `CalledMeth` + `TypeDirectedConversionUsed` for ranking.
- `OverloadResolutionCache.fs` — caches the result of resolving a `calledMethGroup` keyed by `CalledMeth`/`CallerArgs`.
- `ConstraintSolver.fs` (sibling) — calls `AdjustCallerArgs` / `MakeMethInfoCall` during overloading resolution and for witnesses.
- `NicePrint.fs` — `stringOfMethInfo*` used in overload-resolution error messages.
- `TypeRelations.fs` / `TypeHierarchy.fs` — subsumption and interface-hierarchy checks used when examining candidates.

# Exprs.fs

**Purpose**
Implements the `Exprs.fsi` contract. Its core is the conversion engine (`FSharpExprConvert`) that
translates checked TAST (`Expr`) into the language-level `E` enum exposed as `FSharpExpr`, plus the
`FSharpExprPatterns` active-pattern module and the `FSharpAssemblyContents` /
`FSharpImplementationFileContents` wrappers over `CheckedImplFile`s. This is how scripting and FCS
"decompile" function bodies back into F-shape expressions (the same mechanism reflected in
quotation/reflected-definition tooling).

**Namespace(s)**
`namespace FSharp.Compiler.Symbols`

**Modules / Types declared**
- `ExprTranslationImpl` (`[<AutoOpen>]` module) — `ExprTranslationEnv` record: `vs: ValMap<unit>`,
  `tyvs: StampMap<FSharpGenericParameter>`, `isinstVals: ValMap<TType*Expr>`,
  `substVals: ValMap<Expr>`, `suppressWitnesses: bool`, `witnessesInScope: TraitWitnessInfoHashMap<int>`;
  `Bind*` combinators; exception `IgnoringPartOfQuotedTermWarning`.
- `E` (union) — the "core tree": `Value`, `ThisValue`, `BaseValue`, `Application`, `Lambda`,
  `TypeLambda`, `Quote`, `IfThenElse`, `DecisionTree`, `DecisionTreeSuccess`, `Call`, `NewObject`,
  `Let`, `LetRec`, `NewRecord`, `NewAnonRecord`, `AnonRecordGet`, `ObjectExpr`,
  `FSharpFieldGet/Set`, `NewUnionCase`, `UnionCaseGet/Set/Tag/Test`, `TraitCall`, `NewTuple`,
  `TupleGet`, `Coerce`, `NewArray`, `TypeTest`, `AddressSet`, `ValueSet`, `Unused`, `DefaultValue`,
  `Const`, `AddressOf`, `Sequential`, `IntegerForLoop`, `WhileLoop`, `TryFinally`, `TryWith`,
  `NewDelegate`, `ILFieldGet/Set`, `ILAsm`, `WitnessArg`, `DebugPoint`.
- `FSharpObjectExprOverride` (sealed) — wraps a `SlotSig` plus generic params, curried args, body.
- `FSharpExpr` (sealed) — `(cenv, f: (unit -> FSharpExpr) option, e: E, m: range, ty)`; lazy
  `E` member (first access forces `f`); `Range`, `Type`, `ImmediateSubExpressions` (big match over
  `E`), `ToString = "%+A" E`.
- `module FSharpExprConvert` — the translation engine (see below).
- `FSharpAssemblyContents`, `FSharpImplementationFileDeclaration` (union),
  `FSharpImplementationFileContents` — public API classes; `getBind` decurries bindings via
  `IteratedAdjustLambdaToMatchValReprInfo` and wraps bodies with `ConvExprOnDemand`.
- `module FSharpExprPatterns` — one active pattern per `E` case (e.g.
  `(|Value|_|) (e: FSharpExpr) = match e.E with E.Value v -> Some v | _ -> None`).

**Notable internal helpers / active patterns**
- `(|StaticInitializationCheck|_|)`, `(|StaticInitializationCount|_|)` — recognize and elide
  compiler-generated static-init guards (`init@N` fields) from the presentation.
- `(|ILUnaryOp|_|)`, `(|ILBinaryOp|_|)`, `(|ILMulDivOp|_|)`, `(|ILConvertOp|_|)` — map `AI_*` IL
  ops to `mkCall*` F# operator calls; `(|TTypeConvOp|_|)` maps target basic types to
  `Checked/Unchecked` convert functions.
- `ConvExprPrim` / `ConvExpr` / `ConvExprLinear` (tail-recursive continuation-passing forms for
  long let/sequential/union chains), `ConvModuleValueOrMemberUseLinear`, `ConvExprsLinear`,
  `ConvTargetsLinear`, `ConvDecisionTree(Prim)`, `ConvDecisionTreeCase`.
- `GetWitnessArgs` — generates witness args for generic calls when
  `Features.LanguageFeature.WitnessPassing` is enabled; suppresses witnesses for
  conditional-typar (auto-generated comparison/equality) cases; special-cases `op_LeftShift` on
  `char`.
- `ConvLetBind` — erases `isinst` let-bindings (decompiles cached type tests back to
  `TypeTest`/unbox), compiler-generated passthrough lets, literal `()` binds, union-case proofs.
- `ConvILCall` — resolves IL method calls back to F# shapes: `FSharpFunc` Invoke → `Application`;
  constructors; union `New*`/`Is*`/`GetTag`; record `.ctor`/property accessors; module members;
  uses `MakeApplicationAndBetaReduce` for partially-applied/arity-mismatched calls.
- `ConvConst` — all `Const` variants; `Const.Zero` → `E.DefaultValue`.
- `Mk`/`Mk2`/`ConvExprOnDemand` — on-demand FSharpExpr wrappers deferring translation.

**Significant internal logic**
- Tail-recursive translation (continuation `contF`) avoids stack overflow on large linear chains of
  `let`/`seq`/lists, since `E` construction is deferred.
- Decision trees: `TDSwitch`/`TDSuccess`/`TDBind` are flattened into
  `IfThenElse`/`DecisionTree`/`DecisionTreeSuccess`; `IsNull` discriminators are decompiled from
  cached `isinst` bindings recorded in `env.isinstVals`.
- `Expr.DebugPoint` nodes are stripped (inner expression is surfaced).
- `FSharpImplementationFileContents.getDeclarations` walks `TMDefRec`/`TMDefLet`/`TMDefDo`/`TMDefs`,
  producing `Entity` / `MemberOrFunctionOrValue` / `InitAction` declarations.

**Cross-references**
- `Exprs.fsi` — the contract; signatures must stay in sync (e.g. `Call`'s 5-tuple drops witnesses;
  `CallWithWitnesses` adds them).
- `Symbols.fsi` / `Symbols.fs` — `FSharpExpr` carries `FSharpType`,
  `FSharpMemberOrFunctionOrValue`, `FSharpGenericParameter`, `FSharpField`, `FSharpUnionCase`
  values; uses `SymbolEnv` as `cenv`.
- `FSharpDiagnostic.fs` — none directly; `SymbolHelpers.fs` is also unrelated to expressions.

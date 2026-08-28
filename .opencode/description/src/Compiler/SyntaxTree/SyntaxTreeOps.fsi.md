# SyntaxTreeOps.fsi

**Purpose**: Public (module-level internal) contract for `FSharp.Compiler.SyntaxTreeOps`, the helpers module for building/inspecting/transforming the F# syntax tree. Declares the `SynArgNameGenerator` class, the `SynInfo` sub-module, and the full surface of ident/lid helpers, active-pattern matchers, node builders, operator builders, member-flag constructors, val-signature inference, and file/directive utilities.

**Namespace(s)**: `FSharp.Compiler.SyntaxTreeOps`

**Modules / Types declared** (public surface):
- `SynArgNameGenerator` (`[<Class>]`) — `New() : string`, `Reset()`
- `SynInfo` sub-module (qualified) — the val-signature inference/adjustment surface
- (The rest of the surface is the `val` bindings listed in the .fsi below.)

**Public API surface**:
- **Ident / lid**: `ident`, `textOfId`, `pathOfLid`, `arrPathOfLid`, `textOfPath`, `textOfLid`, `rangeOfLid`, `mkSynId`, `pathToSynLid`, `mkSynIdGet`, `mkSynLidGet`, `mkSynIdGetWithAlt`, `mkSynSimplePatVar`, `mkSynCompGenSimplePatVar`, `pushUnaryArg`, `findSynAttribute` (inline)
- **Matchers / active patterns**:
  - `(|LetOrUse|_|)`
  - `(|LongOrSingleIdent|_|)` — matches a long identifier, with a more-optimized shape for single identifiers
  - `(|SingleIdent|_|)`
  - `(|SynAndAlso|_|)`, `(|SynOrElse|_|)`, `(|SynPipeRight|_|)`, `(|SynPipeRight2|_|)`, `(|SynPipeRight3|_|)`
  - `(|SynPatForConstructorDecl|_|)`, `(|SynPatForNullaryArgs|_)`
  - `(|SynExprErrorSkip|)`, `(|SynPatErrorSkip|)`, `(|SynExprParen|_|)`
  - `flattenSequentials`, `(|Sequentials|_|)`
  - `(|Attributes|)`, `(|TyparDecls|)`, `(|TyparsAndConstraints|)`, `(|ValTyparDecls|)`
  - `stripParenTypes`, `(|StripParenTypes|)`
  - `(|MultiDimensionArrayType|_|)`, `(|TypesForTypar|)`
  - `(|Get_OrSet_Ident|_|)`
- **Predicates**: `IsControlFlowExpression` (affects debug-point placement), `IsDebugPointBinding`, `synExprContainsError`
- **Pattern decomposition**: `SimplePatOfPat`, `SimplePatsOfPat`, `PushPatternToExpr`, `PushCurriedPatternsToExpr`, `normalizeTuplePat`
- **Field/pattern builders**: `mkSynAnonField`, `mkSynNamedField`, `mkSynPatVar`, `mkSynThisPatVar`, `mkSynPatMaybeVar`
- **Operator / app builders**: `opNameParenGet`, `opNameQMark`, `mkSynOperator`, `mkSynInfix`, `mkSynBifix`, `mkSynTrifix`, `mkSynPrefixPrim`, `mkSynPrefix`, `mkSynCaseName`, `mkSynApp1`…`mkSynApp5`, `mkSynDotParenSet`, `mkSynDotBrackGet`, `mkSynQMarkSet`, `mkSynUnit`, `mkSynUnitPat`, `mkSynDelay`, `mkSynAssign`, `mkSynDot`, `mkSynDotMissing`, `mkSynFunMatchLambdas`, `arbExpr`
- **Attribute / range helpers**: `unionRangeWithListBy`, `unionRangeWithXmlDoc` (inline), `mkAttributeList`, `ConcatAttributesLists`, `rangeOfNonNilAttrs`, `prependIdentInLongIdentWithTrivia`
- **Dynamic / tuple**: `mkDynamicArgExpr`, `getTypeFromTuplePath`
- **Bindings / members**: `mkSynBindingRhs`, `mkSynBinding`, `mkSynLetBangBinding`, `NonVirtualMemberFlags`, `CtorMemberFlags`, `ClassCtorMemberFlags`, `OverrideMemberFlags`, `AbstractMemberFlags`, `StaticMemberFlags`, `ImplementStaticMemberFlags`, `inferredTyparDecls`, `noInferredTypars`, `unionBindingAndMembers`, `desugarGetSetMembers`, `addEmptyMatchClause`, `getGetterSetterAccess`
- **Function-option combinators**: `appFunOpt`, `composeFunOpt`
- **Val-signature (SynInfo)**: `emptySynValData`, `emptySynArgInfo`, `unnamedTopArg1`, `unnamedTopArg`, `unitArgData`, `unnamedRetVal`, `selfMetadata`, `HasNoArgs`, `IsOptionalArg`, `HasOptionalArgs`, `IncorporateEmptyTupledArgForPropertyGetter`, `IncorporateSelfArg`, `IncorporateSetterArg`, `AritiesOfArgs`, `AttribsOfArgData`, `InferSynArgInfoFromSimplePat`, `InferSynArgInfoFromSimplePats`, `InferSynArgInfoFromPat`, `AdjustArgsForUnitElimination`, `AdjustMemberArgs`, `InferSynReturnData`, `InferSynValData`
- **File / directive / misc**: `longIdentToString`, `stdinMockFileName`, `getSourceIdentifierValue`, `applyLineDirectivesToSourceIdentifier`, `parsedHashDirectiveArguments`, `parsedHashDirectiveArgumentsNoCheck`, `parsedHashDirectiveStringArguments`

**Internal helpers / active patterns / extension members**: `isSimplePattern`, `SynSingleIdent`, `SynBinOp` (all private in the .fs).

**Significant internal logic** (contract-level):
- **`SimplePatOfPat`** (and the `SynArgNameGenerator` parameter) documents that decomposition of a non-simple pattern allocates a fresh `_argN` name from the generator and returns a `SynExpr -> SynExpr` "push" function that inserts the let-binding when the body is applied — the single mechanism behind complex lambda-parameter desugaring.
- **`IsControlFlowExpression`** is documented as affecting debug-point placement; **`IsDebugPointBinding`** encodes the rule "a `let` debug point extends to the `let` only if the r.h.s. is not control-flow and it is not a function-definition".
- **`findSynAttribute`** carries the explicit caution that it operates over the *untyped* tree (checks only the last segment, with or without the `Attribute` suffix) and should be used sparingly.
- **`SynInfo`** — the `Incorporate*` / `Adjust*` / `Infer*` functions define the contract for turning a `SynBinding`/member into `SynValInfo`/`SynArgInfo` (curried arg groups, self-arg, empty-tuple arg for property getters, setter arg, optional args, and the unit-elimination adjustment at the IL level).
- **`mkLetBangBinding`** vs **`mkSynBinding`**: the former is the `let!`/`use!` form (used inside computation expressions), the latter the plain `let`/`use` form.
- The `mkSyn*` operator builders are the canonical way to build `App` trees with the correct `ExprAtomicFlag`/`isInfix` marking; they wrap `PrettyNaming.CompileOpName` so `+` is stored as `op_Addition` in the ident.

**Cross-references**: `SyntaxTreeOps.fs` (implementation), `SyntaxTree.fs` (the AST), `PrettyNaming.fs` (`CompileOpName`, `parenGet`, `qmark`), `SyntaxTrivia.fs` (trivia fields), `ParseHelpers.fs` (consumers of the builders), `Diagnostics`/`Features` (error reporting & language-version gating).

# SyntaxTrivia.fs

**Purpose**: Defines the "trivia" (non-semantic, source-faithful annotation) record types that the F# syntax tree nodes carry. Each AST node in `SyntaxTree.fs` that corresponds to a construct with recognizable source keywords/punctuation (let/and/or, `|`, `->`, `then`/`else`, `with`, `try`/`finally`, `in`, `module`, `type`, `abstract`/`static`/`member`/`override`/`default`/`new`/`val`, `::`, `|{`/`{|`, etc.) carries one of these trivia records plus a `PreXmlDoc`. The trivia record preserves the *exact source positions* of keywords the core node drops, so tooling (formatting, syntax highlighting, go-to-definition, refactoring) can map back to the source. This is also where the *file-level* trivia (`ConditionalDirectiveTrivia`, `WarnDirectiveTrivia`, `CommentTrivia`, grouped under `ParsedInputTrivia`) is defined — it is the public output of `LexerStore` and `WarnScopes`.

**Namespace(s)**: `FSharp.Compiler.SyntaxTrivia` (recursive; `rec` because `ConditionalDirectiveTrivia`/`IfDirectiveExpression` are mutually recursive and `IdentTrivia`/`SynLeadingKeyword` are re-exported into the `FSharp.Compiler.Syntax` namespace via the `open` in `SyntaxTree.fs`)

**Modules / Types declared** (all `[<NoEquality; NoComparison>]`; most `[<RequireQualifiedAccess>]` where noted):
- `IdentTrivia` — `OriginalNotation | OriginalNotationWithParen` | `HasParenthesis` (operator display-name vs. mangled name, with parenthesis ranges)
- `ConditionalDirectiveTrivia` — `If | Elif | Else | EndIf` (with `IfDirectiveExpression` + range)
- `IfDirectiveExpression` — `And | Or | Not | Ident` (the `#if` expression shape)
- `WarnDirectiveTrivia` — `Nowarn | Warnon` (each with a range)
- `CommentTrivia` — `LineComment | BlockComment`
- **`ParsedInputTrivia`** — record bundling `ConditionalDirectives: ConditionalDirectiveTrivia list`, `WarnDirectives: WarnDirectiveTrivia list`, `CodeComments: CommentTrivia list`; `static member internal Empty` — this is the *file-level* trivia attached to `ParsedInput`
- `SynExprTryWithTrivia` — `TryKeyword`, `TryToWithRange`, `WithKeyword`, `WithToEndRange`
- `SynExprTryFinallyTrivia` — `TryKeyword`, `FinallyKeyword`
- `SynExprIfThenElseTrivia` — `IfKeyword`, `IsElif`, `ThenKeyword`, `ElseKeyword`, `IfToThenRange`
- `SynExprLambdaTrivia` — `ArrowRange` (+ `Zero`)
- `SynExprDotLambdaTrivia` — `UnderscoreRange`, `DotRange`
- `SynLetOrUseTrivia` — `InKeyword` (+ `Zero`)
- `SynExprMatchTrivia` — `MatchKeyword`, `WithKeyword`
- `SynExprMatchBangTrivia` — `MatchBangKeyword`, `WithKeyword`
- `SynExprDoBangTrivia` — `DoBangKeyword`
- `SynExprYieldOrReturnTrivia` — `YieldOrReturnKeyword` (+ `Zero`)
- `SynExprYieldOrReturnFromTrivia` — `YieldOrReturnFromKeyword` (+ `Zero`)
- `SynExprAnonRecdTrivia` — `OpeningBraceRange`
- `SynExprSequentialTrivia` — `SeparatorRange` (+ `Zero`)
- `SynMatchClauseTrivia` — `ArrowRange`, `BarRange` (+ `Zero`)
- `SynEnumCaseTrivia` — `BarRange`, `EqualsRange`
- `SynUnionCaseTrivia` — `BarRange`
- `SynPatOrTrivia` — `BarRange`
- `SynPatListConsTrivia` — `ColonColonRange`
- **`SynTypeDefnLeadingKeyword`** — `Type | And | StaticType | Synthetic` (+ `Range` member)
- `SynTypeDefnTrivia` — `LeadingKeyword`, `EqualsRange`, `WithKeyword` (+ `Zero`)
- `SynTypeDefnSigTrivia` — same shape (+ `Zero`)
- **`SynLeadingKeyword`** — the large union of all binding/member leading keywords: `Let | LetBang | LetRec | And | AndBang | Use | UseBang | UseRec | Extern | Member | MemberVal | Override | OverrideVal | Abstract | AbstractMember | Static | StaticMember | StaticMemberVal | StaticAbstract | StaticAbstractMember | StaticVal | StaticLet | StaticLetRec | StaticDo | Default | DefaultVal | Val | New | Do | Synthetic` (+ `Range`)
- `SynBindingTrivia` — `LeadingKeyword`, `InlineKeyword`, `EqualsRange` (+ `Zero`)
- `SynModuleDeclNestedModuleTrivia` — `ModuleKeyword`, `EqualsRange` (+ `Zero`)
- `SynModuleSigDeclNestedModuleTrivia` — same shape (+ `Zero`)
- `SynModuleDeclLetTrivia` — `InKeyword` (+ `Zero`)
- **`SynModuleOrNamespaceLeadingKeyword`** — `Module | Namespace | None`
- `SynModuleOrNamespaceTrivia` — the module/namespace record
- `SynModuleOrNamespaceSigTrivia`
- `SynValSigTrivia`
- `SynTypeFunTrivia` — `ArrowRange`
- `SynMemberGetSetTrivia`
- `SynMemberDefnImplicitCtorTrivia` — `AsKeyword`
- `SynArgPatsNamePatPairsTrivia` — `ParenRange`
- `GetSetKeywords`
- `SynMemberDefnAutoPropertyTrivia`
- `SynMemberDefnLetBindingsTrivia` (+ `Zero`)
- `SynMemberDefnAbstractSlotTrivia` (+ `Zero`)
- `SynMemberDefnInheritTrivia` — `InheritKeyword`
- `SynFieldTrivia`
- `SynTypeOrTrivia` — `OrKeyword`
- `SynTypeWithNullTrivia` — `BarRange`
- `SynBindingReturnInfoTrivia` — `ColonRange`
- `SynMemberSigMemberTrivia` (+ `Zero`)
- `SynTyparDeclTrivia` (+ `Zero`)
- `SynMeasureConstantTrivia`
- `SynTypeConstraintWhereTyparNotSupportsNullTrivia` — `ColonRange`, `NotRange`

**Public API surface**: every type is public (no `[<internal>]`); the `Zero` static members are the "empty" trivia record used by desugaring passes when a node is synthesized with no source. `ParsedInputTrivia.Empty` is internal but the `ParsedInputTrivia` record type is the public file-level trivia shape.

**Internal helpers / active patterns / extension members**: none — the .fs is a pure type-definition file (the .fs and .fsi are structurally identical, differing only in the absence of `<NoEquality;NoComparison>` attribute placement and the inline `Zero` initializations).

**Significant internal logic**:
- **The `Zero` records**: when the compiler *synthesizes* a node (e.g. during desugaring, `LibraryOnly*` lowering, signature emission), it carries the `Zero` trivia so that downstream code can match the record shape uniformly. The `Range` of `Zero` is typically `range0` (synthetic).
- **`SynLeadingKeyword` is the master table** of every leading keyword the compiler recognizes on a binding/member, each case carrying the precise source range(s) of the keyword(s) (for multi-token forms like `static abstract member`, the ranges for each token are stored). This is what `ParseHelpers.appendValToLeadingKeyword` manipulates when it appends `val` to `static member`, etc.
- **`IdentTrivia`** is the bridge between the *display* name (e.g. `+`, `>=>`, `|Odd|Even|`) and the *mangled* name (e.g. `op_Addition`, `op_GreaterEqualsGreater`, `|Odd|Even|`) — the `OriginalNotation`/`OriginalNotationWithParen` cases preserve the original token text and, where relevant, the paren ranges so tools can re-display the operator in its source form. See `PrettyNaming.ConvertValLogicalNameToDisplayName` for the inverse.
- **`ParsedInputTrivia`** is the single public channel for file-level trivia: it bundles the `ConditionalDirectiveTrivia` (from `LexerStore.IfdefStore`), `WarnDirectiveTrivia` (from `WarnScopes.getDirectiveTrivia`), and `CommentTrivia` (from `LexerStore.CommentStore`). The parser sets this on the `ParsedInput` it returns; the F# service and tooling read it.

**Cross-references**:
- `SyntaxTrivia.fsi` — public contract (identical shape)
- `SyntaxTree.fs` — the AST nodes that carry these trivia records (e.g. `SynExpr.TryWith` carries `SynExprTryWithTrivia`, `SynBinding` carries `SynBindingTrivia`, `ParsedInput` carries `ParsedInputTrivia`)
- `SyntaxTreeOps.fs` — `SynLongIdentHelpers`, `FindSynAttribute`, etc. that inspect trivia
- `PrettyNaming.fs` — `ConvertValLogicalNameToDisplayName` / `DoesIdentifierNeedBackticks` / `NormalizeIdentifierBackticks` (the inverse of `IdentTrivia.OriginalNotation`)
- `ParserDetail` (in `SyntaxTree.fs`) — the `Ok | ErrorRecovery` tag that is the *only* thing the type-checker cares about; trivia is *orthogonal* to it
- `LexerStore.fs` — the *producer* of `ConditionalDirectiveTrivia`, `CommentTrivia`
- `WarnScopes.fs` — the *producer* of `WarnDirectiveTrivia`
- `XmlDoc.fs` — `PreXmlDoc` is the parallel channel for XML-doc text

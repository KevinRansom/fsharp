# SyntaxTree.fsi

**Purpose**: Public contract for the F# front-end AST. Declares every node type the parser emits and the type-checker / codegen / tools consume, together with their `Range` member, the named union-case fields, and the trivia/`PreXmlDoc` fields. It is the *contract* — `SyntaxTree.fs` is the implementation (in the F# compiler project the .fsi and .fs are structurally close, but the .fsi is what downstream projects see).

**Namespace(s)**: `FSharp.Compiler.Syntax` (recursive)

**Modules / Types declared** (same list as the .fs — this is the public surface):
- **Identifiers & names**: `Ident`, `SynIdent`, `LongIdent`, `SynLongIdent`, `SynLongIdentHelpers` (obsolete active-pattern helpers), `SynTypar`, `SynTyparDecl`, `SynValTyparDecls`, `LongIdentWithDots` (obsolete)
- **Constants, measure, rational**: `SynConst`, `SynMeasure`, `SynRationalConst`, `SynStringKind`, `SynByteStringKind`
- **Access**: `SynAccess`, `SynValSigAccess`
- **Debug points**: `DebugPointAtTarget`, `DebugPointAtLeafExpr`, `DebugPointAtSequential`, `DebugPointAtTry`, `DebugPointAtWith`, `DebugPointAtFinally`, `DebugPointAtFor`, `DebugPointAtInOrTo`, `DebugPointAtWhile`, `DebugPointAtBinding`
- **Blocks / records / patterns**: `SeqExprOnly`, `BlockSeparator`, `RecordFieldName`, `RecordBinding`, `ExprAtomicFlag`, `SynBindingKind`, `SynPat`, `SynSimplePat`, `SynSimplePats`, `SynArgPats`, `NamePatPairField`, `SynSimplePatAlternativeIdInfo`, `SynLetOrUse`
- **Types**: `SynType`, `SynTupleTypeSegment`, `SynTypeConstraint`, `SynTyparDecls`, `SynTypeSpread`
- **Members / bindings**: `SynAttribute`, `SynAttributeList`, `SynAttributes`, `SynValData`, `SynBinding`, `SynBindingReturnInfo`, `SynMemberFlags` (`[<Flags>]`), `SynMemberKind`, `SynMemberSig`, `SynMemberDefn`, `SynMemberDefns`
- **Type definitions**: `SynTypeDefnKind`, `SynTypeDefnSimpleRepr`, `SynFieldOrSpread`, `SynEnumCase`, `SynUnionCase`, `SynUnionCaseKind`, `SynTypeDefnSigRepr`, `SynTypeDefnSig`, `SynField`, `SynComponentInfo`, `SynTypeDefnRepr`, `SynTypeDefn`
- **Exception / val signatures**: `SynExceptionDefnRepr`, `SynExceptionDefn`, `SynExceptionSig`, `SynValSig`, `SynValInfo`, `SynArgInfo`, `SynReturnInfo`
- **Module / namespace**: `SynModuleDecl`, `SynModuleSigDecl`, `SynModuleOrNamespaceKind`, `SynModuleOrNamespace`, `SynModuleOrNamespaceSig`, `SynOpenDeclTarget`
- **File-level input / output**: `ParsedHashDirectiveArgument`, `ParsedHashDirective`, `ParsedImplFileFragment`, `ParsedSigFileFragment`, `ParsedScriptInteraction`, `ParsedImplFile`, `ParsedSigFile`, `QualifiedNameOfFile`, `ParsedImplFileInput`, `ParsedSigFileInput`, **`ParsedInput`**
- **Expressions**: **`SynExpr`** (the core ~50-case union), `SynExprSpread`, `SynExprRecordField`, `SynExprRecordFieldOrSpread`, `SynExprAnonRecordField`, `SynExprAnonRecordFieldOrSpread`, `SynInterpolatedStringPart`, `SynInterpolationFormatting`, `SynMatchClause`, `SynInterfaceImpl`, `SynStaticOptimizationConstraint`
- **Other**: `ParserDetail`, `TyparStaticReq`, `SynStringKind`, `SynByteStringKind`

**Public API surface** (representative `Range`/accessor members; every type has at least a `Range : range`):
- `Ident.idText`, `Ident.idRange`, `Ident.MakeSynthetic` (internal)
- `SynLongIdent.Range`, `.LongIdent`, `.Dots`, `.Trivia`, `.IdentsWithTrivia`, `.ThereIsAnExtraDotAtTheEnd`, `.RangeWithoutAnyExtraDot`
- `SynExpr.Range`, `.RangeWithoutAnyExtraDot`, `.RangeOfFirstPortion`, `.IsArbExprAndThusAlreadyReportedError`
- `SynPat.Range`, `SynType.Range`, `SynBinding.Range`, `SynMatchClause.Range`, `SynLetOrUse.Range`, `SynSimplePat.Range`, `SynTypar.Range`
- `SynTypeDefn.Range`, `SynTypeDefnSig.Range`, `SynMemberDefn.Range`, `SynField.Range`, `SynValSig.Range`, `SynComponentInfo.Range`
- `SynValInfo.CurriedArgInfos`, `SynValInfo.ReturnInfo`
- `SynArgInfo.Attributes`, `SynArgInfo.Optional`, `SynArgInfo.Ident`
- `ParsedInput.FileName`, `.Range`, `.QualifiedName`, `.Identifiers`
- `ParsedScriptInteraction.Defns`, `.Range`
- `SynConst.IsIntegral`, `.IsNumericOrFloat` (as applicable)

**Public API surface on the core unions** (the cases are a *public* contract):
- `SynExpr`: `Paren | Quote | Const | Typed | Tuple | AnonRecd | ArrayOrList | Record | New | ObjExpr | While | For | ForEach | ArrayOrListComputed | IndexRange | IndexFromEnd | ComputationExpr | Lambda | MatchLambda | Match | Do | Assert | App | TypeApp | TryWith | TryFinally | Lazy | Sequential | If | AddressOf | TraitCall | JoinIn | ImplicitZero | SequentialOrImplicitYield | YieldOrReturn | YieldOrReturnFrom | LetOrUse | MatchBang | DoBang | WhileBang | LibraryOnlyILAssembly | LibraryOnlyStaticOptimization | LibraryOnlyUnionCaseFieldGet | LibraryOnlyUnionCaseFieldSet | ArbitraryAfterError | FromParseError | DiscardAfterMissingQualificationAfterDot | Fixed | InterpolatedString | DebugPoint | Dynamic`
- `SynPat`: `Const | Id | Tuple | ListOrArray | OrPatterns | Constructor | Cast | IsInst | RelationalOp | AndPattern | Typed | Attrib | Record | TypeOf | AnonRecd | ArrayOrListFieldOrSpread | ListOrAnonRecdFieldOrSpread`
- `SynType`: `Fun | Generic | Tuple | Array | Dynamic | Anonymous | TypeOf | TypeWith`
- `SynModuleDecl`: `ModuleAbbrev | NestedModule | Let | Expr | Types | Exception | Open | Attributes | HashDirective | NamespaceFragment`
- `SynModuleSigDecl`: `Val | Nested | Include | Type | Exception | Open`
- `SynMemberDefn`: `Open | Member | GetSetMember | ImplicitCtor | ImplicitInherit | LetBindings | AbstractSlot | Interface | Inherit | ValField | NestedType | AutoProperty`
- `SynTypeDefnRepr`: `ObjectModel | Exception | Simple`
- `SynTypeDefnKind`: `ObjectModel | Simple | Exception`
- `SynTypeDefnSigRepr`: `ObjectModel | Exception | Simple`

**Internal helpers / active patterns / extension members**:
- `SynLongIdentHelpers` (`[<AutoOpen>]`) — `LongIdentWithDots` active pattern + constructor (both `[<Obsolete>]`)
- The `[<RequireQualifiedAccess>]` attribute on the major unions (no implicit opening)

**Significant internal logic** (contract-level):
- The .fsi does not declare any functions — it is purely the type surface. All *operations* on the tree live in `SyntaxTreeOps.fs` (constructors, match helpers, tree rewriters) and `ParseHelpers.fs` (the `mkSyn*` builders the parser uses).
- The `Rec` / mutual-recency between `SynExpr` ↔ `SynPat` ↔ `SynType` is implicit in the `rec` namespace and is the reason the AST is a single big declaration rather than a hierarchy.
- The `PreXmlDoc` fields on `SynBinding`, `SynTypeDefn`, `SynTypeDefnSig`, `SynMemberDefn` (several cases), `SynValSig`, `SynUnionCase`, `SynField`, and `SynComponentInfo` are the single channel by which XML documentation text reaches the type-checker and the signature emitter.
- The `*Trivia` fields on `SynExpr` cases (especially `SynExpr.Lambda`, `SynExpr.Match`, `SynExpr.MatchLambda`, `SynExpr.TryWith`, `SynExpr.TryFinally`, `SynExpr.IfThenElse`, `SynExpr.Sequential`, `SynExpr.AnonRecd`, `SynExpr.YieldOrReturn`, `SynExpr.YieldOrReturnFrom`, `SynExpr.DoBang`, `SynExpr.MatchBang`) are the channel by which *source-only* information (bar-ranges, `and`/`or` keyword positions, `with` keyword positions, `then`/`else` positions) is preserved to the tools without bloating the core nodes.
- `ParsedInput` is the *unified* top-level that the rest of the compiler sees — it erases the Impl/Sig distinction into a single node with `FileName`, `Range`, `QualifiedName`, and `Identifiers`.

**Cross-references**: `SyntaxTree.fs` (implementation), `SyntaxTrivia.fs` (the trivia types), `SyntaxTreeOps.fs` (ops), `XmlDoc.fs` (`PreXmlDoc`), `PrettyNaming.fs` (names), `ParseHelpers.fs` (builders), `LexFilter.fs` / `LexHelpers.fs` / `LexerStore.fs` (token / trivia production), `WarnScopes.fs` (`#nowarn`/`#warnon` trivia), `Diagnostics` (consumption of `ParseErrorContext`).

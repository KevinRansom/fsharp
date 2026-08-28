# SyntaxTree.fs

**Purpose**: The central AST declaration of the F# front-end. Defines every node type the parser (pars.fsy) emits and the rest of the compiler (typecheck, infer, codegen, tools, service) consumes: identifiers, constants/measure/rational constants, types, expressions (`SynExpr`), patterns (`SynPat`), bindings (`SynBinding`), members (`SynMemberDefn`/`SynMemberSig`), type definitions (`SynTypeDefn`), exception definitions, module/namespace declarations, val signatures, and the top-level parsed-file shapes (`ParsedImplFile`, `ParsedSigFile`, `ParsedInput`). Every node carries a source `range` and, in many cases, a `*Trivia` field (see `SyntaxTrivia.fs`) so the tree preserves the original tokens' comments, `#if`/`#nowarn` directives, and the "leading keyword" (`val`/`member`/`abstract`/`override`/`default`/`new`).

**Namespace(s)**: `FSharp.Compiler.Syntax` (declared `namespace rec FSharp.Compiler.Syntax` — the `rec` is needed for the mutual references between `SynExpr`, `SynPat`, `SynType`, etc.)

**Modules / Types declared** (the major ones — a representative list; ~100 types total):
- `Ident` (`[<Struct; NoEquality; NoComparison; DebuggerDisplay>]`) — an identified token with a source range
- `SynIdent` — `Ident` + optional `IdentTrivia`
- `LongIdent = Ident list`
- `SynLongIdent` — `id: LongIdent * dotRanges: range list * trivia: IdentTrivia option list`
- `SynLongIdentHelpers` (`[<AutoOpen>]`) — obsolete `LongIdentWithDots` active pattern / constructor helpers
- `ParserDetail` — `Ok | ErrorRecovery`
- `TyparStaticReq` — `None | HeadType` (for `measure 'a`)
- `SynTypar` — `ident * staticReq * isCompGen`
- `SynStringKind` (Regular / Verbatim / TripleQuote), `SynByteStringKind` (Regular / Verbatim)
- `SynConst` — integer (8/16/32/64, uint*, nativeint), floating-point (IEEE32/64), decimal, bignum, char, string, byte-array, true/false, null, unit, plus `SynConstKind` variants; `IsIntegral`, `IsNumericOrFloat` predicates
- `SynMeasure` — `Dimension | DimensionProduct | Constant | Unit | Rational | Reciprocal | Exponentiation`
- `SynRationalConst` — numerator/denominator rationals
- `SynAccess` — `Public | Private | Internal | None | Protected | PrivateProtected`
- `DebugPointAtTarget`, `DebugPointAtSequential`, `DebugPointAtTry`, `DebugPointAtWith`, `DebugPointAtFinally`, `DebugPointAtFor`, `DebugPointAtInOrTo`, `DebugPointAtWhile`, `DebugPointAtBinding`, `DebugPointAtLeafExpr` — the rich debug-point metadata used by FSI / tooling breakpoint placement
- `SeqExprOnly` — `SeqExprOnly of bool`
- `BlockSeparator = range * pos option`
- `RecordFieldName = SynLongIdent * bool` (name + `isDotDotDot`/spread flag)
- `RecordBinding` — `BindingPattern | BindingId | BindingDotDotDot | BindingUnderscore`
- `ExprAtomicFlag` — `NonAtomic | Atomic`
- `SynBindingKind` — `Normal | ValueRestriction`
- `SynTyparDecl` — `id * attributes * canInfer`
- `SynTypeConstraint` — `Subtype | Delegate | Enum | Measure | SupportsConstraint | NotSupportsConstraint | StaticArgument | StaticArgumentType` and related variants
- `SynTyparDecls` — `SynTyparDecls of typarDecls: SynTyparDecl list * constraints: SynTypeConstraint list`
- `SynTupleTypeSegment`
- `SynType` — `Fun | Generic | Tuple | Array | Dynamic | Anonymous | TypeOf | TypeWith` and friends
- `SynLetOrUse` — `isRec * isUse * keywordRange * bindings * body * range * trivia`
- **`SynExpr`** — the core expression union (~50+ cases): `Paren`, `Quote`, `Const`, `Typed`, `Tuple`, `AnonRecd`, `ArrayOrList`, `Record`, `New`, `ObjExpr`, `While`, `For`, `ForEach`, `ArrayOrListComputed`, `IndexRange`, `IndexFromEnd`, `ComputationExpr`, `Lambda`, `MatchLambda`, `Match`, `Do`, `Assert`, `App`, `TypeApp`, `TryWith`, `TryFinally`, `Lazy`, `Sequential`, `If`, `AddressOf`, `TraitCall`, `JoinIn`, `ImplicitZero`, `SequentialOrImplicitYield`, `YieldOrReturn`, `YieldOrReturnFrom`, `LetOrUse`, `MatchBang`, `DoBang`, `WhileBang`, `LibraryOnlyILAssembly`, `LibraryOnlyStaticOptimization`, `LibraryOnlyUnionCaseFieldGet/Set`, `ArbitraryAfterError`, `FromParseError`, `DiscardAfterMissingQualificationAfterDot`, `Fixed`, `InterpolatedString`, `DebugPoint`, `Dynamic`
- `SynTypeSpread`, `SynExprSpread`, `SynExprRecordField`, `SynExprRecordFieldOrSpread` (`RequireQualifiedAccess`), `SynExprAnonRecordField`, `SynExprAnonRecordFieldOrSpread`
- `SynInterpolatedStringPart` (`String | FillExpr`), `SynInterpolationFormatting` (`DotNet | Printf`)
- `SynSimplePat` — `Id | Typed | Attrib` (with `isCompilerGenerated`, `isThisVal`, `isOptional`, `altNameRefCell`)
- `SynSimplePatAlternativeIdInfo` (`Undecided | Decided`)
- `SynStaticOptimizationConstraint` — `WhenTyparTyconEqualsTycon | WhenTyparIsStruct | WhenTyparIsValueType`
- `SynSimplePats` — `SynArgPats`-shaped arg list
- `NamePatPairField`
- `SynPat` — `Const | Id | Tuple | ListOrArray | OrPatterns | Constructor | Cast | IsInst | RelationalOp | AndPattern | Typed | Attrib | Record | TypeOf | AnonRecd | ArrayOrListFieldOrSpread | ListOrAnonRecdFieldOrSpread`
- `SynInterfaceImpl`
- `SynMatchClause` — `pat * guard * expr * barRange * nextBar * range * trivia`
- `SynAttribute` (target, head, args, kind, range), `SynAttributeList`, `SynAttributes`
- `SynValData` — `typarDecls * optional * typeOpt * xmlDoc`
- **`SynBinding`** — `bindingKind * vis * pat * valData * rhs * xmlDoc * mPattern * mRhs * range * trivia`
- `SynBindingReturnInfo`
- `SynMemberFlags` — `[<Flags>]` set of `Abstract | Instance | Virtual | Override | Final | NewSlot | Internal | Private | Public | Protected | Static | Property | Method | Indexer` etc.
- `SynMemberKind` — `Property | Get | Set | Indexer | Method | EnumCase`
- `SynMemberSig`
- `SynTypeDefnKind` — `ObjectModel | Simple | Exception`
- `SynTypeDefnSimpleRepr`
- `SynFieldOrSpread`
- `SynEnumCase`
- `SynUnionCase` — `id * attributes * access * kind * fields * xmlDoc * range * trivia`
- `SynUnionCaseKind` — `Normal | EnumerantConstant | EnumerantExplicit | NoneCase`
- `SynTypeDefnSigRepr`
- `SynTypeDefnSig`
- `SynField`
- `SynComponentInfo`
- `SynValSigAccess` — `Private | NoAccess | PublicPrivate | PublicPrivateProtected | PublicProtected | PublicInternal | Public | NoInfo`
- `SynValSig`
- **`SynValInfo`** — `Simple | Fun | SynValInfo` (with `curriedArgInfos: SynArgInfo list list * returnInfo: SynArgInfo`)
- `SynArgInfo` — `attributes * optional * ident`
- `SynValTyparDecls` — `typars: SynTyparDecls option * canInfer: bool`
- `SynReturnInfo` — `returnTy: SynType * SynArgInfo * range`
- `SynExceptionDefnRepr`, `SynExceptionDefn`
- `SynTypeDefnRepr`
- **`SynTypeDefn`** — `typeInfo * typeRepr * members * implicitConstructor * range * trivia`
- **`SynMemberDefn`** — `Open | Member | GetSetMember | ImplicitCtor | ImplicitInherit | LetBindings | AbstractSlot | Interface | Inherit | ValField | NestedType | AutoProperty`
- `SynMemberDefns`
- **`SynModuleDecl`** — `ModuleAbbrev | NestedModule | Let | Expr | Types | Exception | Open | Attributes | HashDirective | NamespaceFragment`
- `SynOpenDeclTarget`
- `SynExceptionSig`
- **`SynModuleSigDecl`** — `Val | Nested | Include | Type | Exception | Open`
- `SynModuleOrNamespaceKind`
- **`SynModuleOrNamespace`**
- `SynModuleOrNamespaceSig`
- `ParsedHashDirectiveArgument` — `None | Bool | Float | Int | String | File | Lang | Line | Warn | Nowarn`
- `ParsedHashDirective`
- **`ParsedImplFileFragment`** — `defns: SynModuleDecl list * range * hashDirectives * xmlDocs`
- **`ParsedSigFileFragment`**
- `ParsedScriptInteraction` — top-level `for-in` style interaction
- `ParsedImplFile`
- `ParsedSigFile`
- `QualifiedNameOfFile` — `ModuleName | Namespace`
- `ParsedImplFileInput` — `defns * scriptKind* * hashDirectives * xmlDocs * captureIdents`
- `ParsedSigFileInput`
- **`ParsedInput`** — `ImplFile | SigFile`, with `FileName`, `Range`, `QualifiedName`, and `Identifiers: Set<string>` (populated only under `captureIdentifiersWhenParsing`)

**Public API surface**: all members above are the *surface* — each node exposes a `Range : range` member, and the union cases expose named fields. Notably:
- `SynExpr.Range`, `SynExpr.RangeWithoutAnyExtraDot`, `SynExpr.RangeOfFirstPortion`, `SynExpr.IsArbExprAndThusAlreadyReportedError`
- `SynLongIdent.Range`, `.LongIdent`, `.Dots`, `.Trivia`, `.IdentsWithTrivia`, `.ThereIsAnExtraDotAtTheEnd`, `.RangeWithoutAnyExtraDot`
- `Ident.idText`, `.idRange`, `.MakeSynthetic` (internal)
- `SynPat.Range`, `SynType.Range`, `SynBinding.Range`, `SynTypeDefn.Range`, `SynTypeDefnSig.Range`, `SynMemberSig.Range`, `SynMemberDefn.Range`, `SynField.Range`, `SynValSig.Range`, `SynValInfo`'s `CurriedArgInfos`, `SynMatchClause.Range`, `SynSimplePat.Range`, `SynLetOrUse.Range`, `SynExprInterpolatedStringPart` etc.

**Internal helpers / active patterns / extension members**: none in the .fs (the .fs is the AST declaration; the *operations* on it live in `SyntaxTreeOps.fs`, and *trivia* in `SyntaxTrivia.fs`).

**Significant internal logic**:
- **`rec` namespace**: the mutual recurrences between `SynExpr` (which contains `SynPat` in `Match`/`MatchLambda`/`LetOrUse`) and `SynPat` (which contains `SynExpr` in guards) force a recursive namespace.
- **`NoEquality; NoComparison`** is on virtually every node (the tree contains `ref` cells like `SynSimplePatAlternativeIdInfo ref` and the `PreXmlDoc` lazy collector, which cannot be meaningfully compared).
- **`RequireQualifiedAccess`** is on the major unions (`SynExpr`, `SynPat`, `SynType`, `SynModuleDecl`, `SynMemberDefn`, `SynTypeDefn`, …) so client code must write `SynExpr.App ...` — this avoids name shadowing and keeps the surface stable.
- **Trivia-attached nodes** (e.g. `SynExpr.Lambda` carries `SynExprLambdaTrivia`, `SynExpr.Match` carries `SynExprMatchTrivia`, `SynExpr.TryWith` carries `SynExprTryWithTrivia`) and **`PreXmlDoc`-attached nodes** (`SynTypeDefn`, `SynMemberDefn.AbstractSlot`, `SynMemberDefn.AutoProperty`, `SynMemberDefn.ImplicitCtor`, `SynValSig`, `SynBinding`) are the two cross-cutting channels by which "source-only" information reaches the rest of the compiler without the core types importing tooling types.
- **`ParsedImplFileInput` / `ParsedSigFileInput`** are the parser's *output* shapes, separate from the *input* shapes `ParsedImplFile` / `ParsedSigFile` so that the service can hold the same data in either direction. `ParsedInput` unifies both.
- **`SynConst`** is a large union covering every F# literal (including `Bignum`, `Measure`, `Rational`) and is the node that the type-checker pattern-matches against to drive conversion to `Syn.RationalConst` (see F# spec section on `System.Numerics.BigInteger` and decimal literals).
- **Debug-point fields**: the `DebugPointAt*` record types each carry `range` + `originalDebugPoint` + hidden flag, allowing FSI/diagnostics to attach the real source position even when the compiler has rewritten the expression.

**Cross-references**:
- `SyntaxTree.fsi` — public contract (this .fs is the implementation; all members are defined in the .fs, not the .fsi)
- `SyntaxTrivia.fs` — the `*Trivia` types referenced throughout (IdentTrivia, SynExpr*Trivia, SynTypeDefnTrivia, SynMemberDefn*Trivia, SynBindingTrivia, …)
- `SyntaxTreeOps.fs` — the constructor / walker / matcher helpers (`ident`, `mkSynId`, `mkSynIdGet`, `mkSynApp1`, `mkSynLetBangBinding`, `mkSynMemberDefn*`, …)
- `XmlDoc.fs` — `PreXmlDoc` used by `SynBinding`, `SynTypeDefn`, `SynMemberDefn`, `SynValSig`, `SynUnionCase`, `SynField`, etc.
- `ParseHelpers.fs` — the `mkSyn*` family that *builds* these nodes from parser actions
- `LexFilter.fs` / `LexHelpers.fs` / `LexerStore.fs` — produce the token stream + trivia that the parser folds into these nodes
- `PrettyNaming.fs` — name mangling applied when the tree is lowered to `Syn.RationalConst`-level names and emitted to IL
- `WarnScopes.fs` — `#nowarn`/`#warnon` trivia that flow through `ParsedHashDirective`

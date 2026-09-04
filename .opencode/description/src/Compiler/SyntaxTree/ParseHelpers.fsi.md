# ParseHelpers.fsi

**Purpose**: Public (module-level internal) contract for `FSharp.Compiler.ParseHelpers`. Declares the exceptions, position/range plumbing, lexer-state types, and the large `mkSyn*` AST-construction surface that the generated Yacc parser (pars.fsy actions) and the lexing infrastructure import. The .fs holds the implementations and extra internal helpers.

**Namespace(s)**: `FSharp.Compiler` (module `FSharp.Compiler.ParseHelpers`; extension members on `LexBuffer<'Char>` and `IParseState` live in `FSharp.Compiler` and `Internal.Utilities.Text.Parsing` respectively)

**Modules / Types declared** (public surface):
- `SyntaxError of obj * range` — `<NoEquality; NoComparison>`; payload is a `ParseErrorContext` from the parser engine
- `IndentationProblem of string * range`
- `LexerIfdefStackEntry` / `LexerIfdefStackEntries` / `LexerIfdefStack`
- `LexerEndlineContinuation` (`RequireQualifiedAccess`): `Token | IfdefSkip`
- `LexerStringStyle` (`RequireQualifiedAccess`): `Verbatim | TripleQuote | SingleQuote | ExtendedInterpolated`
- `LexerStringKind` (`RequireQualifiedAccess; Struct`): `{ IsByteString; IsInterpolated; IsInterpolatedFirst }` + static members `ByteString`, `InterpolatedStringFirst`, `InterpolatedStringPart`, `String`
- `LexerInterpolatedStringNesting`
- `LexerContinuation` (`RequireQualifiedAccess`): `Token | IfDefSkip | String | Comment | SingleLineComment | StringInComment | EndLine`; `default` + `LexerIfdefStack` / `LexerInterpStringNesting` members
- `LexCont = LexerContinuation` (type alias)
- `BindingSet`: `BindingSetPreAttrs of range * bool * bool * (functor) * range`

**Public API surface**:
- Range/pos: `warningStringOfCoords`, `warningStringOfPos`, `posOfLexPosition`, `mkSynRange`, `LexBuffer<'Char>.LexemeRange`
- Parse-state accessors: `lhs`, `rhs2`, `rhs`
- Interpolated strings: `peelTrailingPrintfSpecifier`, `mkInterpolatedStringFillParts`
- Conditional compilation: `LexerIfdefStack*`, `LexerContinuation`, `LexerStringKind`
- Inline IL: `ParseAssemblyCodeInstructions`, `ParseAssemblyCodeType`
- XML docs: `grabXmlDocAtRangeStart`, `grabXmlDoc`
- Errors: `reportParseErrorAt`, `raiseParseErrorAt`
- AST constructors: `mkSynMemberDefnGetSet`, `mkSynTypeTuple`, `mkLetExpression`, `mkLetBangExpression`, `mkAndBang`, `mkDefnBindings`, `mkClassMemberLocalBindings`, `mkSynDoBinding`, `mkSynExprDecl`, `mkAutoPropDefn`, `mkValField`, `mkSynField`, `mkAbstractMember`, `mkSynUnionCase`, `mkMatchClauses`, `mkMatchClausesRecoverMissingResult`, `mkRecdField`, `mkUnderscoreRecdField`, `rebindRanges`
- Misc: `adjustHatPrefixToTyparLookup`, `exprFromParseError`, `patFromParseError`, `idOfPat`, `checkForMultipleAugmentations`, `rangeOfLongIdent`, `appendValToLeadingKeyword`, `leadingKeywordIsAbstract`, `checkEndOfFileError`, `unionRangeWithPos`, `addAttribs`, `debugPrint`

**Internal helpers / active patterns**: the .fsi exposes the `GetIdent | SetIdent | OtherIdent`-style split indirectly through signatures; the actual active pattern and the binding-builder closures live in the .fs.

**Significant internal logic** (declared by the contract, implemented in the .fs):
- The `BindingSet` type encodes the two-stage attributes-then-binding structure of `let`/`use`/`let!` so the parser can attach attributes parsed around the binders later.
- `grabXmlDoc` documents that the XML-doc store is drained at a specific parse-state range — see `XmlDoc.fs` and `LexerStore.XmlDocStore`.
- `checkEndOfFileError` documents that a non-`Token` `LexerContinuation` at EOF is an error (dangling `#if`/string/comment).
- `mkMatchClauses*` are documented as threaded functions carrying ranges and a `nextClauses` callback so the recursive parse stays range-correct.

**Cross-references**: `ParseHelpers.fs` (implementation), `LexHelpers.fs` (string/keyword/unicode helpers), `LexerStore.fs` (drained by `grabXmlDoc`/`checkEndOfFileError`), `XmlDoc.fs` (`PreXmlDoc`), `SyntaxTree.fs` (the AST types these functions construct), `LexFilter.fs` (raises `IndentationProblem`), `SyntaxTreeOps.fs` (tree ops used by some helpers).

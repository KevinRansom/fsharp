# ParseHelpers.fs

**Purpose**: Internal F-module of helpers used *inside* the generated Yacc parser actions (pars.fsy) and the lexing infrastructure. It provides: (1) the `SyntaxError`/`IndentationProblem` exceptions and range/position plumbing the parser engine uses to report errors; (2) the `LexArgs`-adjacent lexer bookkeeping types (`LexerIfdefStack`, `LexerStringKind`, `LexerContinuation`, `LexerInterpolatedStringNesting`) that flow through the F# lexer states in `LexFilter.fsl`-generated code; (3) the big family of `mkSyn*` / `mk*` functions that build `SynExpr`/`SynPat`/`SynMemberDefn`/`SynUnionCase`/`SynModuleDecl` nodes for let/use/bang bindings, auto-properties, fields, abstract members, match clauses, and record updates; (4) XML-doc grabbing against the `LexerStore`/`XmlDoc` stores; (5) inline-IL string parsing entry points (`ParseAssemblyCodeInstructions`/`ParseAssemblyCodeType`); (6) interpolated-string fill-part construction.

**Namespace(s)**: `FSharp.Compiler` (module `FSharp.Compiler.ParseHelpers`; also `FSharp.Compiler` for the `LexBuffer`/`IParseState` extension members)

**Modules / Types declared**:
- `SyntaxError of obj * range` — exception: parse-error context (from the parser engine) + range
- `IndentationProblem of string * range` — lexfilter offside-rule diagnostic
- `LexerIfdefStackEntry` / `LexerIfdefStackEntries` / `LexerIfdefStack` — `#if/#else/#elif` nesting state carried by the lexer
- `LexerEndlineContinuation` — what follows an end-of-line inside a conditional/string (`Token` | `IfdefSkip`)
- `LexerStringStyle` — `Verbatim | TripleQuote | SingleQuote | ExtendedInterpolated`
- `LexerStringKind` — struct `{ IsByteString; IsInterpolated; IsInterpolatedFirst }` with `ByteString`, `InterpolatedStringFirst`, `InterpolatedStringPart`, `String` static members
- `LexerInterpolatedStringNesting` — `(int * LexerStringStyle * int * range option * range) list`
- `LexerContinuation` — `Token | IfDefSkip | String | Comment | SingleLineComment | StringInComment | EndLine`; each carries the ifdef stack + string nesting; `Default` static member
- `BindingSet` — `BindingSetPreAttrs of range * bool * bool * (SynAttributes -> SynAccess option -> SynAttributes * SynBinding list) * range`
- `NameArityPair` (internal; actually in PrettyNaming) — n/a here
- Active pattern `GetIdent | SetIdent | OtherIdent` — splits a property accessor ident for `mkSynMemberDefnGetSet`

**Public API surface**:
- Position/range: `warningStringOfCoords`, `warningStringOfPos`, `posOfLexPosition`, `mkSynRange`, `LexBuffer<'Char>.LexemeRange`
- Parser-state access: `lhs : IParseState -> range`, `rhs2 : IParseState -> int -> int -> range`, `rhs : IParseState -> int -> range`
- Interpolated strings: `peelTrailingPrintfSpecifier`, `mkInterpolatedStringFillParts` (builds `SynInterpolatedStringPart` list, splitting `{x,n}` alignment and printf specifier)
- Inline IL: `ParseAssemblyCodeInstructions`, `ParseAssemblyCodeType` (gated by `#if NO_INLINE_IL_PARSER`)
- XML docs: `grabXmlDocAtRangeStart`, `grabXmlDoc` (calls into `XmlDocStore.GrabXmlDocBeforeMarker` via the `lexbuf`)
- Errors: `reportParseErrorAt`, `raiseParseErrorAt`
- AST-construction (used by parser actions):
  - `mkSynMemberDefnGetSet` — property get/set accessor definitions
  - `mkLetExpression`, `mkLetBangExpression`, `mkAndBang`, `mkDefnBindings`, `mkClassMemberLocalBindings`, `mkSynDoBinding`, `mkSynExprDecl`
  - `mkAutoPropDefn`, `mkValField`, `mkSynField`, `mkAbstractMember`
  - `mkSynUnionCase`
  - `mkMatchClauses`, `mkMatchClausesRecoverMissingResult`
  - `rebindRanges`, `mkRecdField`, `mkUnderscoreRecdField`
  - `mkSynTypeTuple`, `mkSynMemberDefnGetSet`
- Misc: `adjustHatPrefixToTyparLookup` (turn `^T` into typed lookup), `exprFromParseError`, `patFromParseError`, `idOfPat`, `checkForMultipleAugmentations`, `rangeOfLongIdent`, `appendValToLeadingKeyword`, `leadingKeywordIsAbstract`, `checkEndOfFileError`, `unionRangeWithPos`, `addAttribs`, `debugPrint`

**Internal helpers / active patterns**:
- `GetIdent | SetIdent | OtherIdent` — property accessor name split
- `chopStringTo`-style local helpers inside `mkSynMemberDefnGetSet`

**Significant internal logic**:
- **Binding construction**: `mkLetExpression`/`mkLetBangExpression`/`mkAndBang` assemble `SynBinding` lists from `BindingSetPreAttrs` (which carries a deferred builder function `SynAttributes -> SynAccess -> Attributes * bindings` so the parser can attach attributes parsed *after* the `let` keyword before the binders) and produce `SynExpr.LetOrUse` / `SynExpr.LetOrUseBang` with correct `SynBindingReturnInfo`.
- **Get/Set assembly**: `mkSynMemberDefnGetSet` walks a list of accessor elements and produces a `SynMemberDefn list` with the proper `SynAccess` per accessor, splitting `Get`/`Set` via the `GetIdent|SetIdent` active pattern.
- **Auto-property** (`mkAutoPropDefn`): single `SynMemberDefn` for `member x.Property = ...` with optional `Get/Set` accessor list.
- **Match clauses** (`mkMatchClauses`): threaded function pattern — folds the clauses list forward, threading a `nextClauses` callback and emitting `SynMatchClause` nodes with the right `with`/`and` ranges; the `RecoverMissingResult` variant synthesizes a dummy result for recovery.
- **XML-doc grab** (`grabXmlDoc`): calls `XmlDocStore.GrabXmlDocBeforeMarker` at the parse-state range so the pending `PreXmlDoc` is attached to the right element; handles `elemIdx > 0` (e.g. `and`-chains) by returning empty.
- **`checkEndOfFileError`**: if the lexer terminated mid-`#if` or mid-string (a `LexerContinuation` other than `Token`), report the dangling directive/string diagnostic with its range — this is what produces the "unclosed ``#if``" style errors.
- **`adjustHatPrefixToTyparLookup`**: rewrites a `SynExpr.App`/field whose head is `^T` into the appropriate qualified-lookup form, preserving range.
- **`mkSynTypeTuple`**: normalizes trailing single-unit segments so `(int,)` parses correctly.

**Cross-references**: `ParseHelpers.fsi` (public contract), `LexHelpers.fs` (the lower-level lexing helpers — strings, keywords, unicode escapes), `LexerStore.fs` (drained by `grabXmlDoc`, `checkEndOfFileError`), `LexFilter.fs` (raises `IndentationProblem`), `XmlDoc.fs` (`PreXmlDoc`), `SyntaxTree.fs` (the AST types these functions produce), `SyntaxTreeOps.fs` (tree-walking used by some helpers).

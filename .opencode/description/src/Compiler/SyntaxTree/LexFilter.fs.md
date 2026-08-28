# LexFilter.fs

**Purpose**: The heart of F#'s lexical front-end: a stateful token-stream transformer that runs between the OCaml-ported lexer (lexbuf + lexer in `LexFilter.fsl`-generated code, driven via `LexArgs` from `LexHelpers.fs`) and the Yacc parser. It implements the offside rule (indentation-based block structure), inserts the `OBLOCKBEGIN/OBLOCKEND/ODECLEND/OLET/OTOKEN` family of pseudo-tokens, disambiguates `type`/`module`/`member`/`with`/`fun`/`if`/`match` etc. into their O-variants, handles "coming soon" tokens for error recovery, adjacency disambiguation (`f(1)` vs `f (1)`, `f<int> x`), and signed-literal merging. It also records XML-doc grab points per token via `LexerStore.XmlDocStore`.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.LexFilter`)

**Modules / Types declared**:
- `Context` — discriminated union of offside-rule contexts (`CtxtLetDecl`, `CtxtIf`, `CtxtTry`, `CtxtFun`, `CtxtFunction`, `CtxtWithAsLet`, `CtxtWithAsAugment`, `CtxtMatch`, `CtxtFor`, `CtxtWhile`, `CtxtWhen`, `CtxtVanilla`, `CtxtThen`, `CtxtElse`, `CtxtDo`, `CtxtInterfaceHead`, `CtxtTypeDefns`, `CtxtNamespaceHead`, `CtxtModuleHead`, `CtxtMemberHead`, `CtxtMemberBody`, `CtxtModuleBody`, `CtxtNamespaceBody`, `CtxtException`, `CtxtParen`, `CtxtSeqBlock`, `CtxtMatchClauses`)
- `AddBlockEnd`, `FirstInSequence`, `LexingModuleAttributes` — small helper unions
- `isInfix`, `infixTokenLength` — token-classification helpers
- Active patterns: `TokenLExprParen`/`TokenRExprParen` (left/right expression delimiters), `TyparsCloseOp` (splits `>>...` closers into `GREATER` runs), `Equals`/`StartsWith` (span matchers)
- `LexbufState` — struct snapshot of lexbuf (start/end/EOF)
- `TokenTup` — class pairing a token with `LexbufState` and previous token position (mutable for perf)
- `TokenTupPool` — object-pool for `TokenTup` (max 100; `Rent`/`Return`/`UseLocation`/`UseShiftedLocation`) to reduce GC pressure in hot lexing loop
- `PositionWithColumn` — struct helper for undentation limits
- `LexFilterImpl` — the main implementation type; all offside-rule logic lives here
- `LexFilter` — thin public wrapper; adds "coming soon" (`RPAREN_COMING_SOON`, `RBRACE_COMING_SOON`, `OBLOCKEND_COMING_SOON`) inserts before the corresponding real tokens

**Public API surface**:
- `LexFilter(compilingFSharpCore: bool, lexer: LexBuffer<char> -> token, lexbuf: LexBuffer<char>, debug: bool)` — constructor
- `member LexBuffer : LexBuffer<char>` — access to the underlying lexbuf
- `member GetToken() : token` — pull the next transformed token
- `TyparsCloseOp` active pattern (also in .fsi)

**Internal helpers**:
- `parenTokensBalance` — matches open/close token pairs including `INTERP_STRING_*` and `LQUOTE/RQUOTE`
- `tokenBalancesHeadContext` / `tokenForcesHeadContextClosure` — decide when a token closes the head context
- `suffixExists`, `isAdjacent`, `nextTokenIsAdjacentLBrack/LParen`, `peekAdjacentTypars` — adjacency/lookahead heuristics for HIGH_PRECEDENCE disambiguation
- `insertComingSoonTokens(keywordName, comingSoon, isHere)` — emit 6 recovery dummy tokens (`TYPE_COMING_SOON`/`TYPE_IS_HERE` etc.) to help the Yacc parser recover from unclosed parens before a `type`/`module` keyword
- `checkForInvalidDeclsInTypeDefn` — detects `TYPE`/`MODULE`/`EXCEPTION`/`OPEN` declarations improperly nested inside a type definition (per `LanguageFeature.ErrorOnInvalidDeclsInTypeDefinitions`), walking the offside stack
- `thereIsACtxtMemberBodyOnTheStackAndWeShouldPopStackForUpcomingMember` — conservatively decides whether a new `member` pops the old `CtxtMemberBody` (exempting object expressions and static-inline constraints)
- `endTokenForACtxt` — maps context to its closing token (`OEND`, `ODECLEND`, `OBLOCKEND`, `ORIGHT_BLOCK_END`, `OBLOCKSEP`)
- `pushCtxtSeqBlock` / `tryPushCtxtSeqBlock` / `pushCtxtSeqBlockAt` — push a new `CtxtSeqBlock` and insert `OBLOCKBEGIN` when appropriate
- `isLongIdentEquals` — detects `expr.let` / `expr.M.x = ...` for `with`/record binding detection
- `rulesForBothSoftWhiteAndHardWhite` — token-splitting/merging rules: `INT32_DOT_DOT` → `INT32 DOT_DOT`, `DOT_DOT_HAT` → `DOT_DOT INFIX_AT_HAT_OP`, `RQUOTE_DOT` → `RQUOTE DOT`, `RQUOTE_BAR_RBRACE` → `BAR_RBRACE RQUOTE`, signed-literal merging (`-42` → `INT32(-42)`), `HASH_IDENT` → `HASH IDENT`, `HIGH_PRECEDENCE_TYAPP` insertion for `f<int>`
- `hwTokenFetch` — the main loop (2000+ lines of pattern matching)
- `getLexbufState` / `setLexbufState` / `runWrappedLexerInConsistentLexbufState` — save/restore lexbuf state when faking a new token stream
- `peekInitial` — initial context setup; seeds `CtxtSeqBlock(FirstInSeqBlock, ...)`
- `reportDiagnostic` / `warn` / `error` — emit `IndentationProblem` diagnostics

**Significant internal logic**:
- **Offside rule**: `Context` carries the start position of each active construct; when a token's column drops below (or equals, with per-keyword grace) the context's offside column, the context is popped and the appropriate end-token (`OEND`, `ODECLEND`, `OBLOCKEND`, `ORIGHT_BLOCK_END`) is inserted. Each context kind has its own rule with keyword-specific "continuator" checks (e.g. `THEN`/`ELSE`/`ELIF` may align with `if` to close it; `WITH` aligns with `match`/`try`; `END` aligns with `with` for type augmentation).
- **RelaxWhitespace2**: a `lexbuf.SupportsFeature` gate that relaxes several rules (let/match/paren alignment).
- **`else if` → `elif`**: `ELSE IF` on the same line is rewritten to `ELIF` with a combined range.
- **`with` disambiguation**: `WITH` is context-dependent — object expression `with` (`CtxtWithAsLet`), type/augmentation `with` (`CtxtWithAsAugment`), `match`/`try` with-clauses (`CtxtMatchClauses`) — each with distinct offside limits.
- **TYPE/MODULE recovery**: `checkForInvalidDeclsInTypeDefn` + `insertComingSoonTokens` emit `TYPE_COMING_SOON`×6 / `TYPE_IS_HERE` (and equivalents for `MODULE`/`EXCEPTION`/`OPEN`) to give the parser shiftable tokens when a type/module appears inside an unclosed paren context.
- **High-precision app detection**: `f(1)` adjacency, `f<int>`, `f<int>(x)` (HIGH_PRECEDENCE_PAREN_APP/BRACK_APP/TYAPP), and `TyparsCloseOp` splitting of `>>`-style closers.
- **Signed literals**: `-42`, `+3.5`, `&1` merging, with special handling of `bad` overflow flags.
- **`;;` (SEMICOLON_SEMICOLON)**: terminates a sequence block; in a namespace/module-whole-file body it's passed through; in F# Interactive it schedules `ORESET` to reinitialize the filter.
- **`BAR NULL` → `BAR_JUST_BEFORE_NULL`** under `LanguageFeature.NullnessChecking`.
- **XML doc tracking**: after each token, `XmlDocStore.AddGrabPoint` is called; the last non-comment token line is tracked for doc validation.
- **Performance**: `TokenTupPool` avoids per-token allocation in the hot path; `delayedStack` + `tokensThatNeedNoProcessingCount` short-circuit already-processed inserted tokens.

**Cross-references**: `LexHelpers.fs` (`LexArgs`, `Keywords`, `ByteBuffer`, `escape`, `unicodeGraph*` — the lower-level lexing helpers), `LexerStore.fs` (XmlDoc/Ifdef/Comment/LineDirective stores), `UnicodeLexing.fs` (Unicode table), `SyntaxTree.fs` (the AST the parser builds), `SyntaxTrivia.fs` (trivia emitted from these stores), `ParseHelpers.fs` (parser-side helpers).

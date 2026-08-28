# LexFilter.fsi

**Purpose**: Public contract for the `FSharp.Compiler.LexFilter` module — the stateful offside-rule token-stream filter that sits between the lexer and the Yacc parser. The .fsi exposes only the `LexFilter` class and the `TyparsCloseOp` active pattern; all implementation types (`Context`, `TokenTup`, `TokenTupPool`, `LexFilterImpl`, the rule set, etc.) are internal to the .fs.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.LexFilter`)

**Modules / Types declared** (public surface):
- `TyparsCloseOp` — `[<Struct>]` active pattern returning `(bool -> token)[] * token voption` voption; splits a leading run of `>` into `GREATER` tokens, with an optional trailing operator token
- `LexFilter` — the filter class

**Public API surface**:
- `LexFilter.new : compilingFSharpCore: bool * lexer: (LexBuffer<char> -> token) * lexbuf: LexBuffer<char> * debug: bool -> LexFilter`
- `member LexBuffer : LexBuffer<char>` — the wrapped lex buffer
- `member GetToken : unit -> token` — pull the next (possibly rewritten/inserted) token
- `TyparsCloseOp` active pattern (also used in `service.fs` for limited post-processing)

**Internal helpers / active patterns** (see .fs): `Context`, `AddBlockEnd`, `FirstInSequence`, `LexingModuleAttributes`, `isInfix`, `infixTokenLength`, `TokenLExprParen`, `TokenRExprParen`, `Equals`, `StartsWith`, `parenTokensBalance`, `LexbufState`, `TokenTup`, `TokenTupPool`, `PositionWithColumn`, `LexFilterImpl`, `rulesForBothSoftWhiteAndHardWhite`, `hwTokenFetch`, `pushCtxtSeqBlock`, `insertHighPrecedenceApp`, `checkForInvalidDeclsInTypeDefn`, `thereIsACtxtMemberBodyOnTheStackAndWeShouldPopStackForUpcomingMember`, `endTokenForACtxt`, `tokenForcesHeadContextClosure`, `suffixExists`, `isAdjacent`, `peekAdjacentTypars`, `insertComingSoonTokens`.

**Significant internal logic**:
- Implements the **offside rule** (indentation-driven block structure) and a set of lexical transformations that rewrite raw tokens into `O*`-prefixed tokens (`OLET`, `ODECLEND`, `OBLOCKSEP`, `OBLOCKBEGIN`, `OBLOCKEND`, `ORIGHT_BLOCK_END`, `OWITH`, `OTOKEN_OTHEN`, `OTOKEN_OELSE`, `OTOKEN_OEND`, `OTOKEN_ODO`, `OTOKEN_OLET`, `OINTERFACE_MEMBER`, etc.) so the Yacc grammar can recognize block boundaries.
- Inserts "coming soon" recovery tokens (`TYPE_COMING_SOON`×6 / `TYPE_IS_HERE`, `MODULE_COMING_SOON`/`MODULE_IS_HERE`, `RPAREN_COMING_SOON`/`RPAREN_IS_HERE`, `RBRACE_COMING_SOON`/`RBRACE_IS_HERE`, `OBLOCKEND_COMING_SOON`/`OBLOCKEND_IS_HERE`) to help the parser shift rather than recover.
- Disambiguates adjacent tokens via `isAdjacent`/`nextTokenIsAdjacent*`: `HIGH_PRECEDENCE_PAREN_APP`, `HIGH_PRECEDENCE_BRACK_APP`, `HIGH_PRECEDENCE_TYAPP`.
- Rewrites `ELSE IF` (same line) → `ELIF`, `IN`→`ODECLEND`, `DONE`→`ODECLEND`, `DO`→`ODO`, `FUNCTION`→`OFUNCTION`, `THEN`→`OTOKEN_OTHEN`, `ELSE`→`OTOKEN_OELSE`, `WITH`→`OWITH`, `LET`→`OLET`, `LAZY`→`OLAZY`, `ASSERT`→`OASSERT`, `DO_BANG`→`ODO_BANG`, `BINDER`→`OBINDER`, `AND_BANG`→`OAND_BANG`, `INTERFACE`→`OINTERFACE_MEMBER` when it starts an abstract member list inside a `type`.
- Merges signed integer/decimal literals (`-42`, `+.5`, `&1`); splits `INT32_DOT_DOT`, `DOT_DOT_HAT`, `RQUOTE_DOT`, `RQUOTE_BAR_RBRACE`, `GREATER_RBRACK`, `GREATER_BAR_RBRANK`, `GREATER_BAR_RBRACE`, `GREATER_BAR_RBRACE` via `TyparsCloseOp` / `UseShiftedLocation`.
- Tracks the last non-comment token line for XML-doc validation (via `XmlDocStore.SetLastNonCommentTokenLine`) and adds XML-doc grab points per token (`XmlDocStore.AddGrabPoint`).

**Cross-references**: `LexFilter.fs` (implementation), `LexHelpers.fs` (lower-level lex helpers: `escape`, `unicodeGraphShort/Long`, `addUnicodeChar`, `digit`, `hexdigit`, `trigraph`, `Keywords`), `LexerStore.fs` (XmlDoc/Ifdef/Comment/LineDirective stores this filter populates), `ParseHelpers.fs` (parser-side helpers), `SyntaxTree.fs` (AST built from the filtered token stream), `SyntaxTrivia.fs` (trivia types emitted into the tree).

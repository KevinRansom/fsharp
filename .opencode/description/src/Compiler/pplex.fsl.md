# pplex.fsl — Preprocessor Conditional-Expression Lexer

**Purpose**: The companion lexer for `pppars.fsy`, generated as module
`FSharp.Compiler.PPLexer`. It produces the tiny token stream of a preprocessor
conditional-compilation expression (the text after `#if`/`#elif`) — identifiers,
`!`, `&&`, `||`, `(`, `)` — so the paired `PPParser` can evaluate `#if DEBUG &&
!FEATURE || OTHER`-style conditions at **lexing** time, without needing to parse F#
source. It is invoked from the main lexer (`lex.fsl`) via its `evalIfDefExpression`
helper (lex.fsl:204-210), or directly by other tooling that only needs to evaluate
`#if` conditions.

The build flags (in `FSharp.Compiler.Service.fsproj`, around line 270) generate
this file as `<module> FSharp.Compiler.PPLexer`, opened with
`FSharp.Compiler.ParseHelpers`, `FSharp.Compiler.LexerStore`, and using the
Unicode flexlib `Internal.Utilities.Text.Lexing`.

## Header / helper functions (the `{ ... }` F# block, lines 3-13)

- `open FSharp.Compiler.DiagnosticsLogger`; `open FSharp.Compiler.ParseHelpers`.
- **`lexeme lexbuf`** — thin wrapper over `UnicodeLexing.Lexbuf.LexemeString lexbuf`
  to fetch the current lexeme's text.
- **`fail (args: LexArgs) lexbuf e`** (lines 9-12) — the single error-reporting
  helper: reports a diagnostic via
  `args.diagnosticsLogger.ErrorR(Error(e, m))` where `m = lexbuf.LexemeRange`,
  **and then returns `PPParser.EOF`** so the parser can still reach end-of-input
  (or its `Recover` recovery rule) rather than the lexer crashing. This is the
  only way this lexer signals "I saw something invalid."

## Character classes (lines 15-35)

- `letter`, `digit`, `connecting_char` (`\Pc`), `combining_char` (`\Mn`/`\Mc`),
  `formatting_char` (`\Cf`) — Unicode categories for identifiers.
- **`ident_start_char`** — `letter | '_'`.
- **`ident_char`** — `letter | connecting_char | combining_char | formatting_char |
  digit | "'"` (allows `'` inside identifiers, the F# convention).
- **`ident`** — `ident_start_char ident_char*`.
- **`comment`** — `"//" _*` (a single-line comment to end-of-line).
- **`mcomment`** — `"(*" _*` (a block comment; in this context it is *not* valid
  and is a lexer error).
- **`whitespace`** — `[' ' '\t']`.

## The single rule: `rule tokenstream (args: LexArgs)` (lines 37-58)

This is the entire lexer; there is exactly one rule and one auxiliary rule:

- **`| "#if"` → `PPParser.PRELUDE`** (line 39) and **`| "#elif"` → `PPParser.PRELUDE`**
  (line 40) — the two "prelude" keywords that open a `#if` or `#elif` branch. Both
  produce the same `PRELUDE` token; the parser's `Full` production (`PRELUDE Expr EOF`)
  consumes it.
- **`| ident → PPParser.ID(lexeme lexbuf)`** (line 41) — any identifier becomes an
  `ID` token carrying the identifier text (e.g. `DEBUG`, `FEATURE_X`).
- **`| "!" → OP_NOT`**, **`| "&&" → OP_AND`**, **`| "||" → OP_OR`** (lines 43-45).
- **`| "(" → LPAREN`**, **`| ")" → RPAREN`** (lines 46-47).
- **`| whitespace → tokenstream args lexbuf`** (line 49) — skip spaces/tabs.
- **`| comment → PPParser.EOF`** (line 51) — a single-line comment to end-of-line
  is treated as end-of-input for the expression. This allows a trailing `// …`
  comment after a `#if` line to be ignored.
- **`| mcomment → fail args lexbuf (FSComp.SR.pplexExpectedSingleLineComment())`**
  (line 52) — a `(* … *)` block comment in a `#if` expression is not allowed; reports
  an `ExpectedSingleLineComment` diagnostic and falls back to `EOF`.
- **`| _ →` (lines 53-57)** — any other character that does not match above
  triggers the generic `fail`: it calls `lexeme lexbuf`, then a `rest lexbuf`
  sub-rule (to consume the character(s), lines 60-62) and reports
  `FSComp.SR.pplexUnexpectedChar(lex)`. This is the default "unexpected char" path.
- **`| eof → PPParser.EOF`** (line 58) — end of the line's text.

## Auxiliary rule: `and rest = parse` (lines 60-62)

```
and rest = parse
| _         { rest lexbuf   }
| eof       { PPParser.EOF  }
```

A simple "eat one character and keep going" helper whose only purpose is to advance
past the offending character in the generic `| _ → fail …` branch so the reported
range is consistent and the lexer does not get stuck on the same character.

## Key rules / logic

- **Single-purpose**: this lexer only recognizes the boolean-expression token subset
  of F# that can appear in a `#if`/`#elif` condition (identifiers, `!`, `&&`, `||`,
  `(`, `)`, `#if`, `#elif`). It is *not* a full F# lexer — it is a tiny companion
  to `pppars.fsy` used for conditional-compilation evaluation.
- **Error handling**: every failure path funnels through `fail` (lines 9-12), which
  emits a diagnostic and returns `PPParser.EOF`. This is the only way this lexer
  signals "I saw something invalid"; after that, the parser's `Recover` production
  (pppars.fsy:40-41) takes over and reports a parser-level diagnostic if needed.
- **Comment handling**: a trailing `//` single-line comment is silently swallowed
  (produces `EOF`), but a `(* … *)` block comment in the expression is a hard error
  (with a specific `pplexExpectedSingleLineComment` message) because a block comment
  in a `#if` condition is almost always a user mistake.

## Cross-references

- **`pppars.fsy`** — the companion parser. It declares the tokens this lexer emits
  (`PRELUDE`, `ID`, `OP_NOT`, `OP_AND`, `OP_OR`, `LPAREN`, `RPAREN`, `EOF`) and
  builds the `LexerIfdefExpression` from them. See `pppars.fsy.md`.
- **`lex.fsl`** — the main F# lexer. Its `evalIfDefExpression` helper (lex.fsl:204-210)
  runs the flow:
  ```fsharp
  let lexbuf    = LexBuffer<char>.FromChars (…, lexed.ToCharArray ())
  let tokenStream = FSharp.Compiler.PPLexer.tokenstream args   // THIS lexer
  let expr          = FSharp.Compiler.PPParser.start tokenStream lexbuf
  (LexerIfdefEval lookup expr), expr
  ```
  to decide whether the current `#if`/`#elif` branch is active, using the
  `conditionalDefines` set. See `lex.fsl.md`.
- **`pars.fsy`** — the full F# parser (the real "pppars" in spirit). This file is a
  much smaller, self-contained grammar whose output feeds only
  `LexerIfdefEval`, not the `SyntaxTree`.

# lex.fsl — Main F# Source Lexer

**Purpose**: The primary lexer of the F# compiler, implemented as a FlexLexer (.fsl)
specification. It converts raw F# source text into the stream of typed tokens (the token
algebra declared in `pars.fsy`) consumed by the PARS-based parser and, ultimately, the
type checker. It is also reused in "partial lexing" mode by Visual Studio tooling
(`skip = false`): in that mode it emits artificial `WHITESPACE`, `COMMENT`, `LINE_COMMENT`
and `STRING_TEXT` tokens instead of skipping them, preserving trivia for display and
IntelliSense. The file is compiled to the `FSharp.Compiler.Lexer` module
(flexlib is `Internal.Utilities.Text.Lexing`).

## Header / helper functions (the `{ ... }` F# block, lines 3-218)

- `Ranges` — helpers to detect "bad max" integer literals (`128y`, `32768s`, `2147483648`,
  `9223372036854775808`) that are accepted so they can be parsed as their signed `MinValue`
  (the `-` is lexed as an operator).
- `lexeme`, `lexemeTrimBoth/Right/Left` — extract the lexeme string, optionally trimming
  suffix prefix characters (type tags, quotes).
- `fail args lexbuf msg dflt` — reports a lexer error via
  `args.diagnosticsLogger.ErrorR(Error(msg, m))` and returns a default token.
- Integer parsing (`parseInt32`, `parseBinaryUInt64`, `parseOctalUInt64`,
  `lexemeTrimRightToInt32`) — optimized parsing used in bootstrap; handles `0x`/`0o`/`0b`
  prefixes and `_` separators.
- `checkExprOp` / `checkExprGreaterColonOp` — deprecation errors when `:` or `$` appear in
  operator names (F# no longer allows these in operators).
- `startString` (lines 123-178) — sets up the string buffer and a `LexerStringFinisher`
  that, at string end, emits one of the string tokens: `BYTEARRAY`, `STRING`,
  `INTERP_STRING_BEGIN_PART`, `INTERP_STRING_BEGIN_END`, `INTERP_STRING_PART`,
  `INTERP_STRING_END`, choosing `SynStringKind` Regular/Verbatim/TripleQuote and validating
  byte strings (non-ASCII, interpolation forbidden).
- `trySaveXmlDoc` / `tryAppendXmlDoc` — accumulate `///` XML doc comment lines into
  `XmlDocStore` for later attachment to declarations.
- `shouldStartLine` / `shouldStartFile` — validate that `#if`, `#else`, `#warn` etc. start
  at column 0, and that shebangs start the file.
- `evalIfDefExpression` (lines 204-210) — evaluates `#if`/`#elif` expressions by lexing the
  expression with the **preprocessor lexer/parser** (`FSharp.Compiler.PPLexer.tokenstream` +
  `FSharp.Compiler.PPParser.start`) and reducing it with `LexerIfdefEval`. This is the main
  cross-reference point to `pplex.fsl`/`pppars.fsy`.
- `evalFloat` — parses float literals with error recovery.

## Character classes and regexes (lines 220-337)

`letter`, `digit`, `hex`, `truewhite`/`offwhite` (tab is an explicit error), `anywhite`,
`op_char`, `separator` (`_`), integer literals with scale tags — `int8` (`…y`), `int16`
(`…s`), `int`/`int32` (`…l`), `int64` (`…L`), unsigned forms (`uy`,`us`,`u`,`ul`),
`nativeint` (`…n`), `unativeint` (`…N`) — each in decimal or `xinteger` (hex/octal/binary)
flavour; `bignum` (`…I`/`…N`/`…Z`/`…Q`/`…R`/`…G`); `ieee32` (`f`/`F`), `ieee64`; `decimal`
(`m`/`M`); `char` with escapes; `trigraph`; `hexGraphShort` `\xHH`; `unicodeGraphShort`
`\uHHHH`; `unicodeGraphLong` `\UHHHHHHHH`; `newline`; `ident` (Unicode identifier rules).

## Main rule: `rule token (args: LexArgs) (skip: bool)` (line 338)

The entry point, parameterized by `LexArgs` (diagnostics logger, `skip` flag, ifdef stack,
string nesting) and `skip`:

- **Identifiers/keywords**: `ident` is routed through
  `Keywords.KeywordOrIdentifierToken` (defined in `SyntaxTree/LexHelpers.fs`), which maps
  known F# keywords (`abstract`, `and`, `as`, …) to their token constructors or emits `IDENT`.
  `ident '!'` produces a `BINDER` (a `let!`-style binder, `let!` → BINDER).
- **Async/computation-expression keywords**: `do!` → DO_BANG, `yield!` → YIELD_BANG(true),
  `return!` → YIELD_BANG(false), `match!` → MATCH_BANG, `and!` → AND_BANG(false),
  `while!` → WHILE_BANG.
- **Integer literals**: each integer pattern (INT8/INT16/INT32/UINT32/INT64/UINT64/
  NATIVEINT/UNATIVEINT) checks range via `Ranges.isInt*BadMax` and `fail`s with a
  specific `FSComp.SR.lexOutside*Range` error on overflow. `int '.' '.'` yields
  `INT32_DOT_DOT` (for the special `1..N` pattern form).
- **Floats & bigints**: `ieee64` → IEEE64, `ieee32` → IEEE32, `bignum` → BIGNUM,
  `decimal` → DECIMAL.
- **Chars**: plain char, trigraph, `\x` short, `\u`/`\U` long forms (with the `B` byte-char
  affix for byte literals).
- **Strings** (lines 595-699): `"`, `@` (verbatim `@"`), `$` (interpolated `$"`),
  `$$+"""` (triple-quoted `"""` and extended `$$"""`, `$$$"""` interpolation), `@$`/`$@`
  (verbatim-interpolated `@"$"`). Each checks the current `stringNest` for invalid nesting
  (single quote inside single quote, triple inside triple) and starts the corresponding
  string rule (`singleQuoteString`, `verbatimString`, `tripleQuoteString`,
  `extendedInterpolatedString`).
- **Whitespace**: `truewhite+` → skip or emit `WHITESPACE`; `offwhite+` (tab) →
  `errorR(...lexTabsNotAllowed())`.
- **Comments**: `//// op_char*` → `LINE_COMMENT`; `///` → `LINE_COMMENT` with XML-doc
  accumulation (and an informational warning `xmlDocNotFirstOnLine` if not at line start);
  `//` → `LINE_COMMENT`; `(*` → nested `comment` rule that tracks nesting depth.
- **Hash identifiers**: `#id` → HASH_IDENT (generic constraints on union fields, etc.).
- **`#line` directive** (lines 763-817): parses `N @"file"` to adjust the line number for
  error reporting (used when compiling preprocessed output); stored via
  `LineDirectiveStore.SaveLineDirective`.
- **Quote tokens**: `<@` / `@>` (LQUOTE/RQUOTE), `<@@`/`@@>` and the `>}`/`.">/`|}`
  variants for `@`-quoted F# interactive code blocks.
- **Punctuation / operators**: `#` (HASH), `&`/`&&` (AMP/AMP_AMP), `||` (BAR_BAR),
  `(`,`)`,`*`,`,`,`->` (RARROW), `?`,`??`,`..`,`..^`,`...`,`.`,`:`,`::`,`:>`,`?:`,`:=`,
  `;;`,`;`,`<-` (LARROW),`=`,`[`,`[|`,`{|`,`<`,`>`,`>]`,`[<`,`]`,`|]`,`|}`.
  `<`/`>` carry a `bool` that indicates whether the tokens are part of a type application
  (detected by the LexFilter).
- **`{` / `}`** (lines 911-964): braces are stateful — inside an interpolated string the
  lexer tracks a `stringNest` counter: `{` at the outer level of a `{…}` hole increments a
  depth counter and emits `LBRACE cont`; the matching `}` decrements it or (at depth 1)
  resumes `startString` to continue the literal (emitting an
  `InterpolatedStringPart` string token). This is how `{expr}` holes inside `$"…"`,
  `$@"…"` and `$$"""…"""` are lexed correctly.
- **Operator names** (lines 978-1006): any run of `op_char`s (optionally prefixed by
  `ignored_op_char` `.`/`$`/`?`) is classified into the operator token family
  `INFIX_STAR_STAR_OP` (`**`), `INFIX_STAR_DIV_MOD_OP` (`*`,`/`,`%`), `PLUS_MINUS_OP`
  (`+`,`-`), `INFIX_AT_HAT_OP` (`@`,`^`), `INFIX_COMPARE_OP` (`=`,`!=`,`<`,`$`,`>`),
  `INFIX_AMP_OP` (`&`), `INFIX_BAR_OP` (`|`), `PREFIX_OP` (`!`,`~`). Each call
  `checkExprOp`/`checkExprGreaterColonOp` to enforce the `:`/`$` ban.
  - Special case (lines 991-996): `=` immediately followed by the opener of an interpolated
    string (`$"`, `$…"…"""` forms) lexes only the `=` and rewinds, so that the next scan
    re-enters the normal interpolated-string lexer (fixes issue #16696).
- **Funky member-access operators** (lines 1008-1010): `.[]`, `.[]<-`, `.[,]<-`, `.[,,"]<-`
  etc. as `FUNKY_OPERATOR_NAME` (for array/list/record member access syntax).
- **`#!` shebang** (lines 1012-1017): treated as a single-line comment, `shouldStartFile`
  forces it to appear only at the very start of the file.
- **`#light`/`#indent`** (lines 1019-1028): `#light`/`#indent "on"` toggles the
  OBLOCKSEP/#light offside-rule token stream; `#light "off"`/`#indent "off"` is
  deprecated with `mlCompatLightOffNoLongerSupported`.
- **Preprocessor `#if` / `#else` / `#elif` / `#endif`** (lines 1030-1088): each pushes a
  state onto `args.ifdefStack`, evaluates the condition via `evalIfDefExpression` (which
  invokes `PPLexer`/`PPParser`), and either continues with `LexerEndlineContinuation.Token`
  (branch taken) or enters `ifdefSkip` state (branch skipped). All are stored in
  `IfdefStore` for the IDE.
- **`#warn`/`#nowarn`** (lines 1104-1109): registers a warning scope via
  `WarnScopes.ParseAndRegisterWarnDirective`.
- **`_` / `eof`**: unmatched characters → `LEX_FAILURE` via `unexpectedChar`; `eof` →
  `EOF` token.

## Sub-rules (the `and …` rules)

- `ifdefSkip` (line 1121): consumes skipped branches of `#if/#else/#elif` at a given depth
  `n`, emitting `INACTIVECODE` tokens.
- `endline` (line 1247): consumes the rest of the current line after a `#if`-family
  directive and dispatches to the continuation in `LexCont.EndLine`.
- `singleQuoteString` (line 1275): lexes `"…"` string content, handling line continuation
  (`\` + newline), escape chars, `\d{3}` trigraphs, `\xHH`, `\uHHHH`, `\UHHHHHHHH`, and
  the `{...}` interpolation holes; ends by invoking the `LexerStringFinisher` (see
  `startString`).
- `verbatimString` (line 1453): `"@\"…\""` lexing with `""` as the escape for a literal
  quote.
- `tripleQuoteString` (line 1560): `"\"\"\"…\"\"\""` raw string lexing (no escapes).
- `extendedInterpolatedString` (line 1660): the `$$"…"`, `$$$"…"` extended interpolation
  form where `$`/`$$`/… delimiters and `}}`/`}}}` closing-brace runs must be handled.
- `singleLineComment` (line 1782): continues a `//` comment to the line end.
- `comment` (line 1814): nested `(* … *)` block comments that track a depth counter.
- `stringInComment`, `verbatimStringInComment`, `tripleQuoteStringInComment` (lines
  1879/1916/1946): handle strings that appear inside comments so that the comment state
  machine terminates correctly when a line of the comment ends.

## Token stream / continuations

Many token actions return the token **along with a `ParseHelpers.LexerContinuation`** value
(`LexCont.Token`, `LexCont.String`, `LexCont.Comment`, `LexCont.EndLine`,
`LexCont.IfDefSkip`, `LexCont.SingleLineComment`), not a bare token. The PARS parser
(pars.fsy) threads this continuation back into the lexer by setting
`lexbuf.Lexer` — this is how the lexer "resumes" in the right state (inside a string,
inside a comment, inside an interpolated hole, inside a skipped `#if` branch) after the
parser has consumed the intervening tokens. In `skip=false` mode (VS) the same mechanism
drives the artificial trivia tokens.

## Cross-references

- **Token algebra**: every token constructor emitted here (`IDENT`, `INT32`, `STRING`,
  `BYTEARRAY`, `INTERP_STRING_*`, `HIDE_KEYWORD`, `LBRACE`, `RBRACE`, `HASH_IF`,
  `HASH_ELSE`, `WARN_DIRECTIVE`, `WHITESPACE`, `STRING_TEXT`, `INACTIVECODE`, `EOF`,
  …) is declared in `pars.fsy` as `%token` or `%nonassoc` lines.
- **`pplex.fsl` / `pppars.fsy`**: `evalIfDefExpression` (lines 204-210) builds a
  `PPLexer.tokenstream` from the `#if`/`#elif` expression text and passes it to
  `FSharp.Compiler.PPParser.start`, so the small PP lexer + parser are used as a helper
  inside the main lexing pipeline. See the companion descriptions for those files.
- **`parse_state` / `parseState.LexBuffer`** used in `pars.fsy` are the lexer state; the
  `LexArgs` here (`diagnosticsLogger`, `stringNest`, `ifdefStack`, `conditionalDefines`,
  `interpolationDelimiterLength`) is the persistent state the lexer threads through all
  rules.
- **`LexHelpers.fs` (`SyntaxTree/LexHelpers.fs`)**: hosts `LexerStringFinisher`,
  `LexerContinuation`, `startString`'s finisher callback, `Keywords.KeywordOrIdentifierToken`,
  and the `addByteChar`/`addUnicodeChar` buffer helpers all used by this file.

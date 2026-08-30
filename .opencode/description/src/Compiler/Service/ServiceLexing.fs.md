# ServiceLexing.fs

Full implementation of the FSharp.Compiler.Service tokenizer surface: legacy line-based "Babel" token layout service plus the modern experimental whole-file lexer.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. The main consumers:
1. **Incremental colorization**: `FSharpSourceTokenizer.CreateLineTokenizer lineText` → `FSharpLineTokenizer.ScanToken`. Caches one packed `FSharpTokenizerLexState` per line. `ScanToken` runs the real compiler lexer (in `BuildPhase.Parse`, discarding diagnostics via `UseDiagnosticsLogger DiscardErrorsLogger`) over the line and returns `FSharpTokenInfo` (columns, `FSharpTokenColorKind`/`FSharpTokenCharKind`/`FSharpTokenTriggerClass`, tag, name, full matched length) plus the next state.
2. **Whole-file analysis**: `FSharpLexer.Tokenize` streams `FSharpToken`s (with ranges and `FSharpTokenKind`) over an `ISourceText`, optionally running through `LexFilter`.

## Namespaces / opens

- `FSharp.Compiler.Tokenization` with `open System`, `System.Collections.Generic`, `System.Threading`, `FSharp.Compiler.IO`, `Internal.Utilities(.Library(.Extras))`, `FSharp.Compiler`, `FSharp.Compiler.Diagnostics`, `DiagnosticsLogger`, `Features`, `Lexhelp`, `Parser`, `ParseHelpers`, `Syntax`, `Text`, `Text.Position`, `Text.Range`.

## Module `FSharpTokenTag`

Public module of precomputed integer token tags (`tagOfToken <sample token>`): `Identifier`/`IDENT`, `String`/`STRING`, the four interpolated-string tags, brackets/braces/parens incl. attribute/baket `LBRACK_LESS`/`GREATER_RBRACK`, array `LBRACK_BAR`/`BAR_RBRACK`, operator families, `WHITESPACE`, `COMMENT`, `LINE_COMMENT`, and the keywords `BEGIN/DO/FUNCTION/THEN/ELSE/STRUCT/CLASS/TRY/WITH/OWITH/NEW`.

## Token classification enums

- `FSharpTokenColorKind` — `Default/Text, Keyword, Comment, Identifier, String, UpperIdentifier, InactiveCode, PreprocessorKeyword, Number, Operator, Punctuation`.
- `FSharpTokenTriggerClass` — `None, MemberSelect, MatchBraces, ChoiceSelect, MethodTip(ParamStart|ParamNext|ParamEnd)`.
- `FSharpTokenCharKind` — `Default/Text, Keyword, Identifier, String, Literal, Operator, Delimiter, WhiteSpace, LineComment, Comment`.
- `FSharpTokenInfo` record — columns, classes, tag, name, `FullMatchedLength`.

## Module `TokenClassifications` (internal)

- `tokenInfo token : FSharpTokenColorKind * FSharpTokenCharKind * FSharpTokenTriggerClass` — the big per-token match:
  - Uppercase-first identifiers → `UpperIdentifier`; else `Identifier`.
  - Numeric literals (`DECIMAL/BIGNUM/INT*/UINT*/IEEE*/NATIVEINT`) → `Number`/`Literal`; `INT32_DOT_DOT` → number-colored operator (bug 3727 known-fudge).
  - `INFIX_STAR_DIV_MOD_OP "mod"` → keyword.
  - Operators (`.`-leading families incl. `FUNKY_OPERATOR_NAME`, `ADJACENT_PREFIX_OP`, ...) → `Operator`; ranges `DOT_DOT_*` add `MemberSelect` trigger.
  - `COMMA` → `Punctuation`+`ParamNext`; `DOT` → `Punctuation`+`MemberSelect`; `LESS`→`ParamStart`, `GREATER`→`ParamEnd` (type-provider static args); parens/brackets/braces → `MatchBraces` (+`ParamStart`/`ParamEnd` for parens).
  - Most keywords incl. offside keywords (`O*`) → `Keyword`.
  - Preprocessor directives → `PreprocessorKeyword`; `INACTIVECODE` → `InactiveCode`; whitespace/failure → `Default`; `COMMENT`/`LINE_COMMENT`; `STRING_TEXT`/interpolated/`STRING`/`BYTEARRAY`/`CHAR` → `String`; `EOF` → `failwith "tokenInfo"`.

## Module `TestExpose` (internal)

- `TokenInfo tok = TokenClassifications.tokenInfo tok`.

## `FSharpTokenizerLexState` (`[<Struct; CustomEquality; NoComparison>]`)

`{ PosBits; OtherBits }` with `Initial = {0L; 0L}`, structural `Equals`, `Equals(obj)` override, `GetHashCode = hash PosBits + hash OtherBits`.

## `FSharpTokenizerColorState` (enum)

`Token/IfDefSkip/String/Comment/StringInComment/VerbatimStringInComment/VerbatimString/SingleLineComment/EndLineThenSkip/EndLineThenToken/TripleQuoteString/TripleQuoteStringInComment/InitialState` **plus** `.fs`-specific `ExtendedInterpolatedString = 15` (not in the .fsi enum list).

## Module `LexerStateEncoding` (internal)

Bit-packed continuation encoding fit into 64 bits (mask layout documented via bit-range constants and a 64-bit `assert`):
- Fields: `lexstateNumBits=4`, `ncommentsNumBits=4`, `ifdefstackCountNumBits=8`, `ifdefstackNumBits=24` (2 bits/entry: `00`=if, `01`=else, `10`=elif), `stringKindBits=3`, `nestingBits=12`, `delimLenBits=3`.
- `computeNextLexState token prevLexcont` — tokens carrying a `LexerContinuation` (`HASH_*`, `INACTIVECODE`, whitespace/comment, string family incl. interpolated, `LBRACE`/`RBRACE`, `BYTEARRAY`) propagate `cont`; others keep the previous continuation.
- `revertToDefaultLexCont = LexCont.Default` (discards ifdef stack too — documented lossy).
- `colorStateOfLexState`, `lexStateOfColorState`, `encodeStringStyle`/`decodeStringStyle` (SingleQuote/Verbatim/TripleQuote/ExtendedInterpolated).
- `encodeLexCont (colorState, numComments, pos, ifdefStack, stringKind, stringNest, delimLen)` — packs ifdef entries (bit per pair), string-kind flags (`IsByteString/IsInterpolated/IsInterpolatedFirst`), up to two levels of interpolation nesting (`tag1/tag2`, index 0..7, style 0..3), and clamped delim length into `OtherBits`; `PosBits = pos.Encoding`.
- `decodeLexCont state` — reverses into `(colorState, ncomments, pos, ifDefs, stringKind, stringNest, delimLen)`.
- `encodeLexInt lexcont` / `decodeLexInt state` — maps `LexerContinuation` (`LexCont.Token/IfDefSkip/EndLine/String(style,kind,delimLen)/Comment/SingleLineComment/StringInComment`) to/from `FSharpTokenizerColorState` (+n, +pos); `EndLine` distinguishes `LexerEndlineContinuation.IfdefSkip` vs `Token`.

## `SingleLineTokenState`

`BeforeHash = 0 | NoFurtherMatchPossible = 1` — tracks whether a `#` directive/meta-command is still possible on the current line.

## `FSharpLineTokenizer` (sealed)

Backed by `UnicodeLexing.Lexbuf`, `maxLength`, `fileName`, `lexargs`.
- `fsx = ParseAndCheckInputs.IsScript fileName` — decides whether `#`-meta-commands apply.
- Directive post-processing (the lexer returns a whole `   #if IDENT // …` as one token; VS needs pieces): `processDirective` (splits leading whitespace, then `HASH_IF`), `processWhiteAndComment` (`//` comments), `processDirectiveLine`, `processHashEndElse` (`#else`/`#endif` lines), `processHashIfLine` (`#if IDENT`), `processWarnDirective` (`#nowarn`).
- `callLexCont lexcont skip` — installs `lexargs.ifdefStack`/`stringNest`/`interpolationDelimiterLength` from the continuation and invokes the right `Lexer.*` entry point (`endline`, `token`, `ifdefSkip`, `singleQuoteString`/`verbatimString`/`tripleQuoteString`/`extendedInterpolatedString`, `comment`, `singleLineComment`, `stringInComment`, `verbatimStringInComment`, `tripleQuoteStringInComment`).
- `columnsOfCurrentToken` — StartPos/EndPos columns (right column clamped to `maxLength` when the token spans lines).
- `getTokenWithPosition lexcont` — pops the `tokenStack` if non-empty; otherwise runs the lexer, then postsplits tokens for colorization:
  - `HASH_IF/ELIF/ELSE/ENDIF` with inline trailing text → `processHash*Line/EndElse`.
  - `WARN_DIRECTIVE` → `processWarnDirective`.
  - `HASH_IDENT` → delay `IDENT` after `#` (`HASH` + ident).
  - `RQUOTE_DOT(s, raw)` → `RQUOTE` + delayed `DOT` (so `x."member"` gets completion on the dot).
  - `INFIX_COMPARE_OP` with `LexFilter.TyparsCloseOp(greaters, afterOp)` → split the type-arg-closing run into individual `GREATER`s (`greaters[i]false`) + optional `afterOp`, mirroring LexFilter behavior but for pure colorization.
  - Any `.`-leading operator (`INFIX_STAR_STAR_OP`/`PLUS_MINUS_OP`/`INFIX_COMPARE_OP`/`INFIX_AT_HAT_OP`/`INFIX_BAR_OP`/`PREFIX_OP`/`INFIX_STAR_DIV_MOD_OP`/`INFIX_AMP_OP`/`ADJACENT_PREFIX_OP`/`FUNKY_OPERATOR_NAME`) → delay the operator-without-dot, return `DOT` first (auto-popup-completion).
  - Faults caught → `(EOF revertToDefaultLexCont, 0, 0)`.
- `ScanToken(lexState)`:
  - `UseBuildPhase Parse` + `DiscardErrorsLogger`.
  - `decodeLexInt` → continuation; `getTokenWithPosition`.
  - `EOF`/`LEX_FAILURE` → `None`; else categorize via `TokenClassifications.tokenInfo`, compute final continuation (`computeNextLexState`, or keep previous when the token came from the cache), tag, name (`token_to_string`), and `FullMatchedLength`.
  - `#`-meta-command merging: when state is `BeforeHash`, the token is the `#`, and the following token is an `IDENT` matching one of the script directives (`r/reference/I/load/time/dbgbreak/cd/…/help`), the two are merged into one `FSharpTokenInfo` (`RightColumn = rightc`, color `PreprocessorKeyword`, char `Keyword`). Leading whitespace before `#` keeps `BeforeHash` alive; anything else flips to `NoFurtherMatchPossible`.
- `static member ColorStateOfLexState` / `LexStateOfColorState` — (de)compose the color state only.

## `FSharpSourceTokenizer` (sealed)

- Constructor `(conditionalDefines, fileName, langVersion)` — builds `langVersion` (default `LanguageVersion.Default`), `LexResourceManager()`, `mkLexargs` (with `DiscardErrorsLogger`, empty path map, `applyLineDirectives=false`).
- `CreateLineTokenizer lineText` → `StringAsLexbuf` + `FSharpLineTokenizer(lexbuf, Some lineText.Length, fileName, lexargs)`.
- `CreateBufferTokenizer bufferFiller` → `FunctionAsLexbuf` + `FSharpLineTokenizer(lexbuf, None, fileName, lexargs)`.

## Module `FSharpKeywords`

- `NormalizeIdentifierBackticks` → `PrettyNaming.NormalizeIdentifierBackticks`.
- `KeywordsWithDescription` → `PrettyNaming.keywordsWithDescription`.
- `KeywordsDescriptionLookup` — internal `dict`-backed lookup.
- `KeywordNames` → `Keywords.keywordNames`.

## `FSharpLexerFlags` / `FSharpTokenKind` / `FSharpToken` / `FSharpLexerImpl` / `FSharpLexer`

- `FSharpLexerFlags` (`[<Flags>]`) — `Default=0x11011`, `Compiling=0x10`, `CompilingFSharpCore=0x110`, `SkipTrivia=0x1000`, `UseLexFilter=0x10000`.
- `FSharpTokenKind` — the normalized union; `.fs` matches the `.fsi` (with small differences: `.fs` uses `RQUOTE_BAR_RBRACE` etc.; its `UInt64` case maps `INT64`/`UINT64` and `Int64` vs `UInt64` differ from `.fsi` naming).
- `FSharpToken` (`[<Struct; NoComparison; NoEquality>]`):
  - private `tok: token`, `tokRange: range`; constructor `(tok, tokRange)`.
  - `Range`, and `Kind` (big match → `FSharpTokenKind`, fallback `None`).
  - `IsKeyword` — large list of keyword/offside/reserved kinds (offside `O*` kinds included, `InfixMod`/`Sig`/`KeywordString`/`Binder`).
  - `IsIdentifier`, `IsStringLiteral`, `IsNumericLiteral` (integer/float/bigint kinds), `IsCommentTrivia` (`CommentTrivia`|`LineCommentTrivia`).
- Module `FSharpLexerImpl` (`[<AutoOpen>]`):
  - `lexWithDiagnosticsLogger text conditionalDefines flags reportLibraryOnlyFeatures langVersion diagnosticsLogger onToken pathMap ct` — builds the lexbuf (`SourceTextAsLexbuf`), `lexargs` (with `LexResourceManager(0)`), optionally wraps `Lexer.token` in `LexFilter.LexFilter(isCompilingFSharpCore, lexer, lexbuf, false)` when `UseLexFilter`; `resetLexbufPos "" lexbuf`; loops `while not lexbuf.IsPastEndOfStream`, reporting each token with `onToken (getNextToken lexbuf) lexbuf.LexemeRange`; honors `ct.ThrowIfCancellationRequested()`.
  - `lex …` — uses `CompilationDiagnosticLogger("Lexer", FSharpDiagnosticOptions.Default)`.
- `FSharpLexer` (`[<AbstractClass; Sealed>]`):
  - `static Tokenize(text, tokenCallback, ?langVersion="latestmajor", ?filePath, ?conditionalDefines=[] , ?flags=Default, ?pathMap, ?ct)` — folds the path map into `PathMap`, wraps tokens into `FSharpToken`, suppresses `FSharpTokenKind.None` from the callback, then runs `lex`.

## Notes

- The legacy API keeps per-line state packed into 64 bits to respect IDE memory constraints; it is intentionally lossy (no deep `#if`/interpolation context, no accurate mismatched-`#if` diagnostics).
- `ScanToken` deliberately discards lexer diagnostics and runs in the Parse build phase so it never interferes with user diagnostics.
# ServiceLexing

**Purpose:** The service's tokenization pipeline. Wraps the compiler's core lexer (OCaml-based parser/lexing via `UnicodeLexing` + `Lexhelp`) into a line-oriented, state-carrying tokenizer (`FSharpLineTokenizer`) for IDE syntax colorization (legacy API), plus a newer callback-driven, line-independent `FSharpLexer` built on the F#-implemented token stream (`Parser.token`, `FSharpTokenKind`, `FSharpToken`) that honors the `LexFilter` (`#if`/`#else`/`#endif`, inactive code) semantics. Exposes the `GetLexingResults` building blocks used by language services.

**Namespace(s):** `FSharp.Compiler.Tokenization`

## Declared types / modules
- `FSharpTokenTag` (module): integer tag constants for tokens (ID `IDENT`/`Identifier`, `String`, interpolated-string parts, delimiters like `LPAREN`/`LBRACE`, operators, keyword tags, `COMMENT`/`LINE_COMMENT`, etc.).
- `FSharpTokenColorKind` (enum union): color classes — `Keyword`, `Identifier`, `String`, `UpperIdentifier`, `Number`, `Operator`, `Punctuation`, `Comment`, `InactiveCode`, `PreprocessorKeyword`, `Text/Default`.
- `FSharpTokenTriggerClass` (flags-style union): editor actions on token — `MemberSelect`, `MatchBraces`, `ChoiceSelect`, and param-info bits `ParamStart`/`ParamNext`/`ParamEnd`/`MethodTip`.
- `FSharpTokenCharKind` (flags): per-character classes (`Keyword`, `Identifier`, `String`, `Literal`, `Operator`, `Delimiter`, `WhiteSpace`, `LineComment`, `Comment`).
- `FSharpTokenInfo` (record): one token's output — `LeftColumn`, `RightColumn`, `ColorClass`, `CharClass`, `FSharpTokenTriggerClass`, `Tag`, `TokenName`, `FullMatchedLength`.
- `TokenClassifications` (internal module): mapping from `Parser.token` to (color, char, trigger) classes — the core classification table.
- `TestExpose` (internal module): exposes `TokenInfo : Parser.token -> FSharpTokenColorKind * FSharpTokenCharKind * FSharpTokenTriggerClass` for tests.
- `FSharpTokenizerLexState` (struct, CustomEquality): encoded end-of-line lexing state (two `int64` bit fields, `PosBits`/`OtherBits`); static `Initial`; used to continue lexing on subsequent lines.
- `FSharpTokenizerColorState` (enum): stable line state — `Token`, `IfDefSkip`, `String`, `Comment`, `StringInComment`, `VerbatimString`, `SingleLineComment`, `EndLineThenSkip`, `EndLineThenToken`, `TripleQuoteString`, `TripleQuoteStringInComment`, `InitialState`.
- `LexerStateEncoding` (internal module): encodes/decodes the lexer state to/from the two `int64` fields of `FSharpTokenizerLexState`.
- `SingleLineTokenState` (internal type): per-line state for the classic line tokenizer.
- `FSharpLineTokenizer` (sealed class): tokenizes one line with `ScanToken lexState -> (FSharpTokenInfo option * FSharpTokenizerLexState)`; statics `ColorStateOfLexState` and `LexStateOfColorState` (the latter noted as possibly inaccurate since it ignores in-file `#if`/interpolation context).
- `FSharpSourceTokenizer` (sealed class): file-scoped tokenizer; `CreateLineTokenizer lineText` and `CreateBufferTokenizer bufferFiller` (for lazy buffer access).
- `FSharpKeywords` (module): `NormalizeIdentifierBackticks`, `KeywordsWithDescription`, `KeywordNames`, internal `KeywordsDescriptionLookup`.
- `FSharpLexerFlags` (flags, experimental): `Default`, `Compiling`, `CompilingFSharpCore`, `SkipTrivia`, `UseLexFilter`.
- `FSharpTokenKind` (large enum union, experimental): one case per token type — hash directives, offside tokens, keywords, operators, literals, `Identifier`, `String`, `ByteArray`, `FunkyOperatorName`, etc.
- `FSharpToken` (struct, experimental): wraps a `Parser.token` + range; properties `Kind`, `IsIdentifier`, `IsKeyword`, `IsStringLiteral`, `IsNumericLiteral`, `IsCommentTrivia`.
- `FSharpLexer` (sealed/abstract, experimental): static `Tokenize : text * tokenCallback * ?langVersion * ?filePath * ?conditionalDefines * ?flags * ?pathMap * ?ct -> unit` — the modern full-file, token-callback tokenizer.
- `FSharpLexerImpl` (module): implementation for `FSharpLexer` (token enumeration with LexFilter support).

## Public API surface
- Legacy/classic: `FSharpSourceTokenizer` → `CreateLineTokenizer`/`CreateBufferTokenizer` → `FSharpLineTokenizer.ScanToken` + state round-trip via `FSharpTokenizerLexState`/`ColorStateOfLexState`.
- Modern: `FSharpLexer.Tokenize(text, callback, ...)` with `FSharpLexerFlags` (e.g. `SkipTrivia`, `UseLexFilter`).
- Constants/enums for consumers: `FSharpTokenTag`, `FSharpTokenColorKind`, `FSharpTokenTriggerClass`, `FSharpTokenCharKind`, `FSharpTokenKind`, `FSharpKeywords`.

## Internal helpers / notable details
- `TokenClassifications` is the single source of truth mapping internal `Parser.token` to the public classification enums.
- `LexerStateEncoding` packs the OCaml lexer's continuation state (strings, comments, `#if` regions) into a portable struct so IDEs can cache it line-by-line.

## Significant internal logic
- The classic line tokenizer drives the OCaml lexer (`UnicodeLexing.Lexbuf` plus `Lexhelp`/`LexArgs`) incrementally per line, requiring the previous line's `FSharpTokenizerLexState`.
- The new `FSharpLexer` processes the entire text stream (optional `bufferFiller`-style lazy access) and applies the `LexFilter` so `#if`/`#else`/`#endif` regions (inactive code) are correctly classified, honoring conditional defines, language version, and optional `CancellationToken`.
- `FSharpTokenKind` is deliberately exhaustive over the token grammar (offside tokens included) so consumers can pattern-match on tokens without depending on the internal `Parser.token` type.

## Cross-references
- `src/Compiler/Facilities/prim-lexing` and `src/Compiler/SyntaxTree/LexFilter` (per task context) — the underlying tokenization/filtering machinery
- `FSharp.Compiler.Lexhelp`, `FSharp.Compiler.Parser` (OCaml lexer entry points)
- `SemanticClassification.fs` (higher-level classification built on these tokens)
- `ServiceTokenization`/language-server code that calls `FSharpLexer.Tokenize`

# ServiceLexing.fsi

**Signature for `ServiceLexing.fs`.** Declares the tokenizer public API of the FSharp.Compiler.Service — the "Babel-style" legacy line tokenizer (`FSharpLineTokenizer`) with per-line encoded lexer states, plus the modern experimental `FSharpLexer`/`FSharpToken` whole-text tokenizer, and `FSharpKeywords` helpers.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. Editors colorize F# source incrementally: for each line they keep a compressed `FSharpTokenizerLexState` encoding the lexer continuation (string/comment/#if stack, interpolation nesting), call `FSharpLineTokenizer.ScanToken` repeatedly, and use the returned `FSharpTokenInfo` (color class, char class, triggers, tag) for syntax highlighting and IDE actions (member select, brace matching, parameter info). `FSharpSourceTokenizer` owns per-file lexical resources (defines, language version). The `FSharpLexer`/`FSharpToken` API is a newer, experimental whole-file token stream including trivia and lex-filtered offside tokens.

## Namespaces

- `FSharp.Compiler.Tokenization`, with `open System`, `System.Threading`, `FSharp.Compiler`, `FSharp.Compiler.Text` (`#nowarn "57"`).

## Public types (declared)

- `type FSharpTokenizerLexState` (`[<Struct; CustomEquality; NoComparison>]`):
  - `PosBits: int64`, `OtherBits: int64` — lossy encoded lexer continuation state.
  - `static member Initial: FSharpTokenizerLexState`.
  - `member Equals: FSharpTokenizerLexState -> bool` (also overrides `Equals(obj)`/`GetHashCode`).
- `type FSharpTokenizerColorState` (`enum`): `Token=1, IfDefSkip=3, String=4, Comment=5, StringInComment=6, VerbatimStringInComment=7, VerbatimString=9, SingleLineComment=10, EndLineThenSkip=11, EndLineThenToken=12, TripleQuoteString=13, TripleQuoteStringInComment=14`, and `InitialState=0`.
- `type FSharpTokenColorKind` (enum): `Default/Text=0, Keyword=1, Comment=2, Identifier=3, String=4, UpperIdentifier=5, InactiveCode=7, PreprocessorKeyword=8, Number=9, Operator=10, Punctuation=11`.
- `type FSharpTokenTriggerClass` (enum): `None=0, MemberSelect=1, MatchBraces=2, ChoiceSelect=4, MethodTip=0xF0 (ParamStart=0x10 | ParamNext=0x20 | ParamEnd=0x40)`.
- `type FSharpTokenCharKind` (enum): `Default/Text=0, Keyword=1, Identifier=2, String=3, Literal=4, Operator=5, Delimiter=6, WhiteSpace=8, LineComment=9, Comment=0xA`.
- `module FSharpTokenTag` (public `val`s) — precomputed integer `tagOfToken` values for every token the editor checks: identifiers/strings, interpolated-string parts (`INTERP_STRING_BEGIN_END/PART/END`, `INTERP_STRING_PART`), brackets/parens/braces (`LPAREN…BAR_RBRACK`), operators (`PLUS_MINUS_OP`, `INFIX_*_OP`, `COLON_*`, `RARROW`, `LARROW`), `QUOTE`, `WHITESPACE`, `COMMENT`, `LINE_COMMENT`, and keywords (`BEGIN`, `DO`, `FUNCTION`, `THEN`, `ELSE`, `STRUCT`, `CLASS`, `TRY`, `WITH`, `OWITH`, `NEW`).
- `type FSharpTokenInfo` (record): `LeftColumn`, `RightColumn`, `ColorClass: FSharpTokenColorKind`, `CharClass: FSharpTokenCharKind`, `FSharpTokenTriggerClass`, `Tag: int`, `TokenName: string`, `FullMatchedLength: int`.
- `type FSharpLineTokenizer` (`[<Sealed>]`):
  - `member ScanToken: lexState: FSharpTokenizerLexState -> FSharpTokenInfo option * FSharpTokenizerLexState` — one token from the line.
  - `static member ColorStateOfLexState: FSharpTokenizerLexState -> FSharpTokenizerColorState`.
  - `static member LexStateOfColorState: FSharpTokenizerColorState -> FSharpTokenizerLexState` — best-effort default state (may lose `#if` / interpolation context).
- `type FSharpSourceTokenizer` (`[<Sealed>]`, holds expensive per-file resources):
  - `new: conditionalDefines: string list * fileName: string option * langVersion: string option -> FSharpSourceTokenizer`.
  - `member CreateLineTokenizer: lineText: string -> FSharpLineTokenizer`.
  - `member CreateBufferTokenizer: bufferFiller: (char[] * int * int -> int) -> FSharpLineTokenizer` — for reader/callback-backed buffers.
- `module internal TestExpose` — `val TokenInfo: Parser.token -> FSharpTokenColorKind * FSharpTokenCharKind * FSharpTokenTriggerClass`.
- `module FSharpKeywords`:
  - `val NormalizeIdentifierBackticks: string -> string`.
  - `val KeywordsWithDescription: (string * string) list`.
  - `val internal KeywordsDescriptionLookup: string -> string option`.
  - `val KeywordNames: string list`.

### Experimental modern API (declared)

- `[<Flags; Experimental>] type public FSharpLexerFlags` — `Default = 0x11011`, `Compiling = 0x00010`, `CompilingFSharpCore = 0x00110`, `SkipTrivia = 0x01000`, `UseLexFilter = 0x10000`.
- `[<RequireQualifiedAccess; Experimental>] type public FSharpTokenKind` — the big normalized kind union (hash directives, trivia, offside tokens, keywords, operators by family, numeric/string literals, identifier, etc.).
- `[<Struct; NoComparison; NoEquality; Experimental>] type public FSharpToken`:
  - private fields `tok: Parser.token`, `tokRange: range`.
  - `member Range: range`; `member Kind: FSharpTokenKind`; `member IsIdentifier: bool`; `member IsKeyword: bool`; `member IsStringLiteral: bool`; `member IsNumericLiteral: bool`; `member IsCommentTrivia: bool`.
- `[<AbstractClass; Sealed; Experimental>] type public FSharpLexer`:
  - `static member Tokenize: text: ISourceText * tokenCallback: (FSharpToken -> unit) * ?langVersion: string * ?filePath: string * ?conditionalDefines: string list * ?flags: FSharpLexerFlags * ?pathMap: Map<string,string> * ?ct: CancellationToken -> unit`.

## Relation to .fs

The signature is the public contract; `ServiceLexing.fs` implements it with `TokenClassifications.tokenInfo`, `LexerStateEncoding` (bit-packing/decoding of the continuation state), `FSharpLineTokenizer`'s directive-line splitting and `#-meta-command` merging, `SingleLineTokenState`, `FSharpSourceTokenizer`, `FSharpKeywords` (delegating to `PrettyNaming`/`Keywords`), and `FSharpLexerImpl` backing `FSharpLexer.Tokenize`. Note the `.fs` also defines `FSharpTokenizerColorState.ExtendedInterpolatedString = 15` and `FSharpTokenTag.OWITH`, which are extra beyond the signature's enum/values.
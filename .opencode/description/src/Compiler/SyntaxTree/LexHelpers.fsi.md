# LexHelpers.fsi

**Purpose**: Public (module-level internal) contract for `FSharp.Compiler.Lexhelp` — the low-level lexer helpers: the `LexArgs` context record, the identifier-interning `LexResourceManager`, the lexbuf lifecycle helpers (`reusingLexbufForParsing`/`usingLexbufForParsing`), the string-literal / comment state argument tuples, the escape-sequence decoders, and the keyword token constructors.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.Lexhelp`)

**Modules / Types declared** (public surface):
- `LexResourceManager` (`[<Sealed>]`)
- `LexArgs`
- `LongUnicodeLexResult`
- Lexer string/comment state: `LexerStringFinisherContext`, `LexerStringFinisher`, `LexerStringArgs`, `SingleLineCommentArgs`, `BlockCommentArgs`
- `LargerThanOneByte`, `LargerThan127ButInsideByte`
- `Keywords` sub-module + `exception ReservedKeyword`
- `[<Literal>] StringCapacity: int = 100`

**Public API surface**:
- `resetLexbufPos : string -> Lexbuf -> unit`
- `mkLexargs : LexArgs` (from conditionalDefines * resourceManager * ifdefStack * diagnosticsLogger * pathMap * applyLineDirectives)
- `reusingLexbufForParsing : Lexbuf -> (unit -> 'a) -> 'a`
- `usingLexbufForParsing : Lexbuf * string -> (Lexbuf -> 'a) -> 'a`
- `LexResourceManager.InternIdentifierToken : string -> token`
- String buffer ops: `addUnicodeString`, `addUnicodeChar`, `addByteChar`, `stringBufferAsString`, `stringBufferAsBytes`, `errorsInByteStringBuffer : ByteBuffer -> Option<LargerThanOneByte * LargerThan127ButInsideByte>`
- Position ops: `incrLine`, `advanceColumnBy`
- Escape decoders: `trigraph`, `digit`, `hexdigit`, `unicodeGraphShort`, `hexGraphShort`, `unicodeGraphLong : string -> LongUnicodeLexResult`, `escape : char -> char`
- `Keywords.KeywordOrIdentifierToken`, `Keywords.IdentifierToken`, `Keywords.keywordNames`
- `LexerStringFinisher.Finish`, `LexerStringFinisher.Default`
- `exception ReservedKeyword of RichText * range`

**Internal helpers / active patterns / extension members**: `addIntChar` is referenced by the public surface but implemented in the .fs; the `compatibilityMode` distinction and the `keywordTable` are private.

**Significant internal logic** (declared by the contract):
- **`LexArgs`** is the single context object threaded through the lexer; the mutable `ifdefStack`, `stringNest`, and `interpolationDelimiterLength` fields let the lexer maintain conditional-compilation and interpolated-string state across tokens.
- **`LongUnicodeLexResult`** documents the three outcomes of lexing an 8-hex-digit `\U` escape: a supplementary code point encoded as a UTF-16 surrogate pair, a single BMP char, or invalid.
- **`LexerStringFinisher`** documents the pluggable string-finisher protocol: the lexer accumulates into a `ByteBuffer` and the finisher converts it to the appropriate token once the string state is complete; `Default` provides the standard implementation.
- **`errorsInByteStringBuffer`** documents that it returns counts of over-large values (both >255 and in the 128..255 range) so the lexer can emit the right diagnostics.

**Cross-references**: `LexHelpers.fs` (implementation), `UnicodeLexing.fs` (lexbuf types), `LexFilter.fs` (consumer), `LexerStore.fs` (per-lexbuf stores used by the lexer), `PrettyNaming.fs` (`IsCompilerGeneratedName` for the `@`-check in `IdentifierToken`), `ParseHelpers.fs` (the `LexerIfdefStack`, `LexerStringKind`, `LexerContinuation`, `LexerInterpolatedStringNesting` types held by `LexArgs`), `SyntaxTree.fs` (`SynStringKind` produced by the default finisher).

# LexHelpers.fs

**Purpose**: Internal low-level helpers for the char-based F# lexer (the OCaml-ported lexer and its states in the generated `LexFilter`). Provides: the `LexArgs` context record passed to every lex function (defines, diagnostics logger, path map, ifdef stack, string-interpolation nesting, string finisher state); identifier interning (`LexResourceManager`); string-buffer manipulation (`ByteBuffer` helpers for Unicode/byte strings); the escape-sequence decoders (`trigraph`, `digit`, `hexdigit`, `unicodeGraphShort/Long`, `escape`); the keyword table and token constructors (`Keywords.KeywordOrIdentifierToken`/`IdentifierToken`) including reserved-keyword warnings and `__SOURCE_FILE__`-style keyword strings; lexbuf lifecycle (`reusingLexbufForParsing`/`usingLexbufForParsing`, which install the parse-phase and wrap exceptions in `WrappedError` with the lexeme range); and the string-state argument tuples (`LexerStringArgs`, `SingleLineCommentArgs`, `BlockCommentArgs`) consumed by the generated lexer states.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.Lexhelp`)

**Modules / Types declared**:
- `LexResourceManager` (`[<Sealed>]`) — thread-safe identifier interning cache (`ConcurrentDictionary<string, token>`); `InternIdentifierToken(s)`
- `LexArgs` — record: `conditionalDefines`, `resourceManager`, `diagnosticsLogger`, `applyLineDirectives`, `pathMap`, `mutable ifdefStack: LexerIfdefStack`, `mutable stringNest: LexerInterpolatedStringNesting`, `mutable interpolationDelimiterLength`
- `LongUnicodeLexResult` — `SurrogatePair of uint16*uint16 | SingleChar of uint16 | Invalid` (result of lexing `\Uxxxxxxxx`)
- `LexerStringFinisherContext` (`[<Flags>]`) — `InterpolatedPart = 1`, `Verbatim = 2`, `TripleQuote = 4`
- `LexerStringFinisher` — `(ByteBuffer -> LexerStringKind -> LexerStringFinisherContext -> LexerContinuation -> token)` wrapper; `Finish` member + `static member Default` which builds `INTERP_STRING_*` / `STRING` / `BYTEARRAY` tokens from a finished buffer
- `LexerStringArgs` — `ByteBuffer * LexerStringFinisher * range * LexerStringKind * LexArgs` (string-literal state in lex.fsl)
- `SingleLineCommentArgs` — `(range * StringBuilder) option * int * range * range * LexArgs`
- `BlockCommentArgs` — `int * range * LexArgs`
- `LargerThanOneByte` / `LargerThan127ButInsideByte` — error-counter type aliases
- `exception ReservedKeyword of RichText * range`
- `Keywords` sub-module — keyword table + token constructors
- `LargerThanOneByte = int`, `LargerThan127ButInsideByte = int` aliases; `[<Literal>] StringCapacity = 100`

**Public API surface**:
- `resetLexbufPos : string -> Lexbuf -> unit`
- `mkLexargs : conditionalDefines * resourceManager * ifdefStack * diagnosticsLogger * pathMap * applyLineDirectives -> LexArgs`
- `reusingLexbufForParsing : Lexbuf -> (unit -> 'a) -> 'a`
- `usingLexbufForParsing : Lexbuf * string -> (Lexbuf -> 'a) -> 'a`
- String buffer: `addUnicodeString`, `addUnicodeChar`, `addByteChar`, `stringBufferAsString`, `stringBufferAsBytes`, `errorsInByteStringBuffer`
- Position: `incrLine : LexBuffer<'a> -> unit`, `advanceColumnBy : LexBuffer<'a> -> int -> unit`
- Escape decoders: `trigraph : char*char*char -> char`, `digit`, `hexdigit`, `unicodeGraphShort`, `hexGraphShort`, `unicodeGraphLong : string -> LongUnicodeLexResult`, `escape : char -> char`
- `Keywords.KeywordOrIdentifierToken : LexArgs -> Lexbuf -> string -> token`
- `Keywords.IdentifierToken : LexArgs -> Lexbuf -> string -> token`
- `Keywords.keywordNames : string list`
- `LexResourceManager.InternIdentifierToken : string -> token`
- `LexerStringFinisher.Finish`, `LexerStringFinisher.Default`
- `exception ReservedKeyword`

**Internal helpers / active patterns / extension members**:
- `addIntChar` (private in listing but used by `addUnicodeChar`/`addByteChar`) — emits a 16-bit code unit as two bytes (low byte first) into the `ByteBuffer`
- `Keywords.keywordList` / `keywordTable` — the full F# keyword table (ALWAYS vs FSHARP-only entries, including reserved words and the `__token_O*` "opt-in" tokens), and the `compatibilityMode` distinction for `--mlcompatibility`
- `getSourceIdentifierValue` (from `ParseHelpers`) — used by `KeywordOrIdentifierToken` for `__SOURCE_DIRECTORY__` / `__SOURCE_FILE__` / `__LINE__`

**Significant internal logic**:
- **Identifier interning**: `LexResourceManager` keeps a `ConcurrentDictionary<string, token>` so repeated identifiers across tokens/files share one boxed `IDENT s` token — an important GC/heap optimization for the lexer hot path.
- **Unicode `\Uxxxxxxxx` lexing** (`unicodeGraphLong`): parses an 8-hex-digit value; high == 0 → `SingleChar low`; high > 0x10 → `Invalid`; otherwise decodes a supplementary code point (`0x10000..0x10FFFF`) into a UTF-16 **surrogate pair** using the standard formula (`0xD800 + ((cp - 0x10000) / 0x400)`, `0xDC00 + ((cp - 0x10000) % 0x400)`). This is what lets F# string literals contain non-BMP characters.
- **Byte-string error detection** (`errorsInByteStringBuffer`): for `b"..."` byte strings the buffer stores each char as two bytes (little-endian); this function counts values whose high byte is non-zero (i.e. > 255) or whose low byte > 127 and returns `(>1-byte count, >127 count)` so the lexer can emit `FS0081`-style diagnostics.
- **KeywordOrIdentifierToken**: looks up the lexeme in `keywordTable`; for `RESERVED` entries (legacy ML reserved words: `break`, `checked`, `component`, `continue`, `include`, `params`, `parallel`, `process`, `protected`, `pure`, `sealed`, `trait`, `virtual`, etc.) it emits a `ReservedKeyword` warning and falls back to an identifier; for recognized keywords it returns the keyword token (with `LET true/false` and `YIELD true/false` special-cased for `let`/`use`/`return`/`yield`); for `__SOURCE_*`/`__LINE__` it returns `KEYWORD_STRING(s, value)` resolved via the `PathMap`.
- **Identifier validation**: `IdentifierToken` warns (`lexhlpIdentifiersContainingAtSymbolReserved`) if the string contains `@` — reserved for compiler-generated names (`PrettyNaming.IsCompilerGeneratedName`).
- **`reusingLexbufForParsing`**: installs the `BuildPhase.Parse` diagnostic scope and wraps any inner exception (other than `OperationCanceledException`) in a `WrappedError` carrying the `lexbuf.LexemeRange`, so parse-time lex exceptions get proper positions.
- **`LexerStringFinisher.Default`**: the standard finisher that turns a completed `ByteBuffer` into the right token: interpolated pieces → `INTERP_STRING_BEGIN_PART/INTERP_STRING_PART/INTERP_STRING_END` (with `SynStringKind` Verbatim/Regular/TripleQuote chosen from the context flags), byte strings → `BYTEARRAY`, otherwise `STRING`.

**Cross-references**: `LexHelpers.fsi` (public contract), `UnicodeLexing.fs` (the `Lexbuf`/`LexBuffer` factories and local-data store), `LexFilter.fs` (the offside-rule filter and the main consumer of these helpers; also defines the token types), `LexerStore.fs` (per-lexbuf stores, which `LexArgs` and the lexer call into), `PrettyNaming.fs` (`IsCompilerGeneratedName` used to flag `@` names), `ParseHelpers.fs` (`LexerIfdefStack`, `LexerStringKind`, `LexerContinuation`, `getSourceIdentifierValue`), `SyntaxTree.fs` (the `SynStringKind` used by the string finisher).

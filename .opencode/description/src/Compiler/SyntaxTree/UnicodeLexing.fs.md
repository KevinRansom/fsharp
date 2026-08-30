# UnicodeLexing.fs

**Purpose**: Small internal module providing the F# `Lexbuf` (a `LexBuffer<char>`) factories and two convenience extension members for the `LexBuffer` type. It is the entry point used by higher-level code to obtain a char-based lex buffer from a `string`, a `char[]`-filling function, an `ISourceText`, or a `StreamReader` — these buffers feed `LexFilter` (the offside-rule filter) and the OCaml-ported lexer. The `GetLocalData`/`TryGetLocalData` extension members are what `LexerStore.fs`, `WarnScopes.fs`, and others use to attach per-buffer state (XML-doc collector, ifdef stack, warn directives, syn-arg-name generator, …) without a global table.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.UnicodeLexing`)

**Modules / Types declared**:
- `Lexbuf` — type alias for `LexBuffer<char>`
- Extension members on `LexBuffer<'char>` — `GetLocalData<'T>` and `TryGetLocalData<'T>`
- Module-level val functions — `StringAsLexbuf`, `FunctionAsLexbuf`, `SourceTextAsLexbuf`, `StreamReaderAsLexbuf`

**Public API surface**:
- `Lexbuf = LexBuffer<char>`
- `LexBuffer<'char>.GetLocalData<'T when 'T: not null> : key: string * initializer: (unit -> 'T) -> 'T` — get-or-create per-buffer state under a string key
- `LexBuffer<'char>.TryGetLocalData<'T when 'T: not null> : key: string -> 'T option`
- `StringAsLexbuf : reportLibraryOnlyFeatures: bool * langVersion: LanguageVersion * string -> Lexbuf`
- `FunctionAsLexbuf : reportLibraryOnlyFeatures: bool * langVersion: LanguageVersion * bufferFiller: (char[] * int * int -> int) -> Lexbuf`
- `SourceTextAsLexbuf : reportLibraryOnlyFeatures: bool * langVersion: LanguageVersion * sourceText: ISourceText -> Lexbuf`
- `StreamReaderAsLexbuf : reportLibraryOnlyFeatures: bool * langVersion: LanguageVersion * reader: StreamReader -> Lexbuf` (does not dispose the reader)

**Internal helpers**: `StreamReaderAsLexbuf` wraps a `FunctionAsLexbuf` with a closure that tracks `isFinished` and calls `reader.Read` to fill the `char[]` buffer window.

**Significant internal logic**:
- `BufferLocalStore` is a `ConcurrentDictionary<string, obj>` on the `LexBuffer` (defined in `Internal.Utilities.Text.Lexing`); the extension members cast to `obj` for storage and unbox with `:?>` for retrieval. The `not null` constraint on `'T` keeps the dictionary entries strongly typed by convention.
- The four `*AsLexbuf` functions forward to static constructors on `LexBuffer<char>` (`FromChars`, `FromFunction`, `FromSourceText`), passing through the `LanguageVersion` and `reportLibraryOnlyFeatures` flag that later drive `lexbuf.SupportsFeature` checks in `LexFilter.fs` and the lexer.
- `functionAsLexbuf`/`StreamReaderAsLexbuf` make the lexer incremental: the `bufferFiller` is called to refill the lookahead window, which is essential for streaming F# Interactive and for source-text-based lexing in the service layer.

**Cross-references**: `UnicodeLexing.fsi` (public contract), `Internal.Utilities.Text.Lexing` (`LexBuffer<'char>` definition + `BufferLocalStore`), `LexerStore.fs` (primary user of `GetLocalData`), `LexFilter.fs` (consumer of `Lexbuf`), `ParseHelpers.fs` (uses lexbuf for parse-state/range queries), `SyntaxTree.fs` (AST built from the resulting token stream).

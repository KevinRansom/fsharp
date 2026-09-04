# UnicodeLexing.fsi

**Purpose**: Public (module-level internal) contract for `FSharp.Compiler.UnicodeLexing`: the factory surface for creating F# char-based `Lexbuf` instances from strings, filler functions, source text, or stream readers, plus the two extension members on `LexBuffer<'char>` that expose per-buffer local state. This is the single choke point every caller uses to obtain a `Lexbuf` for the lexer/LexFilter, and the same extension surface is used by `LexerStore` / `WarnScopes` to attach per-buffer state (XML-doc collector, ifdef stack, warn directives, name generator).

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.UnicodeLexing`)

**Modules / Types declared** (public surface):
- `Lexbuf` — type alias for `LexBuffer<char>`
- `LexBuffer<'char>` extension members — `GetLocalData<'T>` and `TryGetLocalData<'T>`

**Public API surface**:
- `type Lexbuf = LexBuffer<char>`
- `LexBuffer<'char>.GetLocalData<'T when 'T: not null> : key: string * initializer: (unit -> 'T) -> 'T`
- `LexBuffer<'char>.TryGetLocalData<'T when 'T: not null> : key: string -> 'T option`
- `StringAsLexbuf : reportLibraryOnlyFeatures: bool * langVersion: LanguageVersion * string -> Lexbuf`
- `FunctionAsLexbuf : reportLibraryOnlyFeatures: bool * langVersion: LanguageVersion * bufferFiller: (char[] * int * int -> int) -> Lexbuf`
- `SourceTextAsLexbuf : reportLibraryOnlyFeatures: bool * langVersion: LanguageVersion * sourceText: ISourceText -> Lexbuf`
- `StreamReaderAsLexbuf : reportLibraryOnlyFeatures: bool * langVersion: LanguageVersion * reader: StreamReader -> Lexbuf`

**Internal helpers / active patterns / extension members**: none (the .fsi only re-exports the .fs surface).

**Significant internal logic**:
- `GetLocalData`/`TryGetLocalData` are the sanctioned mechanism for attaching per-buffer state (documented by use in `LexerStore.fs`, `WarnScopes.fs`, `PrettyNaming` consumers) — callers pass a string key and an initializer, so multiple lexers can coexist in one process with independent state.
- The four `*AsLexbuf` functions all pass `reportLibraryOnlyFeatures` and `langVersion` through to the underlying `LexBuffer`, which the lexer and `LexFilter` later query via `lexbuf.SupportsFeature(_)` (see `LexFilter.fs`'s `relaxWhitespace2` and friends).
- `StreamReaderAsLexbuf` is documented as "will not dispose of the stream reader".

**Cross-references**: `UnicodeLexing.fs` (implementation), `Internal.Utilities.Text.Lexing` (the `LexBuffer<'char>` type), `LexerStore.fs` (consumer of `GetLocalData`), `LexFilter.fs` (main consumer of the resulting `Lexbuf`), `SyntaxTree.fs` (AST constructed by the parser fed from this buffer).

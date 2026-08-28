# prim-lexing.ls

**Purpose**: The runtime foundation for F#'s generated lexers ("prim" = primitive lexing): defines the `ISourceText` source abstractions, the internal `LexBuffer<'Char>` that fslex-generated code drives, and the `UnicodeTables` interpreter that walks fslex transition tables. It is a drop-in replacement for the FsLexYacc `Lexing` module, adapted with language-version awareness for the compiler.

**Namespace(s)**: `FSharp.Compiler.Text` (source-text types) and `Internal.Utilities.Text.Lexing` (lexer runtime)

**Modules / TypeDefs / Classes declared**:
- `ISourceText` (interface): char access (`Item`), `GetLineString/Count/LastCharacterPosition`, `GetSubTextString`, `SubTextEquals`, `Length`, `ContentEquals`, `CopyTo`, `GetSubTextFromRange`
- `ISourceTextNew : ISourceText`: adds `GetChecksum: unit -> ImmutableArray<byte>` (MD5; added as separate type to avoid breaking changes)
- `[<Sealed>] StringText` (implements `ISourceTextNew`): string-backed source; lines computed lazily via `StringReader`; implements structural `Equals`/`GetHashCode`
- `module SourceText`: `ofString: string -> ISourceText`; `module SourceTextNew`: `ofString`, `ofISourceText` (adapts any `ISourceText`, TODO-marked checksum via `ToString`)
- `[<Struct>] internal Position`: `FileIndex`, `Line`, `AbsoluteOffset`, `StartOfLineAbsoluteOffset`, computed `Column`; helpers `NextLine`, `EndOfToken n`, `ShiftColumnBy`, `ColumnMinusOne`, `static Empty`, `static FirstLine fileIdx`
- `internal LexBufferFiller<'Char>`; `[<Sealed>] internal LexBuffer<'Char>`: the lexer input buffer machine
- `module internal GenericImplFragments` (`AutoOpen`): `startInterpret`, `afterRefill`, `onAccept`
- `[<Sealed>] internal UnicodeTables`: interprets `uint16[][]` transition + `uint16[]` accept tables

**Public API surface** (LexBuffer, per .fsi):
- Members: `StartPos`/`EndPos` (Position), `LexemeView` (ReadOnlySpan), `LexemeChar`, `LexemeContains`, `LexemeLength` (setting smaller than actual rewinds the scanner), `BufferLocalStore`, `IsPastEndOfStream`
- Language-feature hooks: `ReportLibraryOnlyFeatures`, `LanguageVersion`, `SupportsFeature`, `CheckLanguageFeatureAndRecover`
- Factories: `FromChars` (takes ownership of `char[]`), `FromArrayNoCopy`/`FromArray`, `FromFunction` (filler callback), `FromSourceText`, `static LexemeString`
- `UnicodeTables.Create(trans, accept)`, `member Interpret(initialState, lexBuffer)`; `EndOfScan()` (returns accept action or fails with "unrecognized input")

**Significant internal logic**:
- Comment at top of lexer section: "drop-in replacement runtime for Lexing.fs from the FsLexYacc repository"; the table format must *precisely* match what fslex emits
- Unicode row layout per state: 128 ASCII entries → variable 2×UInt16 pairs for specific Unicode chars → 30 `UnicodeCategory` entries → 1 EOF slot; `lookupUnicodeCharacters` does the ASCII fast path, then specific-char linear search, then category fallback
- Scan loop: on each char, if `accept[state]` isn't the sentinel (`65535`) record a lexeme (`onAccept`); buffer exhaustion triggers `DiscardInput` + `RefillBuffer` + `afterRefill` which either continues or consumes an EOF token
- `LexBuffer` carries `LanguageVersion` so generated lexer actions can gate `#lang` features during lexing; `checkLanguageFeatureAndRecover` hooks into DiagnosticsLogger
- `StringText.GetSubTextFromRange` handles multi-line extraction and validates file-boundary ranges

**Cross-references**: prim-parsing.fs (the parser uses `LexBuffer`/`Position`), LanguageFeatures.fs + DiagnosticsLogger.fs (feature checks), Hashing.fs (`Md5Hasher` for checksums), Checker/parser in `FSharp.Compiler` for token streams.

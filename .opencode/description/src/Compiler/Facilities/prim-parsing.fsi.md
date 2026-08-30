# prim-parsing.fsi

**Purpose**: The contract for `prim-parsing.fs` (drop-in replacement runtime for `Parsing.fsi` from the FsLexYacc repository). Declares the internal parser-table runtime: `IParseState`, `ParseErrorContext<'Token>`, `Tables<'Token>` with its `Interpret` member, the two control-flow exceptions, the `Flags` module, and `ParseHelpers` defaults.

**Namespace(s)**: `Internal.Utilities.Text.Parsing`

**Declarations** (all `internal`):
- `[<Sealed>] type IParseState`: `InputRange(index)`, `InputEndPosition(index)`, `InputStartPosition(index)`, `ResultStartPosition`, `ResultEndPosition`, `ResultRange`, `GetInput(index)`, `RaiseError<'b>` — "Raise an error in this parse context", `LexBuffer: LexBuffer<char>`
- `[<Sealed>] type ParseErrorContext<'Token>`: "context provided when a parse error occurs" — `StateStack`, `ParseState`, `ReduceTokens`, `ReducibleProductions`, `CurrentToken`, `ShiftTokens`, `Message`
- `type Tables<'Token>`: "The type of the tables contained in a file produced by the fsyacc.exe parser generator" — fields `reductions`, `endOfInputTag`, `tagOfToken`, `dataOfToken`, `actionTableElements/RowOffsets`, `reductionSymbolCounts`, `immediateActions`, `gotos` + `sparseGotoTableRowOffsets`, `stateToProdIdxsTable...`, `productionToNonTerminalTable` ("logically part of the Goto table"), `parseError` (holds user `parse_error`/`parse_error_rich`), `numTerminals`, `tagOfErrorTerminal`; plus `member Interpret: lexer * lexbuf * initialState -> obj`
- `exception Accept of obj` — "an accept action has occurred"; `exception RecoverableParseError` — "a parse error has occurred and parse recovery is in progress"
- `module Flags`: `debug: bool` (mutable in DEBUG builds, const in release)
- `module ParseHelpers`: "Helpers used by generated parsers" — `parse_error_rich: (ParseErrorContext<'Token> -> unit) option` (default None), `parse_error: string -> unit` (default no-op)

**Cross-references**: Implements prim-parsing.fs; depends on prim-lexing (`LexBuffer`, `Position`); used by the F# parser's generated table code.

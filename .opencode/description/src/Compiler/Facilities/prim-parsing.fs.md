# prim-parsing.fs

**Purpose**: The drop-in replacement runtime for `Parsing.fs` from the FsLexYacc repository: implements the LALR table interpreter that drives fsyacc-generated parsers. It provides the `Tables<'Token>` machine (state/value stacks, sparse action/goto tables with a binary-search + small direct-mapped cache), the LRM error-recovery protocol (pop until the `error` token can shift, 3-token error suppression, EOF re-feeding), and the `IParseState`/`ParseErrorContext` API the generated actions use.

**Namespace(s)**: `Internal.Utilities.Text.Parsing`

**Modules / TypeDefs / Classes declared**:
- `exception RecoverableParseError`, `exception Accept of obj` — control flow within the interpret loop
- `[<Sealed>] type internal IParseState`: rule input/result positions and values for a reduction (`InputRange`, `GetInput`, `ResultRange`, `RaiseError`, `LexBuffer`)
- `[<Sealed>] type internal ParseErrorContext<'Token>`: state stack, parse state, reducible productions, shiftable/reduce tokens, current token, message — passed to the error reporter
- `type internal Tables<'Token>`: record of everything fsyacc emits (reductions, tag/dataOfToken, sparse action table + row offsets, `immediateActions`, gotos, stateToProdIdxs, productionToNonTerminal, `parseError`, `numTerminals`, `tagOfErrorTerminal`)
- `type Stack<'a>`: grow-by-2-capacity stack with `Peep/Top n/PrintStack`
- `module Flags`: `debug` (mutable in DEBUG, const false in release)
- `module internal Implementation`: the interpreter
  - Action flags: `anyMarker=0xffff`, `shiftFlag=0x0000`, `reduceFlag=0x4000`, `errorFlag=0x8000`, `acceptFlag=0xc000`, `actionMask=0xc000`; `actionValue`/`actionKind`
  - `AssocTable`: sparse row → binary chop; `Read` consults a direct-mapped cache (`cacheKey = (row <<<16) ||| key`, prime-sized 7919 bucket arrays rented from `ArrayPool<int>.Shared`) — comment: without the lookaside cache, the chop takes ~10% of parse time on the self-hosted compiler
  - `IdxToIdxListTable`: active productions per state
  - `[<Struct>] ValueInfo`: `value`, `startPos`, `endPos`
  - `interpret tables lexer lexbuf initialState`: the main loop
- `Tables<'Token> with member Interpret` — the public entry
- `module internal ParseHelpers`: default `parse_error` (no-op), `parse_error_rich` (None)

**Significant internal logic**:
- Loop: immediate-action fast path (no lookahead needed), else get lookahead token from the lexer (with positions); then shift / reduce / error / accept
- Reduce: pops `n` symbol values gathering `ruleStartPoss/EndPoss/Values`, merges LHS range across same-file inputs, calls the generated reduction function; `Accept` ends the parse; exceptions from actions flow through
- Error recovery: `popStackUntilErrorShifted` pops until the error terminal shifts (optionally requiring the next token also shifts — used at EOF); after an error, `errorSuppressionCountDown <- 3` swallows 3 discards before the next report
- EOF handling: `eofCountDown = 20` allows repeated "re-shift the last token at EOF" so `input : realInput EOF | realInput error EOF | error EOF`-style rules can still produce partial results
- On a hard error: gathers `shiftableTokens`/`reduceTokens`/`reducibleProductions` (last 12 states) into a `ParseErrorContext` and calls `tables.parseError`
- LHS position computation spans lines/files via `FileIndex`/`Line` checks

**Cross-references**: prim-lexing.fs (`LexBuffer`, `Position`), generated F# parser tables (`FSharpParse`), DiagnosticsLogger (error reporting via generated `parse_error_rich`), LanguageFeatures (lexers check features; the parser's `error` context feeds suggestions).

# ppars.fsy — Small PARS Parser for `#if` Condition Expressions

> **Note on naming**: despite the name, this *small* `pppars.fsy` is **not** the full F#
> syntax parser. It is the compact PARS grammar that parses the **preprocessor
> conditional-compilation expression** (the text after `#if`/`#elif`) into a
> `LexerIfdefExpression`. The full F# parser spec in this repo is `pars.fsy` (see its
> description).

**Purpose**: A minimal PARS (yacc-style) specification that turns the token stream of a
`#if`/`#elif` condition into the small `LexerIfdefExpression` AST, so the compiler can
decide whether a conditional-compilation branch is active at **lexing** time — without
parsing F# proper. It is generated as module `FSharp.Compiler.PPParser` (see the
`<Compile>` flags in `FSharp.Compiler.Service.fsproj`), paired with the `pplex.fsl`
lexer generated as `FSharp.Compiler.PPLexer`. The main lexer (`lex.fsl`) calls
`FSharp.Compiler.PPParser.start` on each `#if`/`#elif` line (via its
`evalIfDefExpression` helper).

## Header / declarations (the `%{ ... %}` block, lines 3-18)

- `open FSharp.Compiler.DiagnosticsLogger`; `#nowarn "3261"`.
- **`dummy`** (line 8): `IfdefId("DUMMY")` — a throwaway `LexerIfdefExpression` returned
  by error-recovery actions so the grammar still produces a value.
- **`doNothing _ dflt`** (lines 10-11): returns the default value (recovery no-op).
- **`fail (ps : IParseState) i e`** (lines 13-17): reports a diagnostic —
  `errorR(Error(e, m))` where `m = mkSynRange f t` from `ps.InputRange i` — then
  returns `dummy`. Used by every error-recovery alternative in `Full` and `Expr`.

## %start / %token / precedence

- **`%start start`** — single entry symbol.
- **`%token`** (lines 23-24):
  - `ID <string>` — one conditional symbol (e.g. `DEBUG`).
  - `OP_NOT`, `OP_AND`, `OP_OR`, `LPAREN`, `RPAREN` — `!`, `&&`, `||`, `(`, `)`.
  - `PRELUDE` — the `#if`/`#elif` keyword prefix token.
  - `EOF` — end of the condition.
- **Precedence** (lines 26-32) — classic boolean precedence, lowest to highest:
  `%nonassoc RPAREN`, `%nonassoc PRELUDE`, `%left OP_OR`, `%left OP_AND`, `%left OP_NOT`,
  `%nonassoc LPAREN`, `%nonassoc ID`.
  So `!` binds tightest, then `&&`, then `||`; parentheses always group.
- **`%type <LexerIfdefExpression> start`** — result of `start`.

## Productions (lines 38-62)

- **`start: Full { $1 }`** — root, passes through the parsed expression.
- **`Recover:`** — single production `| error { doNothing parseState () }`, the parser's
  error-recovery hook invoked by the generated parser when a `recover`/`error` point is
  hit (reports via `parse_errors` → `fail`; returns `dummy`).
- **`Full:`**
  - `| PRELUDE Expr EOF { $2 }` — well-formed `#if expr` / `#elif expr` line.
  - `| Recover { fail parseState 1 (FSComp.SR.ppparsMissingToken("#if/#elif")) }` — the
    line had no expression (or an unrecoverable error): "missing token" diagnostic.
- **`Expr:`** — the boolean-expression grammar plus error-recovery alternatives:
  - `| LPAREN Expr RPAREN { $2 }` — grouping.
  - `| ID { IfdefId($1) }` — a single conditional symbol.
  - `| OP_NOT Expr { IfdefNot($2) }` — negation.
  - `| Expr OP_AND Expr { IfdefAnd($1, $3) }` — conjunction.
  - `| Expr OP_OR Expr { IfdefOr($1, $3) }` — disjunction.
  - Error alternatives (all call `fail … `, reporting and yielding `dummy`):
    `OP_AND Recover`, `OP_OR Recover`, `OP_NOT Recover` (`ppparsUnexpectedToken("&&"/"||"/"!")`),
    `LPAREN error RPAREN` (`doNothing`), `LPAREN Expr Recover`
    (`ppparsMissingToken(")")`), `LPAREN Recover` and `Expr Recover` and `EOF`
    (all `ppparsIncompleteExpression()`), `RPAREN Recover`
    (`ppparsUnexpectedToken(")")`).

## Key rules / logic

- **Boolean-expression subset only**: identifiers, `!`, `&&`, `||`, parentheses — exactly
  what appears in `#if DEBUG && !FEATURE_X || OTHER` style conditions. No F# expressions,
  no literals, no function calls.
- **Error recovery**: the generated PARS parser routes errors through `Recover`; each
  failure alternative produces a specific, localized diagnostic
  (`ppparsMissingToken`, `ppparsUnexpectedToken`, `ppparsIncompleteExpression`) and a
  `dummy` expression, so a malformed `#if` line degrades gracefully instead of crashing
  the lexing pipeline.

## Internal helpers / actions

- `dummy`, `doNothing`, `fail` (header block) as described above.
- `errorR(Error(e, m))` — diagnostic reporting via `FSharp.Compiler.DiagnosticsLogger`.
- Actions build `LexerIfdefExpression` nodes: `IfdefId`, `IfdefNot`, `IfdefAnd`,
  `IfdefOr` (from `FSharp.Compiler.ParseHelpers`).

## Cross-references

- **`pplex.fsl`** — the companion lexer that emits exactly this grammar's tokens
  (`PRELUDE`, `ID`, `OP_NOT`, `OP_AND`, `OP_OR`, `LPAREN`, `RPAREN`, `EOF`). Generated
  together as `FSharp.Compiler.PPLexer` / `FSharp.Compiler.PPParser`.
- **`lex.fsl`** — the main F# lexer; its `#if`/`#elif` rules (and the
  `evalIfDefExpression` helper at lines 204-210) invoke
  `PPLexer.tokenstream` + `PPParser.start` to evaluate conditional-compilation
  expressions, then consume the result with `LexerIfdefEval lookup expr`.
- **`pars.fsy`** — the full F# parser (distinct from this file); both ultimately feed
  the compiler's `SyntaxTree`-based pipeline, but this file's output
  (`LexerIfdefExpression`) only drives `#if` branch skipping during lexing.

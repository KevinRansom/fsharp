# WarnScopes.fs

**Purpose**: Internal module implementing F#'s `#nowarn` / `#warnon "nnnnn"` lexically-scoped warning suppression. It collects such directives as they are encountered during lexing (via a per-`Lexbuf` store) and, after the file finishes lexing, converts them into per-file `warningScope` entries in `FSharpDiagnosticOptions`, keyed by source range so diagnostics can be filtered by warning number and location.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.WarnScopes`)

**Modules / Types declared**:
- `WarnScopes` module (qualified access) — the whole public surface of this file

**Public API surface**:
- `ParseAndRegisterWarnDirective : Lexbuf -> unit` — called from the lexer when a `#nowarn`/`#warnon "..."` line is seen; stores the directive with its range
- `MergeInto : FSharpDiagnosticOptions -> isScript: bool -> subModuleRanges: range list -> Lexbuf -> unit` — called after lexing finishes; merges the per-file warn directives into the shared `FSharpDiagnosticOptions.Warnings` / `Nowarns` scopes (the `isScript` and `subModuleRanges` parameters exist to preserve back-compat with script mode and `FSharpCheckFSharpSyntax` sub-module ranges)
- `getDirectiveTrivia : Lexbuf -> WarnDirectiveTrivia list` — returns the collected directives for trivia attachment
- `IsWarnon : FSharpDiagnosticOptions -> warningNumber: int -> mo: range option -> bool` — true if `mo` falls inside a `#warnon` scope for that warning
- `IsNowarn : FSharpDiagnosticOptions -> warningNumber: int -> mo: range option -> bool` — true if `mo` falls inside a `#nowarn` scope for that warning

**Internal helpers**: storage is kept in the lexbuf's local data store; helpers to parse the `"nnnnn"` number from the directive text and to scope-merge ranges.

**Significant internal logic**:
- Warning-number scoping: a `#nowarn "5"` (or `#nowarn "5:..."`) applies from that line until end-of-file (or until a new directive overrides), producing a range entry; later `#warnon "nnn"` re-enables within a nested position.
- `MergeInto` appends to `FSharpDiagnosticOptions.Warnings` with the `range` so that `DiagnosticsLogger` (see `FSharpDiagnosticOptions`) can filter per-range.
- `IsNowarn`/`IsWarnon` are the hot-path predicate used by the diagnostic reporter.
- `getDirectiveTrivia` feeds `SyntaxTrivia.fs` so the trivia stream preserves `#nowarn`/`#warnon` for tooling.

**Cross-references**: `WarnScopes.fsi` (public contract), `SyntaxTrivia.fs` (`WarnDirectiveTrivia` trivia type), `FSharpDiagnosticOptions` (in `Diagnostics`), `LexerStore.fs` (sibling per-lexbuf store pattern), `LexFilter.fs` (lexer-side entry point that calls `ParseAndRegisterWarnDirective`).

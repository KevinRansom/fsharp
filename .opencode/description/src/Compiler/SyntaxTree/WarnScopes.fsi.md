# WarnScopes.fsi

**Purpose**: Public (module-level internal) contract for `FSharp.Compiler.WarnScopes`, the module implementing F#'s `#nowarn "..."` / `#warnon "..."` lexically-scoped warning suppression. Declares the API that the lexer, the parser, and the diagnostic options use to register and test warn scopes.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.WarnScopes`)

**Modules / Types declared** (public surface):
- `WarnScopes` module (`RequireQualifiedAccess`)

**Public API surface** (all qualified via `WarnScopes.`):
- `ParseAndRegisterWarnDirective : Lexbuf -> unit` — called during lexing to record a `#nowarn`/`#warnon` directive
- `MergeInto : FSharpDiagnosticOptions -> isScript: bool -> subModuleRanges: range list -> Lexbuf -> unit` — after lexing, fold the file's directives into the shared diagnostic options
- `getDirectiveTrivia : Lexbuf -> WarnDirectiveTrivia list` — trivia output for the tree
- `IsWarnon : FSharpDiagnosticOptions -> int -> range option -> bool` — predicate: is this range/warning re-enabled?
- `IsNowarn : FSharpDiagnosticOptions -> int -> range option -> bool` — predicate: is this range/warning suppressed?

**Internal helpers / active patterns / extension members**: none in the .fsi; the .fs holds the per-lexbuf storage and the parsing of the `"nnnnn"` numbers.

**Significant internal logic**: defines the contract for scoping: `#nowarn`/`#warnon` directives are attached to a position/range during lexing, then merged per-file; `IsNowarn`/`IsWarnon` consult the merged table with the source range of the diagnostic.

**Cross-references**: `WarnScopes.fs` (implementation), `SyntaxTrivia.fs` (`WarnDirectiveTrivia`), `FSharpDiagnosticOptions` (consumer), `LexerStore.fs` (sibling store pattern), `LexFilter.fs` (lexer entry point).

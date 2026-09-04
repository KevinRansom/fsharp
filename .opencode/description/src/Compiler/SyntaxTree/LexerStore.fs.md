# LexerStore.fs

**Purpose**: Internal lexer-side state store used by the OCaml ported lexer (`LexFilter.fs`) to accumulate per-file trivia during lexing. It holds XML doc lines, `#if`/`#else`/`#endif` conditional directive info, comments, and line directives, keyed by local-data slots on the `Lexbuf`. The parser later reads these stores to attach `SyntaxTrivia` to the tree it builds from the token stream. It bridges the low-level lexer and the SyntaxTree/trivia layer.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.LexerStore`)

**Modules / Types declared**:
- `LexerStore (module)` — top-level; `getSynArgNameGenerator` plus nested stores
- `XmlDocStore (module)` — save/retrieve accumulated XML doc comment lines and grab points
- `LexerIfdefExpression (union)` — `IfdefAnd`/`IfdefOr`/`IfdefNot`/`IfdefId`: lexical form of `#if` conditional expressions
- `IfdefStore (module)` — accumulate `ConditionalDirectiveTrivia` from `#if/#elif/#else/#endif`
- `CommentStore (module)` — accumulate line and block `CommentTrivia`
- `LineDirectiveStore (module)` — accumulate `#line` directive mappings (file index + line)

**Public API surface**:
- `getSynArgNameGenerator : Lexbuf -> SynArgNameGenerator` — parser-side name generator for anonymous `SynArg` names, stored as lexbuf local data
- `XmlDocStore`:
  - `SaveXmlDocLine : Lexbuf * string * range -> unit`
  - `AddGrabPoint` / `AddGrabPointDelayed : Lexbuf -> unit` — mark positions where an XML doc block may end/begin (comments-in-between handling)
  - `GrabXmlDocBeforeMarker : Lexbuf * range -> PreXmlDoc` — parser calls when a construct ends to detach the pending doc
  - `ReportInvalidXmlDocPositions : Lexbuf -> range list`
  - `SetLastNonCommentTokenLine` / `GetLastNonCommentTokenLine : Lexbuf * int -> unit / Lexbuf -> int`
- `LexerIfdefEval : (string -> bool) -> LexerIfdefExpression -> bool` — evaluate an `#if` expression against a symbol lookup
- `IfdefStore`: `SaveIfHash`, `SaveElifHash`, `SaveElseHash`, `SaveEndIfHash`, `GetTrivia : Lexbuf -> ConditionalDirectiveTrivia list`
- `CommentStore`: `SaveSingleLineComment`, `SaveBlockComment`, `GetComments`
- `LineDirectiveStore`: `SaveLineDirective`, `GetLineDirectives`

**Internal helpers**:
- `mkRangeWithoutLeadingWhitespace` — trim leading whitespace off a directive's range
- `convertIfdefExpression` — map `LexerIfdefExpression` to the public `IfDirectiveExpression`

**Significant internal logic**:
- All stores use `lexbuf.GetLocalData` with a string key, so state stays attached to the lexing buffer across file includes without global state.
- `AddGrabPointDelayed` handles the case of regular comments between XML doc blocks; a delayed grab point is only promoted when a new XML doc block follows.
- `LexerIfdefEval` is the recursive short-circuit evaluator for conditional compilation directives.
- `GrabXmlDocBeforeMarker` converts the collector's grab points (via `PreXmlDoc.CreateFromGrabPoint`) into a single doc associated with the marker keyword's position.

**Cross-references**: `SyntaxTrivia.fs` (trivia types), `XmlDoc.fs` (`XmlDocCollector`, `PreXmlDoc`), `LexFilter.fs` (callers), `LexerStore.fsi` (public contract), `SyntaxTree.fs` (parser consumes these).

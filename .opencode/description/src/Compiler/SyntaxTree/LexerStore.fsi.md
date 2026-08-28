# LexerStore.fsi

**Purpose**: Public (module-level) contract for the internal lexer state store used during lexing of a source file. It declares the per-`Lexbuf` accumulators for XML doc comments, conditional-compilation (`#if`) directives, comments, and `#line` directives that `LexFilter.fs` writes and the parser later drains to attach `SyntaxTrivia`. This .fsi mirrors the implementation in `LexerStore.fs`.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.LexerStore`)

**Modules / Types declared** (public contract only; see .fs for implementation):
- `getSynArgNameGenerator` — accessor for the parser's `SynArgNameGenerator`
- `XmlDocStore` (`RequireQualifiedAccess`) — XML doc line accumulation and grab-point API
- `LexerIfdefExpression` — union `IfdefAnd`/`IfdefOr`/`IfdefNot`/`IfdefId` for lexical `#if` expressions
- `LexerIfdefEval` — evaluation entry point
- `IfdefStore` (`RequireQualifiedAccess`) — conditional directive trivia store
- `CommentStore` (`RequireQualifiedAccess`) — comment trivia store
- `LineDirectiveStore` (`RequireQualifiedAccess`) — line-directive store

**Public API surface**:
- `getSynArgNameGenerator : Lexbuf -> SynArgNameGenerator`
- `XmlDocStore.SaveXmlDocLine | AddGrabPoint | AddGrabPointDelayed | GrabXmlDocBeforeMarker | ReportInvalidXmlDocPositions | SetLastNonCommentTokenLine | GetLastNonCommentTokenLine`
- `LexerIfdefEval : (string -> bool) -> LexerIfdefExpression -> bool`
- `IfdefStore.SaveIfHash | SaveElseHash | SaveElifHash | SaveEndIfHash | GetTrivia`
- `CommentStore.SaveSingleLineComment | SaveBlockComment | GetComments`
- `LineDirectiveStore.SaveLineDirective | GetLineDirectives`

**Internal helpers**: not exposed; private helpers live in the .fs (e.g. `mkRangeWithoutLeadingWhitespace`, `convertIfdefExpression`).

**Significant internal logic**:
- The surface is a set of imperative save/get pairs keyed on `Lexbuf` local data; it defines no lexing rules itself.
- `GrabXmlDocBeforeMarker` is the contract point where the parser detaches a pending `PreXmlDoc` from the collector, using the marker keyword's range as the end boundary.
- All access is qualified (`RequireQualifiedAccess`) to avoid name collisions when opened.

**Cross-references**: `LexerStore.fs` (implementation), `SyntaxTrivia.fs` (`ConditionalDirectiveTrivia`, `CommentTrivia`), `XmlDoc.fs` (`PreXmlDoc`, `XmlDocCollector`), `LexFilter.fs` (primary caller), `ParseHelpers.fs` (`SynArgNameGenerator`).

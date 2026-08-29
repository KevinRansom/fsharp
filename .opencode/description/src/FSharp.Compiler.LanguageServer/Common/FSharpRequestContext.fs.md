# FSharpRequestContext.fs

> Pipeline role: The per-request context (and context factory) for the F# LSP server — carries `ILspServices`/logger/`FSharpWorkspace`, computes semantic tokens for a file (merging checker semantic classification with syntactic lexer tokens into the LSP delta format), and provides `ContextHolder` (singleton behind the request factory).
> Namespace: `FSharp.Compiler.LanguageServer.Common` (line 1).

---

## `module TokenTypes` (line 20)

- `[<return: Struct>] (|LexicalClassification|_|) (tok: FSharpToken)` — maps lexer token categories to LSP `SemanticTokenTypes` but only for syntax-only classes: Keyword/Number/Comment/String.
- `GetSyntacticTokenTypes (source: ISourceText) (fileName: string)` — full lex run via `FSharpLexer.Tokenize` (flags: `Default &&& ~~~Compiling` and without `UseLexFilter`), collecting `(tok.Range, tokType)` for matched tokens.
- `FSharpTokenTypeToLSP (fst: SemanticClassificationType)` — "XXX kinda arbitrary mapping" from the checker's semantic classification to LSP token types (Class/Struct/Enum/EnumMember/Function/Property/Type/Namespace/Interface/TypeParameter/Operator/Method/Event/Parameter/Variable/String/Keyword/Comment, defaulting to Comment).
- `toIndex (x: string)` — index into `SemanticTokenTypes.AllTypes`.

## `type FSharpRequestContext(lspServices, logger, workspace)` (line 86)

Members: `LspServices`, `Logger`, `Workspace`.

- `GetSemanticTokensForFile(file)` (line 91) — `task`:
  - `Workspace.Query.GetSemanticClassification file` → `Some view` + `GetSource file` → `Some source`.
  - collect semantic tokens from `view.ForEach` (Range, mapped+indexed LSP type).
  - append syntactic tokens from `GetSyntacticTokenTypes` (indexed).
  - build LSP `{ startLine; startCol; length; tokType; tokMods }` records (`length = EndColumn - StartColumn`, "XXX Does not deal with multiline tokens?"), sort by (line, col).
  - produce delta-encoded arrays (each token relative to the previous: `startLine` diff, `startCol` diff when same line) seeded with a `{0,0,0,0,0}` sentinel.
  - flattens to `int[]` (`Data` for `SemanticTokens`).

## `type ContextHolder(workspace, lspServices)` (line 164)

- `logger = GetRequiredService<ILspLogger>()`; memoizes `FSharpRequestContext`.
- `GetContext()` / `UpdateWorkspace(f)` (applies a mutation to `context.Workspace`, e.g. to file open/close).

## `type FShapRequestContextFactory(lspServices: ILspServices)` (line 174)

- `inherit AbstractRequestContextFactory<FSharpRequestContext>`; `CreateRequestContextAsync(...)` — returns the singleton `ContextHolder` context via `Task.FromResult`.

---

## Related

- Registered in `FSharpLanguageServer.ConstructLspServices`; the workspace is `FSharp.Compiler.CodeAnalysis.Workspace.FSharpWorkspace` whose `Query` API (`GetSemanticClassification`, `GetSource`, `GetDiagnosticsForFile`) sits in `src/Compiler/CodeAnalysis/Workspace/`. Handlers (`DocumentStateHandler`, `LanguageFeaturesHandler`) drive mutating vs read-only work.
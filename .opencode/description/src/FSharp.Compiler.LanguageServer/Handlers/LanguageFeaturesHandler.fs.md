# LanguageFeaturesHandler.fs

> Pipeline role: LSP **language feature** handler — implements pull diagnostics (`textDocument/diagnostic` → `documentDiagnostic` with related-documents report) and semantic tokens (`textDocument/semanticTokens/full`). Read-only (`MutatesSolutionState = false`).
> Namespace: `FSharp.Compiler.LanguageServer.Handlers` (line 1).

---

## `type LanguageFeaturesHandler()` (line 15)

- `interface IMethodHandler` — `MutatesSolutionState = false`.

**Diagnostics** (`IRequestHandler<DocumentDiagnosticParams, SumType<RelatedFullDocumentDiagnosticReport, RelatedUnchangedDocumentDiagnosticReport>, FSharpRequestContext>`, endpoint `Methods.TextDocumentDiagnosticName`, line 19):

- `context.Workspace.Query.GetDiagnosticsForFile request.TextDocument.Uri` gives `fsharpDiagnosticReport` (`Diagnostics` + `ResultId`).
- Maps each diagnostic with `_.ToLspDiagnostic()` (`Utils.fs`), builds `FullDocumentDiagnosticReport(Items, ResultId)`, wraps in a `RelatedFullDocumentDiagnosticReport` whose `RelatedDocuments` maps the URI to the report.
- Runs inside `cancellableTask { ... } |> CancellableTask.start cancellationToken` (`CancellableTasks` from the VS F# editor helper).

**Semantic tokens full** (`IRequestHandler<SemanticTokensParams, SemanticTokens, FSharpRequestContext>`, endpoint `Methods.TextDocumentSemanticTokensFullName`, line 52):

- `context.GetSemanticTokensForFile(request.TextDocument.Uri)` → `SemanticTokens(Data = tokens)`; same cancellable-task wrapper.

---

## Related

- Uses `FSharpRequestContext.GetSemanticTokensForFile` (delta-encoded token arrays), `FSharpDiagnosticExtensions.ToLspDiagnostic`, and the workspace diagnostic query; registered in `FSharpLanguageServer.ConstructLspServices`.
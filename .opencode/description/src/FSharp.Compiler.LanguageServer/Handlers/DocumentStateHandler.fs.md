# DocumentStateHandler.fs

> Pipeline role: LSP **document lifecycle** handler — `textDocument/didOpen`, `textDocument/didChange`, `textDocument/didClose`. All three mutate the workspace file store (`ContextHolder.UpdateWorkspace`) and (for open/change) return a `SemanticTokensDeltaPartialResult` stub.
> Namespace: `FSharp.Compiler.LanguageServer.Handlers` (line 1).

---

## `type DocumentStateHandler()` (line 12)

- `interface IMethodHandler` — `MutatesSolutionState = true`.

**didOpen** (`IRequestHandler<DidOpenTextDocumentParams, SemanticTokensDeltaPartialResult, FSharpRequestContext>`, endpoint `Methods.TextDocumentDidOpenName`):

- `contextHolder.UpdateWorkspace (_.Files.Open(request.TextDocument.Uri, request.TextDocument.Text))`; returns `Task.FromResult(SemanticTokensDeltaPartialResult())`.

**didChange** (`IRequestHandler<DidChangeTextDocumentParams, ...>`, endpoint `Methods.TextDocumentDidChangeName`):

- `contextHolder.UpdateWorkspace (_.Files.Edit(request.TextDocument.Uri, request.ContentChanges.[0].Text))` — full-document sync (the cap manager advertised `TextDocumentSyncKind.Full`), using the *first* content change's text.

**didClose** (`INotificationHandler<DidCloseTextDocumentParams, FSharpRequestContext>`, endpoint `Methods.TextDocumentDidCloseName`):

- `contextHolder.UpdateWorkspace (_.Files.Close(request.TextDocument.Uri))`; `Task.CompletedTask`.

---

## Related

- Registered via `LanguageServerEndpoint` attributes in `FSharpLanguageServer`'s services; the `Files.Open/Edit/Close` API is `FSharp.Compiler.CodeAnalysis.Workspace` (see `src/Compiler/CodeAnalysis/Workspace/`).
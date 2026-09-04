# CapabilitiesManager.fs

> Pipeline role: Implements the LSP `IInitializeManager<InitializeParams, InitializeResult>` for the F# server — caches the `initialize` parameters and builds the `ServerCapabilities` response (text sync full, pull diagnostics, semantic tokens legend), with an override hook for hosts to customise per-client capabilities.
> Namespace: `FSharp.Compiler.LanguageServer.Common` (line 1).

---

## `type IServerCapabilitiesOverride` (line 7)

- `abstract member OverrideServerCapabilities: FSharpLanguageServerConfig * ServerCapabilities * ClientCapabilities -> ServerCapabilities`.

## `type CapabilitiesManager(config: FSharpLanguageServerConfig, scOverrides: IServerCapabilitiesOverride seq)` (line 10)

State: `mutable initializeParams`.

- `getInitializeParams ()` / `failwith "InitializeParams is null"`.
- `addIf (enabled: bool) (capability: 'a)` — `capability |> withNull` when enabled else `null`.
- `defaultCapabilities (_clientCapabilities)` (line 22) — `ServerCapabilities`:
  - `TextDocumentSync = TextDocumentSyncOptions(OpenClose = true, Change = TextDocumentSyncKind.Full)`.
  - `DiagnosticOptions` when `config.EnabledFeatures.Diagnostics` (WorkDoneProgress=true, InterFileDependencies=true, `Identifier = "potato"`, WorkspaceDiagnostics=true). TODO comment: "don't register if dynamic registraion is supported".
  - `SemanticTokensOptions` when `config.EnabledFeatures.SemanticHighlighting` — legend with all `SemanticTokenTypes.AllTypes` and `AllModifiers`, `Range = false`.
  - (Hover/Completion commented out.)
- `interface IInitializeManager<...>` — `SetInitializeParams`, `GetInitializeParams`, `GetInitializeResult()` — folds `scOverrides` over `defaultCapabilities` with the client capabilities.

---

## Related

- Wired in `FSharpLanguageServer.ConstructLspServices`; reads `FSharpLanguageServerConfig`; folds `IServerCapabilitiesOverride` (used by IDE hosts, e.g. VS, to add unsupported-but-desired features).
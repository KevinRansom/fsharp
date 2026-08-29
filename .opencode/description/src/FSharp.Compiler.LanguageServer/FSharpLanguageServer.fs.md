# FSharpLanguageServer.fs

> Pipeline role: The F# Language Server Protocol implementation. A `NewtonsoftLanguageServer<FSharpRequestContext>` subclass built on the `Microsoft.CommonLanguageServerProtocol.Framework`, wiring up the DI container (`ConstructLspServices`) with the workspace, request context factory, initialize/capabilities managers, lifecycle manager, and the handler classes; static `Create` helpers additionally construct the named-pipe/full-duplex transport for in-proc hosting.
> Namespace: `FSharp.Compiler.LanguageServer` (line 1).

---

## `[<AutoOpen>] module Stuff` (line 20)

- `[<Literal>] let FSharpLanguageName = "F#"` — the language name registered on `LanguageServerEndpoint` attributes.

## `[<Extension>] type Extensions` (line 25)

- `[<Extension>] static member Please(this: Async<'t>, ct)` — `Async.StartAsTask(this, cancellationToken = ct)` convenience.

## `type FSharpLanguageServer(jsonRpc, logger, ?initialWorkspace, ?addExtraHandlers, ?config)` (line 32)

- Inherits `NewtonsoftLanguageServer<FSharpRequestContext>` ("TODO: Switch to SystemTextJsonLanguageServer").
- Ctor defaults: `config = FSharpLanguageServerConfig.Default`, `initialWorkspace = FSharpWorkspace()`; then `base.Initialize()` (spins up the request queue — comment: "This spins up the queue and ensure the LSP is ready to start receiving requests").
- `member JsonRpc: JsonRpc`.
- `override ConstructLspServices()` — `ServiceCollection` with:
  - singletons: `initialWorkspace`, `ContextHolder`, `FSharpLanguageServerConfig`, `this` (the server), `ILspLogger`.
  - `IMethodHandler` handlers: `InitializeHandler<InitializeParams, InitializeResult, ...>`, `InitializedHandler<..., ...>`, `DocumentStateHandler`, `LanguageFeaturesHandler`.
  - `AbstractRequestContextFactory<FSharpRequestContext>` → `FShapRequestContextFactory`; `IInitializeManager<InitializeParams, InitializeResult>` → `CapabilitiesManager`; `ILifeCycleManager` → `LspServiceLifeCycleManager`.
  - optional `addExtraHandlers` hook (used by hosting code to register extra LSP methods/services).
  - wraps as `FSharpLspServices :> ILspServices`.
- `static member Create()` / `Create(initialWorkspace)` / `Create(initialWorkspace, addExtraHandlers)` / `Create(initialWorkspace, config, addExtraHandlers)` / `Create(logger, initialWorkspace, ...)` — creates an in-proc server **and** the transport: `FullDuplexStream.CreatePair()`, `JsonMessageFormatter`, `HeaderDelimitedMessageHandler`, `JsonRpc` with a `TextWriterTraceListener(Console.Out)` at `SourceLevels.All`; returns `(clientStream, server)` for the host to talk through.

---

## Related

- Uses `FSharp.Compiler.CodeAnalysis.Workspace.FSharpWorkspace` and the `Common/` + `Handlers/` files; consumed by `Executable.fs` and by IDE host code (see `vsintegration` FSharp.Editor LSP host).
# FSharpLanguageServerProvider.cs

## Pipeline role
Core wiring of the VS extension: constructs the in-process F# LSP server, adapts the
VisualStudio.LanguageServer.Protocol types to the `FSharp.Compiler.LanguageServer` host,
and pipes the server's JSON-RPC over an in-memory stream while teaching the compiler's
FSharpChecker how the server attaches.

## Key content
- `VsServerCapabilitiesOverride : IServerCapabilities...` — internal override/adapter so
  the LSP `ServerCapabilities` reported by the F# server are compatible with the VS LSP
  client expectations.
- `FSharpLanguageServerProvider` (a `LanguageServer`-adjacent class):
  - `CreateServerConnectionAsync` (the VS Extensibility entrypoint the LSP client calls)
    —
    - grabs the current project via `ProjectSystem.Query` (`AggregateQuery`/`Workspace`) to
      derive `projectManager` + strings;
    - builds the in-process `FSharpLanguageServer` over the `FSharpChecker` and the
      `ILanguageVersion`-aware `LanguageServerProtocol` facade;
    - negotiates `ServerCapabilities` (alias override), `ServerSettings` (`compilerOptions`
      feed from the project's `.fsproj` args where available);
    - opens an in-memory duplex stream (Nerdbank-Streams `FullDuplexStream`), registers a
      callback so the server raises `NotificationActivity`, then returns the
      `Connection.ConnectAsync` task so VS drives JSON-RPC over that stream.
  - `ShouldBrokerInitialize` / `CreateBrokerAsync`-style predicate respecting the
    `FSharpExtensionSettings` (OLD/LSP/BOTH) choices for diagnostics and semantic
    highlighting.
- Uses `Microsoft.FSharp.Compiler` interop points (FSharpOption/String-valued config) and
  the `FSharp.Compiler.LanguageServer` internal API (`InternalsVisibleTo`).

## Role
The bridge that makes the language server work as a VS "language service" while preserving
the ability to run standalone (dotnet LSP host).
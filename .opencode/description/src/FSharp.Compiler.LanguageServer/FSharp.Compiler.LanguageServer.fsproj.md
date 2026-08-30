# FSharp.Compiler.LanguageServer.fsproj

## Pipeline role
Builds the F# Language Server Protocol host executable (`FSharp.Compiler.LanguageServer`,
net8.0) — the standalone, SDK-independent F# LSP server used by the VS extension and
available as a general F# language server.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Exe`; `TargetFramework=net8.0`; `CheckNulls=true` and
  `Nullable=enable`.

## Packages
- `Microsoft.Extensions.DependencyInjection` (pinned 8.0.0 via VersionOverride to keep the
  net8 host DI in line with the LSP framework baseline — central 10.0.0 only needed by
  consumers pulling DI >= 10 transitively).
- `Microsoft.VisualStudio.LanguageServer.Protocol`, `Microsoft.VisualStudio.Threading`
  (17.12.21 pin), `StreamJsonRpc` (2.26.10 explicit pin).

## Compile items
- Shares `CancellableTasks.fs` from `vsintegration\src\FSharp.Editor\Common`.
- `Utils.fs`, `FSharpLanguageServerConfig.fs` (feature toggles: diagnostics, semantic
  highlighting), `Common\LifecycleManager.fs`, `Common\CapabilitiesManager.fs`,
  `Common\FSharpRequestContext.fs`, `Handlers\LanguageFeaturesHandler.fs`,
  `Handlers\DocumentStateHandler.fs`, `FSharpLanguageServer.fs` (server construction /
  LSP endpoint wiring over FSharpChecker + FSharpWorkspace), `Executable.fs` (main).
- `InternalsVisibleTo FSharp.VisualStudio.Extension`.

## References
- ProjectReferences: `..\Compiler\FSharp.Compiler.Service.fsproj` and
  `..\Microsoft.CommonLanguageServerProtocol.Framework.Proxy\*.csproj`.
- FSharp.Core project reference (or package when `FSHARPCORE_USE_PACKAGE=true`).
- NuspecProperty tokens forward FSharp.Core dependency versions for repack.

## Output
`FSharp.Compiler.LanguageServer[.exe/.dll]` — the LSP server binary; the VSIX spins it up
through `FSharpLanguageServerProvider.CreateServerConnectionAsync`.
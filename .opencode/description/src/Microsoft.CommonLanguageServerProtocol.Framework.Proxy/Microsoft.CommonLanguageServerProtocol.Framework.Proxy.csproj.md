# Microsoft.CommonLanguageServerProtocol.Framework.Proxy.csproj

## Pipeline role
A small C# shim that proxies/up-lifts the `Microsoft.CommonLanguageServerProtocol.Framework`
package to the version FSharp.Compiler.LanguageServer expects, keeping the F# LSP host
(and the VS extension that embeds it) pinned to compatible Newtonsoft-Json/MessagePack
baselines.

## Project type / frameworks
- `Microsoft.NET.Sdk`, C#; `TargetFramework=net8.0`; `ImplicitUsings=enable`;
  `Nullable=enable`.

## PackageReferences
- `Microsoft.CommonLanguageServerProtocol.Framework` with `PrivateAssets=all` (the package
  itself is <see>ed through); `GeneratePathProperty=true`.
- `MessagePack` (PrivateAssets) — pinned to a version compatible with the LSP framework's
  dependency; comment notes it is pinned to avoid NU1902/NU1903 (known-vulnerable
  transitive MessagePack), so this project effectively force-pins MessagePack for the
  whole LSP server graph.
- `Microsoft.VisualStudio.Threading` 17.12.21 (PrivateAssets).

## IVTs
- `InternalsVisibleTo` `FSharp.Compiler.LanguageServer` and
  `FSharp.VisualStudio.Extension`.

## Role in the tree
Referenced (ProjectReference + ReferenceOutputAssembly) by
`FSharp.Compiler.LanguageServer.fsproj`, supplying the typed
`LanguageServerProtocol`/`LSPRequestMessage` machinery the F# server inherits, isolated
from the VS product's version of the framework.
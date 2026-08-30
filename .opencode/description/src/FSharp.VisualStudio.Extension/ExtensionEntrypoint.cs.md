# ExtensionEntrypoint.cs

## Pipeline role
Entry point class of the `FSharp.VisualStudio.Extension` Visual Studio (VisualStudio.Extensibility
SDK) extension — the C# `[VisualStudioContribution]` extension root.

## Details
- `internal class ExtensionEntrypoint : Extension` (Microsoft.VisualStudio.Extensibility).
- `ExtensionConfiguration` metadata:
  - id `FSharp.VisualStudio.Extension.4fd40904-7bdd-40b0-82ab-588cbee624d1`
  - version `this.ExtensionAssemblyVersion`
  - `publisherName "Publisher name"`, `displayName "FSharp.VisualStudio.Extension"`,
    `description "Extension description"` — placeholder strings (the real display text is
    supplied via `.vsextension\string-resources.json` / VSIX localization).
- Overrides `InitializeServices` to configure dependency injection for the extension
  (currently just calls `base` — no extra services registered here).

## Role in the VSIX
Provides the extension identity/activation entrypoint; the actual language server wiring
lives in `FSharpLanguageServerProvider`, which `CreateServerConnectionAsync` starts in-
process (the extension packs `FSharp.Compiler.LanguageServer` resources).
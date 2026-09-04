# string-resources.json

## Pipeline role
Localized (English) resource strings for the `FSharp.VisualStudio.Extension` VSIX; consumed
by the VS Extensibility SDK resource manager to resolve the `%...%` placeholders used in
settings/diagnostics plumbing (and VSIX manifest display names).

## Content
Single entry:
```json
{
  "FSharpLspExtension.FSharpLanguageServerProvider.DisplayName": "FSharp Analyzer LSP server"
}
```

## Format / consumption
- Written in **camelCase** matching the C# class/field: the provider's `DisplayName` used
  by the LSP client UI is `"FSharp Analyzer LSP server"`.
- Localization: translations live alongside in `.vsextension\<culture>\string-resources.*`
  xlf tables; this file is the invariant (en) source. The extension startup `InitializeServices`
  attaches the resource manager so `FSharpExtensionSettings` `%FSharpSettings...%` tokens
  resolve against this payload.
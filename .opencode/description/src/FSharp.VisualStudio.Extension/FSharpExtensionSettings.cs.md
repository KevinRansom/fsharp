# FSharpExtensionSettings.cs

## Pipeline role
Defines the user-facing Visual Studio settings (via the VS Extensibility SDK's
`SettingsGroup[ExtensionEntrypoint]`) that toggle which F# "language features" are served
by the extension: classic (old OM) vs LSP server.

## Key content
- Constants: `OLD = "old"` (legacy FSharp.Editor/classic behavior), `LSP = "lsp"`, `BOTH =
  "both"`, `UNSET = "unset"`.
- `EnumSettingEntry[] ExtensionChoice` — one entry each for OLD/LSP/BOTH (display names
  resolved from localized `%FSharpSettings.%(...)%` resource strings) with description
  `%FSharpSettings.(includeFSharpExtensionsPlease)%`.
- `SettingCategory FSharpCategory = new SettingCategory("fsharp")` — the settings root
  under Options > F#.
- Two `EnumSetting<T>`s in the `fsharp` category:
  - `GetDiagnosticsFrom` — `FSharpSettings.GetDiagnosticsFrom` choosing OLD/LSP/BOTH,
    default derived via `FSharpExtensionLogic`/`FSharpSettings.UpdateSettings` logic; text
    `%FSharpSettings.GetDiagnosticsFrom_Description%` etc.
  - `GetSemanticHighlightingFrom` — analogous toggling semantic token painting between
    classic and LSP.
- Localization: all display/description strings route through `%...%` placeholders resolved
  by `.vsextension\string-resources.json`/xlf+VS resource manager, NOT hardcoded English.

## Role
The runtime gate the F# language server provider reads to decide whether to instantiate and
advise the LSP server or fall back to classic behavior; plumbing lives in
`FSharpLanguageServerProvider`.
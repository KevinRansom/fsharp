# FSharpLanguageServerConfig.fs

> Pipeline role: Configuration record types for the F# language server — feature toggling (diagnostics, semantic highlighting) consumed by `CapabilitiesManager` and `FSharpLanguageServer`.
> Namespace: `FSharp.Compiler.LanguageServer` (line 1).

---

## `type FSharpLanguageServerFeatures` (line 3)

- `{ Diagnostics: bool; SemanticHighlighting: bool }`
- `static member Default = { Diagnostics = true; SemanticHighlighting = true }`

## `type FSharpLanguageServerConfig` (line 15)

- `{ EnabledFeatures: FSharpLanguageServerFeatures }`
- `static member Default = { EnabledFeatures = FSharpLanguageServerFeatures.Default }`

---

## Related

- Read by `CapabilitiesManager` (`addIf config.EnabledFeatures...`); overridable per-host via `IServerCapabilitiesOverride`.
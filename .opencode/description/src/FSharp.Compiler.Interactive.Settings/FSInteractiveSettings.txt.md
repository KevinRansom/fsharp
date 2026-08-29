# FSInteractiveSettings.txt

## Pipeline role
String table for `FSharp.Compiler.Interactive.Settings` — but currently contains only a
header comment and **no entries**:

`# FS Interactive.Settings resource strings`

## Format / consumption
- Standard `id=value` (here: empty) string-table format. The build's
  `FSharpEmbedResourceText` task still generates a `.resources` satellite and a typed
  accessor module; because the generated boilerplate includes a `GetStringFunc` that is
  never referenced, the project sets `TolerateUnusedBindings=true` so the unused binding
  warning does not fail the build.
- Sentinel exists so the resource pipeline/system has an FSInteractiveSettings resource
  registered for localization (xlf), even though no strings are defined today.
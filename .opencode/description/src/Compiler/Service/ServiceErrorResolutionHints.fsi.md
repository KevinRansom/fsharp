# ServiceErrorResolutionHints.fsi

**Signature for `ServiceErrorResolutionHints.fs`.** Declares the public name-suggestion entry point for the FSharp.Compiler.Service diagnostics layer.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. Exposes the string-distance (edit distance) algorithm used to suggest plausible names for a mistyped/unresolved identifier, e.g. as part of error quick-fixes displayed by editors.

## Namespace

- `FSharp.Compiler.Diagnostics`

## Public module

- `module ErrorResolutionHints`:
  - `val GetSuggestedNames: suggestionsF: ((string -> unit) -> unit) -> unresolvedIdentifier: string -> seq<string>` — given a set of candidate names (fed through the `suggestionsF` callback) and an unresolved identifier string, returns the list of feasible suggested names.

## Relation to .fs

The matching `ServiceErrorResolutionHints.fs` body contains only the module declaration; the implementation is imported from `FSharp.Compiler.ErrorResolutionHints` (which is opened in the `.fs`). The signature guarantees consumers see exactly one function.
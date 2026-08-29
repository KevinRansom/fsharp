# ServiceErrorResolutionHints.fs

Thin re-export shim: the `ErrorResolutionHints` module in `FSharp.Compiler.Diagnostics` re-exposes the edit-distance name-suggestion algorithm that lives in the underlying `FSharp.Compiler.ErrorResolutionHints` library.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. The `FSharp.Compiler.Diagnostics` namespace already provides `CompilerDiagnostics.GetSuggestedNames`; this module is the public, reusable surface for the same capability, keeping the string-distance implementation centralized in `FSharp.Compiler.ErrorResolutionHints`.

## Namespace

- `FSharp.Compiler.Diagnostics` (with `open FSharp.Compiler.ErrorResolutionHints`).

## Module

- `module ErrorResolutionHints` — empty body; the `open FSharp.Compiler.ErrorResolutionHints` makes `GetSuggestedNames: ((string -> unit) -> unit) -> string -> seq<string>` (see the .fsi) resolvable, so the module effectively forwards to:
  - `val GetSuggestedNames: suggestionsF: ((string -> unit) -> unit) -> unresolvedIdentifier: string -> seq<string>` — returns feasible candidate spellings within the edit-distance threshold of the unresolved identifier.

## Notes

- Functional sugar used elsewhere: `ServiceCompilerDiagnostics.GetSuggestedNames` composes this same buffer-based logic for diagnostics, while this file provides the direct public entry point.
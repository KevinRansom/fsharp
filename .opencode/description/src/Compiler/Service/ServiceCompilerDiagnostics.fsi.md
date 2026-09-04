# ServiceCompilerDiagnostics.fsi

**Signature for `ServiceCompilerDiagnostics.fs`.** Small API surface in the `FSharp.Compiler.Diagnostics` namespace of the FSharp.Compiler.Service: turns a `FSharpDiagnosticKind` into a human-readable error message, and computes suggested alternative names for mistyped identifiers.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. Editors receive structured diagnostics (e.g. the "add indexer dot" hint or "replace with suggestion" fixes) as a `FSharpDiagnosticKind`; this service formats those into localized strings via `FSComp.SR`, and provides the edit-distance-based name-suggestion mechanism (backed by `SuggestionBuffer` from `FSharp.Compiler.DiagnosticResolutionHints`) used by quick fixes such as "did you mean X?".

## Namespaces

- `FSharp.Compiler.Diagnostics`

## Public types / modules

- `type FSharpDiagnosticKind` (`[<RequireQualifiedAccess>]`) — the kinds of diagnostics this service supports:
  - `AddIndexerDot` — hint to insert a '.' before array indexer.
  - `ReplaceWithSuggestion of suggestion: string` — replace the offending token with a suggestion.
  - `RemoveIndexerDot` — hint to remove a now-unnecessary indexer dot.
- `module CompilerDiagnostics` (`[<RequireQualifiedAccess>]`):
  - `val GetErrorMessage: diagnosticKind: FSharpDiagnosticKind -> string` — the localized error text for the given kind.
  - `val GetSuggestedNames: suggestionsF: ((string -> unit) -> unit) -> unresolvedIdentifier: string -> seq<string>` — feeding candidate names through `suggestionsF`, returns feasible suggested names if the edit-distance buffer is enabled.

## Relation to .fs

The signature exposes the same three cases of `FSharpDiagnosticKind` and the two functions; the matching `.fs` additionally opens `FSharp.Compiler.DiagnosticResolutionHints` and implements `GetSuggestedNames` using a `SuggestionBuffer` (constructed once, disabled-aware), threading the unresolved identifier and dropping disabled buffers to `Seq.empty`.
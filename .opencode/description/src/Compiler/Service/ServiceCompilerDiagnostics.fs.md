# ServiceCompilerDiagnostics.fs

Implementation of diagnostic-message formatting and identifier-suggestion generation for the FSharp.Compiler.Service.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling (`FSharp.Compiler.Diagnostics`). Converts the structured `FSharpDiagnosticKind` delivered to editors into localized error strings (`FSComp.SR` resources), and implements name suggestions for "did you mean …?" scenarios using the `SuggestionBuffer` (Damerau–Levenshtein edit-distance buffer) from `FSharp.Compiler.DiagnosticResolutionHints`.

## Namespaces

- `FSharp.Compiler.Diagnostics` (with `open FSharp.Compiler.DiagnosticResolutionHints`).

## `FSharpDiagnosticKind` (`[<RequireQualifiedAccess>]` union)

- `AddIndexerDot` — "use '.' ... indexer" hint.
- `ReplaceWithSuggestion of suggestion: string`
- `RemoveIndexerDot` — reported when the indexer dot `.[i]` syntax is deprecated (see `FSComp.SR.tcIndexNotationDeprecated`).

## Module `CompilerDiagnostics` (`[<RequireQualifiedAccess>]`)

- `GetErrorMessage diagnosticKind : string`
  - `AddIndexerDot` → `FSComp.SR.addIndexerDot ()`.
  - `ReplaceWithSuggestion s` → `FSComp.SR.replaceWithSuggestion s`.
  - `RemoveIndexerDot` → `(FSComp.SR.tcIndexNotationDeprecated () |> snd).Text` — note the tuple discard + `.Text` (PhaseDiagnostic handling).
- `GetSuggestedNames (suggestionsF: FSharp.Compiler.DiagnosticsLogger.Suggestions) (unresolvedIdentifier: string) : seq<string>`
  - Creates `SuggestionBuffer(unresolvedIdentifier)`.
  - If `buffer.Disabled` → `Seq.empty`.
  - Otherwise feeds all candidate names through `suggestionsF buffer.Add` and returns the buffer as a `seq<string>` of suggested names within the distance threshold.

## Internal logic notes

- `Suggestions` is a function type `(string -> unit) -> unit` from `FSharp.Compiler.DiagnosticsLogger`, letting diagnostics infrastructure push candidate identifiers into the buffer.
- The buffer implements an edit-distance threshold so only *feasible* candidates are returned.
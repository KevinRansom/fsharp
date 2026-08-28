# ServiceCompilerDiagnostics

**Purpose:** Thin service-layer surface exposing compiler diagnostic string messages and identifier "did you mean" suggestions to F# language service consumers. Builds on `FSharp.Compiler.DiagnosticResolutionHints.SuggestionBuffer` for generating candidate names for unresolved identifiers.

**Namespace(s):** `FSharp.Compiler.Diagnostics`

## Declared types / modules
- `FSharpDiagnosticKind` (enum union, `RequireQualifiedAccess`): kinds of service diagnostics — `AddIndexerDot`, `ReplaceWithSuggestion of string`, `RemoveIndexerDot`.
- `CompilerDiagnostics` (module, `RequireQualifiedAccess`): exposes error messages and name suggestions for diagnostics.

## Public API surface
- `CompilerDiagnostics.GetErrorMessage : FSharpDiagnosticKind -> string` — maps a diagnostic kind to its localized message text (via `FSComp.SR` resource strings, e.g. `addIndexerDot`, `replaceWithSuggestion`, `tcIndexNotationDeprecated`).
- `CompilerDiagnostics.GetSuggestedNames : (Suggestions -> unit) -> string -> seq<string>` — given a suggestion collector and an unresolved identifier, returns candidate replacement names.
- The `.fsi` contract mirrors these two functions plus the `FSharpDiagnosticKind` definition, documented as "Supported kinds of diagnostics by this service".

## Internal helpers / notable details
- `GetSuggestedNames` wraps the identifier in a `DiagnosticResolutionHints.SuggestionBuffer`; if the buffer reports `Disabled` (no feasible candidates), returns `Seq.empty`, otherwise invokes the provided `suggestionsF buffer.Add` collector function and exposes the buffer as `seq<string>`.

## Significant internal logic
- `ReplaceWithSuggestion` messages embed the suggestion into the string; `RemoveIndexerDot` extracts the `.Text` from the `snd` component of the deprecated-indexer-notation resource tuple.
- No file-scoping or line filtering is done here; that lives in the main `FSharpCheckerResults`/`service` diagnostic plumbing (see `Service/ServiceCompilerDiagnostics.fsi` for the exact surface and `src/Compiler/ErrorResolutionHints.fs` for the SuggestionBuffer implementation).

## Cross-references
- `src/Compiler/DiagnosticResolutionHints.fs` (SuggestionBuffer, name-distance algorithm)
- `src/Compiler/Service/service.fs` / `FSharpCheckerResults.fs` (diagnostic model, `FSharpErrorInfo`)
- `src/Compiler/Service/ServiceErrorResolutionHints.fs` (adjacent suggestion-hints surface)

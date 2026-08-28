# DiagnosticResolutionHints.fsi

**Purpose**: The contract for `DiagnosticResolutionHints.fs`: declares the two free functions for candidate filtering and the `SuggestionBuffer` type that accumulates "did you mean?" suggestions for a diagnostic.

**Namespace(s)**: module `FSharp.Compiler.DiagnosticResolutionHints` (internal)

**Modules / TypeDefs declared**:
- `val IsInEditDistanceProximity: idText * suggestion -> bool` — "report a candidate if its edit distance is <= the threshold (about a quarter of the number of characters)"
- `val DemangleOperator: nm: string -> string` — "Demangles a suggestion"
- `type SuggestionBuffer`: `new: idText: string -> SuggestionBuffer`, `Add: string -> unit`, `Disabled: bool`, `IsEmpty: bool`, implements both `IEnumerable` and `IEnumerable<string>`

**Contract notes**:
- The .fsi hides the tuning thresholds (`maxSuggestions`, similarity thresholds) and the `SuggestionBufferEnumerator` — implementation detail only
- Callers create a buffer for an identifier, `Add` candidates from the environment, then enumerate up to 5 accepted suggestions

**Cross-references**: Implements DiagnosticResolutionHints.fs; used by the checker's resolution-error reporting; related to DiagnosticsLogger for where hints are attached to diagnostics.

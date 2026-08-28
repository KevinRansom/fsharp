# DiagnosticResolutionHints.fs

**Purpose**: Implements the "did you mean?" suggestion engine behind diagnostic resolution hints. A `SuggestionBuffer` for a given identifier accumulates candidate identifiers, scoring them with Jaro-Winkler similarity plus an edit-distance proximity gate, so tooling can surface up to 5 plausible intended symbols.

**Namespace(s)**: module `FSharp.Compiler.DiagnosticResolutionHints` (internal)

**Modules / TypeDefs / Classes declared**:
- `module internal FSharp.Compiler.DiagnosticResolutionHints`
  - Tuning constants: `maxSuggestions=5`, `minThresholdForSuggestions=0.7`, `highConfidenceThreshold=0.85`, `minStringLengthForSuggestion=3`
  - `SuggestionBufferEnumerator` (class): reverse-order `IEnumerator<string>` over the fixed-size suggestion array
  - `SuggestionBuffer` (class): the accumulating suggestion buffer

**Public API surface** (per .fsi, internal):
- `IsInEditDistanceProximity: string * string -> bool`
- `DemangleOperator: string -> string`
- `SuggestionBuffer`: `new: idText -> SuggestionBuffer`, `Add: string -> unit`, `Disabled: bool`, `IsEmpty: bool`, `IEnumerable<string>` / `IEnumerable`

**Significant internal logic**:
- `IsInEditDistanceProximity`: threshold ≈ length/4 (+1), with short names (len<5 → 1, <7 → 2); uses `EditDistance.CalculateEditDistance`
- `Add` accepts a candidate only if Jaro-Winkler similarity ≥ 0.85, or it ends with "."+idText (namespace prefix case), or similarity ≥ 0.7 AND in edit-distance proximity; names starting with `_` are excluded (they squelch FS1182); if a suggestion equals the id itself, all suggestions are disabled (means a genuine parse error elsewhere)
- Insertion maintains a sorted (by similarity) fixed array `maxSuggestions` slots with a `tail` pointer — an O(n) insertion sort on a 5-slot buffer
- `DemangleOperator` strips the `( ... )` wrapping of operator-escaped names before comparison
- Case-insensitive comparison via uppercasing both sides

**Cross-references**: Uses `EditDistance` (internal utilities); results feed F# tooling diagnostics; rendered by DiagnosticsLogger/RichText output layers.

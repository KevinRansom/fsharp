# EditDistance.fsi

**Purpose**: Signature file for `EditDistance.fs` (same directory). Documents the public contract of the internal string-similarity module used for name-similarity scoring ("did you mean" style) in the compiler.

**Namespace(s)** declared: `Internal.Utilities.EditDistance` (declared `module internal`).

**Declared items** (public contract):
- `JaroWinklerDistance: s1: string -> s2: string -> float` — "Jaro-Winkler edit distance"; similarity metric, 0..1.
- `CalculateEditDistance: a: string * b: string -> int` — edit distance; the number of edit operations (insert, delete, substitution) needed to transform one string into the other.

**Relationship to .fs**: The .fs additionally implements the private pieces — `existsInWin` (windowed char search), the Jaro algorithm itself, and `calcDamerauLevenshtein` (restricted Damerau-Levenshtein DP) — which support the two public functions. No other types or public functions exist in the file.

**Cross-references**: see sibling `EditDistance.md`.

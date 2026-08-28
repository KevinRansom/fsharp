# EditDistance.fs

**Purpose**: Internal string-similarity utilities for the compiler, used to score how similar two names are (e.g. "did you mean" style suggestions). Provides both a similarity score (Jaro-Winkler, in [0,1]) and an edit distance (restricted Damerau-Levenshtein / Optimal String Alignment, in integer edit operations). Declared as `module internal Internal.Utilities.EditDistance`; public contract via `EditDistance.fsi`.

**Namespace(s)** declared: `Internal.Utilities.EditDistance` (internal module)

**Modules / Types declared**:
- Only a module of functions; no types.

**Public API surface** (per EditDistance.fsi):
- `JaroWinklerDistance : string -> string -> float` — similarity of two strings; 1.0 = identical.
- `CalculateEditDistance : string * string -> int` — number of edit operations (insert/delete/substitute/adjacent transposition) to transform one string into the other.

**Internal helpers / notable items**:
- `existsInWin: char * string * offset * rad -> bool` — inline check whether a character exists in a window `[offset-rad, offset+rad]` of a string.
- `jaro: string * string -> float` — private Jaro similarity computation using match radius `ceil(minLen/2)`, counting common characters in both directions and transpositions.
- `calcDamerauLevenshtein: string * string -> int` — private DP (two-line rolling arrays `lastLine`/`lastLastLine`/`actLine`) for restricted Damerau-Levenshtein; source credit in comments (Wikipedia / navision-blog).

**Significant internal logic**:
- Jaro: for each string, scans for matching chars within `matchRadius = minLen/2 + minLen%2`; similarity is `1/3 * (c1/|s1| + c2/|s2| + (c - t)/c)`; NaN (empty-string cases) returns 0.0.
- Jaro-Winkler: adds prefix bonus `l * p * (1 - jaro)` where `l` = number of matching leading characters capped at 4, and `p = 0.1`.
- `CalculateEditDistance` calls `calcDamerauLevenshtein` with the longer string first so that the first dimension iterates over the larger string (the transposition check uses `lastLastLine[j-2]`, requiring i and j offsets into `a`/`b` consistently).
- Performance note: `jaro` here is an O(n²)-ish recursive implementation (not the common optimized table version); fine for short identifiers.

**Cross-references**: `EditDistance.fsi` is its companion signature file; sibling utility files in `src/Compiler/Utilities/` (e.g. `lib.fs`) may call these for suggestion generation.

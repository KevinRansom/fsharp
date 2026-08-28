# PathMap.fs

**Purpose**: Implementation of a path-mapping table used to rewrite real filesystem paths into the paths that will be written into PDBs/IL metadata (e.g. the `--sourcelink`/path-mapping feature of FSI and the compiler). Given a user-specified mapping such as `/goo=/bar`, it rewrites file paths so build-machine paths do not leak into shipped artifacts.

**Namespace(s)**: `Internal.Utilities`

**Modules / Types declared**:

- `type PathMap = PathMap of Map<string, string>` — newtype wrapping a dictionary from source-path prefix (always ending with a directory separator) to replacement-path prefix.
- `module internal PathMap` (`[<RequireQualifiedAccess>]`) — the operations over `PathMap`.

**Public API surface** (all internal, qualified access):

- `empty : PathMap` — the empty mapping.
- `addMapping (src: string) (dst: string) (PathMap map) : PathMap` — normalizes `src` with `FileSystem.GetFullPathShim`, forces a trailing directory separator on the prefix, and inserts/updates the mapping.
- `apply (PathMap map) (filePath: string) : string` — finds the first mapping prefix that `filePath` starts with (ordinal, case-sensitive) and splices the replacement prefix in place, preserving the suffix.
- `applyDir (PathMap pathMap) (dirName: string) : string` — like `apply` but for directory names; ensures a trailing separator is present for matching and trims any separator added by the replacement back off.

**Internal helpers**:

- `dirSepStr` — the platform directory-separator string, used for prefix normalization.

**Significant internal logic**:

- `apply` replicates the behavior of C#'s `PathUtilities.NormalizePathPrefix`: because every stored key ends with a directory separator, a prefix match can never be a spurious partial match (e.g. map `/goo=/bar` does not apply to `/goooo`).
- After splicing, the function normalizes separator style: if the replacement prefix uniformly uses `/` the result's `\` are converted to `/`, and vice versa — matching the mixed backslash/forward-slash conventions accepted in path mappings.
- Matching is ordinal (case-sensitive) with the expectation that callers pass consistently-cased paths.
- Note that key lookups are done with `Map.tryPick` over all entries, not a longest-prefix search.

**Cross-references**: Uses `Internal.Utilities.Library` (from `lib.fs`) for `GetFullPathShim`/`StartsWithOrdinal`-style helpers, and `FSharp.Compiler.IO` (`FileSystem.GetFullPathShim`). Consumers include F# Interactive's `--pathmap` handling and PDB/IL metadata emission code that wants to write mapped source paths.

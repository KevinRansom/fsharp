# PathMap.fsi

**Purpose**: Public contract (signature file) for `PathMap.fs`, exposing the internal `PathMap` type and its module to the rest of the compiler while hiding the wrapping `Map<string, string>` representation. The .fsi also documents the case-sensitivity guarantee of the prefix matching.

**Namespace(s)**: `Internal.Utilities`

**Modules / Types declared**:

- `type internal PathMap` — opaque type alias; implementation in `PathMap.fs` is `PathMap of Map<string, string>`.
- `module internal PathMap` (`[<RequireQualifiedAccess>]`) — signatures for the path-mapping operations.

**Public API surface** (all internal):

- `val empty: PathMap`
- `val addMapping: string -> string -> PathMap -> PathMap` — doc-commented: "Add a path mapping to the map."
- `val apply: PathMap -> string -> string` — doc-commented: "Map a file path with its replacement. Prefixes are compared case sensitively."
- `val applyDir: PathMap -> string -> string` — doc-commented: "Map a directory name with its replacement. Prefixes are compared case sensitively."

**Internal helpers**: None; the .fsi declares no additional members beyond the four documented values.

**Significant internal logic**: The .fsi intentionally omits all internal helpers (`dirSepStr`) and the structural representation of `PathMap`. It guarantees to consumers that `PathMap` is an opaque value: the module functions are the only way to construct or use one, and that prefix matching is case-sensitive (ordinal).

**Cross-references**: Companion implementation file `PathMap.fs` in the same directory (`src/Compiler/Utilities/`). Both files share the `// Functions to map real paths to paths to be written to PDB/IL` header comment, tying this module to sourcelink/path-mapping features of the compiler and F# Interactive.

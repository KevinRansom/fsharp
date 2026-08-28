# TrieMapping.fs

**Purpose**: Builds a Trie of the declared namespaces/modules of every file in a project (in parallel), where each Trie node records which files define that namespace/module and whether they expose types (affects dependency resolution). Used by `DependencyResolution` as the index that maps long identifiers back to files — the core data structure for incremental resolution in the graph-checking architecture.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (module `internal TrieMapping`)

**Public API surface** (per the .fsi):
- `val mkTrie: files: FileInProject array -> (FileIndex * TrieNode) array` — process all files (in parallel) to construct a prefix of Tries; the last element contains the fully merged Trie. Skips the last file (never looked up) and, when multiple files, processes only `files.Length - 1` entries, accumulating via `Array.scan` with `mergeTrieNodes`.
- `val serializeToMermaid: path: string -> filesInProject: FileInProject array -> trie: TrieNode -> unit` — write a Mermaid `classDiagram` visualization of the Trie to `path` (debugging aid).

**Internal helpers**:
- `module private ImmutableHashSet` — `singleton` and `empty` convenience constructors.
- `isAnyAttributeAutoOpen` — checks for `[<AutoOpen>]` via `findSynAttribute`.
- `doesFileExposeContentToTheRoot` — detects files that expose content at the global namespace root (e.g. `namespace global`, or `[<AutoOpen>]` on a single-segment module); such files are added to the root `TrieNodeInfo.Root` set.
- `mergeTrieNodes` — recursive structural merge of two Tries, combining file sets; handles edge cases such as module/namespace collisions (promotes to `Namespace`; see dotnet/fsharp#15985) and multiple files defining the same module name.
- `mkImmutableDictFromKeyValuePairs`, `mkSingletonDict` — small `ImmutableDictionary` builders.
- `processSynModuleOrNamespace<'Decl>` — walks a `SynModuleOrNamespace(Sig)` declaration, producing a Trie per declaration: intermediate path segments become `Namespace` nodes, the final segment becomes a `Namespace` or `Module` node depending on `SynModuleOrNamespaceKind`; `[<AutoOpen>]` causes the containing namespace to expose the file (lifting semantics).
- `mkTrieNodeFor` (rec) — builds the per-file Trie from either `ParsedSigFileInput` or `ParsedImplFileInput`, reducing `mergeTrieNodes` over top-level declarations.
- `mkTrieForSynModuleDecl` / `mkTrieForSynModuleSigDecl` — recurse into nested modules (`Module` nodes), collecting their children.
- `type MermaidBoxPos = First | Second` + `serializeToMermaid` — Mermaid class diagram emission with two "boxes" per namespace (types-exposing vs namespace-only files).

**Significant internal logic**:
- The "exposes types" distinction is the crux: a namespace exposes a file as a dependency only if that file defines types (or has `[<AutoOpen>]` nested modules) within it — because only then could type inference implicitly pull in that file. Files that merely *declare* the namespace are tracked separately (`filesDefiningNamespaceWithoutTypes`) for ghost-dependency resolution.
- `mkTrie` returns a per-file *prefix* array `(FileIndex * TrieNode)` so each file's dependency query can use only the Trie of earlier files (no future leaks).
- `[<AutoOpen>]` on a single-segment top-level module also marks the file as root-exposing content (implicit open semantics).

**Cross-references**:
- Types: `TrieNode`, `TrieNodeInfo`, `FileInProject` in `Types.fs`.
- Consumer: `DependencyResolution.fs` (`queryTrie`, `queryTrieDual`, `collectGhostDependencies`).
- `FileContentMapping.fs` complements this by producing `FileContentEntry` lists per file.

# DependencyResolution.fs

**Purpose**: Core algorithm of the new parallel "graph-checking" architecture: from the parsed ASTs of all files in a project it builds an approximate (super) file-dependency graph that the type-checker can then process in parallel. It queries a Trie of file contents (`TrieMapping`) to decide which earlier files a given file must depend on, and adds "ghost" dependencies for opened-but-unused namespaces so the type-checker can resolve them.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (module `internal DependencyResolution`)

**Public API surface**:
- `queryTrie (trie: TrieNode) (path: LongIdentifier) : QueryTrieNodeResult` — find a path in the Trie and classify the result (not exist / expose no data / expose files). Exposed primarily for unit tests.
- `processOpenPath (trie: TrieNode) (path: LongIdentifier) (state: FileContentQueryState) : FileContentQueryState` — process an `open` statement against the state; used directly in unit tests.
- `mkGraph (filePairs: FilePairMap) (files: FileInProject array) : Graph<FileIndex> * TrieNode` — the main entry point: construct the project dependency graph and the final (fully merged) Trie.

**Internal helpers**:
- `queryTriePartial`, `mapNodeToQueryResult` — lower-level trie traversal returning the terminal `TrieNode option`, then mapped into `QueryTrieNodeResult`.
- `queryTrieDual` — path query from two concatenated paths, avoiding list allocation.
- `processNamespaceDeclaration`, `processIdentifier` — update `FileContentQueryState` based on a trie query for a `namespace` decl or a prefixed identifier.
- `processStateEntry` — recursive fold over `FileContentEntry` values (top-level namespaces, open statements, prefixed identifiers, nested modules, module names), threading the `FileContentQueryState`; handles open-statement extension (existing open namespaces + current path) and scoping of open statements inside nested modules.
- `collectGhostDependencies` — for each opened namespace that resolved to no file, find at most one file (with the lowest index < current file) that defines that namespace, so the type-checker can resolve unused `open` targets.

**Significant internal logic**:
- `mkGraph` computes, for each file (in parallel), the Trie built from only the files *before* it (skipping impl files that have a signature), starting from root-level dependencies (all earlier root-exposing files) and folding over the file's `FileContentEntry` list (`FileContentMapping.mkFileContent`).
- Adds edges from an impl file to its signature file (via `FilePairMap.TryGetSignatureIndex`) and from a signature file to a preceding impl file (to enable diagnostic FS0238 "implementation already given").
- The resulting graph is a supergraph (documented in the .fsi), and project file order is used to avoid backwards edges, since the algorithm relies on F#'s ordering rule (definitions must come before use).
- `collectGhostDependencies` special-cases `TrieNodeInfo.Namespace` with `filesDefiningNamespaceWithoutTypes`; skips files after the current one (those would come from another assembly) and skips if already covered by real dependencies.

**Cross-references**:
- Types: `Types.fs` / `Types.fsi` (`TrieNode`, `FileContentEntry`, `FileContentQueryState`, `FilePairMap`, `QueryTrieNodeResult`, `Graph`).
- `TrieMapping.fs` for `mkTrie`; `FileContentMapping.fs` for `mkFileContent`; `Graph.fs` for the graph type.
- Architecture overview: `Docs.md` in the same directory.

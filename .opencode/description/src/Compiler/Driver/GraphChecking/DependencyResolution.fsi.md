# DependencyResolution.fsi

**Purpose**: Public contract (within the compiler) for the dependency-resolution step of the new parallel graph-based checker. It fixes the shape of the dependency graph produced from a set of files, and documents the important invariant that the graph is a *supergraph* of the strictly-necessary dependencies, and that file ordering constrains which edges may appear.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (module `internal DependencyResolution`)

**Public API surface**:
- `val queryTrie: trie: TrieNode -> path: LongIdentifier -> QueryTrieNodeResult` — query a TrieNode for a path; used directly only by unit tests (per the doc comment).
- `val processOpenPath: trie: TrieNode -> path: LongIdentifier -> state: FileContentQueryState -> FileContentQueryState` — process an `open` path found in a `ParsedInput`; also noted as unit-test-only direct usage.
- `val mkGraph: filePairs: FilePairMap -> files: FileInProject array -> Graph<FileIndex> * TrieNode` — construct the approximate file dependency graph and the merged Trie.
  - Parameter `filePairs` maps signature-file index ⇄ implementation-file index and vice versa (see `FilePairMap`).
  - Returns the `Graph<FileIndex>` (edges = "file A depends on file B") and the final `TrieNode`.

**Significant contract notes (doc comments)**:
- The graph is a *supergraph*: if A is needed to type-check B then edge B→A is present; the converse is not guaranteed because the algorithm operates on ASTs alone.
- The algorithm uses the project file order: if B precedes A, there will be no edge B→A. Consequently this function cannot currently suggest a "reasonable" ordering for an unordered file set.

**Cross-references**:
- Implementation: `DependencyResolution.fs`.
- Types used in the signature: `Types.fs` (`TrieNode`, `LongIdentifier`, `QueryTrieNodeResult`, `FileContentQueryState`, `FilePairMap`, `FileInProject`, `Graph<FileIndex>`).

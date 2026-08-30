# TrieMapping.fsi

**Purpose**: Minimal public contract of the Trie-building module for the graph-checking pipeline: build the per-file Trie prefixes from a project's files, and optionally serialize a resulting Trie to a Mermaid diagram for debugging.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (module `internal TrieMapping`)

**Public API surface**:
- `val mkTrie: files: FileInProject array -> (FileIndex * TrieNode) array`
  - Processes all files (in parallel) to construct root prefix Tries. Returns one `TrieNode` per (skipped) file position — the Nth entry is the Trie built from the first N files, so a caller can look up a file against only files that precede it. When the project has signature files, the implementation counterparts are not processed (their role is covered by `FilePairMap` elsewhere).
- `val serializeToMermaid: path: string -> filesInProject: FileInProject array -> trie: TrieNode -> unit`
  - Write a Mermaid class-diagram representation of the trie to `path` (diagnostics/documentation aid only).

**Types referenced**: `FileInProject` and `TrieNode` come from `Types.fs` / `Types.fsi`.

**Notes**:
- All other functions in `TrieMapping.fs` (`mergeTrieNodes`, `processSynModuleOrNamespace`, `mkTrieNodeFor`, `mkTrieForSynModuleDecl/SigDecl`, `doesFileExposeContentToTheRoot`, `isAnyAttributeAutoOpen`, etc.) are implementation details not part of the signature.

**Cross-references**:
- Implementation: `TrieMapping.fs`.
- Consumer: `DependencyResolution.fs`.
- Related: `Graph.fs` (visualization via Mermaid as well), `Docs.md`.

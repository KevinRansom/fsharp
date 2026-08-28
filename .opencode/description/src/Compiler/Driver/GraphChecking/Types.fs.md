# Types.fs

**Purpose**: Shared type definitions for the graph-based parallel checker: file/identifier aliases, the Trie node model, the summary of "significant constructs" in a file (`FileContentEntry`), the mutable query state threaded through dependency resolution, and the `FilePairMap` helper for matching signature files with their implementation counterparts (needed for diagnostics like FS0238).

**Namespace(s)**: `FSharp.Compiler.GraphChecking`

**Type aliases**:
- `FileIndex = int` — index of a file within a project.
- `FileName = string` — captured from `ParsedInput.FileName`.
- `Identifier = string` — one identifier (e.g. `Hello` in `module Hello`).
- `LongIdentifier = string list` — one or more identifiers (e.g. `X.Y.Z` in `open X.Y.Z`).

**Records / unions / classes**:
- `FileInProject` — record: `Idx`, `FileName`, `ParsedInput`; member `IsScript` (true only for `ImplFile` with `IsScript`).
- `TrieNodeInfo` — union: `Root of ImmutableHashSet<FileIndex>`; `Module of name * file`; `Namespace of name * filesThatExposeTypes * filesDefiningNamespaceWithoutTypes`; member `Files` flattens to a `Set<FileIndex>`. Captures the subtle module-vs-namespace distinction (namespaces only expose files when they contain inferable types or AutoOpen content).
- `TrieNode` — record: `Current: TrieNodeInfo`, `Children: ImmutableDictionary<Identifier, TrieNode>`; member `Files`; `static member Empty`.
- `FileContentEntry` — union (`RequireQualifiedAccess`, no equality/comparison): `TopLevelNamespace of path * content list`, `OpenStatement of path`, `PrefixedIdentifier of path`, `NestedModule of name * content list`, `ModuleName of name`.
- `FileContent` — record: `FileName`, `Idx`, `Content: FileContentEntry array`.
- `FileContentQueryState` — mutable-by-copy state: `OwnNamespace`, `OpenedNamespaces`, `FoundDependencies`; `static member Create(filesAtRoot)`; members `AddOwnNamespace(?files)`, `AddDependencies`, `AddOpenNamespace(?files)`, computed `OpenNamespaces` (own + opened).
- `QueryTrieNodeResult` — union: `NodeDoesNotExist` / `NodeDoesNotExposeData` / `NodeExposesData of Set<FileIndex>`.
- `QueryTrie` — function type `LongIdentifier -> QueryTrieNodeResult`.
- `FilePairMap` — class over `FileInProject array`; bidirectional sig↔impl index maps built by name matching (sig name = impl + `.fsi`), preferring the immediately-following file; members `GetSignatureIndex`, `GetImplementationIndex`, `HasSignature`, `TryGetSignatureIndex`, `IsSignature`, and `TryGetOutOfOrderImplementationIndex` (impl before sig, tracked to emit FS0238 "implementation already given").
- `Finisher<'Node, 'State, 'Result>` — single-case union: a node plus a callback that folds a state to produce a result and next state (used to defer result finalization).

**Significant internal logic**:
- The `Namespace` node deliberately splits "files exposing types" from "files merely declaring the namespace" — this drives both real and "ghost" dependency resolution in `DependencyResolution.fs`.
- `FilePairMap` partitions files by `IsSigFile`, first tries the file at `idx + 1`, then falls back to any impl file whose name is the sig name minus the `.fsi`; out-of-order pairs are kept in a separate `misordered` map.

**Cross-references**:
- Consumers: `DependencyResolution.fs`, `TrieMapping.fs`, `FileContentMapping.fs`, `Graph.fs` (`FileIndex` as node), `GraphProcessing.fs`.
- Signatures: `Types.fsi` mirrors these types (the fsi is the authoritative contract).

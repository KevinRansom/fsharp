# Types.fsi

**Purpose**: Authoritative public contract (within the compiler) for the type vocabulary of the graph-checking architecture: file/identifier aliases, the Trie model, `FileContentEntry` (the per-file summary of dependency-relevant constructs), the query state and result types used by dependency resolution, and the `FilePairMap` signature/implementation pairing helper.

**Namespace(s)**: `FSharp.Compiler.GraphChecking`

**Type aliases**:
- `FileIndex = int`, `FileName = string`, `Identifier = string`, `LongIdentifier = Identifier list`.

**Types**:
- `FileInProject` — record `{ Idx; FileName; ParsedInput }` with `member IsScript: bool`.
- `TrieNodeInfo` — union `Root | Module | Namespace`; the `Namespace` case is documented as carrying `filesThatExposeTypes` (files exposing types in this namespace) and `filesDefiningNamespaceWithoutTypes` (files using the namespace without types); member `Files: Set<FileIndex>`.
- `TrieNode` — record `{ Current: TrieNodeInfo; Children: ImmutableDictionary<Identifier, TrieNode> }`; `member Files: Set<FileIndex>`; `static member Empty: TrieNode`.
- `FileContentEntry` — union (`RequireQualifiedAccess`, `NoComparison`, `NoEquality`): `TopLevelNamespace of path * content`, `OpenStatement of path`, `PrefixedIdentifier of path`, `NestedModule of name * nestedContent`, `ModuleName of name`. Doc comments explain e.g. that `module X.Y.Z` contributes top-level namespace `X.Y`, and that last identifier is deliberately excluded from `PrefixedIdentifier`.
- `FileContent` — record `{ FileName; Idx; Content: FileContentEntry array }`.
- `FileContentQueryState` — record `{ OwnNamespace; OpenedNamespaces; FoundDependencies }` with `Create`, `AddOwnNamespace`, `AddDependencies`, `AddOpenNamespace`, `OpenNamespaces`.
- `QueryTrieNodeResult` — union `NodeDoesNotExist | NodeDoesNotExposeData | NodeExposesData of Set<FileIndex>`; `NodeDoesNotExposeData` carries an example: searching `A` when only `module A.B` exists.
- `QueryTrie` — `LongIdentifier -> QueryTrieNodeResult` (a closure capturing the trie).
- `FilePairMap` — `new: FileInProject array -> FilePairMap`; members `GetSignatureIndex`, `GetImplementationIndex`, `HasSignature`, `TryGetSignatureIndex`, `IsSignature`, `TryGetOutOfOrderImplementationIndex` (documented as existing only to correctly trigger FS0238 when the impl file precedes its signature).
- `Finisher<'Node, 'State, 'Result>` — single-case union of a node and a `('State -> 'Result * 'State)` callback.

**Notes**:
- All types are `internal`; this signature is the contract consumed by the other modules of the same folder.
- Comments make the module/namespace distinction explicit: a namespace does not automatically make its children depend on each other — only exposed types do.

**Cross-references**:
- Implementation: `Types.fs`.
- Consumers: `DependencyResolution.fs`, `TrieMapping.fs`, `FileContentMapping.fs`, `GraphProcessing.fs`.

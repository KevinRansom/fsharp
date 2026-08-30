# Graph.fs

**Purpose**: Generic DAG data structure and operations used by the graph-based parallel checker. A `Graph<'Node>` is simply an `IReadOnlyDictionary<'Node, 'Node array>` mapping each node to its direct dependencies, with helper functions to build, inspect, transform, and visualize it.

**Namespace(s)**: `FSharp.Compiler.GraphChecking`

**Types**:
- `type internal Graph<'Node> = IReadOnlyDictionary<'Node, 'Node array>` — directed acyclic graph of arbitrary (equality) nodes; values are the direct dependencies of each key.

**Module — `module internal Graph`**:
- `make (nodeDeps: ('Node * 'Node array) seq) : Graph<'Node>` — build a graph from node/dependency pairs.
- `map (f: 'T -> 'U) (graph: Graph<'T>) : Graph<'U>` — relabel both nodes and dependency lists.
- `addIfMissing (nodes: 'Node seq) (graph: Graph<'Node>) : Graph<'Node>` — append any missing nodes with empty dependency lists (internal helper, not in the .fsi).
- `nodes (graph: Graph<'Node>) : Set<'Node>` — collect all nodes (keys and values).
- `transitiveDeps (node) (graph)` — DFS collecting transitive dependencies of a single node via a `HashSet` (internal; not in the .fsi).
- `transitive (graph: Graph<'Node>) : Graph<'Node>` — parallel transitive closure over all nodes (O(n²), uses `Array.Parallel.map`).
- `subGraphFor node graph` — subgraph containing only the given node and nodes reachable from it (marked as TODO: optimize).
- `reverse (graph) : Graph<'Node>` — invert all edges (used by `GraphProcessing` to compute dependents).
- `printCustom` / `print` — print the graph to stdout for debugging.
- `serialiseToMermaid (graph: Graph<FileIndex * string>) : string` — render the graph as a Mermaid `flowchart` string; nodes are `(fileIndex, fileName)` pairs.
- `writeMermaidToFile path (graph: Graph<FileIndex * string>) : unit` — write the Mermaid serialization to a file via `FileSystem.OpenFileForWriteShim`.

**Significant internal logic**:
- `transitiveDeps` performs an iterative-DFS using `HashSet.Add`'s return value to filter already-visited nodes, avoiding duplicate work.
- `reverse` groups edges by their dependency target and re-creates the dict, then `addIfMissing` re-adds original keys with no dependents (otherwise they'd be lost).
- `serialiseToMermaid` produces node definitions first (with unique `%i%d` labels to avoid special-character issues) then `-->` edges.

**Cross-references**:
- Consumed by `GraphProcessing.fs` (transitive + reverse) and `DependencyResolution.fs` (`mkGraph` result type).
- Node types are aliases defined in `Types.fs` (e.g. `FileIndex = int`).

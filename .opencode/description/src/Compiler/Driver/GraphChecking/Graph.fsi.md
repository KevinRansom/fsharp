# Graph.fsi

**Purpose**: Signature for the generic DAG type and its operations, providing a small functional graph API that the parallel graph-checking pipeline uses to represent "file depends on file" relationships.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (opens `System.Collections.Generic`)

**Types / public API**:
- `type internal Graph<'Node> = IReadOnlyDictionary<'Node, 'Node array>` — a DAG where each key maps to an array of direct dependencies.

- `module internal Graph`:
  - `val make: nodeDeps: seq<'Node * 'Node array> -> Graph<'Node> when 'Node: equality` — build the graph from pairs.
  - `val map<'T, 'U when 'U: equality> : f: ('T -> 'U) -> graph: Graph<'T> -> Graph<'U>` — relabel nodes (and their dependency arrays).
  - `val nodes: graph: Graph<'Node> -> Set<'Node>` — all nodes (explicit + implied).
  - `val transitive<'Node when 'Node: equality> : graph: Graph<'Node> -> Graph<'Node>` — transitive closure in O(n²), parallelized; edge A→C present iff a directed path of non-zero length A⇒C exists.
  - `val subGraphFor: node: 'Node -> graph: Graph<'Node> -> Graph<'Node> when 'Node: equality` — nodes reachable from the given node.
  - `val reverse<'Node when 'Node: equality> : originalGraph: Graph<'Node> -> Graph<'Node>` — invert edges.
  - `val print: graph: Graph<'Node> -> unit when 'Node: not null` — print to stdout.
  - `val serialiseToMermaid: graph: Graph<FileIndex * string> -> string` and `val writeMermaidToFile: path: string -> graph: Graph<FileIndex * string> -> unit` — Mermaid flowchart rendering (for debugging/documentation).

**Notes**:
- The signature omits two implementation-only helpers (`addIfMissing`, `transitiveDeps`) and the internal `map` constraint on `'T`; keep in mind when reasoning about what is actually callable from other modules (they are internal, so the constraint difference is cosmetic within the assembly).

**Cross-references**:
- Implementation: `Graph.fs`.
- Used by `GraphProcessing.fs` (`Graph.transitive` and `Graph.reverse`) and produced by `DependencyResolution.mkGraph`.

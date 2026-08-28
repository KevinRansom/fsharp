# GraphProcessing.fsi

**Purpose**: Signature for the generic parallel work-scheduler of the graph-checking pipeline. Fixes the public contract: a DAG of items, a per-item work function that can look up already-completed dependency results, and either a blocking run (thread pool) or an `Async` run.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (module `internal GraphProcessing`, opens `System.Threading`)

**Types (public contract)**:
- `type NodeInfo<'Item>` — `Item`, `Deps`, `TransitiveDeps`, `Dependents` — a node's relations to its peers.
- `type ProcessedNode<'Item, 'Result>` — `NodeInfo` + `Result`; passed (for a dependency) to the work function once that dependency is done.
- `type GraphProcessingException = inherit exn ; new: string * Exception -> GraphProcessingException` — raised for work-item failures.

**Public API surface**:
- `val processGraph<'Item, 'Result when 'Item: equality and 'Item: comparison> : graph: Graph<'Item> -> work: (('Item -> ProcessedNode<'Item, 'Result>) -> NodeInfo<'Item> -> 'Result) -> parentCt: CancellationToken -> ('Item * 'Result)[]`
  - Schedules leaves first; after each node completes, schedules newly-unblocked dependents; returns one result per item; uses the thread pool.
- `val processGraphAsync<'Item, 'Result when 'Item: equality and 'Item: comparison> : graph: Graph<'Item> -> work: (('Item -> ProcessedNode<'Item, 'Result>) -> NodeInfo<'Item> -> Async<'Result>) -> Async<('Item * 'Result)[]>`
  - Same semantics for async work items; returns an `Async` that yields the results.

**Doc-comment notes**:
- The .fsi remarks that an alternative "N worker tasks over a BlockingCollection" design was benchmarked and may be faster; the current per-node `Async.Start` design is simpler.

**Internal (not in .fsi)**: `IncrementableInt`, `GraphNode` — thread-safe counter and mutable node state used by the implementation.

**Cross-references**:
- Implementation: `GraphProcessing.fs`.
- Uses `Graph.fs` (`Graph.transitive`, `Graph.reverse`) to precompute `NodeInfo` fields.
- Caller in this architecture: `DependencyResolution.fs` (via the checker driver).

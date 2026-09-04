# GraphProcessing.fs

**Purpose**: The generic work-scheduler for the graph-checking pipeline: given a DAG of work items and a work function, it executes the work in parallel (via the .NET thread pool / Async), starting from the dependency-free "leaves" and dynamically unblocking dependents as each node completes. Both a synchronous (thread-poll) and an `Async` variant are provided.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (module `internal GraphProcessing`)

**Types**:
- `type NodeInfo<'Item>` — record: `Item`, `Deps`, `TransitiveDeps`, `Dependents` describing a node's relations.
- `type IncrementableInt` — small thread-safe (interlocked) counter used for "processed dependency count" bookkeeping.
- `type GraphNode<'Item, 'Result>` — internal runtime state per node: `NodeInfo`, `ProcessedDepsCount`, and a `mutable Result` slot.
- `type ProcessedNode<'Item, 'Result>` — the public view handed to the work function: `NodeInfo` + `Result` (of already-processed dependencies, obtained via a lookup delegate).
- `type GraphProcessingException(msg, ex)` — wraps a work-item exception, preserving the source item in the message.

**Public API surface**:
- `processGraph<'Item, 'Result> (graph: Graph<'Item>) (work: (lookup -> NodeInfo<'Item>) -> 'Result) (parentCt: CancellationToken) : ('Item * 'Result)[]` — blocking parallel execution; uses `Async.Start` + `CancellationTokenSource` and waits on a linked token; rethrows the first exception via `GraphProcessingException`.
- `processGraphAsync<'Item, 'Result> (graph) (work: (...) -> Async<'Result>) : Async<('Item * 'Result)[]>` — async variant; uses a `TaskCompletionSource` as the completion signal, supporting cancellation via `Async.OnCancel`, and distinguishes `OperationCanceledException` (set as canceled) from other failures (set as exception).

**Internal helpers**:
- `makeNode item` — builds `NodeInfo` by looking up the node, its transitive deps graph, and its dependents graph; prints to stdout if the state is inconsistent.
- `leaves` — nodes whose `Deps` array is empty; these are the initial work to schedule.
- `queueNode` / `processNode` (recursive pair) — `processNode` runs the work function (passing a `getItemPublicNode` lookup that materialises already-computed results for dependencies), stores the result, then increments each dependent's `ProcessedDepsCount` and queues those that have just reached "all deps processed".
- `raiseExn, getExn` — first-exception-wins capture under a lock (noted in the source as potentially non-deterministic when multiple items fail).
- `incrementProcessedNodesCount` — when all nodes processed, cancels the local CTS (sync) / completes the TCS (async) to end the run.

**Significant internal logic**:
- The algorithm is a dependency-driven topological execution: leaves run first; each completion releases dependents; results are published before dependents are scheduled (via the `ProcessedDepsCount` increment-and-filter trick, which relies on reading the interlocked return value only once to avoid double-queueing).
- Final results are extracted from all nodes and sorted by key (`Seq.sortBy fst`), so output order is deterministic in input order.
- The .fsi notes an alternative `BlockingCollection`-based worker-pool design was considered; current design is one `Async.Start` per node.

**Cross-references**:
- `Graph.fs` — input type and `Graph.transitive` / `Graph.reverse` used to build `NodeInfo`.
- `DependencyResolution.fs` — caller that builds the graph of files to process.
- `Types.fs` — `Finisher` and related types are part of the same architecture.
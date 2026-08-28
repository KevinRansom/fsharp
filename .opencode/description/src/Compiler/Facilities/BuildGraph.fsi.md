# BuildGraph.fsi

**Purpose**: The contract for `BuildGraph.fs`: declares the (module- and type-level) `internal` surface of the graph-node memoization primitive — a culture-setting helper module and the sealed `GraphNode<'T>` type.

**Namespace(s)**: module `FSharp.Compiler.BuildGraph` (no namespace; everything `internal`)

**Modules / TypeDefs declared**:
- `module internal GraphNode` — "helpers related to the build graph": `mutable culture: CultureInfo` (set by `SetPreferredUILang`, applied to threads running `GraphNode` computations) and `SetPreferredUILang: string option -> unit` (specify the language for error messages)
- `[<Sealed>] type internal GraphNode<'T>` — "evaluate the computation, allowing asynchronous waits on existing ongoing evaluations of the same node, and strongly cache the result"; once cached, the computation is null'ed out to prevent strong retention of captured references

**Contract (API surface)**:
- `new: computation: Async<'T> -> GraphNode<'T>`
- `FromResult: 'T -> GraphNode<'T>` — create a node with a given result already cached
- `GetOrComputeValue: unit -> Async<'T>` — get the value if computed, await an in-progress computation, or start one
- `TryPeekValue: unit -> 'T voption` — `Some` only if already computed
- `HasValue: bool`, `IsComputing: bool`

**Notes**: The F# implementation adds the `requestCount`/semaphore mechanics and the culture restore, none of which appear in this contract.

**Cross-references**: Implements BuildGraph.fs; conceptually adjacent to AsyncMemoize.fsi (single-execution async memoization).

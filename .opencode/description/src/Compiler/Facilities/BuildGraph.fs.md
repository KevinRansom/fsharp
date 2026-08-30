# BuildGraph.fs

**Purpose**: A small general-purpose graph-node facility: `GraphNode<'T>` wraps an `Async<'T>` computation so it computes exactly once, lets multiple callers concurrently await the same in-progress computation, and strongly caches (then nulls out) the computation so captured references can be GC'd. Used by dependency-tracking / graph-checking style features and the service layer.

**Namespace(s)**: module `FSharp.Compiler.BuildGraph` (no `namespace` declaration; internal via the .fsi)

**Modules / TypeDefs / Classes declared**:
- `module GraphNode` (`[<RequireQualifiedAccess>]`): holds `mutable culture: CultureInfo` and `SetPreferredUILang`
- `[<Sealed>] type GraphNode<'T>`: the memoized async computation node

**Public API surface** (per .fsi, internal):
- `new: Async<'T> -> GraphNode<'T>`
- `static member FromResult: 'T -> GraphNode<'T>` — node with a pre-cached value
- `GetOrComputeValue: unit -> Async<'T>` — fast path returns cached node; else awaits a `SemaphoreSlim(1,1)` slot and runs the computation
- `TryPeekValue: unit -> 'T voption`, `HasValue: bool`, `IsComputing: bool`
- `GraphNode.culture` / `GraphNode.SetPreferredUILang` — apply the preferred UI culture to pool threads

**Significant internal logic**:
- Fast path: `cachedResultNode` (an `Async<'T>` returning the cached value) is returned directly without any locking
- Slow path: increments `requestCount`, `WaitAsync` on the semaphore; on cancellation the finally-block inspects `enter` completion to decide whether to release, guaranteeing no leaked semaphore slot
- After computing: stores value in both `cachedResult` (voption) and `cachedResultNode`, and sets `computation <- Unchecked.defaultof<_>` to drop captured references (FSI- and provider-host memory hygiene)
- `culture` is set on the executing thread because computations may hop to thread-pool threads, fixing localized error-message language for the VS scenario
- `IsComputing` simply reports `requestCount > 0`

**Cross-references**: Similar in spirit to AsyncMemoize.fs (single-execution async); used by the checking pipeline's dependency/GraphChecking features and service request memoization.

# eventmodule.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler; implements the `Event` module of combinators for transforming `IEvent<'Delegate,'Args>` streams.

## Namespaces
- `Microsoft.FSharp.Control`

## Module: Event
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Event`

Each combinator creates a fresh `Event<_>` source and wires a subscription into the input event, returning the `Publish`ed `IEvent`.

### Functions
- `map mapping sourceEvent` — produces a new event that triggers with `mapping x` whenever the source fires.
- `filter predicate sourceEvent` — propagates only values satisfying `predicate`.
- `partition predicate sourceEvent` — returns two events; the first fires when `predicate` holds, the second otherwise.
- `choose chooser sourceEvent` — propagates only when `chooser x` returns `Some r`.
- `scan collector state sourceEvent` — folds an internal mutable accumulator over events, triggering each new state value with the (single-threaded) accumulation remark.
- `add callback sourceEvent` — subscribes `callback` as a one-off side effect (equivalent to a fire-and-forget handler).
- `pairwise sourceEvent` — returns an event of consecutive-value pairs `(prev, cur)`, holding the previous value in mutable internal state (`lastArgs`).
- `merge event1 event2` — combines two events of possibly different delegate types into a single event that fires when either source fires.
- `split splitter sourceEvent` — returns a pair of events; each value is routed to the first event when `splitter` yields `Choice1Of2` and to the second when `Choice2Of2`.

## Key design notes
- Consistent pattern: build `Event<_>()`, `sourceEvent.Add(...)` with the transformation, return `ev.Publish`.
- Stateful combinators (`scan`, `pairwise`) rely on mutable closures; `scan`'s docs note it is not safe for multi-threaded triggering without locking.
- Tap-free transformations allocate one internal event object per combinator (no observable leakage).
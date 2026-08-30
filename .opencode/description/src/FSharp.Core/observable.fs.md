# observable.fs

## Overview

This file implements the `Observable` module (namespace `Microsoft.FSharp.Control`), containing operations for working with first-class events and other `IObservable<'T>` objects. The module is `[<RequireQualifiedAccess>]` with `[<CompilationRepresentation(ModuleSuffix)>]`.

Many combinators build an `IObservable<'U>` via an object expression whose `Subscribe` method registers an `IObserver<'T>` (an anonymous `BasicObserver` subclass) on the source.

## Supporting pieces

- `protect f succeed fail` — an `inline` exception-safety helper (`[<InlineIfLambda>]` on all three args). It runs `f ()` inside `try`/`with`; on success calls `succeed x`, on exception calls `fail e`. Used to route exceptions thrown by user callbacks into `OnError` instead of escaping.
- `BasicObserver<'T>` — an `[<AbstractClass>]` implementing `IObserver<'T>` with abstract `Next`, `Error`, `Completed`. It tracks a mutable `stopped` flag: `OnNext` is ignored after stopping, and `OnError`/`OnCompleted` set `stopped <- true` before dispatching (so only the first terminal event is delivered).

## Combinators

- `map mapping source` (`Map`) — applies `mapping` to each observation; `mapping` is run within `protect` so its exceptions become `OnError`.
- `choose chooser source` (`Choose`) — forwards only observations where `chooser` returns `Some v2`; computed inside `protect`.
- `filter predicate source` (`Filter`) — implemented as `choose (fun x -> if predicate x then Some x else None)`.
- `partition predicate source` (`Partition`) — returns two observables: those passing the predicate and those failing it (uses `filter predicate` and `filter (predicate >> not)`).
- `scan collector state source` (`Scan`) — maintains a mutable `state` per subscribed observer; on each value computes `collector state value` inside `protect`, updates and emits the new state. The initial state is not emitted.
- `add callback source` (`Add`) — permanently subscribes; just calls `source.Add(callback)`.
- `subscribe callback source` (`Subscribe`) — subscribes returning an `IDisposable`; delegates to `source.Subscribe(callback)`.
- `pairwise source` (`Pairwise`) — keeps the previous argument in a mutable `lastArgs`; forwards `(prev, curr)` pairs starting from the second observation.
- `merge source1 source2` (`Merge`) — merges two observables into one. Tracks `stopped`, `completed1`, `completed2`; forwards `OnNext` from either (unless stopped), forwards `OnError` (stopping), and completes only when **both** sources have completed. Returns a combined `IDisposable` that disposes both subscriptions.
- `split splitter source` (`Split`) — returns two observables by `Choice`: first forwards values where `splitter` returns `Choice1Of2 x`, second forwards where it returns `Choice2Of2 y` (both via `choose`).

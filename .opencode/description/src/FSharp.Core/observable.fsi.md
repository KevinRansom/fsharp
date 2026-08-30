# observable.fsi

## Overview

This is the public API signature for the `Observable` module (namespace `Microsoft.FSharp.Control`), exposing operations for working with first-class event and other observable (`IObservable`) objects. The module is `[<RequireQualifiedAccess>]` with `[<CompilationRepresentation(ModuleSuffix)>]`. All functions carry a `[<CompiledName>]`.

## Exposed API

- `merge : source1: IObservable<'T> -> source2: IObservable<'T> -> IObservable<'T>` (`Merge`) — merged observations from two sources; propagates success/error from either and completes when both complete. Not thread-safe for concurrent triggering.
- `map : mapping: ('T -> 'U) -> source: IObservable<'T> -> IObservable<'U>` (`Map`) — transforms observations; the mapping runs once per subscribed observer.
- `filter : predicate: ('T -> bool) -> source: IObservable<'T> -> IObservable<'T>` (`Filter`) — keeps only observations for which the predicate is true.
- `partition : predicate: ('T -> bool) -> source: IObservable<'T> -> (IObservable<'T> * IObservable<'T>)` (`Partition`) — two observables: the first triggers when the predicate is true, the second when it is false.
- `split : splitter: ('T -> Choice<'U1,'U2>) -> source: IObservable<'T> -> (IObservable<'U1> * IObservable<'U2>)` (`Split`) — two observables based on a `Choice`-returning splitter.
- `choose : chooser: ('T -> 'U option) -> source: IObservable<'T> -> IObservable<'U>` (`Choose`) — propagates only observations where the chooser returns `Some x`.
- `scan : collector: ('U -> 'T -> 'U) -> state: 'U -> source: IObservable<'T> -> IObservable<'U>` (`Scan`) — applies an accumulating function to successive values; emits computed state values excluding the initial value.
- `add : callback: ('T -> unit) -> source: IObservable<'T> -> unit` (`Add`) — permanently subscribes and calls the callback for each observation.
- `subscribe : callback: ('T -> unit) -> source: IObservable<'T> -> IDisposable` (`Subscribe`) — subscribes and returns a disposable that removes the callback.
- `pairwise : source: IObservable<'T> -> IObservable<'T * 'T>` (`Pairwise`) — emits successive pairs `(N-1th, Nth)` starting from the second observation.

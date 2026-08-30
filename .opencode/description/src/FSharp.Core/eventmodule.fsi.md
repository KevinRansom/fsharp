# eventmodule.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Public API signature for the `Event` module of combinators (implementations in `eventmodule.fs`).

## Namespaces
- `Microsoft.FSharp.Control`

## Module: Event
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Event`

Public surface (each with XML docs, parameter/return descriptions and console examples):

- `merge: event1: IEvent<'Del1,'T> -> event2: IEvent<'Del2,'T> -> IEvent<'T>` — fires when either input event fires.
- `map: mapping: ('T -> 'U) -> sourceEvent: IEvent<'Del,'T> -> IEvent<'U>` — transforms values.
- `filter: predicate: ('T -> bool) -> sourceEvent: IEvent<'Del,'T> -> IEvent<'T>` — passes only values satisfying the predicate.
- `partition: predicate: ('T -> bool) -> sourceEvent: IEvent<'Del,'T> -> (IEvent<'T> * IEvent<'T>)` — two events for predicate true/false respectively.
- `split: splitter: ('T -> Choice<'U1,'U2>) -> sourceEvent: IEvent<'Del,'T> -> (IEvent<'U1> * IEvent<'U2>)` — routes to first/second event by `Choice` result.
- `choose: chooser: ('T -> 'U option) -> sourceEvent: IEvent<'Del,'T> -> IEvent<'U>` — propagates when `Some`.
- `scan: collector: ('U -> 'T -> 'U) -> state: 'U -> sourceEvent: IEvent<'Del,'T> -> IEvent<'U>` — accumulating fold over events, documenting that internal state is not locked during accumulation (single-threaded input assumed).
- `add: callback: ('T -> unit) -> sourceEvent: IEvent<'Del,'T> -> unit` — runs the callback each time the event triggers.
- `pairwise: sourceEvent: IEvent<'Del,'T> -> IEvent<'T * 'T>` — events of consecutive pairs; the N-1th value is retained in hidden internal state.

## Notable behavior
- The `merge`/`map`/`filter`/etc. signatures use distinct delegate type parameters (`'Del`, `'Del1`, `'Del2`), allowing combining events with different delegate types.
- Output events are all `IEvent<'T>` (single-argument form) because the module's internal `Event<_>` sources use the `System.EventHandler` style.
# event.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler; implements the core event types `DelegateEvent`, `Event<'Delegate,'Args>` and the single-argument `Event<'T>` used throughout F#.

## Namespaces
- `Microsoft.FSharp.Control`

## Internal module Atomic
- `setWith thunk (value: byref<'a>)` — lock-free atomic update of a mutable value: loops calling `Interlocked.CompareExchange`, recomputing the new value from the latest observed old value, and stops once the exchange succeeded (reference-equality check between comparand and exchanged value).

## Type: DelegateEvent<'Delegate>
`[<CompiledName("FSharpDelegateEvent`1")>] type DelegateEvent<'Delegate when 'Delegate :> Delegate and 'Delegate: not null>()`

A mutable `Delegate` (multicast) field holds the combined handler list.

- `Trigger(args: objnull array)` — invokes `multicast.DynamicInvoke(args)` if there are handlers; no-op otherwise.
- `Publish` — returns an `IDelegateEvent<'Delegate>` whose `AddHandler`/`RemoveHandler` combine/remove delegates atomically via `Atomic.setWith`.

## Type: EventDelegee<'Args>
Private helper adapting an `IObserver<'Args>` into a delegate-compatible invoker.

- Static `makeTuple` — a cached tuple constructor via `FSharpValue.PreComputeTupleConstructor` when `'Args` is a tuple type (falls back to a failing thunk otherwise).
- `Invoke(_sender, args)` overloads arity 1..6 — each packs the variadic event arguments into an `'Args` tuple (using `makeTuple`) and forwards to `observer.OnNext`. This bridges a multi-parameter CLI event delegate to a single `'Args` object.

## Type alias EventWrapper
`type EventWrapper<'Delegate,'Args> = delegate of 'Delegate * objnull * 'Args -> unit` — typed fast-call wrapper used for the one-argument fast path.

## Type: Event<'Delegate,'Args>
`[<CompiledName("FSharpEvent`2")>] type Event<'Delegate,'Args when 'Delegate: delegate<'Args,unit> ...>()`

- Mutable field `multicast: 'Delegate`.
- Static reflection at type initialization inspects the delegate's `Invoke` method to precompute:
  - `mi, argTypes` — the method info and its parameter types minus the sender (first parameter).
  - `invoker` — an `EventWrapper` created via `Delegate.CreateDelegate` for the fast single-argument case, or `null` for multi-argument delegate types.
  - `invokeInfo` — the matching `EventDelegee<'Args>.Invoke` method (generic instantiated when needed) used to subscribe.
- `Trigger(sender, args)` — snapshots `multicast` to avoid mutation during the call; for the fast path calls `invoker.Invoke(multicast, sender, args)`, otherwise splats `sender` + tuple fields of `args` and uses `DynamicInvoke`.
- `Publish` — object exposing `ToString()` = `"<published event>"`, implementing:
  - `IEvent<'Delegate,'Args>` via `IDelegateEvent<'Delegate>` with atomic AddHandler/RemoveHandler.
  - `IObservable<'Args>.Subscribe` — creates an `EventDelegee`, wraps it as a `'Delegate` handler and registers it; the returned `IDisposable` removes the handler on Dispose.

## Type: Event<'T>
`[<CompiledName("FSharpEvent`1")>] type Event<'T>`

The simple `System.EventHandler`-style event (handler type `Handler<'T>`).

- Mutable field `multicast: Handler<'T>`.
- `Trigger(arg)` — invokes the multicast handler with `(null, arg)`.
- `Publish` — exposes `IEvent<'T>` (atomic AddHandler/RemoveHandler) and `IObservable<'T>.Subscribe` — wraps the observer in a `Handler<_>` and returns an `IDisposable` that removes it.

## Key design notes
- Thread safety: all handler-list mutation goes through `Interlocked.CompareExchange`-based `Atomic.setWith`, so concurrent add/remove do not tear the delegate chain.
- Fast path: single-argument delegate events use a pre-created `EventWrapper` delegate for direct invocation instead of `DynamicInvoke`.
- Multi-argument delegate events pack sender + args via a cached reflection-based tuple constructor (`EventDelegee`).
- `Event<'T>` subscribes with `Handler<_>` and the special `Publish` object also overrides `ToString` for cleaner diagnostics.
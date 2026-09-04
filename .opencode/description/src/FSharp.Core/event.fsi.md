# event.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. This is the public API signature for the event types implemented in `event.fs`.

## Namespaces
- `Microsoft.FSharp.Control`

## Type: DelegateEvent<'Delegate>
`[<CompiledName("FSharpDelegateEvent`1")>] type DelegateEvent<'Delegate when 'Delegate :> Delegate and 'Delegate: not null>`

Event implementation for *any* delegate type.

- `new: unit -> DelegateEvent<'Delegate>` — creates the event object.
- `Trigger: args: objnull array -> unit` — triggers the event using the given parameters.
- `Publish: IDelegateEvent<'Delegate>` — publishes the event as a first-class event value.

## Type: Event<'Delegate,'Args>
`[<CompiledName("FSharpEvent`2")>] type Event<'Delegate,'Args when 'Delegate: delegate<'Args,unit> and 'Delegate :> Delegate and 'Delegate: not struct and 'Delegate: not null>`

Event for delegate types following the standard .NET "first sender argument" convention.

- `new: unit -> Event<'Delegate,'Args>` — creates the event.
- `Trigger: sender: objnull * args: 'Args -> unit` — triggers with sender (may be `null`) and parameters.
- `Publish: IEvent<'Delegate,'Args>` — first-class event value.

## Type: Event<'T>
`[<CompiledName("FSharpEvent`1")>] type Event<'T>`

Event implementation for the `IEvent<_>` type.

- `new: unit -> Event<'T>` — creates an observable object.
- `Trigger: arg: 'T -> unit` — triggers with the given argument.
- `Publish: IEvent<'T>` — publishes as a first-class value.

## Notable documentation behavior
- All types are categorized under "Events and Observables".
- `IEvent<'Delegate,'Args>` is the dual-interface (`IDelegateEvent` + `IObservable`) abstraction that the packaged `Publish` values satisfy.
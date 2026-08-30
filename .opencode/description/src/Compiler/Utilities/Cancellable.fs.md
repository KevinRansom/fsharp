# Cancellable.fs

**Purpose**: Provides cooperative cancellation for *synchronous* compiler code. It offers two mechanisms: (1) explicit `Cancellable.CheckAndThrow()` using a token held in an `AsyncLocal`, and (2) a `cancellable { ... }` computation expression (namespace `Internal.Utilities.Library`) that threads a `CancellationToken` through synchronous computation and represents cancellation as data (`ValueOrCancelled.Cancelled`) rather than an exception. Public contract in `Cancellable.fsi`.

**Namespace(s)** declared: `FSharp.Compiler` (ambient token holder) and `Internal.Utilities.Library` (the `Cancellable<'T>` computation expression).

**Modules / Types declared**:
- `type Cancellable` (sealed, namespace `FSharp.Compiler`) — static ambient-cancellation API backed by `AsyncLocal<CancellationToken voption>`; the token is the "current" cancellation slot.
- `type ValueOrCancelled<'TResult>` (`[<RequireQualifiedAccess; Struct>]`, internal) — `Value of 'TResult | Cancelled of OperationCanceledException`; cancellation-as-data.
- `type Cancellable<'T>` (`[<Struct>]`, internal) — `Cancellable of (CancellationToken -> ValueOrCancelled<'T>)`: a cold, synchronous, cancellable computation.
- `module Cancellable` (internal) — combinators: `run`, `fold`, `runWithoutCancellation`, `toAsync`, `token`.
- `type CancellableBuilder` (internal) — computation-expression builder (all members `inline`, lambdas marked `[<InlineIfLambda>]`), includes `Bind`, `BindReturn`, `Combine`, `Delay`, `Return`, `ReturnFrom`, `TryWith`, `TryFinally`, `Using`, `Zero`.
- `[<AutoOpen>] module CancellableAutoOpens` — exposes the `cancellable` builder value.

**Public API surface** (per Cancellable.fsi):
- `Cancellable.UseToken : unit -> Async<IDisposable>` (internal) — binds the ambient `Async.CancellationToken` into the token holder for the duration of the returned scope.
- `Cancellable.HasCancellationToken : bool`; `CancellationToken.Token` (throws/asserts if unset and guards are on).
- `Cancellable.CheckAndThrow : unit -> unit` — throws if cancellation was requested (fails if no token set and `DISABLE_CHECKANDTHROW_ASSERT` not set).
- `Cancellable.TryCheckAndThrow : unit -> unit` — no-op when no token is ambient.
- `Cancellable.run : ct * Cancellable<'T> -> ValueOrCancelled<'T>` (inline) — executes, pre-checking the token and translating the matching `OperationCanceledException` into `Cancelled`; re-raises an `OCE` from the *wrong* token as `InvalidOperationException("Wrong cancellation token")`.
- `Cancellable.fold`, `Cancellable.runWithoutCancellation`, `Cancellable.token`, `Cancellable.toAsync` (bridges to `Async`, propagating cancellation to the continuation).

**Internal helpers**:
- `ensureToken msg` — pulls the token out of the `AsyncLocal` or fails (unless the `DISABLE_CHECKANDTHROW_ASSERT` env var is set, in which case it falls back to `CancellationToken.None`).
- Builder members call `__debugPoint` (from `FSharp.Core.CompilerServices.StateMachineHelpers`) to improve debugger breakpoints inside inlined code.

**Significant internal logic / behavioral notes**:
- Cancellation propagates as a *result* (`Cancelled exn`) through `Bind`/`Combine`/... chains, short-circuiting the rest of the chain — no exception unwinding across cancellation.
- `Using`/`TryFinally` dispose/compensate even on both value-result and cancellation paths, then raise/return appropriately.
- `toAsync` runs the computation synchronously inside `Async.FromContinuations`, so the whole body blocks one thread to completion (it is not async internally).
- Comment at top of file: prefer the cancellable computation; use `CheckAndThrow()` when wrapping code is impractical (e.g. deep recursion); token must be set first (it is set inside a cancellable computation, or via `UseToken`).

**Cross-references**: none directly among sibling files; conceptually pairs with `Caches.fs` (which uses cancellation tokens for its eviction `MailboxProcessor` shutdown).

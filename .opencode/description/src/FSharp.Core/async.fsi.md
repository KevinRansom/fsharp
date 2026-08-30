# async.fsi

## Pipeline role

The signature file for `async.fs`, part of FSharp.Core, the standard library shipped with the F# compiler. It declares the complete public (and compiler-facing) API of the asynchronous programming model in `Microsoft.FSharp.Control`, with extensive XML documentation, category indices and code examples.

## Namespaces

- `Microsoft.FSharp.Control` — async, events and agents (see the `namespacedoc` summarizing "Library functionality for asynchronous programming, events and agents").

## Types and modules declared

### `Async<'T>` (sealed, `CompiledName("FSharpAsync`1")`)

An asynchronous computation that, when run, eventually produces a value of type `'T` or raises an exception. No members of its own; built via `async` expressions or `FSharpAsync` static members. Category "Async Programming".

### `Async` sealed class (`CompiledName("FSharpAsync")`)

Holds static members for creating and manipulating computations, organized in categories:

- **Starting Async Computations (index 0)**: `RunSynchronously` (`?timeout`, `?cancellationToken`), `RunSynchronouslyImmediate`, `Start`, `StartAsTask`, `StartChildAsTask`, `StartTaskImmediate` (Task/ValueTask/task-like overloads), `StartImmediate`, `StartImmediateAsTask`, `StartWithContinuations` (+ internal `StartWithContinuationsUsingDispatchInfo`).
- **Composing Async Computations (index 1)**: `Parallel(seq)` and `Parallel(seq, ?maxDegreeOfParallelism)`, `Sequential`, `Choice`, `FromContinuations`, `Ignore`.
- **Awaiting Results (index 2)**: `AwaitEvent`, `AwaitWaitHandle`, `AwaitIAsyncResult`, `AwaitTask` (Task/unit-Task; note exceptions wrapped in `AggregateException`), `Await` (Task/ValueTask — single exceptions surfaced directly, legacy behavior retained through `AwaitTask`), `Sleep` (int ms and TimeSpan overloads).
- **Cancellation and Exceptions (index 3)**: `Catch`, `TryCancelled`, `OnCancel`, `CancellationToken`, `CancelDefaultToken`, `DefaultCancellationToken`.
- **Threads and Contexts (index 4)**: `SwitchToNewThread`, `SwitchToThreadPool`, `SwitchToContext`.
- **Legacy .NET Async Interoperability (index 5)**: `FromBeginEnd` (1–3 arg overloads), `AsBeginEnd`.
- Exceptions: negative/infinite-unless-infinite `Sleep` throws `ArgumentOutOfRangeException`.

### `AsyncTaskLikeExtensions` (`[<AutoOpen>]`)

SRTP extension members on `Async` awaiting any `GetAwaiter`-shaped task-like value:
- `inline Await< ^TaskLike, ^Awaiter, 'T>` — constraint `GetAwaiter`, `ICriticalNotifyCompletion`, `IsCompleted`, `GetResult`.
- `inline StartTaskImmediate< ^TaskLike, ^Awaiter, 'T>`.
- `[<NoEagerConstraintApplication>]` so the compiler does not eagerly apply constraints.

### `AsyncReturn` and `AsyncActivation<'T>` (Async Internals, index 5)

`AsyncReturn` — the sentinel return type of generated async code. `AsyncActivation<'T>` is a struct with members the compiler emits calls to: `IsCancellationRequested`, static `Success`, `OnSuccess` (obsolete path), `OnExceptionRaised`, `OnCancellation`, plus internal `QueueContinuationWithTrampoline`/`CallContinuation` (used by `MailboxProcessor`). `AsyncResult<'T>` (internal union `Ok/Error/Canceled`, also MailboxProcessor-facing).

### `AsyncPrimitives` sealed module (Async Internals, index 5)

Entry points for generated code — `MakeAsync`, `Invoke`, `CallThenInvoke`, `Bind` (the `let!` primitive), `TryFinally`, `TryWith`; internal `ResultCell<'T>` (a mutable completion cell with wait handle, used by `MailboxProcessor`) and `CreateAsyncResultAsync`.

### `AsyncBuilder` (`CompiledName("FSharpAsyncBuilder")`, sealed)

The builder object for `async { }`:
- `For` (enumerates a sequence and runs `body` for each element), `Zero` (cancellation-checked `()`), `Combine` (sequence), `While`, `Return`, `ReturnFrom`, `Delay`, `Using` (disposes resource, permits `use`/`use!`), `Bind` (permits `let!`), `TryFinally`, `TryWith`.
- Every member documents that a cancellation check is performed and which computation-expression syntax it enables. Internal `new : unit -> AsyncBuilder`.

### `CommonExtensions` (`[<AutoOpen>]`)

- `System.IO.Stream.AsyncRead` (into a buffer with optional offset/count), `AsyncRead (count:int -> Async<byte array>)` (reads a full buffer, documented `ArgumentException`/`ArgumentOutOfRangeException`), `AsyncWrite`.
- `IObservable<'T>.Add` (`CompiledName("AddToObservable")`) and `Subscribe` (`CompiledName("SubscribeToObservable")`).

### `WebExtensions` (`[<AutoOpen>]`)

- `System.Net.WebRequest.AsyncGetResponse` → `Async<WebResponse>`.
- `System.Net.WebClient.AsyncDownloadString` → `Async<string>`, `AsyncDownloadData` → `Async<byte array>`, `AsyncDownloadFile` → `Async<unit>`.

### `AsyncBuilderImpl` (internal module)

`val async : AsyncBuilder` — the single `async` value used by the `async` keyword.

### `Async` module (`ModuleSuffix`, camelCase functions)

`result`, `inline map`, `inline bind`, `ignore<'T>` (`[<RequiresExplicitTypeArguments>]`), `catchWith` (handles non-cancellation exceptions: `OperationCanceledException` and derived types propagate), `catch` (reifies outcome as `Result<'T, exn>`, cancellation still propagates), `empty` (= `async.Zero()`).

## Key design notes

- The `.fsi` is split by `<category index="...">` groups that drive the online FSharp.Core reference doc ordering (Starting / Composing / Awaiting / Cancellation & Exceptions / Threads / Legacy Interop / Internals).
- Compiler-facing surface (`AsyncReturn`, `AsyncActivation`, `AsyncPrimitives`, `AsyncBuilderImpl`, internal `AsyncResult`, internal `ResultCell`) is documented as "The F# compiler emits references to this type/function to implement F# async expressions."
- `AwaitTask` vs `Await` documents the deliberate behavioral difference: legacy `AggregateException` wrapping vs. direct single-exception surfacing (with `UnwrapExn` in the implementation).

## Notable behavior

- `RunSynchronously` documentation explicitly explains the inline-on-threadpool-thread rule and recommends `RunSynchronouslyImmediate` for scripts/F# Interactive/unit tests (clearer call stacks, two fewer frames on exception).
- `Parallel`/`Sequential`/`Choice` document fork/join semantics: on the first exception all remaining children are cancelled but the computation still waits for them to complete; `Choice` returns the first `Some`.
- `OnCancel` returns an `Async<IDisposable>` whose disposal in non-cancellation scenarios unregisters the token handler.
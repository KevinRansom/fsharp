# async.fs

## Pipeline role

A source file of FSharp.Core, the standard library shipped with the F# compiler. It implements the entire `Microsoft.FSharp.Control.Async` asynchronous programming model: the `Async<'T>` type, the `async { }` computation-expression builder (`AsyncBuilder` and the `async` value), the `AsyncPrimitives` continuation-passing engine, the `Async` static methods used in every F# async workflow, and the auto-opened extension members for streams, observables, `WebRequest` and `WebClient`.

## Namespaces

- `Microsoft.FSharp.Control` — the only namespace; hosts `Async`, its builder, and extension modules.

## Core execution model

F# async uses a CPS (continuation-passing) interpreter compiled from async expressions.

### Continuations and the interpretation stack

- `type AsyncReturn = | AsyncReturn` — a dummy, never-instantiated sentinel return type. F# compiles `unit`-returning tail calls to `void` in IL, which breaks async's tail recursion, so all continuations return `AsyncReturn` instead.
- `type cont<'T> = 'T -> AsyncReturn`, `type econt = ExceptionDispatchInfo -> AsyncReturn`, `type ccont = OperationCanceledException -> AsyncReturn` — the success, exception and cancellation continuations carried by a running computation.
- `Trampoline` — a per-thread, per-invocation loop object that prevents stack overflow in long chains of synchronous binds. Its `Execute` runs actions in a `while` loop: each action may file a continuation via `Set (saving storedCont)`, `IncrementBindCount` counting to `bindLimitBeforeHijack` (300), after which the trampoline "hijacks" the synchronous stack and reruns the continuation from the loop base instead of recursing. All exceptions raised by user code propagate up to the single trampoline catch handler, which records a full `.StackTrace` (see the stack-overflow link comment, because exceptions are truncated at the first catch handler, and the trampoline is the only catch handler underneath all async code). Exception continuations are recovered there via `storedExnCont` and `ExceptionDispatchInfo.RestoreOrCapture`.
- `ExceptionDispatchInfoHelpers` — an `[<AutoOpen>]` module holding a `ConditionalWeakTable<exn, ExceptionDispatchInfo>` used to re-associate an exception object with its original captured stack, plus `RestoreOrCapture` and the `ThrowAny` helper.
- `LinkedSubSource` — a helper wrapping `CancellationTokenSource.CreateLinkedTokenSource` with a second, local `failureCTS` whose `Cancel()` cancels a group of children (used by `Async.Parallel`/`Async.Choice`).
- `TrampolineHolder` — lazily allocates `SendOrPostCallback`/`WaitCallback`/`ParameterizedThreadStart` delegates that all flow through `ExecuteWithTrampoline`; provides `PostWithTrampoline`, `QueueWorkItemWithTrampoline`, `PostOrQueueWithTrampoline`, `StartThreadWithTrampoline`, `HijackCheckThenCall`.
- `AsyncActivationAux` / `AsyncActivationContents<'T>` — "rarely changing" fields (token, econt, ccont, trampolineHolder) and the mutable success continuation.
- `AsyncActivation<'T>` — a struct wrapper with `WithContinuation(s)`, `WithCancellationContinuation`, `WithExceptionContinuation`, plus the important `Success` static (cancellation check then trampoline hijack check then call), `HijackCheckThenCall`, `ProtectCode` (finally-block that saves the exception continuation if user code raised), `OnCancellation`, `OnExceptionRaised`, `QueueContinuationWithTrampoline`, `Create`.
- `Async<'T> = { Invoke: AsyncActivation<'T> -> AsyncReturn }` — a record holding a single function; `[<CompiledName("FSharpAsync`1")>]`.
- `Latch` — a thin `Interlocked.CompareExchange` gate so callbacks (events/timers/tasks) execute at most once.
- `AsyncResult<'T> = Ok of 'T | Error of ExceptionDispatchInfo | Canceled of OperationCanceledException` — a reified completion, with `Commit()` that dispatches to the right exception-throwing path.

### `AsyncPrimitives` — the code-gen entry points

This internal module is referenced directly from the IL that the F# compiler generates for `async { }`:

- `Invoke computation ctxt` — hijack check, then run `computation.Invoke ctxt`.
- `MakeAsync body` — wraps a body; `MakeAsyncWithCancelCheck` prepends a `IsCancellationRequested → OnCancellation()` check.
- `CallThenContinue`, `CallThenInvoke`, `CallThenInvokeNoHijackCheck`, `CallFilterThenInvoke` — apply user functions (mapping, binding, exception filters) with `ProtectCode` and route to the right continuation.
- `Bind ctxt part1 part2` — the `let!` primitive: cancellation check, `Invoke part1` with a continuation that applies `part2` (deliberately **without** a second cancellation check so a `try/finally` disposing a resource still runs before cancellation).
- `TryFinally` — reruns all three continuations, each first executing the `finallyFunction`; if the finally function itself throws, the previous continuation is resumed with the new exception.
- `TryWith` — replaces the econt; re-checks cancellation before applying `catchFunction (Some/None)`.
- `CreateReturnAsync`, `CreateBindAsync`, `CreateCallAsync`, `CreateDelayAsync`, `CreateSequentialAsync`, `CreateTryFinallyAsync`, `CreateTryWithAsync`, `CreateTryWithFilterAsync`, `CreateWhenCancelledAsync`, `CreateIgnoreAsync`, `CreateUsingAsync` (implementing `use!` via dispose), `CreateWhileAsync` (allocates nothing per iteration; one `whileAsync` closure recurs on itself), `CreateForLoopAsync` (enumerator + while), `CreateSwitchToAsync`/`CreateSwitchToNewThreadAsync`/`CreateSwitchToThreadPoolAsync`, `DelimitSyncContext`.
- `cancellationTokenAsync` and `unitAsync` — preallocated single computations.
- `StartWithContinuations` — installs a trampoline, builds the activation, invokes.
- `SuspendedAsync<'T>` — snapshot of the ambient `SynchronizationContext` and current thread used to defer continuation runs; `ContinueImmediate` executes inline only when null context or posting back to the same context/thread, otherwise posts/queues.
- `ResultCell<'T>` — a mutable result slot with a saved-continuation list, a lazily created `ManualResetEvent`, dispose support; `RegisterResult` (single-writer, ignores double registration, runs continuations outside the lock), `AwaitResult_NoDirectCancelOrTimeout`, `TryWaitForResultSynchronously (?timeout)`.
- `FuncDelegate<'T>` — fabricates a delegate of an arbitrary `'Delegate` type from an F# function via reflection (used by `AwaitEvent`).
- `QueueAsync`, `QueueAsyncAndWaitForResultSynchronously` (timeout support via `LinkedSubSource`, then cancellation, quiesce wait and `TimeoutException`), `RunSynchronouslyImmediate` (TaskCompletionSource + `GetResult()` to avoid `AggregateException` wrapping), `RunSynchronouslyBackgroundThreadPool` (inline when ambient context null + thread-pool thread + no timeout).
- `Start` (exceptions rethrown on completion), `StartAsTask`, `UnwrapExn` (elides single-inner `AggregateException`), `OnTaskCompleted`/`OnUnitTaskCompleted` (canceled → `TaskCanceledException` to econt, faulted → `RestoreOrCapture`, else success), `AttachContinuationToTask`/`AttachContinuationToUnitTask` (`ContinueWith` with `ExecuteSynchronously` + a fresh trampoline), `AwaitTask`/`AwaitUnitTask` (completed → synchronous path; else `DelimitSyncContext` + attach).
- `AsyncIAsyncResult<'T>` + `AsBeginEndHelpers` — implements the .NET APM `IAsyncResult` (with `CompletedSynchronously`, `AsyncWaitHandle`, `AsyncState`, `CancelAsync`, `Close`) and Begin/End/Cancel helpers.

## `AsyncBuilder` and the `async` value

- `type AsyncBuilder` (`[<CompiledName("FSharpAsyncBuilder")>]`) — implements the computation-expression methods `Zero`, `Delay`, `Return`, `ReturnFrom`, `Bind`, `Using`, `While`, `For`, `Combine`, `TryFinally`, `TryWith` (and the filtered variant commented out), all forwarding to the `Create*Async` primitives.
- `AsyncBuilderImpl.async` (`[<AutoOpen>]`) — the global `async` object every `async { }` expression is compiled against. The builder methods with `inline` are marked so their bodies inline into user assemblies.

## `Async` static class (`[<CompiledName("FSharpAsync")>]`)

- **Starting**: `RunSynchronously` (inline/threadpool decision + timeout via `QueueAsyncAndWaitForResultSynchronously`; when a cancelable token is provided, timeout is dropped), `RunSynchronouslyImmediate`, `Start`, `StartAsTask`, `StartChildAsTask`, `StartImmediate` (starts on the calling thread), `StartImmediateAsTask`, `StartWithContinuations`, `StartWithContinuationsUsingDispatchInfo` (internal), `StartTaskImmediate` (for `Task`/`ValueTask`).
- **Cancellation**: `CancellationToken`, `CancelCheck`, `CancelDefaultToken` (replaces the global `defaultCancellationTokenSource` before canceling so future work uses a fresh token), `DefaultCancellationToken`, `TryCancelled`, `OnCancel`, linking used by `Parallel`/`Choice`.
- **Composition**: `Catch` (reifies exceptions as `Choice1Of2/Choice2Of2`, using `GetAssociatedSourceException`), `Parallel(seq)` and `Parallel(seq, ?maxDegreeOfParallelism)` (fork/join with `LinkedSubSource`, first-exception capture via `CompareExchange`, and a `worker`-loop when `maxDegreeOfParallelism` is set; cancels remaining children on first failure but waits for all to quiesce), `Sequential` (Parallel with maxDegreeOfParallelism=1), `Choice` (first `Some`), `Ignore`, `FromContinuations` (invokes exactly one continuation; guards with a `Latch` against double invocation, uses tail-call/PostOrQueue/Execute fallbacks), `AwaitAndBindResult_NoDirectCancelOrTimeout`, `AwaitAndBindChildResult`, `FromBeginEnd` family (Begin/End APM adapters computing via `ResultCell` + cancellation registration + `Complete` latch), `AsBeginEnd`, `AwaitEvent`, `AwaitIAsyncResult`, `AwaitWaitHandle` (via `ThreadPool.RegisterWaitForSingleObject`), `Sleep`, `SynchronizationContext` delimiters via `SwitchToContext`/`SwitchToNewThread`/`SwitchToThreadPool`, `DefaultCancellationToken`.
- **Task interoperability**: `AwaitTask` (preserves `AggregateException`), `Await` for `Task`/`ValueTask` (unwraps single exceptions via `unwrap=true` → `UnwrapExn`), plus the SRTP `Await`/`StartTaskImmediate` in `AsyncTaskLikeExtensions` (static-constraint `GetAwaiter` pattern, `[<NoEagerConstraintApplication>]`).

## Extension modules (all `[<AutoOpen>]`)

- `CommonExtensions` — `System.IO.Stream.AsyncRead/AsyncReadBytes/AsyncWrite` (via `Async.FromBeginEnd`), `IObservable<'Args>.Add/Subscribe` hand-rolled `IObserver` adapters.
- `WebExtensions` — `System.Net.WebRequest.AsyncGetResponse` (uses `CreateTryWithFilterAsync` to translate `WebException` with `RequestCanceled` status into cancellation when the abort came from the cancelAction), and `WebClient.AsyncDownloadString/AsyncDownloadData/AsyncDownloadFile` (event-driven `FromContinuations` with per-download `UserState` matching and `Async.OnCancel` → `CancelAsync`).

## Module `Async` (camelCase functions, `ModuleSuffix`)

At the bottom of the file: `result`, `map` (compiled `Map`), `bind` (compiled `Bind`), `ignore<'T>` (requires explicit type args), `catchWith`, `catch` (returns `Result<'T, exn>`), `empty` — the newer module-level, non-builders API surface used in modern F# pipelines.

## Key design notes

- The trampoline is what makes unbounded `while`/recursive async computations safe: after 300 nested binds a continuation is parked in the trampoline and resumed from the base loop instead of recursing.
- Continuations are deliberately never bound to a single thread; `SuspendedAsync` decides inline-vs-post based on ambient `SynchronizationContext`, which is what keeps UI-thread postbacks correct (with a documented F# 2.0-era compatibility quirk comparing `Object.Equals(syncCtxt, currentSyncCtxt)`).
- `ExceptionDispatchInfo` is used throughout so re-thrown exceptions preserve the original stack; the eager re-association in `GetAssociatedSourceException` feeds `Catch`, `TryWith` and `AwaitTask`.
- The file suppresses warnings 40 (recursive references) and 52 (copying values) and defines `Latch` to make every one-shot callback edge safe.

## Notable behavior

- `Async.RunSynchronously` prefers to run inline on the current thread when it is a thread-pool thread with a null `SynchronizationContext` and no timeout — giving the best stack traces in failure — otherwise it queues to the thread pool. `RunSynchronouslyImmediate` always starts on the calling thread and blocks there.
- A canceled task being awaited calls the exception continuation (not the cancellation continuation) because the task's token may differ from the async's token.
- `Async.Parallel`/`Choice` always cancel the remaining children after the first failure but still wait for their quiescence before completing, preventing leaks of the linked token source.
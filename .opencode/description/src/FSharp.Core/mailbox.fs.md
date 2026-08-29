# mailbox.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler; implements the `MailboxProcessor<'Msg>` message-processing agent (F# "agents"/mailboxes) in `Microsoft.FSharp.Control`.

## Namespaces
- `Microsoft.FSharp.Control`

## Module: AsyncHelpers (internal helpers within the file)
- `awaitEither a1 a2` — an `Async` that starts both computations with `Async.StartWithContinuationsUsingDispatchInfo`, tags each result as `Choice1Of2`/`Choice2Of2`, and races them into a `ResultCell`. Uses `AwaitResult_NoDirectCancelOrTimeout` because the child computations share the caller's cancellation token and register cancelled results themselves.
- `timeout msec cancellationToken` — starts `Async.Sleep msec` into a `ResultCell` and returns its awaitable; used as the race-side of a timeout.

## Type: Mailbox<'Msg> (internal)
`[<Sealed>] [<AutoSerializable(false)>] type Mailbox<'Msg>` — the shared core supporting the public processor.

### State and threading model
- `isDisposed`, `inboxStore` (lazy `List<'Msg>`, the already-scanned inbox), `arrivals` (`Queue<'Msg>`, new arrivals) and `syncRoot` = the arrivals queue (used as the lock object).
- **Single-reader protocol**: `savedCont: (bool -> AsyncReturn) option` holds the descheduled reader's continuation; when a message arrives the writer either re-schedules this continuation ("activated" via trampoline) or sets the *pulse* `AutoResetEvent` for wait-handle-based readers (used when a timeout is involved).
- `ensurePulse ()` — lazily creates the `AutoResetEvent`.
- `waitOneNoTimeoutOrCancellation` — `MakeAsync` that, under the lock, installs `savedCont` only if no arrival is pending; races are handled by re-checking `arrivals.Count` inside the lock. Guarantees at most one waiting reader continuation (`failwith` otherwise).
- `waitOneWithCancellation timeout` — `Async.AwaitWaitHandle (pulse, timeout)`.
- `waitOne timeout` — no-timeout path when cancellation isn't supported; otherwise wait-handle path.

### Queue access
- `inbox` — lazily created inbox list.
- `CurrentQueueLength` — `inbox.Count + arrivals.Count` under the lock.
- `ScanArrivalsUnsafe` / `ScanArrivals f` — dequeue from arrivals; messages rejected by scanner go to the inbox; returns first accepted `Async<'T> option`. The "Unsafe" variant is lock-free (caller must lock).
- `ScanInbox(f, n)` — scans the inbox list; removes the matched element.
- `ReceiveFromArrivalsUnsafe` / `ReceiveFromArrivals` / `ReceiveFromInbox` — FIFO dequeue paths.
- `Post msg` — under the lock: enqueue into `arrivals` (or raise `ObjectDisposedException` when disposed + `isThrowExceptionAfterDisposed`); then wake a waiting reader — re-schedule `savedCont` (cleared) or set `pulse`.

### Scans / receives (async)
- `TryScan(f, timeout)` — first `ScanInbox`; if nothing found, with a negative timeout enters `scanNoTimeout` (wait-then-rescan loop); with a timeout creates a linked `CancellationTokenSource` and races the reader wait against `AsyncHelpers.timeout` via `awaitEither`. If the timeout wins, the pending reader continuation is abandoned (`savedCont <- None`, the documented "HERE BE DRAGONS" single-reader cancellation), and `None` is returned; if a message is found, the timeout watcher is cancelled and the scanner's async runs.
- `Scan(f, timeout)` — `TryScan`; raises `TimeoutException` (`mailboxScanTimedOut`) on `None`.
- `TryReceive timeout` / `Receive timeout` — `processFirstArrival` loop: try `ReceiveFromArrivals`; ensure pulse if a timeout/cancellation will be needed; otherwise wait then rescan. Receive raises `TimeoutException` on timeout; TryReceive returns `None`.

### IDisposable
- Empty both queues, mark disposed, and dispose the pulse event.

### Debug
- `UnsafeContents` (DEBUG builds) exposes internal queues.

## Type: AsyncReplyChannel<'Reply>
`[<Sealed>] [<CompiledName("FSharpAsyncReplyChannel`1")>] type AsyncReplyChannel<'Reply>(replyf: 'Reply -> unit)`
- `Reply value` — invokes the wrapped reply function, completing the reply cell of a `PostAndReply` call.

## Type: MailboxProcessor<'Msg>
`[<Sealed>] [<AutoSerializable(false)>] [<CompiledName("FSharpMailboxProcessor`1")>] type MailboxProcessor<'Msg>(body, isThrowExceptionAfterDisposed, ?cancellationToken)`

- Wraps a `Mailbox<'Msg>`; `cancellationSupported` = whether a user token was supplied; default token = `Async.DefaultCancellationToken`.
- State: `defaultTimeout = Timeout.Infinite`, `started = false`, and an `errorEvent: Event<Exception>`.

### Constructors
- `new(body)` and `new(body, isThrowExceptionAfterDisposed, ?cancellationToken)` — delegate into the primary ctor.

### Members
- `CurrentQueueLength` — underlying mailbox queue length (approximate, unprotected read).
- `DefaultTimeout` — get/set timeout used by all receive/reply operations.
- `Error` — `[<CLIEvent>]` event fired when the body computation throws.
- `PrepareToStart()` — marks `started = true` (raises `InvalidOperationException` on double start) and returns an `async` that runs `body x` with try/with forwarding exceptions to `errorEvent`.
- `Start()` / `StartImmediate()` — `PrepareToStart` + `Async.Start` / `Async.StartImmediate`.
- `Post message` — enqueue a message (never blocks).
- `TryPostAndReply(buildMessage, ?timeout)` — constructs the message via an `AsyncReplyChannel` writing into a `ResultCell`, posts, then `TryWaitForResultSynchronously(timeout)`; a disposed cell after timeout harmlessly drops late replies.
- `PostAndReply(buildMessage, ?timeout)` — `TryPostAndReply`; raises `TimeoutException` on `None`.
- `PostAndTryAsyncReply(buildMessage, ?timeout)` — async variants: infinite-timeout-without-cancellation uses `AwaitResult_NoDirectCancelOrTimeout`; otherwise awaits the wait handle with timeout and grabs/none the result.
- `PostAndAsyncReply(buildMessage, ?timeout)` — like above but raises `TimeoutException` on timeout.
- `Receive`/`TryReceive`/`Scan`/`TryScan` (with optional timeout, defaulting to `DefaultTimeout`) — forward to the mailbox.
- `Dispose()`, plus `interface IDisposable` — disposes the underlying mailbox.

### Static factories
- `MailboxProcessor.Start(body, ?cancellationToken)` / `Start(body, isThrowExceptionAfterDisposed, ?cancellationToken)` — create + start.
- `MailboxProcessor.StartImmediate(...)` — same but started on the current thread.

## Key design notes
- Thread safety: queue mutation and reader-state transitions are serialized on `syncRoot`; message writes are lock-free from the caller's perspective (Post never blocks).
- Single-reader constraint is enforced structurally (one `savedCont`); starting two concurrent reads fails fast, and timeout cancellation intentionally abandons the stale reader (documented in-code).
- Reply channels are `ResultCell`-based, so "reply after timeout" results are silently dropped rather than crashing the agent.
- The agent body is wrapped so exceptions surface via the `Error` event instead of killing the .NET thread pool (stack traces are intentionally lost — noted in the code).
- The internal `Mailbox<'Msg>` type is what `MailboxProcessor` delegates all queue/reader logic to.
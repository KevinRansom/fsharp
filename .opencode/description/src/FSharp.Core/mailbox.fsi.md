# mailbox.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Public API signature for the agent types implemented in `mailbox.fs`.

## Namespaces
- `Microsoft.FSharp.Control`

## Type: AsyncReplyChannel<'Reply>
`[<Sealed; CompiledName("FSharpAsyncReplyChannel`1")>] type AsyncReplyChannel<'Reply>`

A handle to a capability to reply to a `PostAndReply` message. Categorized under "Agents".

- `Reply: value: 'Reply -> unit` — sends a reply to the pending `PostAndReply` message.

## Type: MailboxProcessor<'Msg>
`[<Sealed; AutoSerializable(false); CompiledName("FSharpMailboxProcessor`1")>] type MailboxProcessor<'Msg>`

A message-processing agent executing an asynchronous computation. The docs describe a message queue with **multiple writers and a single reader**; writers use `Post` and variants, the reader uses `Receive`/`TryReceive` or scans with `Scan`/`TryScan`.

### Constructors
- `new: body: (MailboxProcessor<'Msg> -> Async<unit>) * ?cancellationToken: CancellationToken -> MailboxProcessor<'Msg>` — body is *not* executed until `Start`.
- `new: body * isThrowExceptionAfterDisposed: bool * ?cancellationToken: CancellationToken` — the flag selects whether `Post` after `Dispose` raises `ObjectDisposedException`.

### Static factories
- `Start: body * ?cancellationToken` and `Start: body * isThrowExceptionAfterDisposed * ?cancellationToken` — create and start.
- `StartImmediate: ...` — create and start on the current operating system thread.

### Members
- `Post: message: 'Msg -> unit` — post asynchronously (non-blocking).
- `PostAndReply: buildMessage: (AsyncReplyChannel<'Reply> -> 'Msg) * ?timeout: int -> 'Reply` — synchronous request/reply; `TimeoutException` on timeout.
- `PostAndAsyncReply: ... -> Async<'Reply>` — asynchronous request/reply.
- `TryPostAndReply: ... -> 'Reply option` — synchronous request/reply returning `None` on timeout.
- `PostAndTryAsyncReply: ... -> Async<'Reply option>` — asynchronous request/reply returning `None` on timeout.
- `Receive: ?timeout: int -> Async<'Msg>` — awaits next message in arrival order; `TimeoutException` on timeout. For use within the agent body; at most one concurrent reader (Receive/TryReceive/Scan/TryScan) per agent.
- `TryReceive: ?timeout: int -> Async<'Msg option>` — as Receive but `None` on timeout.
- `Scan: scanner: ('Msg -> Async<'T> option) * ?timeout: int -> Async<'T>` — scans messages in arrival order until `scanner` returns `Some`; other messages remain queued; `TimeoutException` on timeout.
- `TryScan: scanner * ?timeout: int -> Async<'T option>` — as Scan but `None` on timeout.
- `Start: unit -> unit` / `StartImmediate: unit -> unit` — instance start methods.
- `DefaultTimeout: int with get, set` — default timeout for operations; `-1` = infinite.
- `Error: IEvent<System.Exception>` — `[<CLIEvent>]` event raised when body execution throws.
- `CurrentQueueLength: int` — number of unprocessed messages.
- `Dispose: unit -> unit` plus `interface System.IDisposable` — releases agent resources.

## Notable behavior
- Timeout defaults to `-1` (`Timeout.Infinite`).
- The single-reader rule is a documented precondition of all receive/scan methods.
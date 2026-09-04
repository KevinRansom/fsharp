# FSharpInteractiveServer.fs

**Purpose**: Implementation of the Ctrl+Break channel for F# Interactive: a named-pipe "server" thread that a host can connect to in order to interrupt a running interactive evaluation, plus the client side that hosts call `Interrupt()` from.

**Namespace(s)**: `FSharp.Compiler.Interactive`

**Module — `module CtrlBreakHandlers`** (public):
- Constants: `interruptCommand = "Interactive-CtrlCNotificationCommand-Interrupt"`; `lineInterruptCommand` (UTF-8 bytes of the command + newline); `connectionTimeout = 1000` ms.
- `type public CtrlBreakService(channelName)` — `[AbstractClass]`:
  - `abstract Interrupt : unit -> unit` — implemented by the host to perform the interrupt (e.g. forward to `FsiEvaluationSession.Interrupt`).
  - `member Run : unit -> unit` — creates a `NamedPipeServerStream(channelName, PipeDirection.In)`, waits for a client, reads lines until EOF, invoking `Interrupt` whenever a line equals the sentinel command. Doc comment: exceptions propagate to the caller; should be run on a new thread.
- `type public CtrlBreakClient(channelName)` — keeps an optional `NamedPipeClientStream` (out direction);
  - `member Interrupt : unit -> unit` — lazily connects (swallowing connection failures), writes the interrupt bytes and flushes.
  - `IDisposable` — disposes the client stream and nulls the reference.

**Significant internal logic**:
- The protocol is deliberately dumb: a single sentinel line over a local named pipe — no framing, no response, works across processes.
- The client tolerates a not-yet-listening server (connect errors are swallowed) and reuses the stream for a single signal.

**Cross-references**:
- Signature: `FSharpInteractiveServer.fsi`.
- `fsi.fs` — `FsiEvaluationSession.Interrupt` and the interrupt controller that this channel ultimately triggers.
- Uses `System.IO.Pipes`.

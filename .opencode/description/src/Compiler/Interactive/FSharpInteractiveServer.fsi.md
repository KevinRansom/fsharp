# FSharpInteractiveServer.fsi

**Purpose**: Signature for the Ctrl+Break plumbing used by the Fsi server: a named-pipe-based protocol through which a host (running alongside the interactive session) can signal "interrupt" to a running interaction. The service runs on a dedicated thread and waits for a client to connect.

**Namespace(s)**: `FSharp.Compiler.Interactive`

**Module — `CtrlBreakHandlers`** (public):
- `type public CtrlBreakService` (`AbstractClass`) —
  - `new : channelName : string -> CtrlBreakService`
  - `abstract Interrupt : unit -> unit` — the host implements what an interrupt means for its session (typically calling `FsiEvaluationSession.Interrupt`).
  - `member Run : unit -> unit` — listens on the named pipe until a client connects, then reads lines; when the sentinel command is received, `Interrupt` is invoked. Must be run on its own thread; IO exceptions propagate to the caller.
- `type public CtrlBreakClient` —
  - `new : channelName : string -> CtrlBreakClient`
  - `member Interrupt : unit -> unit` — (re)connects to the named pipe (1 s timeout, silent failure) and writes the interrupt command.
  - `interface IDisposable` — releases the pipe client.

**Protocol constants** (implementation detail, in the .fs): sentinel line `"Interactive-CtrlCNotificationCommand-Interrupt"`, 1000 ms connect timeout.

**Significant internal logic**:
- One connection at a time is supported (`WaitForConnection` then read until EOF); each client connects just to signal and closes.
- Designed so a separate process/host that owns the UI thread can interrupt a long-running Fsi evaluation without sharing managed state.

**Cross-references**:
- Implementation: `FSharpInteractiveServer.fs`.
- `fsi.fs` — `FsiEvaluationSession.Interrupt`, the interrupt controller; `SpawnInteractiveServer` (launching the pipe server thread).

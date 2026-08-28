# ControlledExecution.fs

**Purpose**: Thin wrapper around `System.Runtime.ControlledExecution` (a .NET 7+ CoreCLR feature) that lets F# Interactive (Fsi) safely interrupt a running script thread. Because this compiler still supports older CoreCLR and the Windows desktop framework (netstandard2.0), the API is accessed via reflection and falls back to `Thread.Abort` where available.

**Namespace(s)**: `FSharp.Compiler.Interactive`

**Types**:
- `type internal ControlledExecution(isInteractive: bool)` — internal helper class.
  - `Run(action: Action) : unit` — if interactive and `ControlledExecution` is available, runs the action under a fresh `CancellationTokenSource` (stored for later abort); otherwise runs it directly on the current thread (kept for `ResetAbort`).
  - `TryAbort() : unit` — requests the in-flight action to stop: cancels the token on CoreCLR, or `Thread.Abort()` on the desktop CLR; no-op when not interactive.
  - `ResetAbort() : unit` — calls `Thread.ResetAbort()` (reflection) so a subsequent `Abort` works again; no-op elsewhere.
  - `static StripTargetInvocationException(exn) : Exception` — recursively unwraps `TargetInvocationException` to the root inner exception (the action was invoked via reflection, so real exceptions are wrapped).

**Internal helpers**:
- `static ceType`, `ceRun` — reflection lookups for `System.Runtime.ControlledExecution.Run(Action, CancellationToken)` from `System.Private.CoreLib` (may be absent on older runtimes).
- `static threadResetAbort` — reflection lookup of `Thread.ResetAbort`, only on non-CoreCLR.
- `mutable cts/thread` value-options track the current run for abort/reset.

**Significant internal logic**:
- All feature detection goes through `Type.GetType(..., false)` + `Option.ofObj`, so the type is safe to reference even when the runtime doesn't provide it (no `TypeLoadException` at load time).
- Gated by the `isInteractive` flag and `isRunningOnCoreClr` from `Internal.Utilities.FSharpEnvironment`.
- Used by the Fsi interrupt machinery in `fsi.fs` (`FsiInterruptController`) to stop user code when Ctrl+Break/Ctrl+C is pressed.

**Cross-references**:
- `fsi.fs` — `FsiInterruptController`, the session's `Interrupt()` member.
- `#nowarn "3262"` suppresses the nullness warning for `Type.GetType` under the netstandard2.0 profile.

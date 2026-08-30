# fsiaux.fs

> Pipeline role: Implementation of `FSharp.Compiler.Interactive.Settings` — the `IEventLoop` interface, a console-friendly `SimpleEventLoop` (thread/`AutoResetEvent`-based queue), the `InteractiveSession` settings object, and the `Settings.fsi` singleton with `AutoOpen`. Also emits the assembly-level `ComVisible(false)`/`CLSCompliant(true)` attributes and the legacy `Microsoft.FSharp.Compiler.Interactive` aliases.
> Namespace: `FSharp.Compiler.Interactive` (line 3).

---

## `type IEventLoop` (line 16)

Interface (see `fsiaux.fsi`): `Run`, `Invoke`, `ScheduleRestart`.

## `[<AutoSerializable(false)>] type internal SimpleEventLoop()` (line 23)

Console/thread-based event loop ("An implementation of IEventLoop suitable for the command-line console"):

- Signals: `runSignal`, `exitSignal`, `doneSignal` (`AutoResetEvent`s); a `queue: (unit -> obj) list` and `result: obj option`; flags `running`/`restart`.
- `setSignal` (busy `Set` retry loop) and `waitSignal`/`waitSignal2`.
- `interface IEventLoop`:
  - `Run()` — sets `running=true`; loops `waitSignal2 runSignal exitSignal`; on run-signal it drains `queue` (catching exceptions into `Some`/`None`), signals `doneSignal`, repeats; on exit-signal returns `restart`.
  - `Invoke(f)` — queues `[f >> box]`, signals `runSignal`, waits `doneSignal`, returns `unbox (Option.get result)`.
  - `ScheduleRestart()` — when `running`, sets `restart <- true` and signals `exitSignal` (comment: "nb. very minor race condition here on running here, but totally unproblematic as ScheduleRestart and Exit are almost never called").
- `IDisposable` disposes the three events.

## `[<Sealed>] type InteractiveSession()` (line 87)

Mutable settings state; default values: `evLoop = SimpleEventLoop`, `showIDictionary=true`, `showDeclarationValues=true`, `args = Environment.GetCommandLineArgs()`, `fpfmt = "g10"`, `fp = CultureInfo.InvariantCulture`, `printWidth=78`, `printDepth=100`, `printLength=100`, `printSize=10000`, `showIEnumerable=true`, `showProperties=true`, `addedPrinters=[]`.

- Properties: `FloatingPointFormat`, `FormatProvider`, `PrintWidth`, `PrintDepth`, `PrintLength`, `PrintSize`, `ShowDeclarationValues`, `ShowProperties`, `ShowIEnumerable`, `ShowIDictionary`, `AddedPrinters`, `CommandLineArgs`.
- `AddPrinter(printer: 'T -> string)` — prepends `Choice1Of2(typeof<'T>, unbox-based fn)`; `AddPrintTransformer(printer: 'T -> obj)` — `Choice2Of2`. (Registrations are last-in-first-won by the printer matching loop.)
- `EventLoop` setter schedules restart on the old loop before swapping (so GUI apps can hot-swap loops).
- `member internal SetEventLoop(run, invoke, restart)` — wraps the three functions in an `IEventLoop` instance and installs it (used by the FSI host when a WinForms/WindowsFormsEventLoop is requested).

## `module Settings` (line 178)

- `let fsi = new InteractiveSession()` — singleton.
- `[<assembly: AutoOpen("FSharp.Compiler.Interactive.Settings")>] do ()` — auto-open (duplicated with `fsiattrs.fs`).

## Legacy aliases (line 185)

`namespace Microsoft.FSharp.Compiler.Interactive` re-maps `IEventLoop`, `InteractiveSession`, and `Settings.fsi` to the new-namespace definitions (line 191–193) — joined after this so both views expose the same singleton instance.

---

## Related

- Contract in `fsiaux.fsi`; the FSI driver sets `fsi.EventLoop <- WinFormsEventLoop()` under desktop .NET (see `fsi\fsimain.fs`).
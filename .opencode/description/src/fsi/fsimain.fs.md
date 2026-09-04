# fsimain.fs

> Pipeline role: `fsi.exe` (F# Interactive) console entry point. Configures a Windows GUI/STA message loop when on desktop .NET, installs the `FsiEvaluationSession`, processes top-level arguments, optionally runs the "server-mode" TCP process for tooling, and executes `--times` statistics reporting. A second `evaluateSession` handles `--shadowcopyreferences` in a separate application domain.
> Namespace: `module internal Sample.FSharp.Compiler.Interactive.Main` (line 11).

---

## Implementation

- `SetCurrentUICultureForThread (lcid: int option)` (47) — sets thread UI culture honoring the `--lcid` switch.
- `callStaticMethod (ty: Type) name args` (59) — reflective call used to transparently try WinForms event-loop registration.
- `type DummyForm()` (74) — minimal `Form` for the no-WinForms case.
- `type WinFormsEventLoop()` (83) — wraps `Application.Run`/`Idle`; on coreclr chooses `SynchronizationContext`-free operation (NanoServer container without apartment threads — see comment near 350).
- `TrySetUnhandledExceptionMode()` (140) — best-effort `Application.SetUnhandledExceptionMode`.
- `StartServer (fsiSession: FsiEvaluationSession) fsiServerName` (152) — the `--server` mode: writes `ConcurrentDictionary`/named-mutex handshake and connects via `FsiServerWindows`? loops calling `session.EvalExpression` per command, printing results (used by interactive debugging/tooling).
- `evaluateSession (argv)` (172) — builds `FsiEvaluationSession` over the command line with the console provider (`ReadLineConsole` from `console.fs`), handles `--quiet`/`--ignore`? and the reflection `--use`/input loading, then `fsiSession.Run()` (345).
- `[<STAThread>]` (only under `!FX_NO_WINFORMS`) `[<EntryPoint>] [<LoaderOptimization(LoaderOptimization.MultiDomainHost)>] MainMain argv` (358):
  - re-reads `Environment.GetCommandLineArgs`; `--times` hooks `ProcessExit` to print `ILBinaryReader` "STATS:" counters (364–374).
  - `#if FSI_SHADOW_COPY_REFERENCES`: when `--shadowcopyreferences` is set and we are the default AppDomain, spawn a helper domain `"FSI_Domain"` with `ShadowCopyFiles <- "true"` and `ExecuteAssemblyByName` (376–399); falls back to non-shadow on `FileLoadException`. Otherwise `evaluateSession (argv)`.

---

## Related

- Builds on: `FSharp.Compiler.Interactive` (`FsiEvaluationSession`, `ConsoleLoggerProvider`, `InteractiveOptions`), `console.fs` (the readline console), `AbstractIL.ILBinaryReader`, `FSharp.Compiler.Driver`-adjacent plumbing.
- Counterpart: `fsc\fscmain.fs`.
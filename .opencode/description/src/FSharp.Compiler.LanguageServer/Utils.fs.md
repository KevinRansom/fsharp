# Utils.fs

> Pipeline role: Shared helpers for the F# language server — the `ILspLogger` adapter, F# `Range` → LSP `Range` and `FSharpDiagnostic` → LSP `Diagnostic` conversions, and an `Activity`-listener utility that surfaces the compiler's System.Diagnostics activity tracing (F# compiler `ActivityNames.FscSourceName`) on the console.
> Namespace: `FSharp.Compiler.LanguageServer` (line 1).

---

## `[<AutoOpen>] module Utils` (line 11)

- `type LspRange = Microsoft.VisualStudio.LanguageServer.Protocol.Range`.
- `let LspLogger (output: string -> unit) : ILspLogger` — adapter writing formatted lines: `EndContext :: ...`, `ERROR :: ...`, `EXCEPTION :: ...`, `INFO :: ...`, `StartContext :: ...`, `WARNING :: ...`.
- `type FSharp.Compiler.Text.Range with member ToLspRange()` — converts to 0-based `LspRange` (Start/End `Position`, line − 1 kept, column unchanged).

## `[<Extension>] type FSharpDiagnosticExtensions` (line 46)

- `[<Extension>] static member ToLspDiagnostic(this: FSharpDiagnostic) : Diagnostic` — `Range = this.Range.ToLspRange()`, `Severity = DiagnosticSeverity.Error`, `Message = "LSP: " + this.Message`, `Code = SumType<int, _>(this.ErrorNumberText)`.

## `module Activity` (line 58)

- `listen (filter) logMsg` — installs an `ActivityListener` for `FSharp.Compiler.Diagnostics.ActivityNames.FscSourceName`: samples by `filter` name, and on `ActivityStarted` logs an indented (by parent depth) `"{operationName}     {tags}"` line. `listenToAll()`/`listenToSome()` (the latter filtering out names containing `"StackGuard"`) wired to `Trace.TraceInformation`.

---

## Related

- Consumed by `FSharpLanguageServer` (logger) and the LSP Executable host; diagnostic conversion is what `LanguageFeaturesHandler` uses for pull-diagnostics.
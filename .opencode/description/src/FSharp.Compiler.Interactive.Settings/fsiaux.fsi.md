# fsiaux.fsi

> Pipeline role: Public contract for the F# Interactive session settings library — declares the `IEventLoop` interface, `InteractiveSession` (settings + printer registration), and the `Settings.fsi` object, plus legacy `Microsoft.FSharp.Compiler.Interactive` type aliases.
> Namespace: `FSharp.Compiler.Interactive` (line 3).

---

## `type IEventLoop` (line 7)

"An event loop used by the currently executing F# Interactive session to execute code in the context of a GUI or another event-based system."

- `abstract Run: unit -> bool` — "Run the event loop. Returns true if the event loop was restarted; false otherwise."
- `abstract Invoke: (unit -> 'T) -> 'T` — "Request that the given operation be run synchronously on the event loop. Returns the result."
- `abstract ScheduleRestart: unit -> unit` — schedule a restart.

## `[<Sealed>] type InteractiveSession` (line 24)

- Printing knobs: `FloatingPointFormat: string`, `FormatProvider: System.IFormatProvider`, `PrintWidth: int`, `PrintDepth: int`, `PrintLength: int`, `PrintSize: int`.
- Display toggles: `ShowProperties: bool`, `ShowIEnumerable: bool`, `ShowDeclarationValues: bool`.
- `AddPrinter: ('T -> string) -> unit` — "Register a printer that controls the output of the interactive session."
- `AddPrintTransformer: ('T -> obj) -> unit` — "Register a print transformer that controls the output of the interactive session."
- `member internal AddedPrinters: Choice<(Type * (obj -> string)), (Type * (obj -> obj))> list` — accumulated registered printers/transformers consumed by the pretty-printer.
- `CommandLineArgs: string[] with get, set` — docs: "The command line arguments after ignoring the arguments relevant to the interactive environment and replacing the first argument with the name of the last script file, if any. Thus 'fsi.exe test1.fs test2.fs -- hello goodbye' will give arguments 'test2.fs', 'hello', 'goodbye'. This value will normally be different to those returned by System.Environment.GetCommandLineArgs."
- `EventLoop: IEventLoop with get, set` — current event loop used to process interactions.
- `member internal SetEventLoop: (unit -> bool) * ((unit -> obj) -> obj) * (unit -> unit) -> unit`.

## `module Settings` (line 74)

- `val fsi: InteractiveSession` — the singleton session object.

## Legacy aliases (namespaces `Microsoft.FSharp.Compiler.Interactive`, line 80)

- `type IEventLoop = FSharp.Compiler.Interactive.IEventLoop`, `type InteractiveSession = FSharp.Compiler.Interactive.InteractiveSession`, `module Settings = ...` (line 86) re-exporting `fsi` — for historical sources referencing the old namespace.

---

## Related

- Implementation in `fsiaux.fs`; consumers: the FSI host (`fsimain.fs`), the `FSharp.Compiler.Interactive` service (`FsiEvaluationSession`), and FSharp.Core's runtime printing.
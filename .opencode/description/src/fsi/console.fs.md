# console.fs

> Pipeline role: The `fsi.exe` interactive console — a from-scratch "readline" editing layer used when running on Windows console: history management, input line editing with prompt and continuation prompt, tab completion hooks, cursor/anchor positioning, and full-width (CJK) character handling. Implements the `IInteractiveConsoleProvider`-ish surface that `FsiEvaluationSession` drives (`Printing`, `Prompt`, `ReadInput`...).
> Namespace: `FSharp.Compiler.Interactive` (line 3).

---

## Types & functions

- `type internal Style = Prompt | Out | Error` (11) — print styling classifications forwarded to the console provider.
- `type internal History() : class` (17) — wraps a `List<string>` with a rotating `current` index; `Count`, `Current`, `Clear`, `Add` (ignores `null`/`""`), `AddLast` (also resets `current` to the end), `Previous`/`Next` (circular). Used both for entry history and for tab-completion *option cycling* via the `Options` subclass.
- `type internal Options() = inherit History()` (60), `Root` property — the "list of available optionsCache"; completion candidates are navigated with the inherited previous/next.
- `module internal Utils` (71):
  - `guard f` — runs console calls inside a try; on exception emits a `warning(Failure("Note: an unexpected exception in fsi.exe readline console support. Consider starting fsi.exe with the --no-readline option ..."))` including the stack trace.
  - Word-motion helpers `previousWordFromIdx`/`nextWordFromIdx` (line/space-aware) for Ctrl-arrow editing.
  - `isFullWidth (char)` (169) — tests East-Asian-width via `Array.BinarySearch` over the concatenated `fullWidthCharRanges` (Unicode UAX #11 ranges; encoding trick: `n >= 0 || n % 2 = 0` means inside a range, since range start/end land on even positions).
  - `bufferWidth () = Console.BufferWidth - 2` (199) — documented: leaving one column spare keeps full-width characters from mis-rendering or jumping cursor positions.
- `[<Sealed>] type internal Cursor` (202) — `static member ResetTo(top,left)` (clamped to `BufferHeight-1`), `static member Move(delta)` (linear cursor addressing using `bufferWidth`).
- `type internal Anchor = { top:int; left:int }` (216) — `Current(inset)`, `Top(inset)`, and `PlaceAt(inset,index)` (two-dimensional placement for wrapping prompts).
- `type internal ReadLineConsole()` (239) — the main console:
  - `history`; `supportsBufferHeightChange` (Windows only); `complete : string option * string -> seq<string>` set via `SetCompletionFunction` (hooks `fsi`'s tab-completion API from `FsiEvaluationSession`).
  - `Prompt = "> "`, `Prompt2 = "- "`, `Inset = Prompt.Length`.
  - `GetOptions(input)` (256) — computes `Options` completion candidates for the text before the cursor with parenthesis/quote balance tracking (`look parenCount i`).
  - Line editing: `Insert`/`BackSpace`/`Delete`/word-delete, `Move`, `Home`/`End`, `Up`/`Down` (history), `Tab` (completion + cycling), `Enter` (returns a completed line), arrow-key translation from console key events, and multi-line continuation detection (unterminated `(`, `[`, `{`, string/triple-quote, `;`? — returning the extra prompt).
  - `Write`-style output methods (`Write`, `WriteLine` with `Style` coloring: prompts green, errors red per `errorStyles`?), `ReadInput(prefix)` loop, and the `IsValidCompletion` predicates.
  - Also implements `IDisposable`-ish console restore and the `startupText`/sign-off banner handling used when `--quiet` is off (name/version rendered via `fsihelp`-supplied text).
  - `Reinit`/`WriteStartupText` etc. used during `--exec`/`#quit`.

---

## Related

- Builds on: `FSharp.Compiler.DiagnosticsLogger` (`warning`, `Failure`), the F# interactive session API (`FSharp.Compiler.Interactive.Settings` contracts for `IInteractiveConsole`/`IEventLoop`).
- Uses: `fsihelp`/`fsiattrs` strings for the banner; used by `fsimain.fs` through `FsiEvaluationSession`. Alternative implementation used on Unix/non-Windows hosts (a simpler console) — this file is Windows-specific.
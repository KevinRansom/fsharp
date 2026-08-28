# ildiag.fs

**Purpose**: Minimal configurable diagnostics channel for the F#/compiler IL-related tooling in this area. Provides a small printf-style helper set that writes to a settable `TextWriter` (defaulting to `stdout` in the .fs; the .fsi notes it historically pointed at stderr). Used throughout `illib` and other internal libraries to produce trace/diagnostic output that can be re-targeted off or pointed at any sink.

**Namespace(s)** declared: `FSharp.Compiler.AbstractIL.Diagnostics` (module is `internal`).

**Modules declared**:
- `module internal FSharp.Compiler.AbstractIL.Diagnostics` — the single diagnostics channel module.

**Public API surface** (per ildiag.fsi; all `val`s are `public`-qualified but the module is `internal`):
- `diagnosticsLog : TextWriter option` (mutable, .fs) — current diagnostics sink; `None` disables output.
- `setDiagnosticsChannel : TextWriter option -> unit` — redirect/disable the channel.
- `dflushn : unit -> unit` — write a newline and flush.
- `dflush : unit -> unit` — flush the current writer.
- `dprintn : string -> unit` — write a line then flush.
- `dprintf : Format<'a,'b,'c,'d> -> 'a` — formatted write then `dflush` (see .fs).
- `dprintfn : Format<'a,'b,'c,'d> -> 'a` — formatted write then `dflushn` (see .fs).

**Internal helpers / notable items**:
- `dflushn`/`dflush`/`dprintn` all check the `diagnosticsLog` option before emitting, so callers can safely call them when diagnostics are off.
- `dprintf` / `dprintfn` are implemented via `Printf.kfprintf` bound to either the current writer or `TextWriter.Null`.

**Significant internal logic / behavioral notes**:
- All output functions call `Flush()` after writing, so a diagnostics line is never buffered on exit; this is documented in the .fsi ("All functions call flush() automatically").
- The .fsi contains a note: "REVIEW: review if we should just switch to System.Diagnostics" — this is a deliberately small, dependency-light channel rather than a structured logging system.
- Contrast with sibling `.md` files: `Caches.md` / `LruCache.md` / `Activity.md` are all telemetry/instrumentation layers that are higher-order; `ildiag` is a raw text channel with no structure.

**Cross-references**: none of the other listed siblings directly reference `ildiag`; it is consumed by the AbsIL tooling (see sibling `illib.md`) and by any compiler code that wants a switchable diagnostic sink.

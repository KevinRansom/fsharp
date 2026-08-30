# ildiag.fsi

**Purpose**: Signature file for `ildiag.fs` (same directory, namespace `FSharp.Compiler.AbstractIL.Diagnostics`). Documents the small configurable diagnostics channel used by the AbsIL / IL tooling; the module is `internal` but exposes three printf-style entry points and a setter for the underlying `TextWriter`.

**Namespace(s)** declared: `FSharp.Compiler.AbstractIL.Diagnostics` (declared `module internal`).

**Declared items** (public contract, all `val public`):
- `setDiagnosticsChannel: TextWriter option -> unit` — redirect or disable (pass `None`) the diagnostics sink.
- `dprintfn: TextWriterFormat<'a> -> 'a`
- `dprintf: TextWriterFormat<'a> -> 'a`
- `dprintn: string -> unit`

**Relationship to .fs**: The .fs additionally defines the mutable `diagnosticsLog : TextWriter option` storage (initialized to `Some stdout`), and the `dflush` / `dflushn` helper used by the printf forms; those helpers are not part of the .fsi. The .fsi doc comment notes the channel historically pointed at stderr and calls `flush()` after every write.

**Cross-references**: see sibling `ildiag.md`.

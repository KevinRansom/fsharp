# ilprint.fs

**Purpose**
DEBUG-only pretty printer (`output_module`) for the abstract IL algebra. Serializes an entire `ILModuleDef` (types, methods, fields, instructions, attributes, manifests) back into the ILASM/ASCII-IL text format (using the `AsciiConstants` mnemonic tables) so compiler developers can inspect/diff the IL tree during debugging.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILAsciiWriter`)

**Public API surface** (see `ilprint.fsi`)
- `output_module (writer: TextWriter) (ilg: ILGlobals) (modul: ILModuleDef) : unit` — the single entry point; gated by `#if DEBUG`.

**Key internals (one-line descriptions)**
- `tyvar_generator` — a mutable counter that turns generic-parameter indices into fresh `!1..!n` names during printing (avoids name collisions between enclosing type and method type vars).
- `ppenv` (record) — the printing environment: `{ ilGlobals; ppenvClassFormals: int; ppenvMethodFormals: int }`; the way typeVar `!n` is printed depends on which scope (class vs. method) the current type occurs in.
- `ppenv_enter_method (mgparams, env)`, `ppenv_enter_tdef (gparams, env)`, `ppenv_enter_modul env`, `mk_ppenv ilg` — environment transitions when descending into a method / type-def / module.
- `output` helpers (further down the file) — text-stream pretty-printers for types, instructions, custom attributes, manifests, and the module as a whole.

**Significant internal logic**
- The printer uses the `AsciiConstants` tables (word lists) to render `ILInstr` nodes back to mnemonics — the reverse of what `illex.fsl`/`ilpars.fsy` parse.
- It is DEBUG-only (compiled in only under `#if DEBUG`), so it is not part of the shipped compiler's surface.

**Cross-references**
- `ilprint.fsi` (contract), `il.fs` (ILModuleDef, ILType, ILInstr, ILGlobals, ...), `ilascii.fs` (mnemonic tables)

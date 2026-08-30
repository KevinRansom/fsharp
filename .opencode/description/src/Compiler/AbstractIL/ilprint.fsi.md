# ilprint.fsi

**Purpose**
Interface contract for the DEBUG-only IL printer (`ILAsciiWriter`). The single entry point `output_module` walks an `ILModuleDef` and pretty-serializes it back into the ILASM/ASCII-IL text form (using the `AsciiConstants` mnemonic tables), so compiler developers can inspect/diff the IL tree during debugging.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.ILAsciiWriter`)

**Public API surface** (see the .fsi body)
- `output_module : System.IO.TextWriter -> ILGlobals -> ILModuleDef -> unit` — pretty-print a whole module to the given `TextWriter`.
- The whole module is `#if DEBUG`-gated, so it is only present in DEBUG builds of FSharp.Build.

**Cross-references**
- `ilprint.fs` (implementation), `il.fs` (ILModuleDef, ILGlobals), `ilascii.fs` (mnemonic tables used to render instructions)

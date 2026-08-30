# XmlAdapters.fsi

**Purpose**: Signature file for `XmlAdapters.fs`. Declares the internal XML-escape helpers in `Internal.Utilities.XmlAdapters` — the compiler's cross-platform replacement for `System.Security.SecurityElement.Escape`.

**Namespace(s)**: None — `module internal Internal.Utilities.XmlAdapters`.

**Modules / Types declared**:

- `module internal Internal.Utilities.XmlAdapters` — the only declaration.

**Public API surface** (all internal, as declared):

- `val s_escapeChars: char[]` — the escapable character set.
- `val getEscapeSequence: c: char -> string` — per-character entity mapping.
- `val escape: str: string -> string` — whole-string escape.

**Internal helpers**: None.

**Significant internal logic**: None in the signature.

**Cross-references**: Companion implementation `XmlAdapters.fs` (same directory, `src/Compiler/Utilities/`).

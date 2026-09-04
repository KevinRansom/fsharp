# XmlAdapters.fs

**Purpose**: Small internal utility providing XML character escaping for the compiler, explicitly intended as a cross-platform replacement for `System.Security.SecurityElement.Escape(line)` (which the file header notes is being replaced on all platforms). Used when emitting or adapting XML content (e.g. XML documentation comment processing) where `<`, `>`, `"`, `'`, `&` must be entity-escaped.

**Namespace(s)**: None — declared as `module internal Internal.Utilities.XmlAdapters`.

**Modules / Types declared**:

- `module internal Internal.Utilities.XmlAdapters` — the whole file; no types.

**Public API surface** (all internal):

- `s_escapeChars : char[]` — `[| '<'; '>'; '\"'; '\''; '&' |]`, the set of characters needing escaping.
- `getEscapeSequence (c: char) : string` — maps a character to its XML entity: `<`→`&lt;`, `>`→`&gt;`, `"`→`&quot;`, `'`→`&apos;`, `&`→`&amp;`, any other character to itself (`ch.ToString()`).
- `escape (str: string) : string` — `String.collect getEscapeSequence str`; escapes the whole string.

**Internal helpers**: None beyond the three values above.

**Significant internal logic**: None — a direct character-by-character map. Note that unlike some escapers, this one escapes both `<`/`>` (not only `&`/quotes), and it does not escape control characters or non-ASCII text (they pass through unchanged).

**Cross-references**: `XmlAdapters.fsi` (same directory) declares the same three values. Served as a `SecurityElement.Escape` stand-in for XML doc-comment and XML serialization paths inside the compiler; otherwise independent of the sibling Utilities modules.

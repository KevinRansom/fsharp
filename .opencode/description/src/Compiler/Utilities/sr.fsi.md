# sr.fsi

**Purpose**: Signature file for `sr.fs`. Declares the internal contract for compiler resource-string lookup: `SR.GetString` (fetch a localized message by ID from the compiler's resource set) and `DiagnosticMessage` (bind a message ID + `Printf.StringFormat` signature to a reusable `ResourceString<'T>`).

**Namespace(s)**: `FSharp.Compiler`

**Modules / Types declared**:

- `module internal SR`
- `module internal DiagnosticMessage`
  - `type ResourceString<'T>` — `new: string * Printf.StringFormat<'T> -> ResourceString<'T>`; `member Format: 'T`.

**Public API surface** (all internal):

- `val SR.GetString: string -> string` — resource lookup by message ID.
- `val DiagnosticMessage.DeclareResourceString: string * Printf.StringFormat<'T> -> ResourceString<'T>` — declare a resource string for `messageID` with format signature `fmt`; the returned `ResourceString`'s `Format` member yields the message (a value of `'T`, typically a function of the message's arguments).
- `type ResourceString<'T>.Format: 'T` — the formatted-message value.

**Internal helpers**: None exposed; `mkFunctionValue`, `capture1`, `postProcessString`, `createMessageString`, and the DEBUG-only hole/placeholder counters are implementation-private to `sr.fs`.

**Significant internal logic**: None in the signature; it exposes exactly the public entry points the compiler uses to declare and fetch error/warning messages by ID.

**Cross-references**: Companion implementation `sr.fs` (same directory); the `ResourceString<'T>` type is the unit through which every compiler diagnostic message (in `checks.fs`, `tastcheck.fs`, `lookup.fs`, etc.) is declared, tying this module to the whole diagnostic pipeline of `FSharp.Compiler`.

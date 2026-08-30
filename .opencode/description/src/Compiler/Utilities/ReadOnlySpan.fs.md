# ReadOnlySpan.fs

**Purpose**: Shims a handful of `ReadOnlySpan<char>` search extensions that are not present on the .NET 7-and-newer BCL, so the compiler's source-scanning code (lexing, scanning helpers) can use span-based search uniformly across target frameworks. Compiled only when the BCL lacks these members.

**Namespace(s)**: `System` (deliberately placed in `System` so the extensions are found by extension-method resolution on `ReadOnlySpan<char>`).

**Modules / Types declared**:

- `[<Sealed; AbstractClass; Extension>] type ReadOnlySpanExtensions` — static extension class, declared only under `#if !NET7_0_OR_GREATER`.

**Public API surface** (internal extension members, all on `ReadOnlySpan<char>`):

- `IndexOfAnyExcept(span, value0: char, value1: char) : int` — index of first char that is neither `value0` nor `value1`, else `-1`.
- `IndexOfAnyExcept(span, values: ReadOnlySpan<char>) : int` — first char not contained in `values` (uses `values.IndexOf`), else `-1`.
- `IndexOfAnyExcept(span, value: char) : int` — first char that is not `value`, else `-1`.
- `LastIndexOfAnyInRange(span, lowInclusive: char, highInclusive: char) : int` — last char in the inclusive range `[low, high]`, else `-1`.
- `LastIndexOfAnyExcept(span, value: char) : int` — last char that is not `value`, else `-1`.

**Internal helpers**: None beyond the five extension methods; each is a simple linear scan via indexed span access.

**Significant internal logic**: The whole file is wrapped in `#if !NET7_0_OR_GREATER` — on .NET 7+ the BCL provides equivalent `ReadOnlySpan` search members, so this file compiles to nothing there. Placement in namespace `System` with `[<Extension>]` static members is what makes them available as method-call syntax (`span.IndexOfAnyExcept(...)`) at call sites in the compiler.

**Cross-references**: `.fsi` counterpart `ReadOnlySpan.fsi` (same directory) mirrors these five signatures as `internal`. Used by the compiler's text/lexing utilities that scan `ReadOnlySpan<char>` source chunks.

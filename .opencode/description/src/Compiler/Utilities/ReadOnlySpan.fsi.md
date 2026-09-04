# ReadOnlySpan.fsi

**Purpose**: Signature file for `ReadOnlySpan.fs`. Declares the internal `ReadOnlySpanExtensions` static extension class (in namespace `System`) providing span-search helpers that mirror BCL members, compiled only when targeting below .NET 7.

**Namespace(s)**: `System`

**Modules / Types declared**:

- `[<Sealed; AbstractClass; Extension>] type internal ReadOnlySpanExtensions` — extension class, under `#if !NET7_0_OR_GREATER`.

**Public API surface** (all internal extension members on `ReadOnlySpan<char>`):

- `static member IndexOfAnyExcept: span: ReadOnlySpan<char> * value0: char * value1: char -> int`
- `static member IndexOfAnyExcept: span: ReadOnlySpan<char> * values: ReadOnlySpan<char> -> int`
- `static member IndexOfAnyExcept: span: ReadOnlySpan<char> * value: char -> int`
- `static member LastIndexOfAnyInRange: span: ReadOnlySpan<char> * lowInclusive: char * highInclusive: char -> int`
- `static member LastIndexOfAnyExcept: span: ReadOnlySpan<char> * value: char -> int`

All return the span index of the match or `-1`.

**Internal helpers**: None.

**Significant internal logic**: None in the signature; the `#if !NET7_0_OR_GREATER` guard means the signature (like the implementation) is a no-op on modern TFMs where the BCL provides the members.

**Cross-references**: Companion implementation `ReadOnlySpan.fs` (same directory). Part of the compiler-internal utilities under `src/Compiler/Utilities/`.

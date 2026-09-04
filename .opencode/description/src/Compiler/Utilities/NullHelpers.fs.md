# NullHelpers.fs

**Purpose**: A small auto-opened utility module in the compiler-internal `Internal.Utilities.Library` namespace providing null-handling helpers used throughout the compiler for safely working with possibly-null references (e.g. from `ResourceManager`, reflection, P/Invoke-style APIs). It complements `Uncheck.nullCheck`-style helpers by offering a null-preserving inverse (`!!`) and a null-safe equality combinator.

**Namespace(s)**: `Internal.Utilities.Library`

**Modules / Types declared**:

- `module internal NullHelpers` (`[<AutoOpen>]`) — the only declaration; auto-opened when the namespace is opened so its operators/idents are ambient.

**Public API surface** (all `internal`, inline):

- `isNotNull (x: 'T) : bool` — `not (isNull x)`, the inverse of `Internal.Utilities.Library.Extras`-style `isNull` idiom.
- `!! (x: 'T | null) : 'T` — `Unchecked.nonNull x`; asserts non-null and strips the null type annotation.
- `nullSafeEquality (x, y) (nonNullEqualityFunc) : bool` — null-aware equality; uses `[<InlineIfLambda>]` for the supplied non-null comparer so both-null compares as true, and one-null compares false.

**Internal helpers / noteworthy details**:

- `type objEqualsArg` — a conditional type alias used as the argument type for `System.Object.Equals(arg)` overrides: `objnull` on `NET5_0_OR_GREATER` (nullable annotation available) and plain `obj` on older targets. This alias is referenced by internal collections that override `Equals` (e.g. TaggedCollections) so their signatures compile across TFMs.
- `#if NET5_0_OR_GREATER` conditional compilation for the alias above.
- `|NonEmptyString|_|` active pattern (`[<return: Struct>]`): matches a `string | null` that is neither null nor empty, yielding the non-empty string; `ValueNone` otherwise. Used in compiler code checking for non-trivial strings.

**Significant internal logic**: All operations are `inline` to avoid boxing/allocation overhead in hot compiler paths; `nullSafeEquality` defers the actual comparison to a caller-supplied function so it can be used with structural or custom equality without capturing it.

**Cross-references**: Sibling files under `src/Compiler/Utilities/` such as `lib.fs` (the same `Internal.Utilities.Library` namespace) and the `Internal.Utilities.Library.Extras` module commonly consumed here; `objEqualsArg` is used by `TaggedCollections.fs` (`Set`/`Map` `Equals` overrides) and `sr.fs`.

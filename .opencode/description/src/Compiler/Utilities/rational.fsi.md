# rational.fsi

**Purpose**: Signature file for `rational.fs`. Exposes the internal `Rational` type (a rational number over `BigInteger`) and the arithmetic operations used for exponents on units-of-measure, hiding the `{ numerator; denominator }` record representation.

**Namespace(s)**: None — `module internal Internal.Utilities.Rational` (qualified module declaration under the `Internal.Utilities` area).

**Modules / Types declared**:

- `module internal Internal.Utilities.Rational`
- `type Rational` — opaque to consumers; documented in comments on the accessors.

**Public API surface** (all internal, as declared):

- `val intToRational: int -> Rational`
- `val ZeroRational: Rational`
- `val OneRational: Rational`
- `val AbsRational: Rational -> Rational`
- `val AddRational: Rational -> Rational -> Rational`
- `val MulRational: Rational -> Rational -> Rational`
- `val DivRational: Rational -> Rational -> Rational`
- `val NegRational: Rational -> Rational`
- `val SignRational: Rational -> int`
- `val GetNumerator: Rational -> int` — commented "Can be negative".
- `val GetDenominator: Rational -> int` — commented "Always positive" (the normalization guarantee).
- `val GcdRational: Rational -> Rational -> Rational` — commented "Greatest rational that divides both exactly".
- `val RationalToString: Rational -> string`

**Internal helpers**: None exposed in the signature; `mkRational`, `gcd`, `lcm` are implementation-only in `rational.fs`.

**Significant internal logic**: None in the signature itself; it pins the normalization contract (positive denominator, reducible numerator) that the implementation enforces via `mkRational`, enabling reliable structural equality/hash of rationals in typechecking.

**Cross-references**: Companion implementation is `rational.fs` in the same directory; consumed by `TypeHashing.fs` (rational exponent hashing) and the units-of-measure typechecker.

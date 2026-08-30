# rational.fs

**Purpose**: Rational-number arithmetic over `BigInteger`, used by the compiler for exponents on units-of-measure (`[<Measure>]` powers such as `m^(-1/2)`). Provides exact, normalized rational construction and the arithmetic needed by the typechecker when simplifying measure expressions.

**Namespace(s)**: None — declared as `module internal Internal.Utilities.Rational` (a fully-qualified-module-name declaration, so it is opened as `Internal.Utilities.Rational`).

**Modules / Types declared**:

- `module internal Internal.Utilities.Rational` — the whole file.
- `type Rational = { numerator: BigInteger; denominator: BigInteger }` — record (structurally equal, comparison available since only BCL types).

**Public API surface** (all internal):

- `mkRational p q` — constructs a normalized rational: divides by `gcd(q, p)`, forces the denominator positive (by flipping both signs), raises `DivideByZeroException` for `q = 0`. (Not re-exported in the .fsi but used by all ops.)
- `intToRational (p: int) : Rational`
- `ZeroRational`, `OneRational` — predefined values.
- `AddRational m n` — addition using a `gcd`-reduced common denominator.
- `NegRational m`, `MulRational m n`, `DivRational m n`, `AbsRational m` — standard operations, each routed through `mkRational` so results stay reduced/normalized.
- `GcdRational m n` — "greatest rational that divides both exactly": `gcd` of numerators over `lcm` of denominators.
- `GetNumerator p : int` (can be negative) / `GetDenominator p : int` (always positive).
- `SignRational p : int` — -1/0/1 by numerator sign.
- `RationalToString m` — integer form when denominator is 1, else `"(p/q)"`.

**Internal helpers**: `gcd a b` (Euclidean, recursive), `lcm a b = a*b / gcd a b`.

**Significant internal logic**: Normalization happens exactly once at construction (`mkRational`), so every subsequent operation is just `BigInteger` multiply/divide plus re-reduction; the canonical sign convention (denominator > 0) makes equality by structural record equality well-defined. This arithmetic underlies units-of-measure type analysis, where exponents are rational numbers on measure variables.

**Cross-references**: `.fsi` counterpart `rational.fsi` (same directory). Used by `TypeHashing.fs` (`open Internal.Utilities.Rational`; `hash exp` for rational exponents) and by the typechecker's measure/type-unification code paths.

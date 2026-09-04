# z.fs

> Pipeline role: Implementation companion of `z.fsi` — preserves the empty-but-present `Microsoft.FSharp.Math` namespace for source compatibility (programs containing `open FSharp.Math`) and defines the `bigint` abbreviation plus the `NumericLiteralI` module giving F# big-integer literal (`` `ddd I ``) support via statically-resolved `FromZero`/`FromOne`/`FromInt32`/`FromInt64`/`FromString`.
> Namespace: `Microsoft.FSharp.Math` (deliberately empty, lines 1–14), then `Microsoft.FSharp.Core`.

---

## Implementation

- The `Microsoft.FSharp.Math` namespace block is **deliberately left empty** — comment (lines 7–13): "FSharp.Core previously exposed the namespace Microsoft.FSharp.Math even though there were no types in it. This retains that. Existing programs could, and did contain the line: open FSharp.Math".
- `type bigint = System.Numerics.BigInteger` (line 17).
- `[<AutoOpen>] module NumericLiterals` (line 26):
  - `module NumericLiteralI`:
    - `tab64 : Dictionary<int64, objnull>` and `tabParse : Dictionary<string, objnull>` — caches of boxed `BigInteger`s for literals (`#nowarn "44"` for the deprecated-construct usage; values are `objnull` boxed).
    - `FromInt64Dynamic value` (33) — thread-safe (lock) memoized `BigInteger(value)`.
    - `inline get32 (x32)` — `FromInt64Dynamic(int64 x32)`.
    - `isOX s` — detects `0x`/`0X` prefixes.
    - `FromZero()/FromOne()/FromInt32/FromInt64` (generic, SRTP-constrained to `BigInteger`): cast the dynamic bigint; statically `when 'T: BigInteger`.
    - `getParse s` — lock-guarded memoized parse: `BigInteger.Parse(s.[2..], AllowHexSpecifier, InvariantCulture)` when `isOX`, else `BigInteger.Parse(s, AllowLeadingSign, InvariantCulture)`.
    - `FromStringDynamic text` = `getParse text`; `FromString text` (generic) = cast of the dynamic value.

---

## Related

- Auto-opened through the contract (`z.fsi`); the `I`-suffix literal syntax is what makes `123I`, `0x10I` work out of the box in F# code.
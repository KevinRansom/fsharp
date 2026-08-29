# z.fsi

> Pipeline role: Public contract for `Microsoft.FSharp.Math` compatibility and the `bigint`/`NumericLiteralI` definitions in `Microsoft.FSharp.Core`. Keeps the documented FSharp.Core surface stable.
> Namespace: `Microsoft.FSharp.Math` (empty), then `Microsoft.FSharp.Core` (line 13).

---

## Contract

- `type bigint = System.Numerics.BigInteger` (line 18) — "An abbreviation for BigInteger" (category "Basic Types", doc-commented in `z.fsi`).
- `[<AutoOpen>] module NumericLiterals` (line 24) — "Provides a default implementation of F# numeric literal syntax for literals of the form 'dddI'" (category "Language Primitives"):
  - `module NumericLiteralI` with `FromZero: unit -> 'T`, `FromOne: unit -> 'T`, `FromInt32: int32 -> 'T`, `FromInt64: int64 -> 'T`, `FromString: text: string -> 'T`, plus the statically-resolved dynamic variants `FromInt64Dynamic: int64 -> objnull`, `FromStringDynamic: text: string -> objnull`.

---

## Related

- Implementation in `z.fs`; auto-opened so `1I`/`42I` literals work without an explicit open (via `FSharp.Core`'s top-level).
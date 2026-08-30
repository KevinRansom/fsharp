# WellKnownAttribs.fsi

**Purpose**: Compilation interface for the flags enums and generic well-known-attribute wrapper. Provides the same `[<System.Flags>]` enums (`WellKnownEntityAttributes`, `WellKnownAssemblyAttributes`, `WellKnownValAttributes`) and the `WellKnownAttribs<'TItem,'TFlags>` struct contract used to get O(1) lookups for well-known attributes on entities and vals, avoiding O(N) linear scans of attribute lists.

**Namespace(s)**: `FSharp.Compiler`.

**Declared types (signatures)** — identical flag sets as the `.fs` (entity/assembly/val enums with the `NotComputed = 1uL <<< 63` sentinel), plus:
- `WellKnownAttribs<'TItem, 'TFlags when 'TFlags: enum<uint64>>` (`[<Struct; NoEquality; NoComparison>]`):
  - `new: attribs: 'TItem list * flags: 'TFlags -> ...`
  - `AsList: unit -> 'TItem list`; `Flags : 'TFlags`
  - `HasWellKnownAttribute: 'TFlags -> bool`
  - `Add: 'TItem * 'TFlags -> WellKnownAttribs<...>`
  - `WithRecomputedFlags: unit -> WellKnownAttribs<...>`
  - `CheckFlag: flag * compute -> struct (bool * WellKnownAttribs * bool)`

**Internal module `Flags`** (contract): `inline isEmpty`, `union`, `intersect`, `except`, `intersects`, `isSubsetOf` over any `enum<uint64>` flag type.

**Notes**: The `.fsi` omits the private `attribs`/`flags` val accessors that appear as `val private` in the `.fs`; otherwise the flag enums are re-declared verbatim so both projects share the same layout.

**Cross-references**: `WellKnownAttribs.fs` (implementation), `TypedTreeOps.Attributes.fs` (computes these flags), `TypedTreePickle.fs` (pickle support).

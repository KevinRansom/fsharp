# zset.fsi

**Purpose**: Signature file for `zset.fs`. Declares the internal `Zset<'T>` alias (tagged/comparer-parameterized set) and the functional `Zset` module in `Internal.Utilities.Collections`, documenting the type as "Sets with a specific comparison function".

**Namespace(s)**: `Internal.Utilities.Collections`

**Modules / Types declared**:

- `type internal Zset<'T> = Internal.Utilities.Collections.Tagged.Set<'T>` — alias for the tagged set.
- `module internal Zset` — functional helpers.

**Public API surface** (all internal, as declared):

- `val empty: IComparer<'T> -> Zset<'T>`
- `val isEmpty: Zset<'T> -> bool`
- `val contains: 'T -> Zset<'T> -> bool`
- `val memberOf: Zset<'T> -> 'T -> bool`
- `val add: 'T -> Zset<'T> -> Zset<'T>`
- `val addList: 'T list -> Zset<'T> -> Zset<'T>`
- `val singleton: IComparer<'T> -> 'T -> Zset<'T>`
- `val remove: 'T -> Zset<'T> -> Zset<'T>`
- `val count: Zset<'T> -> int`
- `val union: Zset<'T> -> Zset<'T> -> Zset<'T>`
- `val inter: Zset<'T> -> Zset<'T> -> Zset<'T>`
- `val diff: Zset<'T> -> Zset<'T> -> Zset<'T>`
- `val equal: Zset<'T> -> Zset<'T> -> bool`
- `val subset: Zset<'T> -> Zset<'T> -> bool`
- `val forall: predicate: ('T -> bool) -> Zset<'T> -> bool`
- `val exists: predicate: ('T -> bool) -> Zset<'T> -> bool`
- `val filter: predicate: ('T -> bool) -> Zset<'T> -> Zset<'T>`
- `val fold: ('T -> 'State -> 'State) -> Zset<'T> -> 'State -> 'State`
- `val iter: ('T -> unit) -> Zset<'T> -> unit`
- `val elements: Zset<'T> -> 'T list`

**Internal helpers**: None declared beyond the above.

**Significant internal logic**: None in the signature.

**Cross-references**: Companion implementation `zset.fs` (same directory); depends on `TaggedCollections.fsi`/`.fs` (`Internal.Utilities.Collections.Tagged.Set`); sibling `zmap.fsi`/`zmap.fs` is the map analogue.

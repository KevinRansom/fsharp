# zmap.fs

**Purpose**: A functional (F# module-style) façade over the tagged map type `Internal.Utilities.Collections.Tagged.Map<'Key,'T>` — i.e. "zipped" maps keyed by an explicit comparer — so compiler code can use familiar `Zmap.add/find/fold/...` function syntax instead of the object-style `Map` members. This is the classic F# "zmap" convention (a "z" collection = a collection parameterized by a comparer/ordered type).

**Namespace(s)**: `Internal.Utilities.Collections`

**Modules / Types declared**:

- `type internal Zmap<'Key, 'T> = Internal.Utilities.Collections.Tagged.Map<'Key, 'T>` — alias for the tagged map (whose second type parameter defaults to the `IComparer<'Key>` constraint tag).
- `module internal Zmap` — the functional helpers.

**Public API surface** (all internal):

- `empty (ord: IComparer<'T>) : Zmap<_, _>` — empty map for a comparer.
- `add k v m`, `find k m` (raises `KeyNotFoundException`), `tryFind k m`, `remove k m`, `mem k m`, `iter action m`.
- `first f m` — first `(k, v)` satisfying `f`, in map order.
- `exists f m`, `forall f m`.
- `map mapping m` (map values only), `mapi mapping m` (map with key).
- `fold f m x`, `toList m`, `foldSection lo hi f m x` (range-restricted fold over keys in `[lo, hi]`).
- `isEmpty m`.
- `foldMap f z m` — fold-and-map: `('State -> 'Key -> 'T -> 'State * 'U) -> 'State -> Zmap -> 'State * Zmap<_, 'U>` (wraps `Map.FoldAndMap`).
- `choose f m` — first `Some` result of `f`.
- `chooseL f m` — collect all `Some` results into a list (in fold order).
- `ofList ord xs` — build a map from a list of pairs.
- `keys m`, `values m` — as lists (in map fold order).
- `memberOf m k` — infix-style `k in m`.

**Internal helpers**: None — each function is a one-line wrapper over the corresponding `Tagged.Map` member (`Add`, `Item`, `TryFind`, `Remove`, `ContainsKey`, `Iterate`, `First`, `Exists`, `ForAll`, `MapRange`, `Map`, `Fold`, `ToList`, `FoldSection`, `IsEmpty`, `FoldAndMap`, `FromList`).

**Significant internal logic**: No logic beyond delegation; the value of the module is giving a uniform function-style API over the object-style `Tagged.Map` API and the `keys`/`values`/`chooseL` conveniences built from `Fold`.

**Cross-references**: `zmap.fsi` (same directory) is the signature. Built on `TaggedCollections.fs` (`Internal.Utilities.Collections.Tagged.Map`) and paired with sibling `zset.fs` (`Zset`), both namesakes of the older F# compiler "zmap/zset" convention.

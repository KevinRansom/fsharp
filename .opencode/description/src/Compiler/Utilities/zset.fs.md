# zset.fs

**Purpose**: A functional (F# module-style) façade over the tagged set type `Internal.Utilities.Collections.Tagged.Set<'T>` — i.e. "zipped" sets parameterized by an explicit key comparer — providing familiar `Zset.add/contains/union/...` function syntax in place of the object-style `Set` members. Companion to `zmap.fs` for compiler-internal set usage.

**Namespace(s)**: `Internal.Utilities.Collections`

**Modules / Types declared**:

- `type internal Zset<'T> = Internal.Utilities.Collections.Tagged.Set<'T>` — alias for the tagged set.
- `module internal Zset` — the functional helpers.

**Public API surface** (all internal):

- `empty (ord: IComparer<'T>) : Zset<'T>` — empty set for a comparer.
- `isEmpty s`, `contains x s`, `memberOf m k` (infix-style membership), `add x s`, `addList xs a` (fold `add` over a list), `singleton ord x`, `remove x s`.
- `count s`, `union s1 s2`, `inter s1 s2`, `diff s1 s2`, `equal s1 s2` (via `Tagged.Set.Equality`), `subset s1 s2`.
- `forall predicate s`, `exists predicate s`, `filter predicate s`.
- `fold ('T -> 'b -> 'b) s b` (note: `Zset.fold` is set element-first order, per the tagged `Set.Fold`), `iter f s`.
- `elements s : 'T list` — `s.ToList()`.

**Internal helpers**: None — one-line wrappers over `Tagged.Set` members (`Empty`, `IsEmpty`, `Contains`, `Add`, `Remove`, `Count`, `Union/Intersection/Difference`, `Equality`, `IsSubsetOf`, `ForAll/Exists/Filter`, `Fold`, `Iterate`, `ToList`).

**Significant internal logic**: None beyond delegation; `addList` and `singleton` are the only composed helpers (folds / empty+add).

**Cross-references**: `zset.fsi` (same directory) is the signature. Built on `TaggedCollections.fs` (`Internal.Utilities.Collections.Tagged.Set`); paired with sibling `zmap.fs`.

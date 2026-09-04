# HashMultiMap.fs

A multi-map keyed hash table for the compiler: a single key can be bound to many values, with the "latest" binding held in a primary dictionary and older bindings for the same key kept in an overflow list. Backed by `Dictionary` (default) or `ConcurrentDictionary` (opt-in). Internal use throughout the compiler for key → many-bindings collections. Public contract in `HashMultiMap.fsi`.

**Namespace(s)** declared: `Internal.Utilities.Collections`

**Modules / Types declared**:
- `[<Sealed>] type internal HashMultiMap<'Key, 'Value when 'Key: not null>` — the multi-map; `new` overloads:
  - `new : size * comparer * ?useConcurrentDictionary`
  - `new : comparer * ?useConcurrentDictionary` (size defaults to 11)
  - `new : seq<'Key * 'Value> * comparer * ?useConcurrentDictionary` — builds from a sequence.

**Public API surface** (per HashMultiMap.fsi; the type and its members are `internal`):
- `Copy: unit -> HashMultiMap<'Key, 'Value>` — shallow copy.
- `Add: 'Key * 'Value -> unit` — adds a binding; on a duplicate key, the previous first entry is pushed to the overflow list and the new value becomes the first entry.
- `Clear`, `ContainsKey`, `Remove : 'Key -> unit` (removes the latest binding if any), `Replace : 'Key * 'Value -> unit`, `Item : 'Key -> 'Value with get, set` (set replaces all bindings with a single one), `TryFind : 'Key -> 'Value option`, `FindAll : 'Key -> 'Value list`, `Fold : ('Key -> 'Value -> 'State -> 'State) -> 'State -> 'State`, `Count : int`, `Iterate : ('Key -> 'Value -> unit) -> unit`.
- Implements `IDictionary<'Key, 'Value>`, `ICollection<KeyValuePair<_, _>>`, `IEnumerable<KeyValuePair<_, _>>`, `System.Collections.IEnumerable`.

**Internal helpers / notable items**:
- `GetRest : 'Key -> 'Value list` — the overflow bindings for a key (empty list if none).
- Two underlying `IDictionary` fields: `firstEntries` (size = initial capacity; holds the "current" binding per key) and `rest` (size 3; holds the displaced bindings as `'Value list`). This two-table design keeps the common case (0 or 1 binding per key) at a single dict lookup.
- `Copy`, `FindAll`, `Fold`, `Iterate`, and `IEnumerable.GetEnumerator` all stitch the two layers together.

**Significant internal logic**:
- `Add(y, z)`: if `y` already exists, its current first entry is unshifted into `rest`'s list, then the new value becomes the first entry. Net effect: most-recent binding is always in `firstEntries`.
- `Remove(y)`: if `rest` has a list `[h]` for `y`, it becomes the new first entry (and `rest.Remove y`); if `[h; t]` or longer, `h` is promoted and `t` becomes the new rest list; otherwise the first entry is removed.
- `Item set` delegates to `Replace`, which just overwrites the first entry (leaving any overflow untouched).
- `IEnumerable` materializes a `List` of `(key, value)` pairs — first entries first, with rest bindings interleaved per key — then enumerates it.
- `IDictionary.TryGetValue` returns only the *first* binding (`TryFind`), not the rest.

**Cross-references**: none in-sibling; this is a general-purpose collection consumed elsewhere in the compiler (e.g. scope/lookup tables).

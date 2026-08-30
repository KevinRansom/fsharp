# HashMultiMap.fsi

**Purpose**: Signature file for `HashMultiMap.fs` (same directory, namespace `Internal.Utilities.Collections`). Documents the public contract of the internal multi-map hash table where a single key may be bound to many values; the "latest binding" is always retrievable via `Item`/`TryFind`, and `FindAll` returns all bindings for a key.

**Namespace(s)** declared: `Internal.Utilities.Collections`

**Declared items** (public contract):
- `[<Sealed>] type internal HashMultiMap<'Key, 'Value when 'Key: not null>` with constructors:
  - `new: size: int * comparer: IEqualityComparer<'Key> * ?useConcurrentDictionary: bool`
  - `new: comparer * ?useConcurrentDictionary` (default size)
  - `new: entries: seq<'Key * 'Value> * comparer * ?useConcurrentDictionary`
- Members (all on the type):
  - `Copy: unit -> HashMultiMap<'Key, 'Value>`
  - `Add: 'Key * 'Value -> unit` — "Add a binding for the element to the table."
  - `Clear: unit -> unit`
  - `ContainsKey: 'Key -> bool`
  - `Remove: 'Key -> unit` — "Remove the latest binding if any for the given element from the table."
  - `Replace: 'Key * 'Value -> unit` — "Replace the latest binding if any for the given element."
  - `Item: 'Key -> 'Value with get, set` — get/set; per docs, set "replaces all existing bindings for a value with a single binding."
  - `TryFind: 'Key -> 'Value option`
  - `FindAll: 'Key -> 'Value list`
  - `Fold: ('Key -> 'Value -> 'State -> 'State) -> 'State -> 'State`
  - `Count: int`
  - `Iterate: ('Key -> 'Value -> unit) -> unit`
- Interfaces implemented: `IDictionary<'Key, 'Value>`, `ICollection<KeyValuePair<'Key, 'Value>>`, `IEnumerable<KeyValuePair<'Key, 'Value>>`, `System.Collections.IEnumerable`.

**Relationship to .fs**: The .fs supplies the implementation with two internal `IDictionary` fields (`firstEntries`, `rest`), optional `ConcurrentDictionary` backing (`useConcurrentDictionary`), and the `GetRest` lookup used by `FindAll`/`Fold`/`Iterate`/enumeration. Minor helpers present in the .fs (e.g. `GetRest`) are not part of the .fsi.

**Cross-references**: see sibling `HashMultiMap.md`.

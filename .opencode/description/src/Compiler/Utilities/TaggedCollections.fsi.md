# TaggedCollections.fsi

**Purpose**: Signature file for `TaggedCollections.fs`. Declares the internal `Set<'T,'ComparerTag>` and `Map<'Key,'Value,'ComparerTag>` types in `Internal.Utilities.Collections.Tagged` — immutable, F#-semantic sets and maps whose key ordering is carried by a comparer type-parameter constraint (`'ComparerTag :> IComparer<'T>`). The header comment notes that this namespace contains "FSharp.PowerPack extensions for the F# collection types".

**Namespace(s)**: `Internal.Utilities.Collections.Tagged`

**Modules / Types declared** (as declared in the signature):

- `type internal Set<'T,'ComparerTag> when 'ComparerTag :> IComparer<'T>` — sealed. Instance: `Add`, `Remove`, `Count`, `Contains`, `IsEmpty`, `Iterate`, `Fold`, `Partition`, `Filter`, `Exists`, `ForAll`, `Choose`, `MinimumElement`, `MaximumElement`, `IsSubsetOf`, `IsSupersetOf`, `ToList`, `ToArray`. Static: `Create: 'ComparerTag * seq<'T> ->`, `Empty: 'ComparerTag ->`, `Singleton: 'ComparerTag * 'T ->`, `Equality`, `Compare`, operators `(-)`, `(+)/Union`, `Intersection`, `Difference`. Interfaces: `ICollection<'T>`, `IEnumerable<'T>`, `IEnumerable`, `IComparable`; `override Equals: objEqualsArg -> bool`. Doc comments mirror F# `FSharp.Collections.Set` ("A useful shortcut for Set.add...", etc.).
- `type internal Set<'T> = Set<'T, IComparer<'T>>` — default-comparer alias.
- `type internal Map<'Key,'Value,'ComparerTag> when 'ComparerTag :> IComparer<'Key>` — sealed. Instance: `Add`, `IsEmpty`, `Item` (get only), `First`, `ForAll`, `Exists`, `Filter`, `Fold`, `FoldSection: 'Key -> 'Key -> ...` (closed-interval range fold), `FoldAndMap`, `Iterate`, `Map`, `MapRange`, `Partition`, `Remove`, `TryFind`, `ToList`, `ToArray`; `Count`, `ContainsKey`. Static: `Empty`, `FromList`, `Create`. Interfaces: `IEnumerable<KeyValuePair<'Key,'Value>>`, `IEnumerable`, `IComparable`; `override Equals: objEqualsArg -> bool`.
- `type internal Map<'Key,'Value> = Map<'Key,'Value, IComparer<'Key>>` — default alias.

**Public API surface**: The member lists above; everything is internal to the compiler. Performance note in the Map doc comment: maps based on structural comparison are efficient for small keys and unsuitable for recursive keys or non-structural comparison semantics.

**Internal helpers**: None declared beyond the two types; tree internals (`SetTree`, `MapTree`, iterators) are implementation-only in the .fs.

**Significant internal logic**: None in the signature beyond documented semantics (e.g. `FoldSection` includes endpoints; `Partition` splits by predicate).

**Cross-references**: Companion implementation `TaggedCollections.fs` (same directory). Facaded by sibling files `zmap.fs`/`zset.fs` (`Zmap<'Key,'T> = Tagged.Map<'Key,'T>`, `Zset<'T> = Tagged.Set<'T>`, in `Internal.Utilities.Collections`).

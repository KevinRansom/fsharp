# map.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Public API signature for the immutable `Map<'Key,'Value>` type and the `Map` module (implemented in `map.fs`).

## Namespaces
- `Microsoft.FSharp.Collections`

## Type: Map<'Key,'Value>
`[<CompiledName("FSharpMap`2")>] [<Sealed>] type Map<...> when 'Key: comparison`

Immutable maps based on binary trees ordered by F# generic comparison. All members are documented as thread-safe.

- `new: elements: seq<'Key * 'Value> -> Map<'Key,'Value>` — builds from enumerable bindings.
- `Add: key * value -> Map<'Key,'Value>` — O(log n) binding insert/replace.
- `Change: key * f: ('Value option -> 'Value option) -> Map<'Key,'Value>` — upsert/deletion via user function.
- `IsEmpty: bool`.
- `ContainsKey: key -> bool`.
- `Count: int`.
- `Item: key -> 'Value with get` — raises `KeyNotFoundException` on missing key.
- `Remove: key -> Map<'Key,'Value>`.
- `TryFind: key -> 'Value option`.
- `TryGetValue: key * byref<'Value> -> bool` — `[<Out>]` out-parameter style.
- `Keys: ICollection<'Key>`, `Values: ICollection<'Value>` (read-only views).
- Additional members exercised via the module: `ToList`, `ToArray`, `Fold`, `FoldSection`, `Filter`, `Map`, `MapRange`, `Partition`, `Iterate`, `Exists`, `ForAll`, `TryPick`, `MinKeyValue`, `MaxKeyValue`.

### Interfaces
- `IDictionary<'Key,'Value>`, `ICollection<KeyValuePair<_,_>>` (both read-only), `IEnumerable<KeyValuePair<_,_>>`, `IComparable`, `IStructuralEquatable`, `IEnumerable`, `IReadOnlyCollection<KeyValuePair<_,_>>`, `IReadOnlyDictionary<'Key,'Value>`.

## Module: Map
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Map` — the standard operation module. All functions take `table` as their last argument (pipelined):

- `add` / `change` — bind/unbind with function.
- `ofList`, `ofArray`, `ofSeq`, `toSeq`, `toList`, `toArray` — conversions (duplicate keys overwrite earlier ones in conversion).
- `isEmpty`, `empty<'Key,'T>`, `count`.
- `find` (KeyNotFound), `tryFind`, `tryPick`, `pick` (KeyNotFound), `containsKey`, `findKey`, `tryFindKey`.
- `remove`, `iter`, `exists`, `filter`, `forall`, `map` (key&-value transform), `partition`.
- `fold` (leftward, in-order) / `foldBack` (rightward).
- `keys`, `values`, `minKeyValue`, `maxKeyValue`.

## Notable documentation behavior
- XML docs emphasize the O(log n) tree complexity and that maps use structural/`IComparable` ordering of keys.
- All module functions have full parameter descriptions and example blocks.
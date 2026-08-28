# lib.fsi

**Purpose**: Signature file for `lib.fs` (same directory, module `Internal.Utilities.Library.Extras`). Documents the large grab-bag of small internal helpers used across the F# compiler: comparers, list/as-set ops, tuple combinators, imperative graph, memo caches, parallel-array helpers, and a weak-map utility.

**Namespace(s)** declared: module path `Internal.Utilities.Library.Extras` (internal).

**Key declarations** (signatures exactly as documented; most helpers omitted — see lib.md for descriptions):
- Toggles: `debug: bool`, `verbose: bool`, `mutable progress: bool`, `mutable tracking: bool`.
- Env/dispose: `isEnvVarSet : string -> bool`, `GetEnvInteger : e * dflt -> int`, `dispose : (IDisposable | null) -> unit`.
- `module Bits` — `b0`/`b1`/`b2`/`b3` (byte extraction), `pown32`, `pown64`, `mask32`, `mask64`.
- `module Bool` — `order : IComparer<bool>`; `module Int32`, `module Int64` similarly; `module Pair` — `order`.
- `type NameSet = Zset<string>`; `module NameSet` — `ofList`; `module NameMap` — `domain`, `domainL`.
- `type IntMap<'T> = Zmap<int, 'T>`; `module IntMap` — `empty`, `add`, `find`, `tryFind`, `remove`, `mem`, `iter`, `map`, `fold`.
- `module ListAssoc` — `find`, `tryFind`.
- `module ListSet` — `inline contains`, `insert`, `unionFavourRight`, `findIndex`, `remove`, `subtract`, `isSubsetOf`, `isSupersetOf`, `equals`, `unionFavourLeft`, `intersect`, `setify`, `hasDuplicates`.
- Tuple combinators (many) — e.g. `mapFoldFst`/`mapFoldSnd`, `pair`, `p13`..`p55`, `map1Of2`..`map6Of6`, `foldPair`/`fold1Of2`/`foldTriple`/`foldQuadruple`, `mapPair`/`mapTriple`/`mapQuadruple`.
- `module Zmap` — `force`, `mapKey`; `module Zset` — `ofList`, `fixpoint`.
- `buildString : (StringBuilder -> unit) -> string`; `writeViaBuffer : TextWriter -> (StringBuilder -> unit) -> unit`.
- `type StringBuilder with` — `AppendString : string -> unit` (like Append, returns unit).
- `type Graph<'Data, 'Id when 'Id: comparison>` — `new : nodeIdentity * nodes * edges`, `GetNodeData`, `IterateCycles`.
- Null-slot: `type NonNullSlot<'T when 'T: not struct> = 'T`; `nullableSlotEmpty`, `nullableSlotFull`.
- Memo: `type cache<'T when 'T: not struct>`; `newCache`; `inline cached`; `inline cacheOptByref`; `inline cacheOptByrefByVersion` (version-stamped; doc notes: caller must read `version` with acquire semantics, and cache must be a reference type); `inline cacheOptRef`; `inline tryGetCacheValue : NonNullSlot<'a> voption`.
- `[<RequireQualifiedAccess>] type MaybeLazy<'T>` — `Strict of 'T | Lazy of InterruptibleLazy<'T>`, `Force`, `Value`.
- `inline vsnd`.
- `type DisposablesTracker` — `new`, `Register : ('a | null) -> unit when 'a :> IDisposable and 'a: not struct and 'a: not null`, `IDisposable`.
- `[<RequireQualifiedAccess>] module ArrayParallel` — `inline iter`, `iteri`, `map`, `mapi`; `module ListParallel` — `map`; `module Async` — `map`.
- `module internal WeakMap` — `getOrCreate : ('Key -> 'Value) -> ('Key -> 'Value)` (with `'Key: not struct and not null`, `'Value: not struct`) — ConditionalWeakTable-backed; `cacheConditionally : ('Value -> bool) * (factory) -> ('Key -> 'Value)`.

**Relationship to .fs**: 1:1 for the public surface; the .fs additionally defines `GraphNode` (the mutable record backing `Graph`), the `#if DUMPER` `Dumper` type, and `module internal ValueTuple` (used internally by lib) — none of which are in the .fsi.

**Cross-references**: `illib.fsi.md` (sibling) declares the `NameMap<'T>`/`NameMultiMap`/`MultiMap` types in the parent `Internal.Utilities.Library` module — distinct from this file's `NameSet`/`NameMap` aliases. `MaybeLazy.Lazy` uses `InterruptibleLazy` from `illib.fs`.

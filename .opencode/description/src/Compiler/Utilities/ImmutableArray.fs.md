# ImmutableArray.fs

**Purpose**: F# functional combinators for `System.Collections.Immutable.ImmutableArray<'T>`, giving the compiler a List/Array-style API (iter/map/choose/filter/fold/...) over immutable arrays without allocating wrappers. Used in hot paths (e.g. IL/PE "block" structures and typed-tree representation) where repeated allocation of per-element wrappers is to be avoided. Companion signature file: `ImmutableArray.fsi`.

**Namespace(s)** declared: module path `Internal.Utilities.Library.Block` (the .fsi declares it `[<AutoOpen>]` and `internal`; the .fs declares the bare module path).

**Modules declared**:
- `[<RequireQualifiedAccess>] module ImmutableArrayBuilder` — `create : size -> ImmutableArray<'T>.Builder` (thin wrapper over `ImmutableArray.CreateBuilder`).
- `[<RequireQualifiedAccess>] module ImmutableArray` — the full combinator set (see API surface).

**Public API surface** (per ImmutableArray.fsi, all signatures exactly as documented):
- `empty<'T> : ImmutableArray<'T>` (`[<GeneralizableValue>]`)
- `init : n * (int -> 'T) -> ImmutableArray<'T>` — O(n) with builder; short-circuits for 0 and 1.
- `iter`, `iteri` — indexed iteration.
- `iter2`, `iteri2` — pairwise iteration; require equal lengths (`invalidOp` otherwise).
- `map`, `mapi` — produce new immutable arrays.
- `concat : ImmutableArray<ImmutableArray<'T>> -> ImmutableArray<'T>` — flattens; fast-paths 0/1/2 inputs, then uses a pre-sized `AddRange` loop.
- `forall`, `forall2` — short-circuiting predicates (uses `OptimizedClosures.FSharpFunc.Adapt` in `forall2` to avoid per-element delegate boxing).
- `tryFind`, `tryFindIndex`, `tryPick` — linear-search combinators returning options.
- `ofSeq : 'T seq -> ImmutableArray<'T>` — `ImmutableArray.CreateRange`.
- `append : arr1 * arr2 -> ImmutableArray<'T>` — via `AddRange`.
- `createOne : 'T -> ImmutableArray<'T>` — `ImmutableArray.Create`.
- `filter` — keeps matching elements; shrinks builder capacity to `Count` before `MoveToImmutable`.
- `exists` — short-circuiting.
- `choose : ('T -> 'U option) * ImmutableArray<'T> -> ImmutableArray<'U>`.
- `isEmpty` — wraps `.IsEmpty`.
- `fold : ('State -> 'T -> 'State) * 'State * ImmutableArray<'T> -> 'State` — uses adapted `FSharpFunc` for speed.

**Internal helpers / notable items**:
- Private `checkCount`-less; uses direct index loops over `ImmutableArray`'s underlying contiguous storage for speed (avoids LINQ/deferred seq overhead).
- Uses `builder.Capacity <- builder.Count` in `filter`/`choose` to free unused backing capacity before immutabilizing.
- Recursion is tail-recursive in the predicate loops (`forall`, `exists`, `tryFind`, `tryPick`).

**Significant internal logic / behavioral notes**:
- All the mapping/filtering functions allocate a fresh backing array for results (inherent to immutable semantics) but reuse a single builder and pre-size it.
- `concat`'s fast path for 2 arrays uses `AddRange` on the first; for more, it sums lengths and `AddRange`s each in a pre-sized builder — O(total) with a single allocation.
- `iter2`/`iteri2`/`forall2` enforce equal-length and throw `InvalidOperationException("Block lengths do not match.")` on mismatch — a deliberate invariant for the "Block" usage context.

**Cross-references**: none among the listed siblings; sibling `Caches.md`, `DependencyGraph.md`, etc. do not directly consume this. The module name suffix `Block` indicates it is primarily used by compiler "block" (IL block) utilities elsewhere under `src/Compiler/`.

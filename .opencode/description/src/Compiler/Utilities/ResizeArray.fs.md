# ResizeArray.fs

**Purpose**: Provides F#-style functional operations on `ResizeArray<'T>` (`System.Collections.Generic.List<'T>`), mirroring the F# `Array` module. Historically this module was part of FSharp.Core (the `Microsoft.FSharp.Collections.ArrayList`/`ResizeArray` module); in this repository it is compiled into the compiler namespace `Internal.Utilities` so compiler code can use list-of-lists-style operations on mutable lists (`ResizeArray`) with familiar `fold`/`iter`/`map`/`choose` naming.

**Namespace(s)**: `Internal.Utilities`

**Modules / Types declared**:

- `module internal ResizeArray` (`[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`) — the entire file; no types.

**Public API surface** (all internal functions; `ResizeArray<'T>` is `System.Collections.Generic.List<'T>`):

Creation/conversion:
- `create n x`, `init n f`, `copy`, `toList`, `ofList`, `toArray`, `ofArray`, `toSeq` (via `Seq.readonly`), `singleton`, `append`, `concat`, `sub arr start len`, `blit src start1 dst start2 len`, `fill arr start len x`, `length`, `get`, `set`, `rev`, `isEmpty`.

Transformation:
- `map`, `mapi`, `iter`, `iteri`, `iter2`, `map2`, `iteri2`, `mapi2`, `filter`, `choose`, `partition`, `exists`, `forall`, `exists2`, `forall2`, `find`, `tryFind`, `tryPick`, `findIndex`, `findIndexi`, `tryFindIndex`, `tryFindIndexi`, `zip`, `unzip`, `sort f`, `sortBy f`.

Folds/scans:
- `fold`, `foldBack`, `fold2`, `foldBack2`, `foldSub`, `foldBackSub`, `reduce`, `reduceBack`, `scan`, `scanBack` (and their `*Sub` range-based cores `scanSub`/`scanBackSub`).

**Internal helpers**:

- `indexNotFound()` — raises `KeyNotFoundException` for `find`/`findIndex` misses.
- Heavy use of `FSharpFunc<_,...>.Adapt` (from `FSharp.Core.OptimizedClosures`) to avoid delegate re-allocation for `mapi`/`iteri`/`iter2`/`map2`/`mapi2`/`fold2`/`foldBack2`/`iteri2`/`scan`-family operations.
- `exists`, `forall`, `exists2`, `forall2`, `tryFind`, `tryPick`, `findIndex` are written as tail-recursive index loops with `||`/`&&` short-circuit.

**Significant internal logic**:

- Two-element versions (`iter2`, `map2`, `exists2`, `forall2`, `fold2`, `foldBack2`, `zip`, `unzip`, `mapi2`, `iteri2`) all validate equal lengths and raise `invalidArg "arr2" "the arrays have different lengths"` — matching the F# `Array` module error contract.
- `find`/`findIndex` raise `KeyNotFoundException` (not `ArgumentException`) on failure, again matching F# `Array` semantics (`indexNotFound`).
- `reduce`/`reduceBack` raise `invalidArg "arr" "the input array may not be empty"` on empty collection.
- Scan variants are built on `scanSub`/`scanBackSub`, which pre-allocate the result with `create (start..fin) acc` and fill positions; `scanSub` seeds position `0` with the initial accumulator, `scanBackSub` builds right-to-left.

**Cross-references**: Signature file `ResizeArray.fsi` (same directory, mirrors the F# core-library `ResizeArray` module signatures). This is the compiler's internal copy of the FSharp.Core `ResizeArray` module; `lib.fsi` and other compiler modules consume `Internal.Utilities` namespace utilities.

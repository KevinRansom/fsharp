# ResizeArray.fsi

**Purpose**: Signature file for `ResizeArray.fs`. Declares the internal `ResizeArray` module in namespace `Internal.Utilities` — F#-style functional operations on `System.Collections.Generic.List<'T>` — with doc comments copied from the F# core library (`"Generic operations on the type System.Collections.Generic.List, which is called ResizeArray in the F# libraries."`).

**Namespace(s)**: `Internal.Utilities`

**Modules / Types declared**:

- `module internal ResizeArray` (`[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`) — the single declaration.

**Public API surface** (all internal; full set as declared in the .fsi):

- `length`, `get`, `set` — indexed access (with doc notes that `arr.[idx]` syntax is equivalent).
- `create: int -> 'T -> ResizeArray<'T>`, `init: int -> (int -> 'T) -> ResizeArray<'T>`
- `append`, `concat: ResizeArray<'T> list -> ResizeArray<'T>`, `sub`, `copy`, `fill`, `blit`
- `toList`, `ofList: 'T list -> ResizeArray<'T>`
- `fold: ('T -> 'U -> 'T) -> 'T -> ResizeArray<'U> -> 'T`, `foldBack` (doc-comment the accumulation order)
- `iter`, `map: ('T -> 'U) -> ResizeArray<'T> -> ResizeArray<'U>`, `iter2`, `map2`, `iteri`, `mapi`
- `exists`, `forall`
- `filter`, `partition: ... -> ResizeArray<'T> * ResizeArray<'T>`
- `choose: ('T -> 'U option) -> ResizeArray<'T> -> ResizeArray<'U>`
- `find` (doc: raises `KeyNotFoundException`), `tryFind`, `tryPick`
- `rev`, `sort: ('T -> 'T -> int) -> ResizeArray<'T> -> unit`, `sortBy: ('T -> 'Key) -> ResizeArray<'T> -> unit when 'Key: comparison`
- `toArray: ResizeArray<'T> -> 'T[]`, `ofArray: 'T[] -> ResizeArray<'T>`, `toSeq: ResizeArray<'T> -> seq<'T>`
- `exists2`, `forall2` (doc: raise `ArgumentException` on length mismatch)
- `findIndex`, `findIndexi` (doc: raise `KeyNotFoundException`)
- `reduce`, `reduceBack` (doc: raise `ArgumentException` when empty)
- `fold2`, `foldBack2`
- `isEmpty`, `iteri2`, `mapi2: (int -> 'T -> 'U -> 'c) -> ResizeArray<'T> -> ResizeArray<'U> -> ResizeArray<'c>`
- `scan: ('U -> 'T -> 'U) -> 'U -> ResizeArray<'T> -> ResizeArray<'U>`, `scanBack`
- `singleton: 'T -> ResizeArray<'T>`
- `tryFindIndex`, `tryFindIndexi`
- `zip`, `unzip: ResizeArray<'T * 'U> -> ResizeArray<'T> * ResizeArray<'U>`

**Internal helpers**: None exposed; implementation-only helpers (`indexNotFound`, `scanSub`, `scanBackSub`, internal `foldSub`/`foldBackSub` cores) do not appear in the signature.

**Significant internal logic**: None in the signature; it pins the F# `Array`-compatible error contracts (which exceptions for which failures) and the exact set of two-list operations.

**Cross-references**: Companion implementation `ResizeArray.fs` (same directory). This mirrors the FSharp.Core `ResizeArray` module; compiler code in `Internal.Utilities` consumes it for functional operations on mutable lists.

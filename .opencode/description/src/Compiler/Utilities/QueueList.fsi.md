# QueueList.fsi

**Purpose**: Signature file for `QueueList.fs`, declaring the internal `QueueList<'T>` type and functional helper module in namespace `Internal.Utilities.Collections`. Carries the doc-comment describing the type as an "Iterable functional collection with O(1) append-1 time" and notes that iteration is slower/allocating because a suffix of elements is stored in reverse order, and that the type does not support structural hashing or comparison.

**Namespace(s)**: `Internal.Utilities.Collections`

**Modules / Types declared**:

- `type internal QueueList<'T>` — the persistent list hybrid.
- `module internal QueueList` — functional helpers.

**Public API surface** (all internal; as declared):

Type:
- `interface System.Collections.IEnumerable`
- `interface System.Collections.Generic.IEnumerable<'T>`
- `new: xs: 'T list -> QueueList<'T>`
- `new: firstElementsIn: 'T list * lastElementsRevIn: 'T list * numLastElementsIn: int -> QueueList<'T>`
- `member Append: ys: seq<'T> -> QueueList<'T>`
- `member AppendOne: y: 'T -> QueueList<'T>`
- `member ToList: unit -> 'T list`
- `member FirstElements: 'T list`
- `member LastElements: 'T list`
- `static member Empty: QueueList<'T>`

Module functions: `empty<'T>`, `ofSeq`, `iter`, `map`, `exists`, `filter`, `foldBack`, `forall`, `ofList`, `toList`, `tryFind`, `one`, `appendOne`, `append` — signatures as in `QueueList.fs`, no implementation details.

**Internal helpers**: None declared here beyond the public-internal surface above.

**Significant internal logic**: None — the .fsi only exposes the contract. Notable omissions: no `Hash`/`Compare`, no `AppendAll`, no indexed access — consistent with the implementation which only supports append + iterate semantics.

**Cross-references**: Companion implementation file `QueueList.fs` in the same directory; the type is an internal utility consumed across the compiler for persistent queue-like structures (namespace also hosts `zmap.fs` / `zset.fs`).

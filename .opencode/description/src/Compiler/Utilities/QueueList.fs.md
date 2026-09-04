# QueueList.fs

**Purpose**: A persistent (immutable) list-queue hybrid collection for the compiler: it gives amortized O(1) append-at-the-back semantics of a queue while retaining full list-like iteration of the front half. It is intended for data structures where elements are appended at the end repeatedly but must occasionally be iterated (e.g. queues of diagnostics/messages in the compiler).

**Namespace(s)**: `Internal.Utilities.Collections`

**Modules / Types declared**:

- `type internal QueueList<'T>(firstElementsIn, lastElementsRevIn, numLastElementsIn)` — the persistent collection. `firstElements` holds the stable head in forward order; `lastElementsRev` holds a pending suffix in reverse order; `numLastElements` tracks its length.
- `module internal QueueList` — top-level functional helpers over the type.

**Public API surface** (all internal):

Type members:

- `member AppendOne(y) : QueueList<'T>` — O(1) unless a "push" rebalance occurs (rare).
- `member Append(ys: seq<'T>) : QueueList<'T>` — append many elements.
- `member ToList() : 'T list` — materialize the full list (folds head + reverse-tail).
- `member FirstElements : 'T list` / `member LastElements : 'T list` — stable head / current tail (reversed).
- `static member Empty : QueueList<'T>` — shared empty value.
- `new(xs: 'T list)` / `new(firstElementsIn, lastElementsRevIn, numLastElementsIn)` — constructors.
- Implements `System.Collections.IEnumerable<'T>` and `IEnumerable` via `ToList()` (enumeration may allocate).

Module functions: `empty`, `ofSeq`, `ofList`, `one`, `iter`, `map`, `exists`, `forall`, `filter`, `foldBack`, `toList`, `tryFind`, `appendOne`, `append` — functional wrappers mostly delegating to `Seq.*` or the members above; `foldBack` is implemented by folding the last-then-first halves explicitly.

**Internal helpers**:

- `lastElements()` — on-demand `List.rev lastElementsRev`.
- `static let empty = QueueList<'T>([], [], 0)`.

**Significant internal logic (key algorithm)**: The invariant is that the pending reversed tail (`lastElementsRev`) is at most about 5x the head (`firstElements`) size. On any `Append`/`AppendOne` that would violate `numLastElementsIn > numFirstElements / 5` (computed at construction), the constructor "pushes" the reversed tail onto the head (`List.append first (List.rev last)`) so the head grows and the pending tail resets. This keeps `AppendOne` O(1) in the common case: appending merely conses into the reversed tail and bumps a counter. Amortized cost remains O(1) per append, with occasional O(n) rebalances; iteration is O(n) and allocates because it must materialize the reversed tail.

**Cross-references**: Lives alongside `zmap.fs`/`zset.fs` in the `Internal.Utilities.Collections` namespace; the functional helpers in this module mirror the style of the F# `List` module. Used in the compiler where a growing queue of items (e.g. error/warning streams) is periodically drained.

# Continuation.fsi

**Purpose**: Signature file for the `Continuation` module used by the graph-based parallel checker. Documents (in rich doc comments) the semantics of CPS sequencing and, critically, explains that the design goal is enabling unbounded recursion by constructing heap closures instead of consuming stack.

**Namespace(s)**: none explicitly (module `internal Continuation` with `RequireQualifiedAccess`)

**Public API surface** (the contract exposed by `Continuation.fs`):
- `val sequence<'T, 'TReturn> : recursions: (('T -> 'TReturn) -> 'TReturn) list -> finalContinuation: ('T list -> 'TReturn) -> 'TReturn`
  - Takes a list of CPS-style computations and a final continuation over the accumulated list; returns the final result.
- `val concatenate<'T, 'TReturn> : recursions: (('T list -> 'TReturn) -> 'TReturn) list -> finalContinuation: ('T list -> 'TReturn) -> 'TReturn`
  - Auxiallary version where the recursions each return a `'T list`; the `'T list list` is concatenated into one list before being passed to the final continuation.

**Internal helpers**: none — the signature declares only the two functions above.

**Significant documentation notes**:
- The docs use `int` as a worked example: an integer is equivalently represented as the function that applies the continuation to that integer (e.g. `3`).
- Explains `sequence` is best understood without its second argument: a higher-order function turning a "list of CPS 'Ts" into a single "CPS 'T list" that chains the inputs.
- Emphasizes the stack-escaping rationale, since this module exists to traverse arbitrarily nested F# syntax without stack overflow.

**Cross-references**:
- Implementation: `Continuation.fs`.
- Consumers: `FileContentMapping.fs` (`visitPat`, `visitSynExpr` use `Continuation.concatenate` for multi-branch patterns/expressions).

# Continuation.fs

**Purpose**: Utility module for the graph-checking architecture providing a stack-free sequencer for computations written in continuation-passing style (CPS). It lets callers chain an arbitrary number of CPS "recursions" together without consuming stack frames, enabling unbounded recursion in deep syntax-tree traversals. Used by `FileContentMapping` to visit deeply nested patterns/expressions without `StackOverflowException`.

**Namespace(s)**: `FSharp.Compiler.GraphChecking` (internal module `Continuation`, declared under the compiler's GraphChecking namespace area)

**Modules**:
- `module internal Continuation` — with `RequireQualifiedAccess`; exposes only two higher-order functions.

**Public API surface**:
- `sequence<'T, 'TReturn> (recursions: (('T -> 'TReturn) -> 'TReturn) list) (finalContinuation: 'T list -> 'TReturn) : 'TReturn` — sequences a list of CPS computations, each receiving a continuation and returning a final result; the final continuation receives the accumulated `'T list`.
- `concatenate<'T, 'TReturn> (recursions: (('T list -> 'TReturn) -> 'TReturn) list) (finalContinuation: 'T list -> 'TReturn) : 'TReturn` — helper for `sequence` where each step returns a `'T list`; results are concatenated (`List.concat`) before the final continuation runs.

**Significant internal logic**:
- `sequence` is implemented recursively by building heap-allocated closures that chain the continuations, rather than recursing on the call stack — this is the point of the module (unbounded depth, stack-safe).
- Conceptually an integer `3` in CPS is `(howToProceed: int -> 'TReturn) -> 'TReturn`; here each "recursion" is one such delayed computation whose individual result is accumulated into a list before the final continuation.

**Cross-references**:
- Consumed by `FileContentMapping.fs` (`visitPat`, `visitSynExpr`) for combining child visits.
- See `Docs.md` in the same directory for background on the graph-checking architecture.

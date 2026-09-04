# seqcore.fs

## Overview

This file is split into two namespaces and holds the **low-level internal plumbing for `seq`** that `seq.fs` and the compiler-generated sequence expressions rely on.

The first namespace, `Microsoft.FSharp.Collections`, contains the internal `IEnumerator` module of primitive enumerator utilities and types. The second namespace, `Microsoft.FSharp.Core.CompilerServices`, contains the `RuntimeHelpers` module (public shape, documented below) with enumerator composition helpers, plus the `GeneratedSequenceBase<'T>` abstract class (the base of compiler-generated `seq { }` implementations) and the `ListCollector<'T>` / `ArrayCollector<'T>` struct collectors.

## `module internal IEnumerator` (Microsoft.FSharp.Collections)

Shared enumerator primitives (exported to other modules via `open Microsoft.FSharp.Collections.IEnumerator`):

- Error helpers: `noReset`, `notStarted`, `alreadyFinished`, `check started`, `dispose`.
- `cast` — adapts a non-generic `IEnumerator` to `IEnumerator<'T>` (unboxing each `Current`), disposing the inner if it is disposable.
- `type EmptyEnumerator<'T>` (`[<Sealed>]`) + `Empty<'T>()` — an enumerator that yields nothing.
- `type EmptyEnumerable<'T>` (union `EmptyEnumerable`) — `IEnumerable<'T>` returning `Empty<'T>()`.
- `type GeneratedEnumerable<'T,'State>(openf, compute, closef)` — an `IEnumerator<'T>` driven by state: `openf` creates state once, `compute : 'State -> 'T option` yields until `None`, `closef` runs exactly once (thread-safe via `lock state`); finishes cleanly on exception (runs `closef`, rethrows).
- `type Singleton<'T>(v)` + `Singleton x` — yields one value.
- `EnumerateThenFinally f e` — wraps enumerator `e` so disposal runs `f` (as `finally`).
- `checkNonNull argName arg` (inline) and `mkSeq f` — builds an `IEnumerable` whose `GetEnumerator` calls `f()` (used everywhere to create lazy sequences).

## `module RuntimeHelpers` (Microsoft.FSharp.Core.CompilerServices)

- `type StructBox<'T when 'T:equality>(value:'T)` (`[<Struct; NoComparison; NoEquality>]` internal) — wraps value types for use as dictionary keys (with a structural `IEqualityComparer<StructBox<'T>>` in `Comparer`), used to avoid boxing and to handle null-represented keys in `Seq.groupBy`/`Seq.countBy`.
- `Generate openf compute closef` / `EnumerateFromFunctions create moveNext current` — build sequences from function triplets (backing the internal generated/iterator protocols).
- `type IFinallyEnumerator` — abstract `AppendFinallyAction : (unit -> unit) -> unit`; enumerators that can accumulate extra disposal/compensation actions.
- `type FinallyEnumerable<'T>(compensation, restf)` (`[<Sealed>]`) — an `IEnumerable` whose enumerators run `compensation` on dispose; it either `AppendFinallyAction`s onto an `IFinallyEnumerator` (avoiding a deep enumerator chain) or wraps with `EnumerateThenFinally`. On any exception while creating the enumerator, it runs the compensation and rethrows.
- `type ConcatEnumerator<'T,'U when 'U :> seq<'T>>(sources)` (`[<Sealed>]`) — optimized `IEnumerable`/`IEnumerator` for flattening a sequence of sequences (`Seq.concat`). Implements `IFinallyEnumerator` and tracks an undo list of `compensations` run during `Finish()`. Skips empty `ICollection<'T>` inner sources without calling `GetEnumerator`, disposes each inner enumerator, and disposes the outer enumerator on finish. `ConcatEnumerator.currElement` is an unchecked field (via `[<DefaultValue(false)>]` with a comment). Backs `mkConcatSeq`.
- `EnumerateUsing resource source` — `use` semantics: builds a `FinallyEnumerable` that disposes `resource` on close.
- `EnumerateWhile guard source` — `while guard() do yield! source` semantics, via `mkConcatSeq` over an enumerator yielding the source repeatedly while the guard holds.
- `EnumerateThenFinally source compensation` — adds a compensation to a sequence's dispose chain.
- `EnumerateTryWith source exceptionFilter exceptionHandler` — implements `try/with` over sequence expressions; lazily creates the original enumerator, and on any exception (including one raised during `Dispose`) consults `exceptionFilter : exn -> int` (returns `1` to match) and switches to `exceptionHandler exn` results. Handles the subtle case where disposing the original fails: tries disposal, and if it both fails and matches the filter, switches to the handler and may yield further values.
- `CreateEvent addHandler removeHandler createHandler` — builds an `IEvent<'Delegate,'Args>` / `IObservable<'Args>` whose subscription adds an adapter handler and returns an `IDisposable` that removes it.
- `SetFreshConsTail cons tail` / `FreshConsNoTail head` — raw-IL helpers (with `[<InlineIfLambda>]`-style `inline`) used by `ListCollector` to stitch cons cells cheaply.

## `type GeneratedSequenceBase<'T>` (`[<AbstractClass>]`)

The abstract base class for **compiler-generated `seq { }` / `yield` implementations**. Holds a `redirect`/`redirectTo` pair used for efficient `yield!` tail recursion without nested enumerators by flipping a redirect flag instead. Abstract members: `GetFreshEnumerator`, `GenerateNext : result:byref<IEnumerable<'T>> -> int` (`0 = Stop`, `1 = Yield`, `2 = Goto`), `Close`, `CheckClose : bool`, `LastGenerated : 'T`. `MoveNextImpl` drives `GenerateNext`; on `Goto` it follows the target (redirecting directly to another `GeneratedSequenceBase` when `CheckClose` is false, else to an adapter that wraps `Close` and disposal). Implements `IEnumerable<'T>`, `IEnumerator<'T>`, and `IDisposable`.

## `type ListCollector<'T>` (`[<Struct; NoComparison; NoEquality>]`)

A mutable struct that efficiently builds an F# list incrementally: `Add value` (uses `FreshConsNoTail`/`SetFreshConsTail` to avoid O(n) appends), `AddMany values` (fast paths for arrays/lists), `AddManyAndClose values` (stitches a trailing list directly), and `Close()` (terminates with `[]` and returns the built list).

## `type ArrayCollector<'T>` (`[<Struct; NoComparison; NoEquality>]`)

A mutable struct that efficiently builds an array, optimized for 0/1/2 elements (stored in `First`/`Second` without allocation, switching to a `ResizeArray` from the 3rd element). Members: `Add`, `AddMany`, `AddManyAndClose`, `Close` (returns `Array.Empty`, `[|First|]`, `[|First;Second|]`, or the resize-array's `ToArray`).

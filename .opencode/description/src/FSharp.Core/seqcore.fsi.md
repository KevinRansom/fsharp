# seqcore.fsi

## Overview

Signature file covering the internal plumbing behind F# `seq` and sequence expressions. Split across two namespaces: `Microsoft.FSharp.Collections` (internal `IEnumerator` module) and `Microsoft.FSharp.Core.CompilerServices` (`RuntimeHelpers`, `GeneratedSequenceBase<'T>`, `ListCollector<'T>`, `ArrayCollector<'T>`). Many of these are the compiler-emitted call targets for `seq { }` constructs.

## `module internal IEnumerator` (Microsoft.FSharp.Collections)

- `noReset` / `notStarted` / `alreadyFinished` / `check` / `dispose` — enumerator state/error helpers (`noReset` raises `NotSupportedException`, the others `InvalidOperationException`).
- `cast: e: IEnumerator -> IEnumerator<'T>` — adapt a non-generic enumerator to a typed one.
- `type EmptyEnumerator<'T>` (`[<Sealed>]`, implements `IEnumerator<'T>`, `IEnumerator`, `IDisposable`) and `Empty: unit -> IEnumerator<'T>`.
- `type EmptyEnumerable<'T>` (single-case union; implements `IEnumerable<'T>` and `IEnumerable`).
- `type Singleton<'T>` (`[<Sealed>]`; implements the three enumerator interfaces) and `Singleton: x: 'T -> IEnumerator<'T>`.
- `inline checkNonNull: argName -> arg -> unit when 'a: null`.
- `mkSeq: f: (unit -> IEnumerator<'U>) -> IEnumerable<'U>` — build a lazy enumerable from an enumerator factory.

## `module RuntimeHelpers` (`[<RequireQualifiedAccess>]`) — Microsoft.FSharp.Core.CompilerServices

"A group of functions used as part of the compiled representation of F# sequence expressions." Public members:

- `type StructBox<'T when 'T:equality>` (`[<Struct; NoComparison; NoEquality>]`, internal) with ctor `value`, `Value: 'T`, and static `Comparer: IEqualityComparer<StructBox<'T>>`.
- `internal mkConcatSeq: sources -> seq<'T>` — string together a sequence of sequences (`Seq.concat` backing).
- `EnumerateWhile: guard: (unit->bool) -> source: seq<'T> -> seq<'T>` — the compiler-emitted implementation of the `while` operator.
- `EnumerateThenFinally: source -> compensation: (unit->unit) -> seq<'T>` — the compiler-emitted `try/finally`.
- `EnumerateTryWith: source -> exceptionFilter: (exn->int) -> exceptionHandler: (exn->seq<'T>) -> seq<'T>` — the compiler-emitted `try/with` (the filter returns `1` to match).
- `EnumerateFromFunctions: create -> moveNext -> current -> seq<'U>` — compiler-intrinsic untyped→typed `IEnumerable` conversion.
- `EnumerateUsing: resource -> source -> seq<'U> when 'T :> IDisposable and 'Collection :> seq<'U>` — the compiler-emitted `use`.
- `CreateEvent: addHandler -> removeHandler -> createHandler -> IEvent<'Delegate,'Args>` — builds an anonymous event.

## `type GeneratedSequenceBase<'T>` (`[<AbstractClass>]`) — line 130

"The F# compiler emits implementations of this type for compiled sequence expressions." `new: unit -> ...` plus abstract members `GetFreshEnumerator`, `GenerateNext: result: byref<IEnumerable<'T>> -> int` (returns `0`/`1`/`2` = Stop/Yield/Goto), `Close`, `CheckClose: bool`, `LastGenerated: 'T`; implements `IEnumerable<'T>`, `IEnumerable`, `IEnumerator<'T>`, `IEnumerator`, `IDisposable`.

## `type ListCollector<'T>` (`[<Struct; NoComparison; NoEquality>]`) — line 164

"Collects elements and builds a list." Mutable internal `Result`/`LastCons` fields; members `Add`, `AddMany`, `AddManyAndClose: seq<'T> -> 'T list`, `Close: unit -> 'T list`.

## `type ArrayCollector<'T>` (`[<Struct; NoComparison; NoEquality>]`) — line 185

"Collects elements and builds an array." Mutable internal `ResizeArray`/`First`/`Second`/`Count` fields; members `Add`, `AddMany`, `AddManyAndClose: seq<'T> -> 'T array`, `Close: unit -> 'T array`.

# LowerComputedCollections.fs

**Purpose**: Lowers computed list and array collection expressions (list comprehensions, array comprehensions, and related seq-driven forms) into explicit calls on F#'s list/array builders (e.g. `FSharpList`/`FSharpArray` collector methods). Recognizes common seq expressions and translates them into direct builder-based code, avoiding per-element seq iteration where it is not needed.

**Namespace / module declared**: `FSharp.Compiler.LowerComputedCollectionExpressions` (internal module; contract in `LowerComputedCollections.fsi`)

**API surface**:
- `LowerComputedListOrArrayExpr: ConstraintSolver.TcValF -> TcGlobals -> ImportMap -> (TType -> ILType) -> Expr option` — the file's single public entry (per the .fsi): given a TAST expression, if it is a recognizable computed list/array shape, return the lowered expression; otherwise `None`.

Note: the .fsi exposes only `LowerComputedListOrArrayExpr`; everything below is internal to the .fs:

**Active patterns (expression recognizers)**:
- `OptionalCoerce`, `OptionalSeq`, `SeqSingleton`, `SingleYield`, `SeqToList`, `SeqToArray` — recognize coercions, `seq` wrappers, singleton/`yield` forms.
- `gatherPrelude` — factor prelude bindings out of a comprehension body.
- `SeqMap`, `SeqCollectSingle`, `SimpleMapping` — recognize `seq { for ... in ... yield ... }` map/collect shapes over a single source.
- `List`/`Array` — module-level patterns recognizing the corresponding collection expression shapes.

**Builder helpers**:
- `BuildDisposableCleanup` — synthesize the try/finally cleanup call when a seq element is a disposable.
- `mkCallCollectorMethod` / `mkCallCollectorAdd` / `mkCallCollectorAddMany` / `mkCallCollectorAddManyAndClose` / `mkCallCollectorClose` — TAST-level wrappers calling the builder API (methods resolved via `ConstraintSolver.TcValF` against `infoReader`).

**Significant internal logic**:
- The pass is invoked during optimization (from `Optimizer.fs` / codegen) when it encounters computed list/array syntax whose body lowers to a seq-based shape. The lowering re-expresses them as builder (`_collect` / `_add` / `_close`) member calls on `FSharpList<'T>Builder` / `FSharpArray<'T>Builder` so that `for..in` loops with simple `yield`/`yield!`/`yield from` semantics are realized without the general seq state machine.
- `ConstraintSolver.TcValF` is threaded in so that the lowering can resolve the specific builder member to call (the exact type instance of the builder is known per expression).
- `ilTyForTy: TType -> ILType` is passed so the lowering can choose between list and array targets at the IL level.

**Cross-references**:
- Signature: `LowerComputedCollections.fsi`.
- Sibling lowering pass in `src/Compiler/Optimize/` driven by `Optimizer.fs`.
- Related: `LowerSequences.fs` (the general seq state machine this pass avoids where possible) and `LowerStateMachines.fs`.
- Depends on `TcGlobals`, `ImportMap` (`FSharp.Compiler.Import`), `ConstraintSolver.TcValF`, `TypedTree`, and `FSharp.Compiler.AbstractIL.IL` (for `ILType`).
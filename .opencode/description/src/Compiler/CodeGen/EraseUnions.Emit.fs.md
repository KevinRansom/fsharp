# EraseUnions.Emit.fs

**Purpose**: "Erase discriminated unions — IL instruction emission." Provides the IL instruction blocks for the *operations on* an erased union: loading a case's data (`LdData`), loading the tag, testing whether a value is a given case (`IsData`), discriminating (`TagDiscriminate` + `BrIsData`), casting to a case (`CastData`), switching over cases (`DataSwitch`), and constructing a new value of a case (`NewData`). The emit code is parameterized over an `ICodeGen<'Mark>` (a small interface for emitting instructions into a buffer), which makes it reusable from `IlxGen.fs`, the legacy generator, and FSI.

**Namespace / module declared**: `FSharp.Compiler.AbstractIL.ILX.EraseUnionsEmit` (`[<AutoOpen>]` internal module; no dedicated .fsi)

**Public API surface** (notable top-level `let`s):
- `mkRuntimeTypeDiscriminate` / `mkRuntimeTypeDiscriminateThen` — emit IL to discriminate by runtime type (the `SmallRef` layouts).
- `mkGetTagFromField` / `mkSetTagToField` — emit IL to load / store the `_tag` integer field (the `Tagged*` layouts).
- `mkGetTagFromHelpers` / `mkGetTag` — pick tag access by helpers vs. raw field based on `DataAccess` (from `EraseUnions.Types.fs`).
- `mkCeqThen after` — emit a `ceq` + `brtrue` jump.
- `mkTagDiscriminate` / `mkTagDiscriminateThen` — emit the tag check for one case + optional branch block.
- `mkLdData` / `mkLdDataAddr` — emit `ldfld`/`ldflda` of the case's field, dispatching by `(access, cuspec, cidx, fidx)`.
- `mkStData` — emit `stfld` (store a case's field).
- `mkNewData` — emit the construction of a new value of a given case; handles `SingleCaseRef` vs. `Tagged*` vs. `FSharpList` and the null-representation case.
- `mkIsData` — emit the "is this value a case" test.
- `mkBrIsData` — emit the branch-if-is-case.
- `emitLdDataTag` / `emitLdDataTagPrim` — higher-level wrappers that emit a tag-check + data-load as a *single* code block (via `ICodeGen`).
- `emitCastData` — emit a cast-to-case (with or without fail).
- `emitDataSwitch` — emit a `switch`-based dispatch over a set of cases.
- `emitRawConstruction` (private) — the raw construction IL.
- `emitBranchOnCase` (private) — branches based on case index.
- `emitIsCase` / `emitCaseSwitch` (private) — the building blocks used by the public emitters.

**Types declared**:
- `ICodeGen<'Mark>` — a small abstract interface for emitting instructions into a code buffer: `CodeLabel: 'Mark -> ILCodeLabel`, `GenerateDelayMark: unit -> 'Mark`, `GenLocal: ILType -> uint16`, `SetMarkToHere: 'Mark -> unit`, `EmitInstr: ILInstr -> unit`, `EmitInstrs: ILInstr list -> unit`, `MkInvalidCastExnNewobj: unit -> ILInstr`. `IlxGen.fs` implements this over its `CodeGenBuffer` when a real buffer is available.
- `genWith g : ILCode -> 'T` — provide a default in-memory implementation of `ICodeGen<ILCodeLabel>` that accumulates instructions into an `ILCode` (a ResizeArray of instructions + label→pc table; `GenLocal`/`MkInvalidCastExnNewobj` are `failwith "not needed"` in this mode).

**Helpers / internals**:
- `adjustFieldNameForTypeDef hasHelpers nm` / `adjustFieldName access nm` — rename fields to their "helper" names (`Head` → `HeadOrDefault`, `Tail` → `TailOrNull`) when `DataAccess` is `ViaHelpers`/`ViaListHelpers` (for list shape interop with C#).
- `mkGetTailOrNull` — the F#-list-specific tail null-check.
- `mkNewData` is the most complex helper: it inspects `(layout, cidx)` via the active patterns from `EraseUnions.Types.fs` to choose between emitting `newobj` (root class), `newobj` (nested type), `ldnull` (null representation), or `ldsfld` (singleton field).

**Significant internal logic**:
- **Two-axis pattern** (from the `EraseUnions.Types.fs` header): every emit function first matches on `CaseStorage` (WHERE is the data?) and then on `DiscriminationMethod` (HOW to tell it apart?). This keeps each function a simple decision table rather than a re-derivation.
- **Nullary cases on helpers**: when a union uses `SpecialFSharpOptionHelpers`/`SpecialFSharpListHelpers` and we are inter-assembly, the underlying type of a nullary case is *not* exposed (it would pollute the visible API surface), so discrimination must go through the `IsFoo` helper rather than a runtime type check.
- **Tail-null discrimination** (F# lists): the `Nil` case is represented as `null`; `Cons` is discriminated by the `Tail` field being non-null. `mkGetTailOrNull` emits that check.
- The emit functions are *pure* with respect to the ILX world: they emit instructions that reference fields/methods by name only (the actual `ILFieldSpec` / `ILMethodRef` is computed at the call site from the same `UnionLayout` / `CaseStorage` that the emitter is given).

**Cross-references**:
- `EraseUnions.Types.fs` — the classification (active patterns, `DataAccess`, `CaseStorage`, `UnionLayout`) that the emit functions match on.
- `EraseUnions.fs` — the type-definition generation (emits the fields/methods whose *names* the emit functions reference).
- `EraseClosures.fs` — sibling erasure pass.
- `IlxGen.fs` — the caller that provides the `ICodeGen` implementation (via `CodeGenBuffer`) and drives both the type-def generation and the body emission.
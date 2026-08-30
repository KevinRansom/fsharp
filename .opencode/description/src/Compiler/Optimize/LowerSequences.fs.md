# LowerSequences.fs

**Purpose**: Lowers F# sequence expressions (`seq { ... }`) into a state machine represented as a TAST expression with `goto`/`return`/label nodes. The compiled form is an `IEnumerator`-implementing closure object whose state (local `let` bindings, program counter, current value, free variables) becomes fields of that object, enabling lazy evaluation across multiple `MoveNext` calls.

**Namespace / module declared**: `FSharp.Compiler.LowerSequenceExpressions` (internal module; contract in `LowerSequences.fsi`)

**Types declared**:
- `LoweredSeqFirstPhaseResult` — result of phase 1 of the lowering: a `phase2` continuation (which, once code-label → program-counter mapping is known, produces the `(generate, dispose, checkDispose)` TAST bodies), the `entryPoints` labels, `significantClose` (whether dispose does real work), `stateVars` (let-bindings promoted to state variables), and `asyncVars` (free variables captured in the non-synchronous path).

**API surface**:
- `ConvertSequenceExprToObject: TcGlobals -> ImportMap -> Expr -> (ValRef * ValRef * ValRef * ValRef list * Expr * Expr * Expr * TType * range) option` — recognize a sequence expression and produce the lowered pieces: state-variable refs (`pc`, `current`, `nextVar`, plus `stateVars`), the generate/dispose/checkDispose bodies, the resulting type, and the range. Returns `None` if the expression is not a sequence expression.
- `IsPossibleSequenceExpr: TcGlobals -> Expr -> bool` — cheap syntactic check that the expression could be the elaborated form of a sequence expression (it is a `Seq` node).
- `(|SeqElemTy|_|): TcGlobals -> ImportMap -> range -> TType -> TType voption` — active pattern that confirms a type is `seq<'T>` (`System.Collections.Generic.IEnumerable<'T>` after the search up the type hierarchy) and returns the element type.
- `callNonOverloadedILMethod: TcGlobals -> ImportMap -> range -> string -> TType -> Exprs -> Expr` — call a non-overloaded known IL method (used e.g. for `GetEnumerator`/`MoveNext`/`Current`) by resolving it intrinsically via `TryFindIntrinsicMethInfo`.

**Significant internal logic**:
- Two-phase analysis (as documented in-file). Phase 1 decides, for each inner `let` binding, whether to represent it as a **local** (non-escaping) variable or as a **state machine variable**, and accumulates the set of code labels (`entryPoints`). `RepresentBindingAsLocal` and `RepresentBindingAsStateMachineLocal` are the two decision implementations, each decorating the phase-2 `generate` body.
- Phase 2 (the `phase2` closure) is invoked after all labels have been assigned integer program counters; it emits the TAST for `MoveNext` (the *generate* body), `Dispose`, and `CheckDispose`.
- The resulting closure object hosts: state variables (`ValRef list`), the program counter (a state variable), the "current" yielded value, and any additional free variables of the sequence expression. This object is what the ILX-level closure mechanism (`EraseClosures`) will later compile to a .NET object with fields.
- `significantClose` flags whether a `try..finally` / `use` is present so the caller knows to emit dispose machinery at all.

**Notes / helpers**:
- `mkLambdaNoType` — lambda without an explicit type annotation (type inferred at use site).
- `tyConfirmsToSeq` — the type-level test used by `SeqElemTy`.
- A `verbose` flag gates trace output during lowering.

**Cross-references**:
- Signature: `LowerSequences.fsi`.
- Runs as part of `src/Compiler/Optimize/` pipeline (orchestrated by `Optimizer.fs`).
- Produces TAST that references `ILCodeLabel`s (from `FSharp.Compiler.AbstractIL`) — the bridge from TAST into the ILX state machine representation.
- Sibling: `LowerStateMachines.fs` — the state machine machinery (async / computation expressions) the seq state machine is built on top of; both feed `EraseClosures`/`EraseUnions`/`IlxGen` in `src/Compiler/CodeGen/`.
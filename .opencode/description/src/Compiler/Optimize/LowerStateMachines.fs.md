# LowerStateMachines.fs

**Purpose**: Analyzes a TAST expression to detect the elaborated form of a *state machine* expression (the form produced by `async {}`, `task {}`, `use`-based computations, and similar resumable-code constructs), and compiles it into an explicit state machine: a TAST with program-counter labels, `goto`/`return`/`label` nodes, state variables for locals, and a `MoveNext`-style resumable body. This is the machinery behind async / computation expressions with resumable semantics.

**Namespace / module declared**: `FSharp.Compiler.LowerStateMachines` (internal module; contract in `LowerStateMachines.fsi`)

**Types declared**:
- `StateMachineConversionFirstPhaseResult` — phase-1 result: `phase1` (expanded expr), `phase2: Map<int, ILCodeLabel> -> Expr` (runs after the pc→label mapping is known), `entryPoints` (labels allocated in this portion), `stateVars` (let-bindings promoted to state variables), `thisVars` (the `this` values of the state machine object), `resumableVars` (free vars captured by the resumable path).
- `LoweredStateMachine` — record-ish wrapper: `templateStructTy`, `dataTy`, `stateVars`, `thisVars`, `moveNext`, `setStateMachine`, `afterCode`.
- `LoweredStateMachineResult` — ADT: `Lowered` (success), `UseAlternative` (recognized but not compilable, with alternative expr), `NoAlternative` (recognized but not compilable, no alternative), `NotAStateMachine`.
- `env` — the state-machine conversion environment: `ResumableCodeDefns: ValMap<Expr>` (bindings of resumable-code values) and `TemplateStructTy: TType option`.
- `LowerStateMachine` — a value-type class wrapping the conversion; `Apply(overallExpr, altExprOpt) -> LoweredStateMachineResult` is its entry method.

**API surface**:
- `LowerStateMachineExpr: TcGlobals -> ValMap<Expr> -> Expr -> LoweredStateMachineResult` — top-level entry: detect and lower a state-machine expression.
- `IsStateMachineExpr: TcGlobals -> Expr -> LoweredStateMachineResult voption` — used at every expression during codegen to check whether it *is* a state machine; walks `let` bindings of resumable-code values, `if __useResumableCode ...` guards, and the `StructStateMachineExpr` node.
- `OptionalResumeAtExpr` — active pattern extracting an optional `pcExpr` and the code body out of a resumable expr.
- `RepresentBindingAsTopLevelOrLocal` / `RepresentBindingAsThis` / `RepresentBindingAsStateVar` — the three decisions for what to do with each `let` binding inside the state machine body.

**Internal machinery (conversion sub-passes)**:
- `ConvertResumableCode` — the driver that walks the resumable-code expression and dispatches to handlers.
- `ConvertResumableWhile`, `ConvertResumableTryFinally`, `ConvertResumableIntegerForLoop`, `ConvertResumableTryWith`, `ConvertResumableMatch`, `ConvertResumableLet`, `ConvertResumableSequential` — per-construct handlers, each composing the phase-1 results of the sub-expressions and merging `entryPoints` / `resumableVars`.
- `addPcJumpTable` — emits the `match pc` jump table at the top of the generated `MoveNext` body.
- `BindResumableCodeDefinitions`, `TryReduceApp`, `TryReduceExpr` — handle references to resumable-code definitions and beta-reduce in-situ.
- `isExpandVar` / `isStateMachineBindingVar` — test for the "resumable" type and for machine-recognized binding names (`builder@...`, `this`).
- `genPC` / `pcCount` — allocation of integer program counters; labels are allocated after phase 1, mapped to PCs, then used to build the jump table in phase 2.

**Significant internal logic**:
- Two-phase construction (mirroring `LowerSequences.fs`): phase 1 walks the expression, decides the representation of each binding (local / `this` / state variable), and collects entry points and free resumable vars; phase 2, after the pc → `ILCodeLabel` map is finalized, produces the final TAST including the jump table.
- State variables are implemented as `mkValSet` stores that clear the variable (set default) when the body completes with `true` (the "completion" return value convention) — this is what makes state machine locals reentrant-safe across `MoveNext` calls.
- `try..with` (exception filter) is special-cased: the inner match is rebuilt over the *inner* pcs via label remapping, and the outer labels are re-emitted around the rebuilt body.
- On failure to lower, the result is an `Alternate`/`NoAlternative` diagnostic path — the pass is conservative and falls back to whatever alternate expression the elaborator provided.

**Cross-references**:
- Signature: `LowerStateMachines.fsi`.
- Uses `ILCodeLabel` and label machinery from `FSharp.Compiler.AbstractIL.IL`.
- Pipeline sibling in `src/Compiler/Optimize/` (orchestrated by `Optimizer.fs`); closely related to `LowerSequences.fs` (same two-phase, state-machine construction).
- Produces TAST with `ILCodeLabel`s and resumable-code nodes, consumed by `EraseClosures.fs` / `IlxGen.fs` in `src/Compiler/CodeGen/` for final IL emission.

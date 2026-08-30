# LowerStateMachines.fsi

**Purpose**: Signature file for `FSharp.Compiler.LowerStateMachines` (implementation in `LowerStateMachines.fs`). Declares the contract of the pass that recognizes the elaborated form of a state machine (async / resumable computation expression) and lowers it into an explicit state machine TAST with state variables, a program counter, and a resumable-body expression.

**Namespace / module declared**: `module internal FSharp.Compiler.LowerStateMachines` (internal, compiler-use only).

**Types declared**:
- `LoweredStateMachine` — record-style wrapper:
  - `templateStructTy: TType` — the struct template type of the state machine
  - `dataTy: TType` — the data type carried by the state machine
  - `stateVars: ValRef list` — state variables (promoted let-bindings)
  - `thisVars: ValRef list` — the "this" values of the state machine
  - `moveNext: (Val * Expr)` — the moved-next / step expression
  - `setStateMachine: (Val * Val * Expr)` — the state-machine setter (val, val, expr)
  - `afterCode: (Val * Expr)` — code run after the state machine completes
- `LoweredStateMachineResult` — ADT:
  - `Lowered of LoweredStateMachine` — a state machine was recognized and is compilable
  - `UseAlternative of message: string * alternativeExpr: Expr` — recognized but not compilable; an alternative is available
  - `NoAlternative of message: string` — recognized but not compilable and no alternative exists
  - `NotAStateMachine` — the construct was not a state machine

**API declared**:
- `LowerStateMachineExpr: g: TcGlobals -> outerResumableCodeDefns: ValMap<Expr> -> overallExpr: Expr -> LoweredStateMachineResult` — documented as: "Analyze a TAST expression to detect the elaborated form of a state machine expression, a special kind of object expression that uses special code generation constructs."

**Dependencies opened**: `FSharp.Compiler.TypedTree`, `FSharp.Compiler.TypedTreeOps`, `FSharp.Compiler.TcGlobals`.

**Cross-references**: `LowerStateMachines.fs` (implementation; `StateMachineConversionFirstPhaseResult` two-phase type, `IsStateMachineExpr` recognizer, the per-construct `ConvertResumable*` handlers, `RepresentBindingAs{TopLevelOrLocal,This,StateVar}`); pipeline sibling `LowerSequences.fs` (shared two-phase, state-machine construction); downstream: `EraseClosures.fs` / `IlxGen.fs` in `src/Compiler/CodeGen/`.
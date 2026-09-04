# LowerSequences.fsi

**Purpose**: Signature file for `FSharp.Compiler.LowerSequenceExpressions` (implementation in `LowerSequences.fs`). Declares the contract of the pass that lowers `seq { ... }` expressions into a state machine TAST (goto/return/label nodes) hosted in a closure object.

**Namespace / module declared**: `module internal FSharp.Compiler.LowerSequenceExpressions` (internal, compiler-use only).

**API declared**:
- `(|SeqElemTy|_|): TcGlobals -> ImportMap -> range -> TType -> TType voption` — documented: "Detect a 'seq<int>' type." Returns the element type when `TType` is `seq<'T>` (aka `IEnumerable<'T>`).
- `callNonOverloadedILMethod: g: TcGlobals -> amap: ImportMap -> m: range -> methName: string -> ty: TType -> args: Exprs -> Expr` — build a call to a known, non-overloaded IL method.
- `ConvertSequenceExprToObject: g: TcGlobals -> amap: ImportMap -> overallExpr: Expr -> (ValRef * ValRef * ValRef * ValRef list * Expr * Expr * Expr * TType * range) option` — recognize and lower a sequence expression. The result tuple carries (per file-level doc-comment): references to the **state variables**, **program counter**, **current** value, list of additional state variables, and the three bodies (`generate`, `dispose`, `checkDispose`) plus the resulting type and source range.
- `IsPossibleSequenceExpr: g: TcGlobals -> overallExpr: Expr -> bool` — quick syntactic test for "is this a sequence expression."

**Dependencies opened**: `FSharp.Compiler.Import`, `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypedTree`, `FSharp.Compiler.Text`.

**Cross-references**: `LowerSequences.fs` (implementation, phase-1/phase-2 structure in `LoweredSeqFirstPhaseResult`); driven by `Optimizer.fs`; produces TAST consumed downstream by `EraseClosures.fs` / `IlxGen.fs` in `src/Compiler/CodeGen/`.
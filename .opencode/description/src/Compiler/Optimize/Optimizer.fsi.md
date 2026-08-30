# Optimizer.fsi

**Purpose**: Signature file for `FSharp.Compiler.Optimizer` (implementation in `Optimizer.fs`). Declares the public contract of the mid-end optimizer, the shape of its settings, the shape of its cross-module optimization info, and the two key side-channel APIs used by sibling modules (`ExprHasEffect` and `IsKnownOnlyMutableBeforeUse`).

**Namespace / module declared**: `module internal FSharp.Compiler.Optimizer` (internal, compiler-use only).

**Types declared**:
- `[<RequireQualifiedAccess>] type OptimizationProcessingMode` — `Sequential` (single thread, all phases per file) or `Parallel` (phase-pipelined across files on multiple threads).
- `type OptimizationSettings` — record of tuning knobs (`abstractBigTargets`, `jitOptUser`, `localOptUser`, `debugPointsForPipeRight`, `crossAssemblyOptimizationUser`, `bigTargetSize`, `veryBigExprSize`, `lambdaInlineThreshold`, reporting flags, `processingMode`, `alwaysInline`); members:
  - `JitOptimizationsEnabled: bool`
  - `LocalOptimizationsEnabled: bool`
  - `static member Defaults: OptimizationSettings`
- `type ModuleInfo` — per-module optimization summary (implementation detail hidden from consumers).
- `type LazyModuleInfo = InterruptibleLazy<ModuleInfo>`
- `type ImplFileOptimizationInfo = LazyModuleInfo`
- `type CcuOptimizationInfo = LazyModuleInfo`
- `[<Sealed>] type IncrementalOptimizationEnv` — the incremental optimization environment; `static member Empty`.
- `[<RequireQualifiedAccess>] type EffectContext` — `Emit` (IL emitting, may eliminate a fully-ground `Unchecked.defaultof` binding) or `InlineBody` (analyzing the pickled body of an `inline` value).

**API declared**:
- `BindCcu: CcuThunk -> CcuOptimizationInfo -> IncrementalOptimizationEnv -> TcGlobals -> IncrementalOptimizationEnv` — "for building optimization environments incrementally."
- `OptimizeImplFile: OptimizationSettings * CcuThunk * TcGlobals * ConstraintSolver.TcValF * Import.ImportMap * IncrementalOptimizationEnv * isIncrementalFragment: bool * emitTailcalls: bool * SignatureHidingInfo * CheckedImplFile -> (IncrementalOptimizationEnv * CheckedImplFile * ImplFileOptimizationInfo * SignatureHidingInfo) * (bool -> Expr -> Expr)` — "optimize one implementation file in the given environment." The returned second function is the `optimizeDuringCodeGen` hook used later at codegen time.
- `p_CcuOptimizationInfo: CcuOptimizationInfo -> WriterState -> unit` — pickle.
- `RemapOptimizationInfo: TcGlobals -> Remap -> (CcuOptimizationInfo -> CcuOptimizationInfo)` — "rewrite the module info using the export remapping."
- `AbstractOptimizationInfoToEssentials: (CcuOptimizationInfo -> CcuOptimizationInfo)` — "ensure that 'internal' items are not exported in the optimization info."
- `UnionOptimizationInfos: seq<ImplFileOptimizationInfo> -> CcuOptimizationInfo`.
- `ExprHasEffect: EffectContext -> TcGlobals -> Expr -> bool` — "check if an expression has an effect."
- `u_CcuOptimizationInfo: ReaderState -> CcuOptimizationInfo` — unpickle.
- `IsKnownOnlyMutableBeforeUse: ValRef -> bool` — "indicates the value is only mutable during its initialization and before any access or capture."

**Conditional declarations**:
- `#if DEBUG`: `moduleInfoL: TcGlobals -> LazyModuleInfo -> Layout` — "display optimization data."

**Dependencies opened**: `FSharp.Compiler`, `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.Text`, `FSharp.Compiler.TypedTree`, `FSharp.Compiler.TypedTreeOps`, `FSharp.Compiler.TypedTreePickle`, `Internal.Utilities.Library`.

**Cross-references**: `Optimizer.fs` (the ~247 KB implementation); consumers include `DelegateForwarding.fs` (takes `ExprHasEffect` as a parameter), `LowerLocalMutables.fs` (calls `IsKnownOnlyMutableBeforeUse`), and the ILX codegen in `src/Compiler/CodeGen/IlxGen.fs` (uses the `optimizeDuringCodeGen` closure).
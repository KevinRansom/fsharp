# Optimizer.fs

**Purpose**: The main body of the F# compiler's "mid-end" peephole/whole-file optimizer and the orchestrator of the lowering pipeline. Run over each implemented module, it performs local (intra-method) and cross-assembly optimizations: inline lambda elimination, constant propagation / value-info analysis, effect analysis, structural (tuple/record/union-case) binding expansion, tuple detupling, query-expression lowering, bool-logic folding, dead-binding elimination, tail-call marking, large-method splitting, and the abstraction/remapping of optimization info that crosses module and assembly boundaries.

**Namespace / module declared**: `FSharp.Compiler.Optimizer` (internal module; contract in `Optimizer.fsi`). The `#if DEBUG` block also exposes `moduleInfoL` for displaying optimization data as `Layout`.

**Types declared**:
- `OptimizationProcessingMode` — `Sequential` (one file, all phases, on one thread) or `Parallel` (phase-pipelined across files on multiple threads).
- `OptimizationSettings` — tuning knobs: `abstractBigTargets`, `jitOptUser`, `localOptUser`, `debugPointsForPipeRight`, `crossAssemblyOptimizationUser`, `bigTargetSize` (split-at-match threshold), `veryBigExprSize`, `lambdaInlineThreshold`, reporting flags (`reportingPhase`, `reportNoNeedToTailcall`, `reportFunctionSizes`, `reportHasEffect`, `reportTotalSizes`), `processingMode`, `alwaysInline`; derived members `JitOptimizationsEnabled` / `LocalOptimizationsEnabled`, plus per-optimation toggle members (`InlineLambdas`, `EliminateUnusedBindings`, `EliminateForLoop`, `EliminateSwitch`, `EliminateRecdFieldGet`, `EliminateTupleFieldGet`, `EliminateUnionCaseCaseFieldGet`, `EliminateImmediatelyConsumedLocals`, `ExpandStructuralValues`, `EliminateTryWithAndTryFinally`, `DebugPointsForPipeRight`); `static member Defaults`.
- `ModuleInfo` — per-module optimization summary (value info per val, tailcall facts, etc.).
- `LazyModuleInfo` / `ImplFileOptimizationInfo` / `CcuOptimizationInfo` — lazy wrappers around module info for cross-file / cross-ccu data.
- `IncrementalOptimizationEnv` — incremental (per-CCU) environment holding global module infos and per-value bindings; `static member Empty`.
- `EffectContext` — `Emit` (emitting IL) or `InlineBody` (analyzing a pickled `inline` body); governs whether a fully-ground `Unchecked.defaultof` binding may be eliminated.

**API surface (key functions)**:
- `OptimizeImplFile: settings * ccu * g * tcVal * importMap * optEnv * isIncrementalFragment * emitTailcalls * hidden * CheckedImplFile -> (IncrementalOptimizationEnv * CheckedImplFile * ImplFileOptimizationInfo * SignatureHidingInfo) * (bool -> Expr -> Expr)` — **the** entry point (line 4749). Builds `cenv`, runs `OptimizeImplFileInternal`, and returns the optimized file plus an `optimizeDuringCodeGen` closure (used later at codegen time to inline/expand further).
- `OptimizeExpr cenv env expr` — the central expression optimizer (line 2494), a big match over `TAST` that drives all the local optimizations.
- `ExprHasEffect: EffectContext -> TcGlobals -> Expr -> bool` (line 1673) — effect analysis, used across the compiler (notably passed into `DelegateForwarding.fs`).
- `IsKnownOnlyMutableBeforeUse: ValRef -> bool` (line 1579) — used by `LowerLocalMutables.fs`.
- `BindCcu`, `AbstractOptimizationInfoToEssentials`, `UnionOptimizationInfos`, `RemapOptimizationInfo`, `p_CcuOptimizationInfo` / `u_CcuOptimizationInfo` — cross-module / cross-assembly info management (pickling/unpickling, abstraction to "essentials", remapping under export renames).

**Internal machinery (notable groups)**:
- **Value / effect analysis**: `MakeValueInfoForValue`, `MakeValueInfoForRecord|Tuple|UnionCase|Const`, `mkAssemblyCodeValueInfo`, `IntegerUnaryOp`/`IntegerBinaryOp`/`SignedIntegerUnaryOp` (over integer widths), `IsPartialExpr`, `ValueOfExpr`, `ExprHasEffect`, `IsDiscardableEffectExpr`, `OrEffects`/`OrTailcalls`.
- **Binding elimination / expansion**: `TryEliminateBinding`, `TryEliminateLet`, `SplitValuesByIsUsedOrHasEffect`, `ExpandStructuralBindingRaw`, `RearrangeTupleBindings`, `TryRewriteBranchingTupleBinding`, `ExpandStructuralBinding`, `CanExpandStructuralBinding`, `MakeStructuralBindingTemp(Val)`, `MakeMutableStructuralBindingForTupleElement`; value-strip active patterns (`StripConstValue`, `StripLambdaValue`, `StripUnionCaseValue`), `destTupleValue` / `destRecdValue`.
- **Bool-logic and decision tree**: `CombineBoolLogic`, `CountBoolLogicTree`, `RewriteBoolLogicTree`, `TDBoolSwitch`, `ConstantBoolTarget`.
- **Query expression lowering**: active patterns `QueryRun`, `QuerySourceEnumerable`, `QueryFor`, `QueryYield`, `QueryYieldFrom`, `QuerySelect`, `QueryZero`, `MaybeRefTupled`, `AnyInstanceMethodApp`, `InstanceMethodApp`, `AnyRefTupleTrans`, `AnyQueryBuilderOpTrans`; `tryRewriteToSeqCombinators`; `TryDetectQueryQuoteAndRun`.
- **String interning helpers**: `IsILMethodRefSystemStringEquals` / `...Concat` / `...ConcatArray`, `IsDebugPipeRightExpr`.
- **Inlining / force-inline in debug**: `HasFrameLocalBody`, `shouldForceInlineInDebug`, `shouldForceInlineMembersInDebug`, `AddDirectDelegateTargetToDontInlineSet`.
- **Abstraction of info**: `AbstractLazyModulInfoByHiding`, `AbstractExprInfoByVars`, `AbstractAndRemapModulInfo`, `BindValueInSubModuleFSharpCore`, `BindValueForFslib`, `BindInternalLocalVal`/`BindExternalLocalVal`/`BindValsInModuleOrNamespace`.
- **Pickling / unpickling**: `p_ExprValueInfo`, `p_ValInfo`, `u_ExprInfo`, `u_LazyModuleInfo`, `p_CcuOptimizationInfo`, `u_CcuOptimizationInfo`.
- **Module-level driver**: `OptimizeImplFileInternal` / `OptimizeModuleExprWithSig` / `OptimizeModuleContents` / `OptimizeModuleDefs` / `OptimizeModuleBindings` / `OptimizeModuleBinding` / `OptimizeBinding`.

**Significant internal logic**:
- The optimizer distinguishes **two scopes of analysis**: local (per expression) value/effect info, and **cross-module / cross-assembly** value info carried in `ModuleInfo` and stored in a layered (`LayeredMap`) global table keyed by CCU. When crossing a signature boundary the info is abstracted to "essentials" (via `AbstractLazyModulInfoByHiding` and `AbstractOptimizationInfoToEssentials`) so internal values are not leaked into downstream CCUs but *are* available for cross-assembly inlining / effect analysis.
- Inline lambda elimination (controlled by `lambdaInlineThreshold`) is gated on the callee having no effect, not being critical-tail-call, and being small enough.
- Structural value expansion inlines tuple / record / union-case construction and deconstruction into the body of the function that immediately consumes them.
- Query expression rewriting runs *before* the generic seq state machine lowering (so simple query shapes compile to direct seq-combinator calls when they match `tryRewriteToSeqCombinators` / `TryDetectQueryQuoteAndRun`).
- The `optimizeDuringCodeGen` closure returned from `OptimizeImplFile` lets the codegen (`IlxGen`) request a further inline-optimization pass over individual expressions, with the `disableMethodSplitting` flag honored.
- `OptimizationProcessingMode.Parallel` is honored at the driver / ccu level; per-file processing phases are arranged so a later file can start its earlier phase while the current file is finishing a later phase.

**Cross-references**:
- Signature: `Optimizer.fsi`.
- Consumes `DelegateForwarding.fs` (via `ExprHasEffect`) and the lowering passes `LowerCalls.fs`, `LowerLocalMutables.fs`, `LowerSequences.fs`, `LowerStateMachines.fs`, `LowerComputedCollections.fs`, `DetupleArgs.fs`, `InnerLambdasToTopLevelFuncs.fs`.
- Provides `ExprHasEffect` and `IsKnownOnlyMutableBeforeUse` back to `DelegateForwarding.fs` and `LowerLocalMutables.fs`.
- Output feeds the ILX-level codegen in `src/Compiler/CodeGen/IlxGen.fs` and the erasure passes `EraseClosures.fs`, `EraseUnions.fs`, `EraseUnions.Emit.fs`, `EraseUnions.Types.fs`.
- Depends on `FSharp.Compiler.TypedTree`, `FSharp.Compiler.TypedTreeOps`, `FSharp.Compiler.TypedTreePickle`, `FSharp.Compiler.ConstraintSolver` (`TcValF`), `FSharp.Compiler.Import` (`ImportMap`, `CcuThunk`), `FSharp.Compiler.TcGlobals`, `Internal.Utilities.Library`, `FSharp.Compiler.Text`.
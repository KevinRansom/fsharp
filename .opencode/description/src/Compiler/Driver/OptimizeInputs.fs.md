# OptimizeInputs.fs

**Purpose** The optimization + code-generation driver stage. Takes the type-checked implementation files, runs them through the F# optimizer passes (first loop, any extra loops, final simplification), producing `CheckedImplFileAfterOptimization` values plus the `LazyModuleInfo`/optimization-data resource, then invokes the IlxGen backend to translate the optimized code to IL. Supports both sequential and a parallel (task-graph) scheduling of the (file × phase) work.

**Namespace(s)** `FSharp.Compiler` (module `FSharp.Compiler.OptimizeInputs`, internal)

**Values / functions (top-level)**
- `mutable showTermFileCount` — debug counter of terms shown.
- `PrintWholeAssemblyImplementation (tcConfig) outfile header expr` — debug printer for a whole assembly implementation.
- `AddExternalCcuToOptimizationEnv tcGlobals optEnv importedAssembly` — imports an external CCU's `LazyModuleInfo` into the `IncrementalOptimizationEnv`.
- `GetInitialOptimizationEnv (tcImports, tcGlobals)` — builds the seed optimization environment from all imported assemblies' `FSharpOptimizationData`.
- `ApplyAllOptimizations ...` — the main entry: builds the phase list from `TcConfig` (`optsOn`, `extraOptimizationIterations`, `doDetuple`, `doTLR`, `doFinalSimplify`), picks sequential vs parallel execution, runs the per-file phases, and assembles the final `CheckedAssemblyAfterOptimization`, `LazyModuleInfo`, and the final `IncrementalOptimizationEnv`.
- `optimizeFilesSequentially optEnv phases implFiles` — the straightforward left-associative fold over files, feeding each file's final phase output as the next file's initial environment.
- `CreateIlxAssemblyGenerator (_tcConfig, tcImports, tcGlobals, tcVal, generatedCcu)` — constructs the `IlxAssemblyGenerator`.
- `GenerateIlxCode ilxBackend isInteractiveItExpr tcConfig topAttrs optimizedImpls fragName ilxGenerator` — walks each optimized impl file through the backend (`AddFile`, `AddType`, …) and produces `IlxGenResults`.
- `NormalizeAssemblyRefs (ctok, ilGlobals, tcImports)` — computes the `ILScopeRef -> ILScopeRef` remap used by the static linker so that type refs in the main module point at the correct (possibly forwarded/local) scope.
- `GetGeneratedILModuleName (t: CompilerTarget) s` — the IL module name (target-dependent; e.g. `"$module"` vs the assembly name) — declared twice in the .fs, identical bodies.

**Types declared**
- `FirstLoopRes` — `{ OptEnv; OptInfo; HidingInfo; OptDuringCodeGen }` — results of the first optimization loop for a file.
- `PhaseContext` — `{ FirstLoopRes; OptEnvExtraLoop; OptEnvFinalSimplify }` — accumulates state carried across a file's phases (and into the next file).
- `PhaseRes` — `CheckedImplFile * PhaseContext`.
- `PhaseIdx` — `int` alias.
- `PhaseInputs` — `{ File; FileIdx; PrevPhase; PrevFile }` — all inputs a phase function needs.
- `PhaseFunc` — `PhaseInputs -> CheckedImplFile * PhaseContext`.
- `Phase` — `{ Idx; Name }` (with `ToString`).
- `PhaseInfo` — `{ Phase; Func }`.

**Module `ParallelOptimization` (private)**
- `Node` — `{ FileIdx; Phase }` — a work unit = (file index × phase index); the whole schedule is the 2-D grid `files.Length × phases.Length`.
- `collectFinalResults fileResults` — flattens per-file `(CheckedImplFile, PhaseContext)` results into `(CheckedImplFileAfterOptimization * ImplFileOptimizationInfo)[]` plus the final `IncrementalOptimizationEnv` (from the last file's `FirstLoopRes.OptEnv`).
- `optimizeFilesInParallel env0 phases files` — builds a `Task<PhaseRes>[,]` (2-D), wires each node's two dependencies (its `(FileIdx, Phase-1)` sibling and its `(FileIdx-1, Phase)` predecessor) through `Task.WhenAll`-style awaiting of `getTask` results, and awaits all tasks via `Task.WhenAll`. A dummy `InterruptibleLazy` placeholder is stored for the initial `OptInfo` to keep the type structure uniform.

**Public API surface** `ApplyAllOptimizations`, `GetInitialOptimizationEnv`, `AddExternalCcuToOptimizationEnv`, `CreateIlxAssemblyGenerator`, `GenerateIlxCode`, `NormalizeAssemblyRefs`, `GetGeneratedILModuleName` (see .fsi).

**Internal helpers / active patterns** The `Phase`/`PhaseFunc`/`PhaseContext` family is the internal type-level encoding of the per-file optimization pipeline; `ParallelOptimization.Node` and its `getTask`/`setTask` closures implement the (file × phase) dependency graph.

**Significant internal logic**
- The optimization pipeline is broken into an ordered list of phases derived from `TcConfig` flags (optimize on/off, extra iterations, detuple, TLR, final simplify). Each phase is a pure `PhaseFunc`, so the .fs can run them in one of two regimes:
  - Sequential: `optimizeFilesSequentially` folds files one by one, each file's final state feeding the next file (correct but slower).
  - Parallel: `optimizeFilesInParallel` schedules the 2-D grid as a `Task` graph where each node awaits `(file, phase-1)` and `(file-1, phase)`, letting independent (file × phase) cells overlap on thread-pool workers (used when `tcConfig.parallelParsing`-style parallelism is on and the number of files/phases justify it).
- The `OptDuringCodeGen` function in `FirstLoopRes` is the tail-call to the "optimize during codegen" pass, preserved across phases so the IlxGen stage can still apply per-node optimizations.
- The final `IncrementalOptimizationEnv` is carried forward from the *last* file's first-loop env so downstream (signature/optimization-data) consumers see the env as if the files had been processed in order.

**Cross-refs** Called from `FSharp.Compiler.Driver` (fsc.fs `main3`); consumes `FSharp.Compiler.CompilerImports` (`ImportedAssembly.FSharpOptimizationData`, `ImportMap`), `FSharp.Compiler.Optimizer` (the passes + `IncrementalOptimizationEnv`), `FSharp.Compiler.IlxGen` (`IlxAssemblyGenerator`, `IlxGenBackend`, `IlxGenResults`), `FSharp.Compiler.TcGlobals`, and feeds `FSharp.Compiler.CreateILModule` (`IlxGenResults`) and `FSharp.Compiler.StaticLinking` (`NormalizeAssemblyRefs`).

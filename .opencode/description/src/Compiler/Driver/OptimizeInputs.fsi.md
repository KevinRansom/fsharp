# OptimizeInputs.fsi

**Purpose** Signature for the optimization + code-generation stage. Declares the main entry `ApplyAllOptimizations` (runs the F# optimizer passes over the type-checked implementation files, producing optimized code + the `LazyModuleInfo`/optimization data + the final incremental optimization environment) and the IL code-generation entry points (`CreateIlxAssemblyGenerator`, `GenerateIlxCode`) used to translate optimized code to IL.

**Pipeline role** fsc `main3`/`main4`: sits between `ParseAndCheckInputs` (which delivers the `CheckedImplFile list` + `TcState.Ccu`) and `StaticLinking`/`CreateILModule` (which consume the `IlxGenResults`). It also owns the seed optimization environment (`GetInitialOptimizationEnv` / `AddExternalCcuToOptimizationEnv`) built from the optimization data of *referenced* F# assemblies.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.OptimizeInputs`, `internal`.

**Functions (contract — order of the .fsi listing)**

- `GetGeneratedILModuleName : CompilerTarget -> string -> string` — compute the IL module name from the target and output name (e.g. `$module` for a netmodule, the assembly name otherwise). *Note: this val is declared twice in the .fsi (lines 16 and 51) with identical shape — likely a historical leftover; the .fs defines it once.*
- `GetInitialOptimizationEnv (tcImports, tcGlobals) : IncrementalOptimizationEnv` — seed the optimizer's incremental environment by feeding every imported F# assembly's lazy `FSharpOptimizationData` into it. Called once, before the assembly's own files.
- `AddExternalCcuToOptimizationEnv (tcGlobals, optEnv, importedAssembly) : IncrementalOptimizationEnv` — register one specific external CCU's optimization info into an existing env (used when the env has to be extended piecemeal, e.g. for incremental service usage).
- `ApplyAllOptimizations` — the main entry. Signature:
  `tcConfig * tcGlobals * tcVal: ConstraintSolver.TcValF * outfile: string * importMap: ImportMap *
   isIncrementalFragment: bool * optEnv: IncrementalOptimizationEnv * ccu: CcuThunk *
   implFiles: CheckedImplFile list ->
   CheckedAssemblyAfterOptimization * LazyModuleInfo * IncrementalOptimizationEnv`.
  Runs the full set of optimization passes (first loop, any extra loops per `extraOptimizationIterations`, TLR, detuple, final simplify — per the `TcConfig` flags), returning the optimized assembly, the assembly-wide `LazyModuleInfo` (used for the optimization-data resource), and the final `IncrementalOptimizationEnv` (carried forward so callers — notably the signature data writer — can still use it).
- `CreateIlxAssemblyGenerator (tcConfig, tcImports, tcGlobals, tcVal, ccu) : IlxAssemblyGenerator` — build the incremental ILX generator for the assembly (one per compile; feeds `GenerateIlxCode`).
- `GenerateIlxCode` — translate optimized code to IL via the backend. Signature:
  `ilxBackend: IlxGenBackend * isInteractiveItExpr: bool * tcConfig * topAttrs: TopAttribs *
   optimizedImpls: CheckedAssemblyAfterOptimization * fragName: string * ilxGenerator: IlxAssemblyGenerator -> IlxGenResults`.
  The `isInteractiveItExpr` flag marks whether the fragment is an F# Interactive "it expression" (affects how the result is exposed).
- `NormalizeAssemblyRefs (ctok, ilGlobals, tcImports) : (ILScopeRef -> ILScopeRef)` — the scope-ref remap used during static linking so that type refs in the main module point at their post-static-link location (local scope or the forwarded assembly). Declared with the comment "Used during static linking".

**Public API surface** `ApplyAllOptimizations` (the driver's main call, made in fsc.fs `main3`), `GetInitialOptimizationEnv` / `AddExternalCcuToOptimizationEnv` (its setup), `CreateIlxAssemblyGenerator` + `GenerateIlxCode` (the codegen pair, consumed in fsc.fs `main4`), and the two helpers `NormalizeAssemblyRefs` + `GetGeneratedILModuleName` (consumed in `FSharp.Compiler.CreateILModule` and `FSharp.Compiler.StaticLinking`).

**Internal helpers / active patterns** The internal phase/type machinery is not in the signature; it is implemented in the .fs as the `FirstLoopRes` / `PhaseContext` / `PhaseInputs` / `PhaseFunc` / `Phase` / `PhaseInfo` family plus the private `ParallelOptimization` module with its `Node = { FileIdx; Phase }` work-item type and the `getTask`/`setTask` task-graph closures. See `OptimizeInputs.fs.md`.

**Notes / caveats**
- The duplicate `GetGeneratedILModuleName` declaration (line 16 and line 51 of the .fsi, identical shape) appears to be a historical leftover; the implementation defines the binding only once.
- `isIncrementalFragment` on `ApplyAllOptimizations` distinguishes a full-assembly compile (fsc) from an incremental service pass (FCS / `IncrementalCompiler`), and drives how the optimizer and the codegen stage treat "top-level" state (e.g. the final `IncrementalOptimizationEnv` carried back to the caller).
- The three-tuple return of `ApplyAllOptimizations` (`CheckedAssemblyAfterOptimization * LazyModuleInfo * IncrementalOptimizationEnv`) is deliberate: the driver needs the optimized files for codegen, the `LazyModuleInfo` for the optimization-data resource written into the assembly, and the final env so that `EncodeOptimizationData` / `EncodeSignatureData` can be invoked with a consistent view of the whole assembly.
- `GenerateIlxCode` takes `fragName`, which is the fragment name used by the ILX backend to name the produced body fragment — in fsc it is derived from the compilation, in FCS it is per-request.

**Significant internal logic** The .fs decomposes per-file optimization into an explicit ordered list of **phases** (first loop + extra loops + final simplify, each with its own incremental environment), and then schedules the **(file × phase) grid** as a dependency task graph so independent (file, phase) cells can run in parallel while preserving the two required dependencies: phase *N* of file *F* needs phase *N-1* of file *F*, and phase *N* of file *F* needs phase *N* of file *F-1* (because each file's optimization must see the previous file's env). `optimizeFilesSequentially` folds files left-to-right for the no-parallelism path.

**Cross-refs**
- Called from: `FSharp.Compiler.Driver` (fsc.fs `main3`/`main4`).
- Consumes: `FSharp.Compiler.CompilerImports` (`TcImports.DllTable`, `ImportedAssembly.FSharpOptimizationData`, `GetImportMap`), `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.CompilerConfig` (`TcConfig` flags).
- Feeds: `FSharp.Compiler.Optimizer` (the actual passes + `IncrementalOptimizationEnv`), `FSharp.Compiler.IlxGen` (the `IlxAssemblyGenerator`/`IlxGenBackend`/`IlxGenResults` machinery), `FSharp.Compiler.CreateILModule` (`CreateMainModule` consumes `IlxGenResults`), `FSharp.Compiler.StaticLinking` (`NormalizeAssemblyRefs`).

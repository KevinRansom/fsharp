# IlxGen.fsi

**Purpose**: Signature file for `FSharp.Compiler.IlxGen` (implementation in `IlxGen.fs`). Declares the public contract of the final code generation engine: the backend choice, the options record, the results type, the `IlxAssemblyGenerator` facade (used by FSI and other consumers to drive codegen incrementally), and the compile-inversion context used by FSI `#get`/`#set`/`#clear`.

**Namespace / module declared**: `module internal FSharp.Compiler.IlxGen` (internal at F#-level, but two of the types are marked `public` so they are also usable from other compiler components such as FSI).

**Types declared** (per the .fsi):
- `type IlxGenBackend` — `IlWriteBackend` (file-based IL) | `IlReflectBackend` (reflection-emit, used in FSI / multi-emit scenarios). "Indicates how the generated IL code is ultimately emitted."
- `[<NoEquality; NoComparison>] type internal IlxGenOptions` — the codegen tuning record. Fields:
  - `fragName: string` — fragment/assembly name.
  - `generateFilterBlocks: bool` — "indicates if we are generating filter blocks" (i.e. real `filter` blocks in the PE exception table, vs. the legacy `try..with` emulation).
  - `workAroundReflectionEmitBugs: bool` — "workaround old reflection emit bugs".
  - `emitConstantArraysUsingStaticDataBlobs: bool` — static blob vs. cctor initialization for constant arrays.
  - `mainMethodInfo: Attribs option` — "if this is set, then the last module becomes the 'main' module".
  - `localOptimizationsEnabled: bool`.
  - `generateDebugSymbols: bool`.
  - `testFlagEmitFeeFeeAs100001: bool` — "a flag to help test emit of debug information" (emits a FEE-FEE marker with a special sequence-point number).
  - `ilxBackend: IlxGenBackend`.
  - `fsiMultiAssemblyEmit: bool` — "is --multiemit enabled?".
  - `isInteractive: bool` — "the code is being generated in FSI.EXE and is executed immediately after code generation. This includes all interactively compiled code, including #load, definitions, and expressions".
  - `isInteractiveItExpr: bool` — "the code generated is an interactive 'it' expression. We generate a setter to allow clearing of the underlying storage, even though 'it' is not logically mutable".
  - `useReflectionFreeCodeGen: bool` — "suppress ToString emit".
  - `alwaysCallVirt: bool` — "whenever possible, use callvirt instead of call".
  - `parallelIlxGenEnabled: bool` — "IlxGen will delay generation of method bodies and generate them later in parallel (parallelized across files)".
  - `alwaysInline: bool` — "inline functions are being inlined or emitted as calls".
- `type public IlxGenResults` — "the results of the ILX compilation of one fragment of an assembly":
  - `ilTypeDefs: ILTypeDef list` — the generated IL type definitions.
  - `ilAssemAttrs: ILAttribute list` — assembly attributes.
  - `ilNetModuleAttrs: ILAttribute list` — .NET module attributes.
  - `topAssemblyAttrs: Attribs` — "the attributes for the assembly in F# form".
  - `permissionSets: ILSecurityDecl list` — security attributes to attach to the assembly.
  - `quotationResourceInfo: (ILTypeRef list * byte[]) list` — "the generated IL/ILX resources associated with F# quotations".
- `type ExecutionContext` — "used to support the compilation-inversion operations 'ClearGeneratedValue' and 'LookupGeneratedValue'": `LookupTypeRef: ILTypeRef -> Type` and `LookupType: ILType -> Type`.
- `type public IlxAssemblyGenerator` — "an incremental ILX code generator for a single assembly." Members:
  - `new: Import.ImportMap * TcGlobals * ConstraintSolver.TcValF * CcuThunk -> IlxAssemblyGenerator` — constructor.
  - `AddExternalCcus: CcuThunk list -> unit` — "register a set of referenced assemblies with the ILX code generator".
  - `AddIncrementalLocalAssemblyFragment: isIncrementalFragment: bool * fragName: string * typedImplFiles: CheckedImplFile list -> unit` — "register a fragment of the current assembly with the ILX code generator. If 'isIncrementalFragment' is true then the input is assumed to be a fragment 'typed' into FSI.EXE, otherwise the input is assumed to be the result of a '#load'".
  - `GenerateCode: IlxGenOptions * CheckedAssemblyAfterOptimization * Attribs * Attribs -> IlxGenResults` — "generate ILX code for an assembly fragment".
  - `ClearGeneratedValue: ExecutionContext * Val -> unit` — "invert the compilation of the given value and clear the storage of the value".
  - `ForceSetGeneratedValue: ExecutionContext * Val * objnull -> unit` — "invert the compilation of the given value and set the storage of the value, even if it is immutable".
  - `LookupGeneratedValue: ExecutionContext * Val -> (objnull * Type) option` — "invert the compilation of the given value and return its current dynamic value and its compiled System.Type".

**Top-level API declared**:
- `val ReportStatistics: TextWriter -> unit` — dump counters (closure count, method-def count, etc.) to a `TextWriter`.
- `val IsFSharpValCompiledAsMethod: TcGlobals -> Val -> bool` — "determine if an F#-declared value, method or function is compiled as a method" (as opposed to a static field).

**Dependencies opened**: `System`, `System.IO`, `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.TypedTree`, `FSharp.Compiler.TcGlobals`.

**Cross-references**:
- `IlxGen.fs` — the ~13,300-line implementation (including the ~9,800-line `GenExpr` expression compiler, `CodeGenBuffer`, `AssemblyBuilder`, `TypeDefsBuilder`, `IlxGenIntraAssemblyInfo`, the `cenv` context, storage-decision functions, and the FSI compile-inversion internals).
- Driven by the F# compiler driver (`fsc`) and by `FSharp.Compiler.FSharpFactory`/FSI; consumes output of `Optimizer.fs` (`CheckedAssemblyAfterOptimization`); uses `EraseClosures.fs`, `EraseUnions.{fs,Emit.fs,Types.fs}`, and `IlxGenSupport.fs` during the `ConvTypeDef` pass.
- Produces `ILTypeDef` lists that the IL writer (in `vsintegration/` and related tooling) serializes to a PE, and that `HotReloadBaseline.fs` snapshots for hot-reload diffs.
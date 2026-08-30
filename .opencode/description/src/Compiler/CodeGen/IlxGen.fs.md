# IlxGen.fs

**Purpose**: The F# compiler's final code generation engine. It takes type-checked and optimized F# implementation files (`CheckedImplFile`), computes the .NET representation of every F# value (method, static field, or closure), and generates the *AbstractIL* (`ILTypeDef`/`ILMethodBody`) representation of the whole assembly — types, methods, fields, attributes, debug info, and initialization code — which is then written to a PE image by the IL writer backends. This is one of the largest files in the compiler (~13,300 lines).

**Namespace / module declared**: `FSharp.Compiler.IlxGen` (internal module; contract in `IlxGen.fsi`)

**TypeDefs / Records / Classes declared** (notable):
- `IlxGenBackend` — `IlWriteBackend` (file-based IL) | `IlReflectBackend` (reflection-emit).
- `IlxGenOptions` — the codegen tuning record: `fragName`, `generateFilterBlocks`, `workAroundReflectionEmitBugs`, `emitConstantArraysUsingStaticDataBlobs`, `mainMethodInfo` (entry point), `localOptimizationsEnabled`, `generateDebugSymbols`, `testFlagEmitFeeFeeAs100001`, `ilxBackend`, `fsiMultiAssemblyEmit`, `isInteractive`, `isInteractiveItExpr`, `useReflectionFreeCodeGen` (suppress `ToString`), `alwaysCallVirt`, `parallelIlxGenEnabled`, `alwaysInline`.
- `IlxGenResults` (public) — the results of compiling one assembly fragment: `ilTypeDefs`, `ilAssemAttrs`, `ilNetModuleAttrs`, `topAssemblyAttrs`, `permissionSets`, `quotationResourceInfo`.
- `ExecutionContext` — `{ LookupTypeRef; LookupType }` for compile-inversion (FSI `#get`/`#clear` support).
- `cenv` — the codegen context: options, `TcGlobals`, `ImportMap`, `TcValF`, `signatureHidingInfo`, `stackGuard`, and attribute callbacks.
- `CompileLocation` — the IL "location" a thing compiles to (namespace / module / type nesting path) plus the CCU.
- `TypeReprEnv` — maps type parameters to their IL type-variable representations, with a "template replacement" feature (used when a closure's template type is specialized).
- `DuFieldCoordinates` / `UnionFieldReuseMap` / `unionFieldReuseMapping` — field-sharing optimization between discriminated-union cases.
- `SlotSig`/`SlotParam`-related types: `SlotParamFlags { IsIn; IsOut }`, `ArityInfo`.
- `IlxClosureInfo`, `ValStorage` (the per-value storage decision: static field, method, or closure) and its `CodeLabel` member.
- `CodegenFileScope` — thread-local-ish file index for parallel codegen.
- `TypeDefBuilder` / `TypeDefsBuilder` — accumulate methods/fields/properties/nested types for each `ILTypeDef`, merge duplicate properties, manage the type initializer (`.cctor`).
- `AnonTypeGenerationTable` — dedupe anonymous record ("F# record literal") types across the assembly.
- `AssemblyBuilder` (the `mgbuf` type) — the whole-assembly accumulator: type defs, assembly/module attributes, script init code, quotation resources, reflected definitions; members like `AddTypeDef`, `AddMethodDef`, `AddExplicitInitToEntryPoint`/`ToCctor`, `GenerateAnonType`/`LookupAnonType`, `GetExplicitEntryPointInfo`, `Close`.
- `CodeGenBuffer` (the `cgbuf` type) — the per-method code-generation buffer: manages the operand stack (`DoPushes`/`DoPops`/`AssertEmptyStack`), exception clause specs, locals (`AllocLocal`/`ReallocLocal`), debug points (`EmitDebugPoint`), marks and branch targets (`SetMark`, `SetMarkToHere`, `SetMarkOrEmitBranchIfNecessary`), and `Close` finalizes into an `ILCode`.
- `CG` — small module of codegen utilities.
- `IlxGenIntraAssemblyInfo` — shared static-field registry (`ILMethodRef -> ILFieldSpec`) across fragments in one assembly (concurrent dictionary).
- `IlxAssemblyGenerator` (public, `#if !FSC_EXE`) — public facade: `new(amap, g, tcVal, ccu)`, `AddExternalCcus`, `AddIncrementalLocalAssemblyFragment`, `GenerateCode`, and the compile-inversion ops `ClearGeneratedValue` / `ForceSetGeneratedValue` / `LookupGeneratedValue`.
- `AttributeDecoder` — pull named-arg values out of an `Attribs` (e.g. for `[<EntryPoint>]`-like attributes).

**Public / top-level API surface** (notable):
- `GenerateCode (cenv, anonTypeTable, eenv, CheckedAssemblyAfterOptimization implFiles, assemAttribs, moduleAttribs)` — the main entry: produce an `AssemblyBuilder` (or run it to completion) over a whole assembly.
- `CodegenAssembly cenv eenv mgbuf implFiles` — codegen across impl files into an `AssemblyBuilder`.
- `PrimeStableNamesForCodegen cenv implFiles` — stable-naming pass (deterministic names for compiler-generated types).
- `GenExpr cenv cgbuf eenv expr sequel` — the giant expression compiler (~9800 lines!): compiles one TAST expression into IL instructions, with a `sequel` describing what stack effect follows. This is where values/calls/tuples/unions/exceptions/structs are lowered to IL.
- `GetEmptyIlxGenEnv g ccu` — fresh codegen environment.
- `ComputeStorageForFSharpValue|Member|FunctionOrFSharpExtensionMember`, `ComputeStorageForValWithValReprInfo`, `ComputeStorageForNonLocalVal`, `IsFSharpValCompiledAsMethod` — decide the physical representation (static field vs. method vs. closure) of each F# value.
- `EraseClosures`/`EraseUnions` interaction: `AddBindingsForModuleOrNamespaceContents`, `AddBindingsForTycon`, `AddExternalCcusToIlxGenEnv`, `AddIncrementalLocalAssemblyFragmentToIlxGenEnv` — register all the top-level bindings/closures into the environment before codegen.
- `ComputeGenerateWitnesses` / `TryStorageForWitness` — trait witness (F# 9 "traits"/interfaces) storage.
- `LookupGeneratedValue` / `SetGeneratedValue` / `ClearGeneratedValue` — implement FSI `#get`/`#set`/`#clear` compile-inversion (uses `ExecutionContext` to reflect back to .NET types).
- `GenerateResourcesForQuotations` — emit the string resources for F# quotations.
- `ReportStatistics` / `NewCounter` (e.g. `CountClosure`, `CountMethodDef`, `CountStaticFieldDef`, `CountCallFuncInstructions`).
- `ChooseUniqueName`, `TypeNameForPrivateImplementationDetails`, `TypeNameForInitClass`, `TypeNameForImplicitMainMethod`, `TypeNameForAnonymousClosure`-style name helpers.
- `GenTyconRef`, `GenTypeArgAux` (the ~290-line type-compiler: maps F# types — tuples, byrefs, function types, unions, arrays, `exn` — to IL types).
- `GenFieldSpecForStaticField`, `GenRecdFieldRef`, `GenExnType` — field/type-spec generation.
- `AddDebugImportsToEnv` — thread open-declaration info for `#load`-style debug imports.
- `CompileLocation` helpers: `CompLocForFragment`, `CompLocForCcu`, `CompLocForFixedPath`, `CompLocForFixedModule`, `NestedTypeRefForCompLoc`, `TypeRefForCompLoc`, `mkILTyForCompLoc`.
- `Access` helpers: `ComputeMemberAccess`, `ComputeTypeAccess` (hiding info → IL access).
- `MergeOptions`, `MergePropertyPair`, `MergePropertyDefs` (dedupe properties with the same name+signature), `AddPropertyDefToHash`, `HashRangeSorted`.
- `GenDebugPointForBinding`, `BindingEmitsNoCode` (skip binding bodies that are pure), `GenerateDelayMark`, `GenString`, `GenConstArray` (with static data blobs), `GenILSourceMarker` / `GenPossibleILDebugRange` (PDB source-marker emission), `Pop`/`Push`/`Push0` helpers, `FeeFee` (FEE-FEE test hook for debug-info testing).
- `CheckCodeDoesSomething`, `IsNonErasedTypar`, `DropErasedTypars`, `DropErasedTyargs` — erased-typar cleanup.
- `IldcInt64`/`IldcDouble`/`IldcSingle`/`IldcZero` — constant-loading instruction helpers.
- `ChooseParamNames`, `ChooseFreeVarNames` — deterministic local/parameter naming.
- `IsILTypeByref`, `VoidNotOK`, `voidCheck`, `PtrsOK` — void/ptr legality checks for IL.
- `IsValRefIsDllImport`, `HasNativePtrWithTypar`, `SlotSigRequiresNativePtrRewrite` — unmanaged-pointer (nativeint) rewriting rules (the "unsafe native pointers" story: a generic over `'T` where `'T` is a native pointer type must be rewritten).
- `GetMethodSpecForMemberVal` — compute the `ILMethodSpec` for a value/member reference (the big switch over `ValUseFlag`, `memberInfo`, val-repr-info, this/self calls, super calls).
- `StorageForVal` / `StorageForValRef` / `ComputeGenerateWitnesses` — per-value storage lookup.

**Significant internal logic**:
- **Representation decisions come first**: for every value, `ComputeStorageFor*` decides whether to emit a **static field** (top-level functions/constants, module values), a **method** (members, extension members, methods with val-repr-info), or a **closure** (`IlxClosureInfo` with free variables — handled by `EraseClosures.fs` during `ConvTypeDef`).
- **Two-stage assembly build**: (1) `AddBindingsFor*` runs to register all values and type constructors into `ilxGenEnv` (including all closure defs and their free-var lists); (2) `CodegenAssembly` walks the optimized impl files and for each binding generates a type def and/or method body. `TypeDefBuilder` dedupes and merges.
- **`GenExpr`** is the workhorse: a `sequel` (what happens to the value after the expression) drives stack hygiene (e.g. whether to box a struct). It handles: values, applications (direct + closure, via `EraseClosures`' `MkCallFunc`), tuples, records, discriminated unions (via `EraseUnions.Emit`), sequences, exceptions, `try`/`finally`, `while`, `for`, `match`, `let`/bindings, lambdas (which become closures), and IL-specific ops like `AddressOf`, `CallVirtualMethod`, etc.
- **Struct "this" convention**: for structs, GenExpr tracks an "uninitialized this" state (`StartUninitializedThisOnStack` / `EndUninitializedThisOnStack`) and uses `constrained.` calls for generic methods over struct type parameters.
- **Debug info**: `GenPossibleILDebugRange` and `EmitDebugPoint` emit IL "source markers" (via the custom `FSharpDebugInfoProvider`-style `#Debug` markers) that the PDB writer later translates into sequence points; `GenILSourceMarker` is the marker itself.
- **Anonymous record types**: `AnonTypeGenerationTable` dedupes anonymous record types (record literals) so that two structurally-identical anonymous records in the same assembly share one `ILTypeDef`.
- **Deterministic names**: `PrimeStableNamesForCodegen`, `CleanUpGeneratedTypeName`, and `ChooseUniqueName` ensure that compiler-generated type/method names are stable across compilations (for cross-compilation and hot-reload).
- **FeeFee**: a test hook that emits a special "100001" debug point for testing the PDB writer's handling of unusual sequence points.
- **Parallelism**: `CodeGenFileScope.With(fileIdx, action)` runs file-scoped work with an ambient file index so that `TypeDefBuilder`/`AssemblyBuilder` can safely interleave work from multiple threads (see `parallelIlxGenEnabled`).

**Cross-references**:
- Signature: `IlxGen.fsi`.
- Heavy consumer of `EraseClosures.fs` (closure erasure), `EraseUnions.fs` + `EraseUnions.Emit.fs` + `EraseUnions.Types.fs` (union erase), `IlxGenSupport.fs` (attribute/name utilities).
- Downstream of `Optimizer.fs` (the mid-end); the `optimizeDuringCodeGen` closure returned by `Optimizer.OptimizeImplFile` is invoked here.
- Produces the `ILTypeDef` list that `HotReloadBaseline.fs` snapshots and the IL writer (in `vsintegration/` / `FSharp.Core` tooling) serializes to a PE.
- Depends on `AbstractIL.IL`, `AbstractIL.ILX.Types`, `TypedTree`, `TypedTreeOps`, `TcGlobals`, `Import`, `CompilerGlobalState`, `CompilerGeneratedNames`, `GeneratedNames`, `SyntaxTree`, and `Internal.Utilities.*`.
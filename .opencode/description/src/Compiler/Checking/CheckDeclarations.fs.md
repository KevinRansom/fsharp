# CheckDeclarations.fs

**Purpose**: The largest Checking module (~190KB); performs full type-checking of declaration-level constructs so the Checking phase can link the parsed `SyntaxTree` into a fully typed `TypedTree` (`CheckedImplFile`). Checks `open` declarations, module/namespace elements, mutually-recursive definitions (`let`/`and`/members), type definitions (records, unions, enums, exceptions, structs, generics with member constraints), signature file elements, and end-of-file checks such as the value restriction.

**Namespace(s)**: `module internal FSharp.Compiler.CheckDeclarations`

**Public API surface** (the .fsi surface, implemented here):
- `AddLocalRootModuleOrNamespace`, `CreateInitialTcEnv`, `AddCcuToTcEnv` — set up the initial `TcEnv` for a file (open declarations, assembly/ccu, auto-opens, `InternalsVisibleTo`).
- `TopAttribs` + `EmptyTopAttrs` / `CombineTopAttrs` — accumulate `mainMethodAttrs`, `netModuleAttrs`, `assemblyAttrs` from the checked file.
- `TcOpenModuleOrNamespaceDecl : TcResultsSink -> TcGlobals -> ImportMap -> range -> TcEnv -> LongIdent*range -> TcEnv * OpenDeclaration list`.
- `AddLocalSubModule` — extend the environment into a submodule.
- `CheckOneImplFile : ... ParsedImplFileInput -> FSharpDiagnosticOptions -> Cancellable<TopAttribs * CheckedImplFile * TcEnv * bool>` — top-level entry point for checking one .fs file.
- `CheckOneSigFile : ... -> Cancellable<TcEnv * ModuleOrNamespaceType * bool>` — top-level entry point for checking one .fsi file.
- Exceptions `NotUpperCaseConstructor of range`, `NotUpperCaseConstructorWithoutRQA of range` (union case naming rules).

**Major internal phases** (the file is organized in phase functions):
- `TcFieldDecl` / `TcAnonFieldDecl` / `TcNamedFieldDecl(s)` (lines ~434-508) — record/union field checking; `CheckUnionCaseName`, `TcUnionCaseDecl(s)` (~510-652) with RQA (restrictive quantifier) attribute handling; `TcEnumDecl(s)`.
- `TcAndPublishMemberSpec` / `TcTyconMemberSpecs` — member spec checking and publishing; `tcaugHasNominalInterface`.
- `TcOpenTypeDecl`, `TcOpenDecl` — `open` of types/namespaces.
- `TcTyconDefnCore_Phase1A_BuildInitialModule` (~2830) — initial construction of the Tycon; `TcMutRecDefns_Phase1` (~4305) — collect tycon/val shapes into `MutRecDefnsPhase1Data`.
- **Mutual recursion core** (see Cross-references section below).
- `TcExnDefnCore_Phase1A` / `Phase1G`, `TcExnDefn` / `TcExnSignature` (~2454-2566).
- `TcTyconDefnCore_CheckForCyclicStructsAndInheritance` (~4139), `accStructField`/`accInAbbrevType` — cyclic struct detection; field comparison/equality support checks `checkIfFieldTypeSupportsComparison/Equality`.
- `TcMutRecSignatureDecls` (~5189), `TcSignatureElementNonMutRec`, `CheckModuleSignature` (~6084), `CheckForDuplicateConcreteType/Module`, `CheckLetOrDoInNamespace`, `TcMutRecDefsFinish`, `TcMutRecDefnsEscapeCheck` (~5498).
- `CheckValueRestriction` (~6057) — value restriction over `ModuleOrNamespaceType` using `UngeneralizableItem`s; `IterTyconsOfModuleOrNamespaceType`.
- `CheckDuplicates` (~398), `CheckNamespaceModuleOrTypeName`, `TcMutRecDefns_UpdateNSContents/UpdateModuleContents/ComputeEnvs`.
- Entry: `CheckOneImplFile` (6132, includes `LightweightTcValForUsingInBuildMethodCall` for method-call building), `CheckOneSigFile` (6293+).

**Check helpers / patterns**:
- Active pattern `(|UndefinedNameError|_|)` on exceptions (~line 53) for recovery from name-resolution errors.
- `collectTycons`, `mapFoldWithEnv`, `iterWithEnv` etc. — generic fold helpers over `MutRecDefns` shapes.
- `SplitTyconDefn` / `SplitTyconSignature` — split a `SynTypeDefn` into its typeInfo/repr/members parts (private rec).

**Significant internal logic**:
- Mutual recursion in two phases: Phase1 builds `MutRecDefnsInitialData`; Phase2 in sub-phases **2A** (create recursive values + check argument patterns, line 1055), **2B** (type-check bindings + incremental generalization, 1302), **2C** (fix up recursive references using accumulated `recUses` from `TcFileState`, 1545), **2D** (extract implicit field/method bindings, 1611) — coordinated through `MutRecDefnsPhase2Info/AData/BData/CData`.
- Generalization: generalizable vs. ungeneralizable (value-restricted) type parameters are decided per block; `generalizedTyparsForRecursiveBlock` flows through the phases.
- The `cenv` alias in this file is the typechecking state (alias of `TcEnv`-related type); member-checking uses `IncrClassReprInfo` from `CheckIncrementalClasses` and constraint solving via `ConstraintSolver`.

**Cross-references**: `CheckBasics.fs/.fsi` (env + file state), `CheckPatterns.fs` (argument patterns), `ConstraintSolver.fs` (constraint solving, `CheckDeclaredTypars`), `InfoReader.fs`, `NameResolution.fs`, `CheckIncrementalClasses.fs` (implicit class construction), `MethodOverrides.fs` (member publishing), `SignatureConformance.fs` (sig conformance after checking).

# CheckDeclarations.fsi

**Purpose**: Public contract for the declaration-checking half of the F# type-checker: environment setup for an implementation or signature file, `open`-declaration checking, submodule extension, and the two top-level entry points `CheckOneImplFile` / `CheckOneSigFile` that turn a `ParsedImplFileInput` / `ParsedSigFileInput` into a `CheckedImplFile` / checked signature type.

**Namespace(s)**: `module internal FSharp.Compiler.CheckDeclarations`

**Types declared**:
- `TopAttribs` — `{ mainMethodAttrs: Attribs; netModuleAttrs: Attribs; assemblyAttrs: Attribs }`: the assembly-level, net-module, and entry-point attributes accumulated while checking an implementation file.
- `ConditionalDefines = string list` — active conditional-compilation defines.
- Exceptions `NotUpperCaseConstructor of range` and `NotUpperCaseConstructorWithoutRQA of range` — raised when a union/exception case name violates (or can repair) F# casing rules.

**Public API surface** (val contracts):
- `AddLocalRootModuleOrNamespace : TcGlobals -> ImportMap -> range -> TcEnv -> ModuleOrNamespaceType -> TcEnv`
- `CreateInitialTcEnv : TcGlobals * ImportMap * range * assemblyName * open-decl list -> OpenDeclaration list * TcEnv`
- `AddCcuToTcEnv : ... ccu * autoOpens * internalsVisibleToAttributes -> OpenDeclaration list * TcEnv`
- `EmptyTopAttrs : TopAttribs`; `CombineTopAttrs : TopAttribs -> TopAttribs -> TopAttribs`
- `TcOpenModuleOrNamespaceDecl : TcResultsSink -> TcGlobals -> ImportMap -> range -> TcEnv -> LongIdent * range -> TcEnv * OpenDeclaration list`
- `AddLocalSubModule : TcGlobals -> ImportMap -> range -> TcEnv -> ModuleOrNamespace -> TcEnv`
- `CheckOneImplFile : TcGlobals * ImportMap * CcuThunk * OpenDeclaration list * (unit -> bool) * ConditionalDefines option * TcResultsSink * bool * TcEnv * ModuleOrNamespaceType option * ParsedImplFileInput * FSharpDiagnosticOptions -> Cancellable<TopAttribs * CheckedImplFile * TcEnv * bool>`
- `CheckOneSigFile : TcGlobals * ImportMap * CcuThunk * (unit -> bool) * ConditionalDefines option * TcResultsSink * bool * FSharpDiagnosticOptions -> TcEnv -> ParsedSigFileInput -> Cancellable<TcEnv * ModuleOrNamespaceType * bool>`

**Implementation-only details** (in the `.fs`, not the .fsi): the mutual-recursion phase pipeline (Phase1, Phase2A-D), tycon/exception/enum/field/union-case checking (e.g. `TcUnionCaseDecl`, `TcMutRecDefns_Phase*`, `CheckValueRestriction`), and the internal `cenv` aliasing — these are not part of the contract.

**Cross-references**: `CheckDeclarations.fs` (implementation), `CheckBasics.fsi` (`TcEnv`), `NameResolution.fsi`, `InfoReader.fsi`, `AccessibilityLogic.fsi`, `ConstraintSolver.fsi` (constraint resolution during member checking), `CheckPatterns.fsi` (argument-pattern checking used by Phase2A), `CheckIncrementalClasses.fsi` (implicit class construction consumed by the definition checker).

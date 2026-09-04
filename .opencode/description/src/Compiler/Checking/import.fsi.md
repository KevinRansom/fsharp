# import.fsi

**Purpose**: Public contract for importing .NET binary metadata (AbstractIL) and type-provider provided types as F# TAST objects. Declares the `AssemblyLoader`/`ImportMap` infrastructure, the type/type-ref/type-def/assembly import entry points, the nullness-attribute model, and the rescope-and-import helpers used throughout the rest of the compiler.

**Namespace(s)**: `module internal FSharp.Compiler.Import`

**Types declared**:
- `AssemblyLoader` (abstract) — interface to assembly loading:
  - `abstract FindCcuFromAssemblyRef : CompilationThreadToken * range * ILAssemblyRef -> CcuResolutionResult` — resolve an AbstractIL assembly reference to a Ccu.
  - `abstract TryFindXmlDocumentationInfo : string -> XmlDocumentationInfo option`
  - (when type providers enabled) `abstract GetProvidedAssemblyInfo : CompilationThreadToken * range * Tainted<(ProvidedAssembly | null)> -> bool * ProvidedAssemblyStaticLinkingMap option`, and `abstract RecordGeneratedTypeRoot : ProviderGeneratedType -> unit` (guides static linking & type relocation for `<[Generate]>` types).
- `ImportMap` ([<Sealed>]) — context for converting AbstractIL / provided types to F# internal structures; caches `ILTypeRef` conversions (hash-based). New: `g: TcGlobals * assemblyLoader: AssemblyLoader -> ImportMap`; members `assemblyLoader`, `g`. Doc notes there is normally one per assembly compilation, additional instances obtainable via `tcImports.GetImportMap()`, and it fronts the tables in the primary `TcImports` structures in CompileOps.fs.
- `module Nullness`:
  - `AttributesFromIL of metadataIndex: int * attrs: ILAttributesStored` (struct) with `member Read : unit -> ILAttributes`.
  - `NullableContextSource` — `FromClass of AttributesFromIL` | `FromMethodAndClass of methodAttrs * classAttrs` (struct).
  - `NullableAttributesSource` — `{ DirectAttributes: AttributesFromIL; Fallback: NullableContextSource }` with `static member Empty` (struct).

**Public API surface** (val contracts, all `val internal`/`val` in this internal module):
- `ImportILTypeRef(amap, range, ILTypeRef) -> TyconRef`, `CanImportILTypeRef(...) -> bool`, active pattern `(|TryImportILTypeRef|_|) -> TyconRef voption`.
- `ImportILType : ImportMap -> range -> TType list -> ILType -> TType`; `CanImportILType : ... -> bool`.
- Provided types (`#if !NO_TYPEPROVIDERS`): `ImportProvidedType`, `ImportProvidedNamedType -> TyconRef`, `ImportProvidedTypeAsILType -> ILType`, `ImportProvidedMethodBaseAsILMethodRef -> ILMethodRef`.
- `ImportILGenericParameters : (unit -> ImportMap) -> range -> ILScopeRef -> TType list -> Nullness.NullableContextSource -> ILGenericParameterDef list -> Typar list`.
- `ImportILAssembly : (unit -> ImportMap) * range * (ILScopeRef -> ILModuleDef) * IXmlDocumentationInfoLoader option * ILScopeRef * sourceDir * fileName * ILModuleDef * IEvent<string> -> CcuThunk` — import an IL assembly as a new TAST CCU.
- `ImportILAssemblyTypeForwarders : (unit -> ImportMap) * range * ILExportedTypesAndForwarders -> CcuTypeForwarderTable`.
- `RescopeAndImportILTypeSkipNullness : ILScopeRef -> ImportMap -> range -> TType list -> ILType -> TType` — re-scope metadata to the current assembly then import; fully skips nullness metadata flags.
- `RescopeAndImportILType : ILScopeRef -> ImportMap -> range -> TType list -> Nullness.NullableAttributesSource -> ILType -> TType`.
- `CanRescopeAndImportILType : ILScopeRef -> ImportMap -> range -> ILType -> bool`.

**Implementation-only (in the .fs)**: `ImportTypeRefData`, `ImportILTypeRefUncached`, `ImportTyconRefApp`, `ImportILTypeWithNullness`, `NullableFlags`, `ImportILTypeDef`/`ImportILTypeDefs*`, `ImportILAssemblyMainTypeDefs`, `ImportILAssemblyExportedType(s)`, `ImportILAssemblyTypeDefs`, and the tree-building helpers `addToTree`/`addNested` for the forwarder table.

**Cross-references**: `import.fs` (implementation), `TcGlobals` (`improveType`), `TcImports` (CompileOps, underlying state), `infos.fs` (metadata types imported into `ILTypeInfo`/`ILMethInfo` etc.), `ConstraintSolver.fs` / `InfoReader.fs` (consumers of imported TAST).

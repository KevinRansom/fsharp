# import.fs

**Purpose**: Implements the import of .NET binary metadata (AbstractIL) — and of type-provider provided types — as F# internal compiler data structures (TAST: `TyconRef`, `TType`, `CcuThunk`, typars). It is the bridge that makes referenced assemblies visible to the type-checker: it builds a `CcuThunk` from an `ILModuleDef`, imports type definitions into a `ModuleOrNamespaceType`, imports types with an instantiation context (and nullness), and handles type forwarders and "exported types".

**Namespace(s)**: `module internal FSharp.Compiler.Import`

**Types declared**:
- `AssemblyLoader` (abstract) — interface to assembly loading used by the importer:
  - `abstract FindCcuFromAssemblyRef : CompilationThreadToken * range * ILAssemblyRef -> CcuResolutionResult`
  - `abstract TryFindXmlDocumentationInfo : string -> XmlDocumentationInfo option`
  - (#if !NO_TYPEPROVIDERS#) `abstract GetProvidedAssemblyInfo : ... -> bool * ProvidedAssemblyStaticLinkingMap option`, `abstract RecordGeneratedTypeRoot : ProviderGeneratedType -> unit` — provided-assembly remapping and `<[Generate]>` root recording for static linking/type relocation.
- `ImportMap(g: TcGlobals, assemblyLoader: AssemblyLoader)` ([<Sealed>]) — the import context; typically one per assembly compilation (see doc at import.fs:60). Exposes `assemblyLoader` and `g`. Internally, this object fronts the tables in `TcImports` (CompileOps.fs) and caches AbstractIL `ILTypeRef` → `TyconRef` conversions.
- `module Nullness` (line 189) — nullable-metadata machinery:
  - `AttributesFromIL of metadataIndex * ILAttributesStored` (struct) with `member Read()` (line 228)
  - `NullableContextSource` — `FromClass of AttributesFromIL` | `FromMethodAndClass of methodAttrs * classAttrs` (line 240)
  - `NullableAttributesSource` — `{ DirectAttributes: AttributesFromIL; Fallback: NullableContextSource }` with `static member Empty` (line 245)
  - `NullableFlags = { Data : byte[]; Idx : int }` (line 270) — bit-walk cursor over a nullable-metadata blob.

**Public API surface** (major functions):
- `ImportTypeRefData (env, m, (scoref, path, typeName))` (line 98) — resolve a (scope, path, name) to a `TyconRef`, with "not found in assembly" diagnostics and dereferencing of fake tcrefs.
- `ImportILTypeRefUncached` (147), `ImportILTypeRef (env, m, tref) -> TyconRef` (161, cached).
- Active pattern `(|TryImportILTypeRef|_|)` (173) — returns `TyconRef voption`.
- `CanImportILTypeRef` — pre-check importability.
- `ImportTyconRefApp (env, tcref, tyargs, nullness)` (185) — via `env.g.improveType`.
- `ImportILType (env, m, tinst, ty) -> TType` (311, rec) — full IL type → F# type conversion (handles array, generic instantiation `ILType.GenAbbr`, byref, ptr, function-pointer, modified types, `box`/`constrainedvar`).
- `ImportILTypeWithNullness` (345, rec) — same but threaded with `Nullness.NullableFlags`, returning `struct(TType * NullableFlags)`.
- `CanImportILType (env, m, ty) : bool` (390, rec).
- Provided types (#if !NO_TYPEPROVIDERS#):
  - `ImportProvidedNamedType (env, m, st) -> TyconRef` (408)
  - `ImportProvidedTypeAsILType (env, m, st) -> ILType` (417, rec) — via `PApply` calls to the Tainted provided type (a major source of type-provider activation, per comment at line 456-460)
  - `ImportProvidedType (env, m, st) -> TType` (453, rec)
  - `ImportProvidedMethodBaseAsILMethodRef (env, m, mbase) -> ILMethodRef` (550) — resolves generic args on the declaring type (lines 559-630).
- `ImportILGenericParameters amap m scoref tinst nullableFallback gps : ILGenericParameterDef list -> Typar list` (645) — imports generic parameters including `CoercesTo` constraints built from rescope-imported constraint types (line 681).
- `ImportILTypeDef amap m scoref cpath enc nm tdef : ILTypeDef -> Entity` (690, rec) and companions `ImportILTypeDefsOfLevel` (725), `ImportILTypeDefs` (743) — build F# `Entity`/`ModuleOrNamespaceType` from IL type defs; comments stress lazy loading (don't force reads of type defs or child namespaces, lines 744-747).
- `ImportILAssemblyMainTypeDefs` (752), `ImportILAssemblyExportedType` (756) / `ExportedTypes` (780), `ImportILAssemblyTypeDefs` (786), `ImportILAssemblyTypeForwarders (amap, m, exportedTypes) -> CcuTypeForwarderTable` (793, via `addToTree`/`addNested` tree builders at 794/823).
- `ImportILAssembly (amap, m, auxModuleLoader, xmlDocInfoLoader, ilScopeRef, sourceDir, fileName, ilModule, invalidateCcu) -> CcuThunk` (848) — the top-level IL-assembly import.
- `RescopeAndImportILTypeSkipNullness (scoref, amap, m, importInst, ilTy) -> TType` (892) — rescope to the current assembly then import, skipping nullable metadata.
- `RescopeAndImportILType (scoref, amap, m, importInst, nullnessSource, ilTy) -> TType` (895) — full version with nullness; uses `rescopeILType` + `ImportILTypeWithNullness`.
- `CanRescopeAndImportILType (scoref, amap, m, ilTy) : bool` (907).

**Notable internal details**:
- Caching: `ImportILTypeRef` uses the ImportMap's `ILTypeRef → TyconRef` cache; `ImportILTypeDef` and friends rely on the TAST entity cache in `TcImports` (CompileOps).
- Comments flag a design constraint: the type name classification of an import is only known once the type is dereferenced (lines 87-88).
- `FunctionPointer` imports degrade to `nativeint` (lines 326-332) — a deliberate loss.
- `ImportProvidedType` is a major type-provider activation point (comment, line 456); `PApply` is the standard tainted-call wrapper.
- The shared `importInst` optimization: "Most IL types have no type parameters, so they share this instead of each allocating a lazy and closure" (line 686).

**Cross-references**: `import.fsi` (contract), `TcGlobals` (`improveType`, built-ins), `TcImports` in CompileOps (underlying cache tables), `AccessibilityLogic.fs` (accessor-level on imported items), `InfoReader.fs` (imported member sets), `infos.fs` (`MethInfo`/`PropInfo` built over `ILMethInfo` etc.), `AbstractIL` (the metadata model).

# TypeHierarchy.fsi

**Purpose**
Public contract for type-hierarchy queries used by the type checker: walking a type's base type and
interface hierarchies, collecting super types/interfaces, head-type comparisons, importing Abstract IL
types from metadata into F# types (with nullness handling), and copying/fixing up typar constraints when
instantiating generic methods and types.

**Namespace(s)**
`module internal FSharp.Compiler.TypeHierarchy`

**Types declared**
- `SkipUnrefInterfaces` (`[RequireQualifiedAccess]`) — `Yes | No`; whether we can skip interface types that lie outside the reference set.
- `AllowMultiIntfInstantiations` (`[RequireQualifiedAccess]`) — `Yes | No`; whether to visit multiple instantiations of the same generic interface.

**Public API surface** (signatures as declared)
- `GetSuperTypeOfType: g: TcGlobals -> amap: ImportMap -> m: range -> ty: TType -> TType option` — base type of a type (accounting for instantiations); `None` if no base type.
- `GetImmediateInterfacesOfType: skipUnref -> g -> amap -> m -> ty -> TType list` — immediate declared interface types of an F# type, without further traversal.
- `FoldPrimaryHierarchyOfType: f: (TType -> 'a -> 'a) -> g -> amap -> m -> allowMultiIntfInst -> ty -> acc -> 'a` — fold over the type hierarchy without following interfaces (unless the type itself is one).
- `FoldEntireHierarchyOfType: (same shape)` — fold following interfaces; skipping unrefd interfaces allowed.
- `IterateEntireHierarchyOfType: f: (TType -> unit) -> ... -> unit`.
- `ExistsInEntireHierarchyOfType: f: (TType -> bool) -> ... -> bool`.
- `SearchEntireHierarchyOfType: f: (TType -> bool) -> g -> amap -> m -> ty -> TType option` — find the first matching super-type/interface.
- `AllSuperTypesOfType: g -> amap -> m -> allowMultiIntfInst -> ty -> TType list` — all super types including `ty` itself.
- `AllInterfacesOfType: g -> amap -> m -> allowMultiIntfInst -> ty -> TType list` — all interfaces including `ty` itself if it is one.
- `HaveSameHeadType: g -> ty1 -> ty2 -> bool`, `HasHeadType: g -> tcref -> ty2 -> bool`.
- `ExistsSameHeadTypeInHierarchy: g -> amap -> m -> typeToSearchFrom -> typeToLookFor -> bool` (the looked-for type need not have a head at all).
- `ExistsHeadTypeInEntireHierarchy: g -> amap -> m -> typeToSearchFrom -> tcrefToLookFor -> bool`.
- `ImportILTypeFromMetadata: amap -> m -> scoref: ILScopeRef -> tinst -> minst -> nullnessSource: Nullness.NullableAttributesSource -> ilTy: ILType -> TType`.
- `ImportILTypeFromMetadataSkipNullness: ... -> TType` — same, ignoring nullness checking.
- `ImportILTypeFromMetadataWithAttributes: ... -> TType` — also reads attributes that may affect the type itself.
- `ImportParameterTypeFromMetadata: amap -> m -> nullnessSource -> ilTy -> scoref -> tinst -> mist -> TType`.
- `ImportReturnTypeFromMetadata: ... -> TType option` — return type, translating `void` to `None`.
- `CopyTyparConstraints: m -> tprefInst: TyparInstantiation -> tporig: Typar -> TyparConstraint list`.
- `FixupNewTypars: m -> formalEnclosingTypars: Typars -> tinst -> tpsorig -> tps -> TyparInstantiation * TTypes`.

**Significant notes**
- `CopyTyparConstraints` doc comment: for a typar tied to a type constructor this is just a rename; for a
  typar on a generic method inside a generic class (e.g. `ty.M<_>`) it involves both substituting the
  instantiation associated with `ty` and copying/instantiating the method's own typar constraints. The
  comment notes this "now looks identical to constraint instantiation."
- `FixupNewTypars` doc comment: copied constraints may refer to each other (e.g.
  `f<'a :> list<'b>, 'b :> list<'a>>`), so the fixup can only run after all new constraints are generated.
- The `nullnessSource` (`Nullness.NullableAttributesSource`) parameter threads the source of nullness
  attributes so imported types carry the correct `[<Nullability>]` information; the `SkipNullness`
  overload is used where nullness is not yet meaningful.

**Cross-references**
- `TypeHierarchy.fs` — implementation (fold engine `FoldHierarchyOfTypeAux`, `System.Numerics`/`IList`
  special-cases, `mkSystemCollectionsGenericIListTy`).
- `TypeRelations.fsi` — the subsumption/feasibility relations are built on these hierarchy walks.
- `MethodCalls.fsi` / `MethodOverrides.fsi` — hierarchy queries when matching methods and overrides.
- `NameResolution.fsi` — extension-member and interface-based lookup paths use these queries.
- `AbstractIL/IL` (`ILType`, `ILScopeRef`) — metadata types imported by the `Import*FromMetadata` family.

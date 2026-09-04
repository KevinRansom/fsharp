# TypeHierarchy.fs

**Purpose**
Implements type-hierarchy queries in the Checking phase: walking a type's supertype and interface
hierarchies (primary vs. entire, with/without following interfaces), collecting super types and interfaces,
head-type comparisons, importing Abstract IL types from metadata into F# types (with nullness handling),
and typar-constraint copying (used when instantiating generic methods/types). The module also special-cases
the `System.Collections.Generic.IList` and `System.Numerics` interface hierarchies for F#-specific rules.

**Namespace(s)**
`module internal FSharp.Compiler.TypeHierarchy`

**Public API surface** (see `.fsi` for signatures)
- `GetSuperTypeOfType: TcGlobals -> ImportMap -> range -> TType -> TType option` — base type (taking instantiations into account).
- `GetImmediateInterfacesOfType: SkipUnrefInterfaces -> TcGlobals -> ImportMap -> range -> TType -> TType list` — immediate declared interfaces (no hierarchy traversal).
- `FoldPrimaryHierarchyOfType` / `FoldEntireHierarchyOfType` / `IterateEntireHierarchyOfType` / `ExistsInEntireHierarchyOfType` / `SearchEntireHierarchyOfType` — fold/iterate/search over the hierarchy, with `AllowMultiIntfInstantiations` controlling whether multiple instantiations of the same generic interface are visited.
- `AllSuperTypesOfType: ... -> TType list`, `AllInterfacesOfType: ... -> TType list` — all super types / interfaces (including the type itself when appropriate).
- `HaveSameHeadType: TcGlobals -> TType -> TType -> bool`, `HasHeadType: TcGlobals -> TyconRef -> TType -> bool`.
- `ExistsSameHeadTypeInHierarchy`, `ExistsHeadTypeInEntireHierarchy` — head-type searches up the hierarchy.
- `ImportILTypeFromMetadata` / `ImportILTypeFromMetadataSkipNullness` / `ImportILTypeFromMetadataWithAttributes` — read an Abstract IL type from metadata and convert to an F# type.
- `ImportParameterTypeFromMetadata`, `ImportReturnTypeFromMetadata` — get the parameter / return type of an IL method (return converts `void` to `None`).
- `CopyTyparConstraints: range -> TyparInstantiation -> Typar -> TyparConstraint list` — copy constraints when a typar is instantiated.
- `FixupNewTypars: range -> Typars -> TType list -> Typars -> Typars -> TyparInstantiation * TTypes` — fix up copied constraints once all new constraints have been generated.

**Internal helpers**
- `GetImmediateInterfacesOfMetadataType` / `GetImmediateInterfacesOfMeasureAnnotatedType` — interface extraction for metadata- and measure-annotated types.
- `ExistsSystemNumericsTypeInInterfaceHierarchy`, `ExistsHeadTypeInInterfaceHierarchy`, `ExistsInInterfaceHierarchy` — specialized hierarchy predicates for the `System.Numerics` and named-head cases.
- `FoldHierarchyOfTypeAux` — the shared fold engine (parameterized by `followInterfaces`, `allowMultiIntfInst`, `skipUnref`).
- `mkSystemCollectionsGenericIListTy` — constructs the `IList<T>` type for F#-specific IList handling.
- `SkipUnrefInterfaces` (`Yes | No`) — whether to skip interfaces outside the reference set.
- `AllowMultiIntfInstantiations` (`Yes | No`) — whether multiple instantiations of a generic interface are visited.

**Significant internal logic**
- `FoldHierarchyOfTypeAux` is the workhorse: it walks the primary (class) hierarchy and, when
  `followInterfaces` is set, also traverses the interface closure. `skipUnref` lets callers skip interfaces
  that aren't in the referenced-assembly set (a performance optimization when the whole closure isn't needed).
- `AllowMultiIntfInstantiations.No` (the default in most paths) deduplicates instantiations of the same
  generic interface, which is the F# language rule that repeated `IFoo<T>` for the same `T` is a single
  interface.
- `ImportILTypeFromMetadata*` build F# `TType`s from `ILType`s, applying the `tinst`/`minst` instantiations
  and (in the non-skip variants) attaching nullness attributes from `Nullness.NullableAttributesSource`;
  `ImportReturnTypeFromMetadata` maps IL `void` to `None`.
- `CopyTyparConstraints` handles the case where copying a typar from a generic method of a generic class
  requires both substituting the class instantiation *and* copying the method's own typar constraints; the
  source comment notes this "now looks identical to constraint instantiation."
- `FixupNewTypars` resolves mutual references among freshly-copied constraints (e.g. `'a :> list<'b>, 'b :>
  list<'a>`) only after all the new constraints are in place.

**Cross-references**
- `TypeHierarchy.fsi` — public contract.
- `TypeRelations.fsi` — subsumption/feasibility relations built on top of these hierarchy queries
  (`TypeFeasiblySubsumesType` calls `GetImmediateInterfacesOfType`, `GetSuperTypeOfType`).
- `MethodCalls.fs` / `MethodOverrides.fs` — hierarchy queries used when matching calls and overrides.
- `InfoReader.fs` (`AbstractIL` / `Import`) — `ILType`/`ILScopeRef`/`ILTypeRef` metadata sources for the
  `Import*FromMetadata` functions.
- `AbstractIL/IL` — `ILType`, `ILFieldInit` types imported by the conversion functions.

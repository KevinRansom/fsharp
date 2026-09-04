# InfoReader.fs

**Purpose**: Implementation of `InfoReader`, the per-file object that reads and caches the metadata "infos" of F# and imported .NET types: entire type hierarchies, inherent/overridden methods, properties, events, record/class fields, IL fields, and constructor sets. It is how the Checking phase (type-checker, name resolution, overload resolution) gets a type's members with access-level filtering (`AccessorDomain`) and hide/override rules applied, caching results for monomorphic types.

**Namespace(s)**: `module internal FSharp.Compiler.InfoReader`

**Main types**:
- `InfoReader` (line 355, class) — main entry point; members include:
  - `GetEntireTypeHierarchy : AllowMultiIntfInstantiations * range * TType -> TType list` (includes interface types)
  - `GetPrimaryTypeHierarchy : ... -> TType list` (excludes interfaces)
  - `GetRawIntrinsicMethodSetsOfType : optFilter * AccessorDomain * AllowMultiIntfInstantiations * range * TType -> MethInfo list list` (raw sets per hierarchy level)
  - `GetIntrinsicMethInfoSetsOfType` / `GetIntrinsicPropInfoSetsOfType` (line 980/985) — per-level sets with `FindMemberFlag` override preference
  - `GetIntrinsicMethInfosOfType` / `GetIntrinsicPropInfosOfType` (line 990/994) — flattened sets
  - `GetEventInfosOfType` / `GetImmediateIntrinsicEventsOfType` / `GetILFieldInfosOfType` / `GetRecordOrClassFieldsOfType` — events and fields
  - `GetTraitInfosInType : string option -> TType -> TraitConstraintInfo list` (for type variables)
  - `TryFindIntrinsicNamedItemOfType : (string, AccessorDomain, includeConstraints) -> FindMemberFlag -> range -> TType -> HierarchyItem option` (line 1006)
  - `TryFindIntrinsicMethInfo` / `TryFindIntrinsicPropInfo` (line 1016/1021) — by name
  - `FindImplicitConversions : range -> AccessorDomain -> TType -> MethInfo list` — finds `op_Implicit`
  - `IsInterfaceTypeWithMatchingStaticAbstractMember` (line 1027) / `TryFindUnimplementedStaticAbstractMemberOfType` (per .fsi)
  - `static member ExcludeHiddenOfMethInfos/PropInfos` (line 973/976) — remove super-type members with matching signature/name
  - `IsLanguageFeatureRuntimeSupported : LanguageFeature -> bool`
- `HierarchyItem` (line 304) — the discriminated result of a named-item lookup: `TraitItem of TraitConstraintInfo list` | `MethodItem of MethInfo list list` | `PropertyItem of PropInfo list list` | `RecdFieldItem of RecdFieldInfo` | `EventItem of EventInfo list` | `ILFieldItem of ILFieldInfo list`.
- `FindMemberFlag` (line 317) — `IgnoreOverrides` | `PreferOverrides` | `DiscardOnFirstNonOverride` (documented in .fsi).
- `PropertyCollector` (line 153) — internal helper that walks the hierarchy collecting property info (including overridden getter/setter pairs); used by `GetImmediateIntrinsicPropInfosOfTypeAux`.
- `IndexedList<'T>(itemLists, itemsByName)` (line 331, private) — an efficient indexed structure for per-level member sets (`itemLists` + `NameMultiMap`), with `static member Empty` and `FilterNewItems` (line 347).

**Module-level functions**:
- `TrySelectMemberVal` (.fsi line 18) — use the given function to select some of the member values.
- `GetImmediateIntrinsicMethInfosOfTypeAux` (line 57, rec) / `GetImmediateIntrinsicPropInfosOfTypeAux` (line 193, rec) — the "immediate" (no inheritance) member-set computations, with `withExplicitImpl` support; entry points for `GetImmediateIntrinsicMethInfos*` / `GetImmediateIntrinsicPropInfos*` public functions in the .fsi.
- `IsIndexerType` (.fsi line 79) — check if a type is a .NET indexer (a property named `Item`).
- `GetMostSpecificItemsByType` / `FilterMostSpecificMethInfoSets` (.fsi lines 82/86) — pick the most-specific items from a hierarchy-walk.
- `GetIntrinsicConstructorInfosOfType` (.fsi line 237) — declared constructors of any F# type (via `GetIntrinsicConstructorInfosOfTypeAux` at fs line 930); includes the "for each F#-declared override, get rid of any equivalent abstract member in the same type" de-dup logic (fs line 588).
- Delegate support: `SigOfFunctionForDelegate` type (line 1087), `GetSigOfFunctionForDelegate` (.fsi line 330), `TryDestStandardDelegateType` — decompose .NET delegate types to their `Invoke` signature; the comment at fs line 680-683 covers the "val A = 0 with get, set" scenario for property getters/setters.
- Events: `IsStandardEventInfo`, `ArgsTypeOfEventInfo`, `PropTypeOfEventInfo` (.fsi lines 339-343) — recognize `System.EventHandler`-style events.
- XML docs: `TryFindMetadataInfoOfExternalEntityRef`, `TryFindXmlDocByAssemblyNameAndSig`, `GetXmlDocSigOfEntityRef/ScopedValRef/RecdFieldRef/UnionCaseRef/MethInfo/ValRef/Prop/Event/ILFieldInfo` — a large family of per-symbol XML-signature lookups (fs line 1240 shows `GetXmlDocSigOfMethInfo`; the others follow similar shape and are enumerated in the .fsi at lines 346-369).
- `checkLanguageFeatureRuntimeAndRecover` (.fsi line 233) — check a language-feature runtime gate and report a friendly error if unsupported.

**Significant internal logic**:
- Caching: `InfoReader` caches for *monomorphic* type results (see member docstrings in the .fsi); generic instantiations typically go uncached or cached at a different level.
- Hide/override rules: `FindMemberFlag.IgnoreOverrides` (prefer top-of-hierarchy, virtual), `PreferOverrides`, and `DiscardOnFirstNonOverride` (discards all lower items once it finds a non-virtual that hides one higher) — see the .fsi doc comments at lines 105-115.
- Most-specific filtering: `IndexedList.FilterNewItems` (line 347) is called for each hierarchy level so that lower (more-derived) items hide same-name/signature ones above when `findFlag` demands it.
- The `optFilter` argument to nearly every `Get*` function enables name filtering ("only get me these methods").

**Cross-references**: `InfoReader.fsi` (contract), `ConstraintSolver.fs` (uses `InfoReader` for member constraint solving, witness codegen), `NameResolution.fs` (uses `TryFindIntrinsicNamedItemOfType`), `MethodCalls.fs` (uses meth sets), `MethodOverrides.fs` (uses hierarchy info), `AttributeChecking.fs` (uses `MethInfo` etc.), `import.fs` (underlying imported TAST), `AccessibilityLogic.fs` (accessor domains).

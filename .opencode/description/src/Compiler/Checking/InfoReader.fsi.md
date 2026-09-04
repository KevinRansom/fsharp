# InfoReader.fsi

**Purpose**: Public contract of the compiler's type-info reader and cache (`InfoReader`) plus the module-level helpers for accessing a type's methods, properties, events, fields, constructors, delegates, and XML documentation signatures. This is the surface used by name resolution, method calls, overload resolution, and method-override checking.

**Namespace(s)**: `module internal FSharp.Compiler.InfoReader`

**Types declared**:
- `PropertyCollector` (line ~50) — collector object used to walk a hierarchy and gather property infos.
- `HierarchyItem` (line ~96) — `TraitItem of TraitConstraintInfo list` | `MethodItem of MethInfo list list` | `PropertyItem of PropInfo list list` | `RecdFieldItem of RecdFieldInfo` | `EventItem of EventInfo list` | `ILFieldItem of ILFieldInfo list`: the result of type-directed name resolution of a named member.
- `FindMemberFlag` (line ~105) — `IgnoreOverrides` (prefer items toward the top of the hierarchy, used for virtual but not for resolving base calls) | `PreferOverrides` (get overrides instead of abstract slots) | `DiscardOnFirstNonOverride` (discard all when finding the first non-virtual member which hides one above).
- `InfoReader` (line ~119) — the per-file caching reader (doc: "one of these for each file we typecheck"):
  - `new : g: TcGlobals * amap: ImportMap -> InfoReader`
  - Hierarchy: `GetEntireTypeHierarchy : allowMultiIntfInst * range * TType -> TType list` (incl. interfaces); `GetPrimaryTypeHierarchy` (excl. interfaces).
  - Members (all take `optFilter: string option * ad: AccessorDomain * m: range * ty: TType`, mostly with caching for monomorphic types): `GetEventInfosOfType`, `GetILFieldInfosOfType`, `GetImmediateIntrinsicEventsOfType`, `GetRawIntrinsicMethodSetsOfType` (adds `AllowMultiIntfInstantiations`), `GetRecordOrClassFieldsOfType`, `TryFindRecdOrClassFieldInfoOfType`, plus `GetIntrinsicMethInfoSetsOfType` / `GetIntrinsicPropInfoSetsOfType` / `GetIntrinsicMethInfosOfType` / `GetIntrinsicPropInfosOfType` (add `findFlag: FindMemberFlag`).
  - `GetTraitInfosInType : string option -> TType -> TraitConstraintInfo list`.
  - `TryFindIntrinsicNamedItemOfType : nm * ad * includeConstraints -> findFlag -> m -> ty -> HierarchyItem option` — type-directed name resolution.
  - `FindImplicitConversions : m -> ad -> ty -> MethInfo list` — find `op_Implicit`.
  - `IsInterfaceTypeWithMatchingStaticAbstractMember : m -> nm -> ad -> ty -> bool`; `TryFindUnimplementedStaticAbstractMemberOfType : m -> interfaceTy -> string option` (cached per interface tycon).
  - `IsLanguageFeatureRuntimeSupported : Features.LanguageFeature -> bool`.
  - Static: `ExcludeHiddenOfMethInfos : g * amap * m * MethInfo list list -> MethInfo list`, `ExcludeHiddenOfPropInfos : ... -> PropInfo list` — remove super-type items shadowed by a more specific one (signature for methods, name for properties).
  - Accessors: `amap`, `g`.
- `SigOfFunctionForDelegate` (line ~325) — `{ delInvokeMeth: MethInfo; delArgTys: TType list; delRetTy: TType; delFuncTy: TType }`.

**Module-level val surface**:
- `TrySelectMemberVal` (line 18) — use a function to select some of the member values from the members of an F# type.
- `GetImmediateIntrinsicMethInfosOfType` / `GetImmediateIntrinsicMethInfosWithExplicitImplOfType` (lines 29/39) and `GetImmediateIntrinsicPropInfosOfType` / `...WithExplicitImplOfType` (lines 60/70) — "immediate" (non-inherited) intrinsic members.
- `IsIndexerType : g -> amap -> ty -> bool` (line 79); `GetMostSpecificItemsByType` (82); `FilterMostSpecificMethInfoSets` (86 — filter to the most specific sets).
- `checkLanguageFeatureRuntimeAndRecover : InfoReader -> LanguageFeature -> m -> unit` (line 233).
- `GetIntrinsicConstructorInfosOfType : InfoReader -> m -> ty -> MethInfo list` (line 237) — declared constructors.
- Re-exports `ExcludeHiddenOfMethInfos / ExcludeHiddenOfPropInfos` as vals (lines 240/243).
- Flattened hierarchy accessors mirroring the InfoReader members: `GetIntrinsicMethInfoSetsOfType` (246), `GetIntrinsicPropInfoSetsOfType` (257), `GetIntrinsicMethInfosOfType` (268), `GetIntrinsicPropInfosOfType` (279), `GetIntrinsicPropInfoWithOverriddenPropOfType` (290 — for get-only/set-only properties, pair with the inherited setter/getter, returning `struct (PropInfo * PropInfo voption) list`).
- `TryFindIntrinsicNamedItemOfType` (301), `TryFindIntrinsicMethInfo : ... nm -> ty -> MethInfo list` (310), `TryFindIntrinsicPropInfo` (315 — adhoc check that `let` definitions and property names differ, used in tc.fs), `GetIntrinsicMostSpecificOverrideMethInfoSetsOfType : ... -> NameMultiMap<TType * MethInfo>` (319).
- `GetSigOfFunctionForDelegate` (line 330), `TryDestStandardDelegateType` (334).
- Event helpers: `IsStandardEventInfo` (339), `ArgsTypeOfEventInfo` (341), `PropTypeOfEventInfo` (343).
- XML doc signatures: `TryFindMetadataInfoOfExternalEntityRef` (346), `TryFindXmlDocByAssemblyNameAndSig` (350), and the family `GetXmlDocSigOfEntityRef` (352), `...OfScopedValRef` (354), `...OfRecdFieldRef` (356), `...OfUnionCaseRef` (358), `...OfMethInfo` (360), `...OfValRef` (362), `...OfProp` (364), `...OfEvent` (366), `...OfILFieldInfo` (368).

**Cross-references**: `InfoReader.fs` (implementation), `infos.fsi` (`MethInfo`, `PropInfo`, `EventInfo`, `ILFieldInfo`, etc.), `AccessibilityLogic.fsi` (`AccessorDomain`), `import.fsi` (`ImportMap`), `NameResolution.fs`, `MethodCalls.fs`, `MethodOverrides.fs`, `SignatureConformance.fs` (consumers).

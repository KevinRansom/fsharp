# MethodOverrides.fsi

**Purpose**
Public contract (internal module) for the F# checker's method-override machinery. Declares the data types
(`OverrideCanImplement`, `OverrideInfo`, `RequiredSlot`, `SlotImplSet`) and exceptions
(`TypeIsImplicitlyAbstract`, `OverrideDoesntOverride`) used when validating that a class or object
expression implements the dispatch slots of its required types, and exposes the `DispatchSlotChecking`
submodule's slot-computation and checking entry points plus end-of-inference-scope type-completion checks.

**Namespace(s)**
`module internal FSharp.Compiler.MethodOverrides`

**Modules / Types declared**
- `OverrideCanImplement` — union limiting which slots an override can fill (`CanImplementAnyInterfaceSlot`, `CanImplementAnyClassHierarchySlot`, `CanImplementAnySlot`, `CanImplementNoSlots`).
- `OverrideInfo` — one method implementation in a class or object expression: `canImplement`, `boundingTyconRef`, `id`, `methTypars`, `memberToParentInstantiation`, `argTypes`, `returnType`, `isFakeEventProperty`, `isCompilerGenerated`, `isInstance`; members `ArgTypes`, `BoundingTyconRef`, `CanImplement`, `IsCompilerGenerated`, `IsInstance`, `IsFakeEventProperty`, `LogicalName`, `Range`, `ReturnType`.
- `RequiredSlot` — `RequiredSlot of MethInfo * isOptional` or `DefaultInterfaceImplementationSlot of MethInfo * isOptional * possiblyNoMostSpecific`; members `HasDefaultInterfaceImplementation`, `IsOptional`, `MethodInfo`, `PossiblyNoMostSpecificImplementation`.
- `SlotImplSet` — `dispatchSlots`, `dispatchSlotsKeyed` (NameMultiMap), `availablePriorOverrides`, `requiredProperties`.
- `TypeIsImplicitlyAbstract of range` — exception.
- `OverrideDoesntOverride of DisplayEnv * OverrideInfo * MethInfo option * TcGlobals * ImportMap * range` — exception.
- `DispatchSlotChecking` (submodule) — see below.

**Public API surface**
- `DispatchSlotChecking.FormatOverride: DisplayEnv -> OverrideInfo -> RichText` — format the signature of an override for an error message.
- `DispatchSlotChecking.FormatMethInfoSig: TcGlobals -> ImportMap -> range -> DisplayEnv -> MethInfo -> RichText` — format the signature of a `MethInfo` for an error message.
- `DispatchSlotChecking.GetObjectExprOverrideInfo: TcGlobals -> ImportMap -> TType -> Ident -> SynMemberFlags -> TType -> ValReprInfo -> Attribs -> Expr -> OverrideInfo * (Val option * Val * Val list list * Attribs * Expr)` — build override info for an object expression method.
- `DispatchSlotChecking.IsExactMatch: TcGlobals -> ImportMap -> range -> MethInfo -> OverrideInfo -> bool`.
- `DispatchSlotChecking.CheckDispatchSlotsAreImplemented: DisplayEnv * InfoReader * range * NameResolutionEnv * TcResultsSink * bool (isOverallTyAbstract) * bool (isObjExpr) * bool (isExplicitInterfaceImpl) * TType * RequiredSlot list * OverrideInfo list * OverrideInfo list -> bool` — check all dispatch slots are implemented.
- `DispatchSlotChecking.CheckOverridesAreAllUsedOnce: DisplayEnv * TcGlobals * InfoReader * bool * TType * NameMultiMap<RequiredSlot> * OverrideInfo list * OverrideInfo list -> unit` — check every implementation maps to a slot.
- `DispatchSlotChecking.GetSlotImplSets: InfoReader -> DisplayEnv -> AccessorDomain -> bool (isObjExpr) -> (TType * range) list -> SlotImplSet list` — compute slot implementation sets for a list of required types.
- `FinalTypeDefinitionChecksAtEndOfInferenceScope: InfoReader * NameResolutionEnv * TcResultsSink * bool (isImplementation) * DisplayEnv * Tycon -> unit` — "Type Completion" inference and a few other checks at the end of the inference scope.
- `GetAbstractMethInfosForSynMethodDecl: ... -> MethInfo list * MethInfo list` — abstract methods relevant to a uniquely-identified-override, for pre-assigning type info (dispatch and non-dispatch).
- `GetAbstractPropInfosForSynPropertyDecl: ... -> PropInfo list` — same for properties.

**Significant notes**
- The two `RequiredSlot` variants model (a) ordinary required slots and (b) default interface implementation
  slots; the latter may be optional (inherited implementation available) and may be "possibly no most specific"
  when multiple inheritance provides competing DII candidates.
- `GetSlotImplSets` is the main entry point used by `CheckDeclarations` and the object-expression
  checker to know which slots a type must implement, given its required type list.
- The `isExplicitInterfaceImpl` flag in `CheckDispatchSlotsAreImplemented` distinguishes explicit interface
  implementation syntax `IFoo.Member = ...` from implicit overrides.

**Cross-references**
- `MethodOverrides.fs` — implementation of all of the above.
- `CheckDeclarations.fs` (sibling) — calls `FinalTypeDefinitionChecksAtEndOfInferenceScope` and `GetSlotImplSets` for type/member checking.
- `MethodCalls.fsi` — shared `MethInfo`/`TypeInst` types used in signatures.
- `NameResolution.fsi` — `NameResolutionEnv`, `TcResultsSink`, `TcResultsSinkImpl` threading.
- `TypeRelations.fsi` / `TypeHierarchy.fsi` — subsumption and interface-hierarchy relations used in slot matching.
- `Infos.fsi` — `MethInfo`, `PropInfo`, `Tycon`, `Typar`, `TyparInstantiation` types.

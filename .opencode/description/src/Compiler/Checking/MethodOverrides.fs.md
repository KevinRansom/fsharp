# MethodOverrides.fs

**Purpose**
Implements the "primary logic related to method overrides" in the Checking phase: given the set of required
types for a class or object expression, this module computes which dispatch slots (class-hierarchy,
interface, default interface implementation, property) must be implemented, matches the actual override
implementations against those slots, and reports ambiguity/missing/unused overrides. It also performs
end-of-inference-scope "type completion" checks that turn a type with unimplemented static abstract members
into an implicit abstract type.

**Namespace(s)**
`module internal FSharp.Compiler.MethodOverrides`

**Modules / Types declared** (see `MethodOverrides.fsi` for the full contract)
- `OverrideCanImplement` — which slot class an override may fill: `CanImplementAnyInterfaceSlot`, `CanImplementAnyClassHierarchySlot`, `CanImplementAnySlot`, `CanImplementNoSlots`.
- `OverrideInfo` — one method implementation in a class or object expression: bounding tycon ref, name, typars, member-to-parent instantiation, arg types, return type, flags (`isFakeEventProperty`, `isCompilerGenerated`, `isInstance`).
- `RequiredSlot` — a slot that must be implemented: `RequiredSlot of MethInfo * isOptional` or `DefaultInterfaceImplementationSlot of MethInfo * isOptional * possiblyNoMostSpecific`; members `IsOptional`, `HasDefaultInterfaceImplementation`, `PossiblyNoMostSpecificImplementation`, `HasImplicitDIMCoverage` (gated by `LanguageFeature.ImplicitDIMCoverage`), `MethodInfo`.
- `SlotImplSet` — dispatch slots (+ name-keyed map), available prior overrides, and required `PropInfo` list for one required type.
- `TypeIsImplicitlyAbstract` / `OverrideDoesntOverride` — exceptions carrying display context.
- `DispatchSlotChecking` (nested module) — the actual slot-discovery and override-checking logic.

**Public API surface** (module-level, re-declared from the .fsi)
- `FinalTypeDefinitionChecksAtEndOfInferenceScope` — "type completion" inference and a few other checks at the end of an inference scope for a `Tycon`.
- `GetAbstractMethInfosForSynMethodDecl` / `GetAbstractPropInfosForSynPropertyDecl` — look up (dispatch and non-dispatch) abstract members on required types, used to pre-assign type information when a uniquely-identified override exists.

**Internal helpers / significant logic**
Inside the `DispatchSlotChecking` module (see fsi for full signatures):
- `FormatOverride`, `FormatMethInfoSig` — rich-text rendering of override/member signatures for error messages (used by `OverrideDoesntOverride`).
- `GetObjectExprOverrideInfo` — build an `OverrideInfo` and the `(Val option * Val * Val list list * Attribs * Expr)` for one method of an object expression.
- `IsExactMatch`, `IsPartialMatch`, `IsNameMatch`, `IsImplMatch`, `IsTyparKindMatch`, `IsSigPartialMatch`, `IsSigExactMatch` — pairwise predicate chain establishing whether an `OverrideInfo` matches a `MethInfo` slot (including the typar-kind and signature comparisons).
- `ComposeTyparInsts`, `ReverseTyparRenaming` — arithmetic on `TyparInstantiation` needed to reason about inherited overrides.
- `DispatchSlotIsAlreadyImplemented`, `OverrideImplementsDispatchSlot` — used when deciding whether a slot is "already taken".
- `GetInterfaceDispatchSlots`, `GetClassDispatchSlots`, `GetDispatchSlotSet` — slot discovery per required type (interface vs. class-hierarchy).
- `GetMostSpecificOverrideInterfaceMethodSets` / `GetMostSpecificOverrideInterfaceMethodsByMethod` — resolve which interface method wins when multiple interfaces declare the same member.
- `CheckInterfaceImpls...` — not here, see `PostInferenceChecks.fs` (`CheckInterfaceImpl`s) for interface-implementation checks against the final type.
- `CheckDispatchSlotsAreImplemented` — walks required slots; produces `OverrideDoesntOverride` when a slot is left unimplemented (with `availPriorOverrides` to find a suitable fallback).
- `CheckOverridesAreAllUsedOnce` — walks overrides and pairs each to exactly one slot, reporting "override doesn't override" or ambiguity when multiple slots match equally well.
- `GetSlotImplSets` — builds a `SlotImplSet list` from `allReqdTys` (TType * range list); the primary entry point used by callers.
- `IsStaticAbstractImpl` — detect whether an override is a static-abstract implementation (member vs. static abstract).
- `CheckImplementationRelationAtEndOfInferenceScope` — the end-of-scope type-completion check; inspects the type contents and `tcaug` (tycon augment info) to find static-abstract members without implementations and either raise `TypeIsImplicitlyAbstract` or verify that the type is an interface / abstract class.

**Significant notes**
- The module distinguishes interface dispatch slots (from interfaces) from class-hierarchy slots (from a
  superclass). An override's `OverrideCanImplement` tells which set it can fill; a class-hierarchy override
  cannot fill an interface dispatch slot and vice versa.
- Default-interface-implementation (`DefaultInterfaceImplementationSlot`) support is present;
  `PossiblyNoMostSpecificImplementation` models DII ambiguity under multiple inheritance.
- `FormatMethInfoSig` and `FormatOverride` both rely on `NicePrint` (see cross-references) to render
  signatures.

**Cross-references**
- `MethodOverrides.fsi` — the public contract for this module.
- `CheckDeclarations.fs` (sibling) — calls `FinalTypeDefinitionChecksAtEndOfInferenceScope` at end of scope.
- `MethodCalls.fs`/`MethodCalls.fsi` — shared `MethInfo`-based data for signature comparison (`IsSigExactMatch`).
- `TypeRelations.fs` / `TypeHierarchy.fs` — used for subtyping and interface-hierarchy analysis.
- `ConstraintsSolver` (ConstraintSolver.fs, sibling) — `TypeEquivEnv` (`aenv`) threading for signature comparison via `CheckDispatchSlotsAreImplemented`/`CheckOverridesAreAllUsedOnce`.
- `NicePrint.fs` — signature formatting.

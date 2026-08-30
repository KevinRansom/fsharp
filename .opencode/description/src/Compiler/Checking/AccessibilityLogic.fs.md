# AccessibilityLogic.fs

**Purpose**: Implements the basic logic of `private` / `internal` / `protected` / `InternalsVisibleTo` / `public` accessibility in the F# Checking phase. Given an `AccessorDomain` ("the keys" a particular piece of code holds), it decides whether F# entities, IL types/members, val refs, union cases, record fields, properties, and events are visible, and raises "not accessible" errors via the `Check*` variants.

**Namespace(s)**: `module internal FSharp.Compiler.AccessibilityLogic`

**Types declared** (in `AccessibilityLogic.fs`):
- `AccessorDomain` — discriminated union of access contexts: `AccessibleFrom of cpaths * tyconRefOpt`, `AccessibleFromEverywhere`, `AccessibleFromSomeFSharpCode` (used when solving member trait constraints and in error-reporting failure paths), `AccessibleFromSomewhere`. Defines `static member CustomEquals` (TcGlobals-dependent) and `static member CustomGetHashCode`, used for memoization tables keyed by an accessor domain.

**Public API surface** (major functions):
- `IsAccessible : AccessorDomain -> Accessibility -> bool` — core check of an F# access level against a domain.
- `IsEntityAccessible` / `CheckTyconAccessible : ImportMap -> range -> AccessorDomain -> TyconRef -> bool` — entity (tycon) accessibility; the `Check*` variant reports diagnostics.
- `IsTyconReprAccessible` / `CheckTyconReprAccessible` — accessibility of a type definition and its representation contents.
- `IsTypeAccessible` / `IsTypeInstAccessible : TcGlobals -> ImportMap -> range -> AccessorDomain -> TType|TypeInst -> bool` — recursive over type applications and type variables.
- `IsProvidedMemberAccessible`, `ComputeILAccess`, `IsILFieldInfoAccessible`, `exprReferencesProtectedILField` (closure/lifted-helper relocation guards for protected IL fields, #19963/#5302).
- `IsILEventInfoAccessible`, `IsILPropInfoAccessible`, `GetILAccessOfILEventInfo`, `GetILAccessOfILPropInfo` — accessor-level checks for imported properties/events.
- `IsValAccessible` / `CheckValAccessible : AccessorDomain -> ValRef -> _`.
- `IsUnionCaseAccessible` / `CheckUnionCaseAccessible`, `IsRecdFieldAccessible` / `CheckRecdFieldAccessible` / `CheckRecdFieldInfoAccessible`, `CheckILFieldInfoAccessible`.
- `IsTypeAndMethInfoAccessible` / `IsMethInfoAccessible` — checks both the enclosing type and the method (accessor) access.
- `IsPropInfoAccessible`, `IsFieldInfoAccessible`.

**Internal helpers**:
- `IsILMemberAccessible` — handles Public / Family (via `ExistsHeadTypeInEntireHierarchy` from TypeHierarchy) / Assembly (InternalsVisibleTo matching on `CompilationPath`) / FamilyOrAssembly / FamilyAndAssembly member access rules.
- `IsILTypeDefAccessible` — treats nested types via their enclosing type's member access.
- `IsTyconAccessibleViaVisibleTo`, `IsILTypeInfoAccessible`, `IsILTypeAndMemberAccessible`, `IsILMethInfoAccessible`.
- `isProtectedILFieldSpec` — supports `exprReferencesProtectedILField`.

**Significant internal logic**:
- Accessibility is a two-tier problem: (1) the accessibility of the containing entity, (2) the accessor-level (IL: Public/Assembly/Family/FamilyOrAssembly/FamilyAndAssembly; F#: `Accessibility`) visibility — combined in `IsTypeAndMethInfoAccessible` and friends.
- `InternalsVisibleTo` matching is by comparison of the `CompilationPath` of the viewing code (`cpaths` in `AccessorDomain`) with that of the declared item.
- `Family`/`FamilyAndAssembly` (C# `protected`) access is granted when the viewing type's entire hierarchy contains the declaring type (`ExistsHeadTypeInEntireHierarchy`).

**Cross-references**: `InfoReader.fs` (access domains passed in), `AccessibilityLogic.fsi` (public contract), `ConstraintSolver.fs` (uses `AccessorDomain` for member constraint solving), `MethodCalls.fs` / `NameResolution.fs` (consumers), TypeHierarchy (IL hierarchy queries).

# AccessibilityLogic.fsi

**Purpose**: Public contract (`.fsi`) for the F# compiler's accessibility logic. Declares the `AccessorDomain` abstraction and the `Is*`/`Check*` accessibility predicates used by name resolution, method calls, and error reporting during the Checking phase. This is the canonical surface other Checking modules see; the `.fs` holds the implementation.

**Namespace(s)**: `module internal FSharp.Compiler.AccessibilityLogic`

**Types declared**:
- `AccessorDomain` ([<NoEquality; NoComparison>]) — the "keys" a piece of code uses to access other constructs: `AccessibleFrom of cpaths: CompilationPath list * tyconRefOpt: TyconRef option`; `AccessibleFromEverywhere` (public items only); `AccessibleFromSomeFSharpCode` (everything but .NET private/internal — used when solving member trait constraints, in error-reporting failure paths, and for ad-hoc delegate-signature lookup in service.fs); `AccessibleFromSomewhere` (everything).
  - `static member CustomEquals : TcGlobals * AccessorDomain * AccessorDomain -> bool`
  - `static member CustomGetHashCode : AccessorDomain -> int`
  - Hash/equals are needed because memoization tables are keyed by accessor domain (TcGlobals-dependent due to `TyconRef`).

**Public API surface** (val contracts):
- `IsAccessible : AccessorDomain -> Accessibility -> bool`
- `IsEntityAccessible` / `CheckTyconAccessible : ImportMap -> range -> AccessorDomain -> TyconRef -> bool`
- `IsTyconReprAccessible` / `CheckTyconReprAccessible`
- `IsTypeAccessible : TcGlobals -> ImportMap -> range -> AccessorDomain -> TType -> bool`
- `IsTypeInstAccessible : ... -> TypeInst -> bool`
- `IsProvidedMemberAccessible : ImportMap -> range -> AccessorDomain -> TType -> ILMemberAccess -> bool`
- `ComputeILAccess : bool*4 -> ILMemberAccess` — from F# visibility booleans to IL access.
- `IsILFieldInfoAccessible`, `exprReferencesProtectedILField` (expression loads/stores/address-of a protected IL field ⇒ closures/lifted helpers must not be relocated out of the declaring type, #19963/#5302), `IsILEventInfoAccessible`, `IsILPropInfoAccessible`, `GetILAccessOfILEventInfo/ILPropInfo`.
- `IsValAccessible` / `CheckValAccessible`, `CheckILFieldInfoAccessible`.
- `IsUnionCaseAccessible` / `CheckUnionCaseAccessible`, `IsRecdFieldAccessible` / `CheckRecdFieldAccessible` / `CheckRecdFieldInfoAccessible`.
- `IsTypeAndMethInfoAccessible` (checks type access `accessDomainTy` distinct from member access `ad`), `IsMethInfoAccessible`, `IsPropInfoAccessible`, `IsFieldInfoAccessible`.

**Notes**: The `.fsi` exposes both passive queries (`Is*`) and error-reporting checks (`Check*`); `CheckTyconAccessible`, `CheckUnionCaseAccessible`, `CheckRecdFieldAccessible`, `CheckValAccessible` etc. produce diagnostics. Minor helper details are implementation-only and not in the FSI.

**Cross-references**: `AccessibilityLogic.fs` (implementation), `CheckBasics.fsi` (`TcEnv.eAccessRights` is an `AccessorDomain`), `NameResolution.fsi`, `MethodCalls.fsi`, `ConstraintSolver.fsi` (all consume these predicates).

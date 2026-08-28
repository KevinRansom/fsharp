# CheckBasics.fsi

**Purpose**: Public contract for the foundational types shared across the F# Checking phase: the per-scope checking environment (`TcEnv`), the per-file state (`TcFileState`, including the constraint solver state, info reader, name resolver, and forward-call pointers), and the pattern/constructor auxiliary types used by `CheckPatterns` and `CheckDeclarations`.

**Namespace(s)**: `module internal FSharp.Compiler.CheckBasics`

**Types declared**:
- `SafeInitData` — `SafeInitField of RecdFieldRef * RecdField` | `NoSafeInitInfo`: initialization field used to check object constructors completed before field access.
- `CtorInfo` — object-constructor checking state: `ctorShapeCounter : int` (tracks the specific shape .NET requires for "new = \arg. { new C with ... }", 3/2/1/0), `safeThisValOpt : Val option` (holds 'this' for `type X() as x = ...` / `new() as x = ...` when `x` is used in inherits arguments), `safeInitInfo : SafeInitData`, `ctorIsImplicit : bool`. Static members `InitialExplicit`, `InitialImplicit`.
- `UngeneralizableItem` ([<NoEquality; NoComparison; Sealed>]) — an environment item that may restrict automatic generalization because it refers to type inference variables; constructor takes `unit -> FreeTyvars`; internal members `GetFreeTyvars`, `WillNeverHaveFreeTypars`, `CachedFreeLocalTycons`, `CachedFreeTraitSolutions`.
- `TcEnv` — the scope environment:
  - `eNameResEnv : NameResolutionEnv`, `eUngeneralizableItems`, `ePath : Ident list`, `eCompPath`, `eAccessPath : CompilationPath`,
  - `eAccessRights : AccessorDomain` (amortized, computed from other fields), `eInternalsVisibleCompPaths`,
  - `eModuleOrNamespaceTypeAccumulator : ModuleOrNamespaceType ref`, `eContextInfo : ContextInfo`, `eFamilyType : TyconRef option` (protected member access in super types),
  - `eCtorInfo : CtorInfo option`, `eCallerMemberName`, `eLambdaArgInfos : ArgReprInfo list list`, `eIsControlFlow`, `eInObjectExpr` (family access but closures cannot keep the implemented type, #5302),
  - `eCachedImplicitYieldExpressions : HashMultiMap<range, SynExpr * TType * Expr>` (avoids exponential rechecking of nested implicit-yield expressions),
  - `eUseBoundValStamps : Set<Stamp>` (suppress duplicate Dispose calls, #12300).
  - Members: `DisplayEnv`, `NameEnv`, `AccessRights`.
- `UnscopedTyparEnv of NameMap<Typar>` — type variables with implicit scope.
- `ExplicitTyparInfo` — declared typars + `infer : bool` flag for `let f<'a, ..>` style inference of additional typars.
- `ArgAndRetAttribs of Attribs list list * Attribs`.
- `CheckConstraints` — `CheckCxs` | `NoCheckCxs`: whether to check constraints when checking syntactic types.
- `PrelimValReprInfo`, `PrelimMemberInfo` — pre-completion value/member repr data.
- `PrelimVal1` — first-phase result of a simple-val-from-pattern prep; members `Type`, `Ident`.
- `TcPatPhase2Input of NameMap<Val * GeneralizedType> * bool` with `WithRightPath`; `TcPatLinearEnv` — left-to-right flow context during pattern checking; `TcPatValFlags` — flags describing the binding location (inline flag, explicit typars, arg/ret attribs, mutability, visibility, compgen).
- `TcFileState` — per-file typechecking state (documented fields see `CheckBasics.fs` summary): `g`, `recUses`, `stackGuard`, `createsGeneratedProvidedTypes`, `isScript`, `amap`, `synArgNameGenerator`, `tcSink`, `thisCcu`, `css : ConstraintSolverState`, `compilingCanonicalFslibModuleType`, `isSig`, `haveSig`, `niceNameGen`, `infoReader`, `nameResolver`, `conditionalDefines`, `namedDebugPointsForInlinedCode`, `isInternalTestSpanStackReferring`, `diagnosticOptions`, `argInfoCache`, `inheritResolutionFailed`, plus forward calls `TcPat`, `TcSimplePats`, `TcSequenceExpressionEntry`, `TcArrayOrListComputedExpression`, `TcComputationExpression`; `static member Create` builds it.

**Significant notes**:
- The forward calls are the means by which `CheckBasics` avoids a module cycle with the expression checker (`TcValF`-like functions are passed in at `Create` time).
- Two parallel paths `ePath` and `eCompPath` exist for historical reasons (signature lookup vs. ccu canonicalization); `ePath` is barely used.

**Cross-references**: `CheckBasics.fs` (impl), `ConstraintSolver.fsi` (`ConstraintSolverState`, `ContextInfo`), `InfoReader.fsi`, `NameResolution.fsi` (`NameResolutionEnv`, `NameResolver`), `AccessibilityLogic.fsi` (`AccessorDomain`), `CheckDeclarations.fsi`, `CheckPatterns.fsi`.

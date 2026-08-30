# CheckIncrementalClasses.fs

**Purpose**: Implements "implicit class construction" checking for F# types defined with a `new()` / "incremental class" body (e.g. `type C() = let field = ... in ...` or `new() = base 3`). It elaborates the left-hand side (implicit static and instance constructors) and decides how each `let`/`do` binding in the class body is represented in the TAST — as a local variable, a (static/instance) field, or a (static/instance) method — then assembles the initialization/constructor expressions and the published fields.

**Namespace(s)**: `module internal FSharp.Compiler.CheckIncrementalClasses`

**Types declared**:
- `IncrClassBindingGroup` — `IncrClassBindingGroup of bindings: Binding list * isStatic: bool * isRecursive: bool` | `IncrClassDo of expr: Expr * isStatic: bool * range: Range`: a single group of bindings (or a `do`) in an implicit-construction class.
- `StaticCtorInfo` — info for the implicit static constructor: `TyconRef`, `IncrCtorDeclaredTypars` (copy of the type parameters for this construction), `StaticCtorValInfo : Lazy<Val list * Val * ValScheme>` (lazy so it's only published if needed), `NameGenerator`.
- `IncrClassCtorInfo` — info for the implicit instance constructor: `InstanceCtorVal`, `InstanceCtorValScheme`, `InstanceCtorArgs`, `InstanceCtorSafeThisValOpt`, `InstanceCtorSafeInitInfo : SafeInitData`, `InstanceCtorBaseValOpt`, `InstanceCtorThisVal`.
- `IncrClassCtorInfo` also has (impl) `member GetNormalizedIncrCtorDeclaredTypars (cenv, denv, m)` (line ~55) — normalizes the ctor's copy of type parameters.
- `IncrClassValRepr` — the representation chosen for a `let`-bound value: `InVar of isArg`, `InField of isStatic * staticCountForSafeInit * fieldRef`, `InMethod of isStatic * value * valReprInfo`.
- `IncrClassReprInfo` — `{ TakenFieldNames: Set<string>; RepInfoTcGlobals: TcGlobals; ValReprs: Zmap<Val, IncrClassValRepr>; ValsWithRepresentation: Zset<Val> }`. Methods (CheckIncrementalClasses.fs:257-586):
  - `static member Empty(g, names)`
  - `LookupRepr (v)` — look up the representation of a value (error if missing).
  - `static member IsMethodRepr (cenv) (bind)` — predicate on whether a binding is represented as a method (not unit, has arguments, non-mutable).
  - `ChooseRepresentation (cenv, env, isStatic, isCtorArg, staticCtorInfo, ctorInfoOpt, staticForcedFieldVars, instanceForcedFieldVars, takenFieldNames, declKind, bind)` — the core decision on `InVar`/`InField`/`InMethod` including name-freshening for taken field names, unused-value warning, and forced-field logic.
  - `ChooseAndAddRepresentation` — choose and record the representation.
  - `ValNowWithRepresentation`, `IsValWithRepresentation`, `IsValRepresentedAsLocalVar`, `IsValRepresentedAsMethod`.
  - `MakeValueLookup / MakeValueAssign / MakeValueGetAddress` — build the TAST for reading/writing/address-taking a value under its chosen representation (accounting for `thisValOpt`, type instantiation, safe-init info).
  - `PublishIncrClassFields (cenv, denv, cpath, staticCtorInfo, safeStaticInitInfo)` — publish the chosen fields onto the type (creates `RecdField` via `mkRecdFieldFromVal` at line ~240).
  - `FixupIncrClassExprPhase2C (cenv, thisValOpt, safeStaticInitInfo, thisTyInst, expr)` — rewrite a body expression substituting each value lookup with its representation and inserting safe-init guards.
- `IncrClassConstructionBindingsPhase2C` — `Phase2CBindings of IncrClassBindingGroup list` | `Phase2CCtorJustAfterSuperInit` | `Phase2CCtorJustAfterLastLet`: phase-2C positions where bindings/ctor slots are emitted.
- Exception `ParameterlessStructCtor of range` — parameterless struct constructors are an error.

**Public API surface** (the .fsi vals, implemented here):
- `TcStaticImplicitCtorInfo_Phase2A : cenv * env * tcref * m * copyOfTyconTypars -> StaticCtorInfo` (CheckIncrementalClasses.fs:90) — builds the implicit static constructor info.
- `TcImplicitCtorInfo_Phase2A : cenv * env * tpenv * tcref * vis * attrs * pat * thisIdOpt * baseValOpt * safeInitInfo * m * copyOfTyconTypars * objTy * thisTy * xmlDoc -> IncrClassCtorInfo` (line 125) — checks/elaborates the LHS of `new () = e` or `new (arg : T) = e`, building the instance-ctor val, arg vals, and `base`/`this` val plumbing (via `checkImplicitInstanceCtor`).
- `MakeCtorForIncrClassConstructionPhase2C : cenv * env * staticCtorInfo * instanceInfo * decs : IncrClassConstructionBindingsPhase2C list * memberBinds * generalizedTyparsForRecursiveBlock * safeStaticInitInfo -> Expr option * Expr option * Binding list * IncrClassReprInfo` (line ~595) — assembles the constructor expression (init expression for the instance, the static-ctor body, the member bindings, and the final `IncrClassReprInfo`).

**Internal helpers**:
- `reportGeneratedPattern (spat)` (line ~139, `let rec`) — reports diagnostic info on a pattern generated during ctor elaboration.
- `mkRecdFieldFromVal` (line ~240) — constructs the underlying `RecdField` for a `let` bound to a field.
- The `IncrClassReprInfo` methods above (member functions on the record) are the main "internal" API surface actually used by CheckDeclarations.

**Significant internal logic**:
- Representation-choice algorithm (`ChooseRepresentation`): a binding becomes a **field** when it is mutable, or when it is in a forced-field set (`staticForcedFieldVars`/`instanceForcedFieldVars`, i.e. it is used from a member/closure such that it must be initialized by the ctor), or when the type is a struct/enum (which cannot introduce new locals). Otherwise a **zero-arity, non-mutable** binding is kept as an `InVar` local (the ctor argument if `isCtorArg`), and a **non-zero-arity** binding is hoisted to a **method**.
- Name-collision handling: if an implicit field name would collide with an existing field, `NameGenerator.FreshCompilerGeneratedName` is used; `reportIfUnused` emits the "unused value" warning unless the bound value starts with `_` or is compiler generated.
- Safe-init plumbing: `SafeInitData` and `SafeInitInfo` threads (from `CheckBasics`) gate field reads with "is the ctor already initialized" checks and drive the `Phase2CCtorJustAfterSuperInit` / `Phase2CCtorJustAfterLastLet` emission points in `MakeCtorForIncrClassConstructionPhase2C`.
- `IncrCtorDeclaredTypars` are a *copy* of the tycon's type parameters (freshened) so that the implicit ctor's generic signature is independent of the tycon's.

**Cross-references**: `CheckIncrementalClasses.fsi` (contract), `CheckBasics.fs/.fsi` (`TcEnv`, `SafeInitData`, `UnscopedTyparEnv`), `CheckDeclarations.fs` (phase-2A/2C callers; the .fsi for `CheckIncrementalClasses` is opened by CheckDeclarations' mutual-recursion engine), `TypedTree` (`RecdFieldRef`, `ValScheme`, `Zmap`), `InferValReprInfoOfBinding` (val repr inference used by the choice algorithm).

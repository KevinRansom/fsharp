# CheckIncrementalClasses.fsi

**Purpose**: Public contract for implicit-class-construction ("incremental class" / `new()` body) checking. Declares the types describing implicit static/instance constructors and per-binding representation decisions (`InVar`/`InField`/`InMethod`), plus the three entry points used by `CheckDeclarations`: Phase-2A constructor-info construction and Phase-2C constructor-body assembly.

**Namespace(s)**: `module internal FSharp.Compiler.CheckIncrementalClasses`

**Exception**: `ParameterlessStructCtor of range` — parameterless struct constructors are rejected.

**Types declared**:
- `StaticCtorInfo` — typechecked info for an implicit static constructor: `TyconRef: TyconRef`, `IncrCtorDeclaredTypars: Typars` (the copy of type parameters allocated for implicit construction), `StaticCtorValInfo: Lazy<Val list * Val * ValScheme>` (lazy so the static ctor value is only published if needed), `NameGenerator: NiceNameGenerator`.
- `IncrClassCtorInfo` — typechecked info for the implicit instance constructor: `InstanceCtorVal: Val`, `InstanceCtorValScheme: ValScheme`, `InstanceCtorArgs: Val list`, `InstanceCtorSafeThisValOpt: Val option` (ref-cell holding `'this'` so it can be referenced in the inherits-call arguments), `InstanceCtorSafeInitInfo: SafeInitData`, `InstanceCtorBaseValOpt: Val option`, `InstanceCtorThisVal: Val`.
- `IncrClassValRepr` — how a `let`-bound value in a class with implicit construction is represented in the TAST:
  - `InVar of isArg: bool` — local variable (e.g. `let v = 3` not used anywhere → kept as an argument/local).
  - `InField of isStatic: bool * staticCountForSafeInit: int * fieldRef: RecdFieldRef` — stored as a field.
  - `InMethod of isStatic: bool * value: Val * valReprInfo: ValReprInfo` — lifted to a (static/instance) method.
- `IncrClassReprInfo` — `{ TakenFieldNames: Set<string>; RepInfoTcGlobals: TcGlobals; ValReprs: Zmap<Val, IncrClassValRepr>; ValsWithRepresentation: Zset<Val> }` — the accumulated representation decisions for one incremental class. Contract members:
  - `static member IsMethodRepr : cenv: TcFileState -> bind: Binding -> bool`
  - `member PublishIncrClassFields : cenv * denv: DisplayEnv * cpath: CompilationPath * staticCtorInfo: StaticCtorInfo * safeStaticInitInfo: SafeInitData -> unit` — publish the fields of the representation onto the type.
  - `member FixupIncrClassExprPhase2C : cenv * thisValOpt * safeStaticInitInfo * thisTyInst: TypeInst * expr: Expr -> Expr` — fix up an expression given the local representations and `this` context.
- `IncrClassBindingGroup` — a single group of bindings in a class with an implicit constructor: `IncrClassBindingGroup of bindings: Binding list * isStatic: bool * isRecursive: bool` | `IncrClassDo of expr: Expr * isStatic: bool * range: Range`.
- `IncrClassConstructionBindingsPhase2C` — `Phase2CBindings of IncrClassBindingGroup list` | `Phase2CCtorJustAfterSuperInit` | `Phase2CCtorJustAfterLastLet`.

**Public API surface** (val contracts):
- `TcStaticImplicitCtorInfo_Phase2A` — check and elaborate the "left hand side" of implicit class construction (static ctor info).
- `TcImplicitCtorInfo_Phase2A` — check and elaborate the instance-constructor LHS (pattern, `thisIdOpt`, `baseValOpt`, `safeInitInfo`, `objTy`/`thisTy`, `xmlDoc`) → `IncrClassCtorInfo`.
- `MakeCtorForIncrClassConstructionPhase2C` — given the static/instance ctor info, the Phase2C declaration groups (`decs`), member bindings, `generalizedTyparsForRecursiveBlock` ("free choices" recorded for unconstrained typars of outer members), and `safeStaticInitInfo`, generate the constructor's initialization expression(s): returns `Expr option * Expr option * Binding list * IncrClassReprInfo` (static init body, instance init body, member bindings, final repr info).

**Implementation-only (in the .fs, not the .fsi)**: `IncrClassReprInfo.Empty`, `LookupRepr`, `ChooseRepresentation`, `ChooseAndAddRepresentation`, `ValNowWithRepresentation`, `IsValWithRepresentation`, `IsValRepresentedAsLocalVar`, `IsValRepresentedAsMethod`, `MakeValueLookup/Assign/GetAddress`, `reportGeneratedPattern`, `mkRecdFieldFromVal`.

**Cross-references**: `CheckIncrementalClasses.fs` (implementation), `CheckBasics.fsi` (`TcFileState`, `SafeInitData`, `TcEnv`), `CheckDeclarations.fs` (drives these phases inside `TcMutRecDefns_Phase2*`), `TypedTree` (`RecdFieldRef`, `ValScheme`, `Zmap`/`Zset`).

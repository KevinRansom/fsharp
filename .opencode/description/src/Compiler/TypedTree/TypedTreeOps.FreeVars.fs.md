# TypedTreeOps.FreeVars.fs

> Pipeline role: Computes free variables / free type variables / free type constructors / free record fields / free union cases of typed expressions and types, with caching. Central input to the optimizer (usage computation), lambda lifting, and value-escaping analyses, plus the "prettify" transformation namespace used to render types in an F#-friendly surface form.
> Namespace: `FSharp.Compiler.TypedTreeOps`

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.FreeTypeVars` (`[<AutoOpen>]`, internal, declared at line 37)

Zset operations on the typed-tree free-variable universes. Each set is ordered by a dedicated comparer and supports empty/union:

- `emptyFreeLocals`/`unionFreeLocals` (over `Val`, ordered by `valOrder`), `emptyFreeRecdFields`/`union`, `emptyFreeUnionCases`/`union`, `emptyFreeTycons`/`union` (tycon order), `emptyFreeTypars`/`union`, `emptyFreeTyvars`/`unionFreeTyvars` (`freeTyvars` aggregates locals + typars + tycons).
- `isEmptyFreeTyvars` test.

**Collect modes — `type FreeVarOptions` (line 108)** record:

- `canCache: bool` — whether results for local (non-global) exprs are memoized per-expression (only the `CollectTyparsAndLocals` family sets this).
- `collectInTypes`, `includeLocalTycons`, `includeTypars`, `includeLocalTyconReprs`, `includeRecdFields`, `includeUnionCases`, `includeLocals`, `templateReplacement: ((TyconRef -> bool) * Typars) option`, `stackGuard: StackGuard option`.
- Member helper `WithTemplateReplacement(f, typars)`.

**Preset modes (lines 127–219)**:

- `CollectAllNoCaching`, `CollectTyparsNoCaching`, `CollectLocalsNoCaching`, `CollectTyparsAndLocalsNoCaching`, `CollectAll` — fixed configurations used by the many `accFreeVarsFamily` call sites.
- `CollectTyparsAndLocalsImpl stackGuardOpt` — the canCache=true configuration.
- `CollectTyparsAndLocals`, `CollectTypars`, `CollectLocals`, `CollectTyparsAndLocalsWithStackGuard`, `CollectLocalsWithStackGuard`.

**Collection implementation**:

- `accTyVars` family: `accTyvarSetsInType`, `accTyvarSetsInTypes`, `accTyvarSetsInAttribs`, `accTyvarSetsInValReprInfo`, `accTyvarSetsInRemap`? — recursive accumulation into `ValMap`/`TyparMap` keyed accumulators.
- `accFreeVarsExpr`, `accFreeVarsBinding`, `accFreeVarsBindings`, `accFreeVarsDecisionTree` plus their `...AndStackGuard` variants — the per-token walkers producing `freeLocals`,`freeTypars`, etc. via ZZset zeroed states.
- `freeVarsOfExpr`, `freeVarsOfBinding`, `freeVarsOfDecisionTree` public entry points; `getUnused`? helpers to compute unused locals per val.
- `TakeEnv`-style helpers: `freeVarsInModuleOrNamespaceTypeAndRemap`, `freeVarsInModuleOrNamespaceContents` wrapped by `AccModuleOrNamespaceMExpr`; `getMaybeFreeTypars`, `getMaybeInstTypars`.
- Typars-of-type: `freeInTypeCollectTypars`/`freeInTypesCollectTypars` — with `emptyFreeTypars` seeded results.

---

## Module: `type` `FSharp.Compiler.TypedTreeOps.Prettify` (internal, declared at line ~240)

Produce "prettified" type renderings — the F# surface syntax of member types as shown in signatures, IntelliSense, and `--tastdump`:

- `CollectInfo` — collects the named type parameters of an entity/val and computes per-typar names; tracks `templateReplacement` for generic member instantiations.
- `NewPrettyTypars` / `PrettyTyparNames` — naming scheme (`'a`, `'b`, or user names preserved) driven by `Reflection`/`MemberUseKind`? (actually by `PrettyTyparNames` naming policy).
- `AssignPrettyTyparNames`-family — lays down names onto the typars (used by `prettifyTypars`).
- `prettifyTypars`, `prettifyTyparsOfEntity`, `prettifyTyparsOfVal`, `prettifyTyparsOfUnionCase`.
- `PrettifyType`/`PrettifyType_NoFixup` and `PrettifyType` derivations (`PrettifyTypeForDisplay`...).
- Member-form helpers: `GetMemberTypeInFSharpForm g memberFlags arities ty m` (line 504) — converts a member's raw `ty` (with `this` param already removed) into F# form accounting for curried arg lists and explicit generics; `GetTypeOfMemberInMemberForm g vref` (line 716), `GetTypeOfMemberInFSharpForm g vref` (line 722) — entry points used by the signature/reference tooling to display `member M : ...`.

---

## Related

- Builds on: `TypedTree`, `TypedTreeBasics`, `ExprConstruction` (Zset orders).
- Used by: `Optimizer`, `LambdaLift`, `CheckDeclarations`/`CheckExpressions` (value restrictions), `Import`, `SignatureChecks`? and all of the API-surface generators in `FSharp.Compiler.SourceCodeServices`-adjacent modules.
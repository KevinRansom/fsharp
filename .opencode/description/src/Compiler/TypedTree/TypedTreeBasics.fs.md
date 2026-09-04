# TypedTreeBasics.fs

## Pipeline role

`module internal FSharp.Compiler.TypedTreeBasics`. Thin companion to `TypedTree.fs`: defines the "basic property functions (old style)", reference constructors/active patterns, tuple/nullness helpers, and — crucially — the *identity comparators* (`valRefEq`, `unionCaseRefEq`, `entityRefEq`, `ccuEq`) and accessibility/path logic (`canAccess*`, `taccess*`, `prim*RefEq`) that the rest of the typed-tree machinery uses. This is effectively the first slice of "typed tree operations" (`TypedTree.fsi`/`.fs` keep the tree *shapes*; here the tree *behaviour* begins), plus the type/nulls stripping helpers shared by `TypedTreeOps.*`.

## Header, module, opens

- Copyright header (Microsoft, `License.txt`); `// Defines the typed abstract syntax trees used throughout the F# compiler.`
- `module internal FSharp.Compiler.TypedTreeBasics`.
- Opens `Internal.Utilities.Library`, `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.CompilerGlobalState`, `FSharp.Compiler.Text`, `FSharp.Compiler.Syntax`, `FSharp.Compiler.TypedTree`.
- `#if DEBUG` asserts the flag-type sizes: `sizeof<ValFlags> = 8`, `sizeof<EntityFlags> = 8`, `sizeof<TyparFlags> = 4` (kept in sync with the pickle format).

## `module ValReprInfo`

Canonical `ValReprInfo` values and inference:
- `unnamedTopArg1`/`unnamedTopArg`/`unitArgData` (`[[]]`), `unnamedRetVal`, `selfMetadata` (a single unnamed arg — the `this`/`self` of members), `emptyValData = ValReprInfo([], [], unnamedRetVal)`.
- `IsEmpty` — true only when both typar and arg lists are empty *and* the ret-info is bare; `InferTyparInfo` — `TyparReprInfo(tp.Id, tp.Kind)` per typar; `InferArgReprInfo` — `{ Attribs = Empty; Name = Some v.Id; OtherRange = None }`; `InferArgReprInfos` — from `Val list list`; `HasNoArgs`.

## Basic value properties (old-style functions)

`typeOfVal`, `typesOfVals`, `nameOfVal`, `arityOfVal` (default `emptyValData`), `tryGetArityOfValForDisplay` (`ValReprInfoForDisplay` first, then `ValReprInfo`), `arityOfValForDisplay`.

## Tuple infos and raw tuple types

`tupInfoRef = TupInfo.Const false`, `tupInfoStruct = TupInfo.Const true`, `mkTupInfo b`, `structnessDefault = false`, `mkRawRefTupleTy`/`mkRawStructTupleTy` (untyped raw `TType_tuple`).

## Equality on locally defined things

- `typarEq` (by stamp), `typarRefEq` (by physical identity — "should be equivalent"), `valEq` (physical identity), `ccuEq` (physical identity, falling back to `AssemblyName` comparison when either reference is unresolved, else `Contents ===`).

## Reference construction and active patterns

- `(|ValDeref|)` — deref-in-pattern helper.
- Union/record case refs: `mkRecdFieldRef`, `mkUnionCaseRef`, `mkModuleUnionCaseRef modref tycon uc` (via `NestedTyconRef` + `MakeNestedUnionCaseRef`).
- `EntityRef` three-state construction: `ERefLocal`/`ERefNonLocal`/`ERefNonLocalPreResolved` (the `nlr` field is `Unchecked.defaultof<_>` when local — that null-check drives `(|ERefLocal|ERefNonLocal|)`), plus extension members `tcref.NestedTyconRef (x: Entity)` (chooses local vs pre-resolved nonlocal by the parent) and `tcref.RecdFieldRefInNestedTycon`.
- `ValRef` analogues: `VRefLocal`/`VRefNonLocal`/`VRefNonLocalPreResolved`, `mkNonLocalValRef`, `mkNonLocalValRefPreResolved`.
- `mkLocalTyconRef`/`mkLocalValRef`/`mkLocalModuleRef`/`mkLocalEntityRef`; `mkNonLocalEntityRef ccu path`, `mkNestedNonLocalEntityRef` (path append), `mkNonLocalTyconRef`/`mkNonLocalTyconRefPreResolved`, `mkNonLocalCcuRootEntityRef`, `mkNestedValRef` (from an `EntityRef` parent + a `Val` — uses `GetLinkageFullKey` for the nonlocal key).
- `ccuOfValRef`/`ccuOfTyconRef` — the owning CCU when nonlocal.
- Export rescoping: `rescopePubPathToParent`/`rescopePubPath` ("From Ref_private to Ref_nonlocal when exporting data").

## Type parameters, inference unknowns, nullness

- `NewNullnessVar()` — a fresh `Nullness.Variable (NullnessVar())`, documented "we don't know (and if we never find out then it's non-null)".
- `KnownAmbivalentToNull`/`KnownWithNull`/`KnownWithoutNull`.
- `mkTyparTy` — `tp.AsType KnownWithoutNull` for kind `Type`, `TType_measure (Measure.Var tp)` for `Measure`.
- `copyTypar clearStaticReq` — clones with a *new stamp*, cloning the (mutable) optional data; "For fresh type variables clear the StaticReq when copying because the requirement will be re-established through the process of type inference." `copyTypars`.
- `tryShortcutSolvedUnitPar canShortcut r` — dereferences solved measure typar chains (with the `canShortcut` note about `IterType` walking constraints everywhere).
- `stripUnitEqnsAux` — recurses through solved unit typars.
- `combineNullness orig new` — the nullness lattice: a variable holding `WithoutNull` keeps its variable; `WithoutNull` stays; `AmbivalentToNull ∧ {Ambivalent,WithoutNull}` → orig, `AmbivalentToNull ∧ WithNull` → new; `WithNull ∧ {Ambivalent,WithNull}` → orig, `WithNull ∧ WithoutNull` → orig.
- `nullnessEquiv` — physical equality.
- `tryAddNullnessToTy`/`addNullnessToTy` — combine nullness into `TType_var`/`TType_app`/`TType_fun` (with the `TType_app` special case: struct/record/union/enum tycons are inherently non-null and left untouched; a fully-solved variable that evaluates to `WithoutNull` and constant `WithoutNull`/`KnownFromConstructor` are identity).
- `stripTyparEqnsAux`/`stripTyparEqns`/`stripUnitEqns` — full deflection of solved type/untyped chains (following the r.h.s. solution, combining nullness along the way); `canShortcut` off for `stripTyparEqns`/`stripUnitEqns`.
- `replaceNullnessOfTy` — after stripping, rewrites the top-level nullness.
- `(|AbbrevOrAppTy|_|)` (`[<return: Struct>]`) — "Detect a use of a nominal type, including type abbreviations": a `TType_app` after stripping → `ValueSome (tcref, tinst)`.
- `(|ILTyconRawMetadata|_|)` (`[<return: Struct>]`) — the `ILTypeDef` metadata behind a `TyconRef` whose `IsILTycon`.

## Local/non-local reference dispatch

`mkLocalValRef` etc. (above) plus `valRefInThisAssembly`, `tyconRefUsesLocalXmlDoc` (non-local refs use their *local* XML doc when `compilingFSharpCore`, or when the tycon is a provided type), `entityRefInThisAssembly`.

## Identity comparators (the `prim*RefEq` family)

- `arrayPathEq` — structural `string[]` equality.
- `nonLocalRefEq` — identity or (`ccuEq` ∧ path equality).
- `nonLocalRefDefinitelyNotEq` — differing paths *can't* be the same (comment: forwarders can still alias same-path different-CCU refs).
- `pubPathEq`, `fslibRefEq`.
- `fslibEntityRefEq`/`fslibValRefEq fslibCcu` — the FSharp.Core.dll-building special case: compiler-internal refs to fslib items are `Ref_nonlocal` even when compiling fslib, so "backup, alternative equality comparison techniques are needed" (nonlocal-vs-local unification by `PublicPath`, and — for vals — comparison by `ValLinkagePartialKey` since fslib refs are not overloaded where identity matters).
- `primEntityRefEq compilingFSharpCore fslibCcu x y` — identity; resolved-target physical equality when both resolved (and not compiling fslib); nonlocal path equality OR forwarder-aware canonical resolution (`TryDeref` then pointer equality); else fslib fallback. This is the routine that "takes into account the possibility that they may have type forwarders".
- `primUnionCaseRefEq` — `==` on the pair, else parent `primEntityRefEq` ∧ case-name equality.
- `primValRefEq` — identity; resolved-target identity; local-local `valEq`; `TryDeref`-based physical equality for cross-CCU/feature-dependent cases (comment: value identity matters chiefly for (a) Active Patterns and (b) detecting FSharp.Core special values such as `seq` and quotation splicing; "doesn't take type forwarding into account"); fslib fallback.

## Accessibility / compilation-path logic

- `fullCompPathOfModuleOrNamespace` — appends the module itself to its `CompPath`.
- `canAccessCompPathFrom cpath1 cpath2` — "is cpath2 a nested type/namespace of cpath1" (prefix path comparison + equal scope refs; order of arguments noted in the comment).
- `canAccessFromOneOf`, `canAccessFrom` (all granting paths must satisfy), `canAccessFromEverywhere` (`IsEmpty`), `canAccessFromSomewhere`, `isLessAccessible`.
- `accessSubstPaths (newPath, oldPath)` — path-rewrite for `TAccess`.
- Canonical values: `compPathOfCcu`, `taccessPublic = TAccess []`, `compPathInternal = CompPath(ILScopeRef.Local, SyntaxAccess.Internal, [])`, `taccessInternal = TAccess [compPathInternal]`, `taccessPrivate accessPath`.
- `combineAccess` — with syntax-access promotion (public/internal beat the merged paths' default).

## Exceptions

`exception Duplicate of string * string * range` and `exception NameClash of string * string * string * range * string * string * range` (the classic two-entity name-clash report used during checking/name resolution).

## Relation to the signature

Implements every `.fsi` declaration. The `.fs` additionally carries the `#if DEBUG` size asserts and the concrete active-pattern/folding bodies not visible in the signature. Consumers: `TypedTreeOps.*` (all operations), `TypedTree.fs` (via `AutoOpen`d pieces), `TcGlobals.fs` (`prim*RefEq`), `Checker.fs`/`Unify.fs` (nullness, access), `IlxGen`.
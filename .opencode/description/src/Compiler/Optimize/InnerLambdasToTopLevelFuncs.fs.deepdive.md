# Deep Dive — InnerLambdasToTopLevelFuncs.fs (TLR) and `realsig=true` Support

Target: `src/Compiler/Optimize/InnerLambdasToTopLevelFuncs.fs` (1393 lines)
Companion: `src/Compiler/Optimize/InnerLambdasToTopLevelFuncs.fsi` (single entry point)
Goal: (1) document exactly what the TLR pipeline does today, pass by pass; (2) enumerate every place where the current code assumes `realsig=false`; (3) specify the exact changes needed for `realsig=true` (lift closures onto the hosting generic class as static members, preserving the enclosing class type parameters, hereafter **ctps**, in the real signature); (4) show how `IlxGen` already consumes such `ctps`/mtps data; (5) final summary with a minimal patch set.

Flag/mechanism note: the identifier `realsig` does not occur anywhere in the TLR file — TLR never reads the switch (a grep across `src/Compiler/Optimize` finds it only in `Optimizer.fs:436/4761`, where it is stashed in the optimizer environment but never consulted). `realsig` is nevertheless a real, shipped compiler switch (`CompilerOptions.fs:570/1093`, `CompilerConfig.fs:654/854/1403`, `TcGlobals.fs:199/1163`, exposed as `--realsig`/`--realsig+`), and its effects live entirely downstream in `IlxGen`, which consults `g.realsig` in ~25 places. Two facts shape everything below:

1. `IlxGen` **already implements `realsig+` for closures it does not lift**: a closure emitted from inside a generic-class member nests as a nested class *inside that class*, carrying the class typars in its real signature (IlxGen.fs:9770–9788, 7288–7294, 6828) — shipped since the 2024 `#5302`-era work.
2. That shipping `realsig+` behavior does **not** extend to TLR-lifted functions: the `#17607` `effectiveCloc` fork (IlxGen.fs:10610–10619) deliberately steers lifts to `moduleCloc`/the init class to avoid generic enclosing scopes, because lifted `fHat`s are created with `ParentNone` and no `MemberInfo` — so `IlxGen` gives them `ctps = []` and a module-class home.

So the root of the `realsig=false` *lift* behavior is one fact — a TLR-lifted fHat is not a member — and every deviation enumerated in Part 2 follows from it.

---

## Part 1 — Existing behavior: the TLR pipeline, pass by pass

Pipeline overview (comment at lines 117–129): `pass1` decide which `f` is TLR and its arity; `pass2` compute `reqdTypars(f)`/`reqdItems(f)` (closure requirements); `step3` choose an env packing and create the `fHat` values; `pass4` rewrite the term (definitions and call sites); `pass5` `copyImplFile` to restore unique bound ids. Entry point: `MakeTopLevelRepresentationDecisions` (1354–1393).

### pass1 — `Pass1_DetermineTLRAndArities` (175–245)

- `DetermineTLRAndArities` (222) computes `GlobalUsageAnalysis.GetUsageInfoOfImplFile g expr`.
- `SelectTLRVals` (183–208) refuses a candidate via `IsRefusedTLR` (148) if: mutable, byref-like, `MemberInfo.IsSome` (155 — members are never TLR'd), already has `ValReprInfo`, `ValInline.Never`, resumable, or `InlineIfLambda`. It also refuses values bound in a decision tree and values whose body references a protected IL base field (the #5302 gate, 191–197).
- Candidate arity: `arity = min nFormals nMaxApplied` (204), where `nFormals` = lam arity from `stripTopLambda` (201) and `nMaxApplied` = max args over all uses (177–181). Accepted if `atTopLevel || arity <> 0 || not (isNil tps)` (205). So a TLR function either has call sites with `wf ≤ args`, or is a polymorphic/top-level value.
- Filters: `IsValueRecursionFree` (212), and exclusion of values bound under `ValInline.Always` defns (`GetValsBoundUnderShouldInline`, 135–142).
- Results: `(tlrS, topValS, arityM)` where `topValS` = genuinely top-level bindings minus byrefs (232–233). `topValS` values are those that "cannot be lifted over": they stay where they are (members and module bindings per `IsMandatoryTopLevel`, 162–165).

Important consequence carried through the whole pass: **pass1 treats the whole term uniformly.** It has no concept of "inside which generic class is this lambda defined". A lambda inside an instance method of class `Foo<'T>` is considered exactly like a lambda in a module. The ambient `'T` is just a free `Typar` of its body.

### pass2 — `Pass2_DetermineReqdItems` (380–647)

State (429–436): a stack of `(fclass, reqdVals0, env)` frames, `reqdItemsMap` (fclass → env), `fclassM` (f → fclass), `revDeclist`, `recShortCallS`.

- `BindingGroupSharingSameReqdItems` (306) = the subset of vals in one mutual `let`/`letrec` that are TLR; they share one environment.
- `ReqdItem` (326): `ReqdSubEnv of Val` (arity-met call to a TLR `g` — the whole env of `g` must be available) or `ReqdVal of Val` (a value is captured).
- `ReqdItemsForDefn` (345–350): `{ reqdTypars: Zset<Typar>; reqdItems: Zset<ReqdItem>; m }`. This is **the closure descriptor**.
- `IsArityMet` (377): `tys.Length = vref.Typars.Length && wf <= args.Length` — the type-instantiation and argument counts together decide arity-met vs arity-short.

Walking (`ExprEnvIntercept`, 500):
- `accInstance` (502): on an application/use of `f`:
  - `f` TLR and arity-met → `LogRequiredFrom f [ReqdSubEnv f]` (510): the caller needs `reqdTypars(g)` and `env(g)`.
  - `f` TLR and arity-short → `LogRequiredFrom f [ReqdVal f]` plus `LogShortCall` (512–515): the caller keeps the value `f`.
  - `f` non-TLR → `LogRequiredFrom f [ReqdVal f]` (520).
- `accBinds` (522): for the TLR subset of a binding group, `reqdTypars0 = frees.FreeTyvars.FreeTypars` (529) — **all** free typars of the bodies — and `reqdVals0` = free locals excluding the fclass itself (531–534). Then fold bodies, `SaveFrame` (538).
- `CloseReqdTypars` (577–610): fixpoint union: `reqdTypars(fclass)` includes the `reqdTypars` of every `ReqdSubEnv` callee. This is how typar requirements propagate transitively.

Note what is NOT tracked here: anything about where the fclass lives. Free typars are just typars. If the fclass is inside `Foo<'T>.M`, then `'T` lands in `reqdTypars` alongside any genuinely-method typars and any locally generalized typars, with no provenance.

### step3 — `ChooseReqdItemPackings` / `FlatEnvPacks` (705–817)

- `PackedReqdItems` (666–679): `ep_etps` (the actual typars the fHat will quantify), `ep_aenvs` (carrier vals for the env), `ep_pack` (bindings defining aenvs from the free vals), `ep_unpack` (bindings defining the free vals from aenvs).
- `FlatEnvPacks.packEnv` (707): `vals(env)` = transclosure of `ReqdVals` ∪ vals of all `ReqdSubEnvs` (716), minus mandatory top-level vals (720), minus byrefs (750), minus `topValS` vals (752); abort with `AbortTLR` on constrained generic carriers (756). Builds `cmap` of fresh compgen carriers (761), `pack`/`unpack` invisible binds (769–777).
- Crucially: `reqdTypars = env.reqdTypars` (767) and `ep_etps = Zset.elements reqdTypars` (792). The **whole** `reqdTypars` set — including any ambient class typars — becomes the fHat's leading quantified typars.

### step3 — `CreateNewValuesForTLR` (827–856)

`createFHat` (829):
- `tps, tau = f.GeneralizedType` (835); `argTys, retTy = stripFunTy g tau` (836).
- `newTps = envp.ep_etps @ tps` (837) — the fHat's typar list = **all reqd typars + the original f typars, flattened into one list.**
- `fHatTy = mkLambdaTy g newTps (aenvs' types @ argTys) retTy` (839–841).
- `fHatArity = MakeSimpleArityInfo newTps (ep_aenvs.Length + wf)` (843, simple arity at 825).
- `fHat = mkLocalNameTypeArity ... ParentNone` (848; `mkLocalNameTypeArity` at 89–90 constructs the `Val` with `ParentNone` and no `MemberInfo`). The fHat is a fresh compiler-generated val whose **entire** generic nature is expressed as method typars.

### pass4 — `Pass4_RewriteAssembly` (862–1341)

`RewriteContext` (865–877) carries `tlrS`, `topValS`, `arityM`, `fclassM`, `recShortCallS`, `envPackM`, `fHatM`.

`TransTLRBindings` (977–1033) rewrites each TLR binding group into two products:
- The **wrapper / rebinding** of the original `f` (`fRebinding`, 983–1000): keep `f<tps> vss = ...` but the RHS becomes a call `fHat〈ep_etps @ tps〉 (aenvExprs @ vsExprs)` (994–999). `fOrig` is `ClearValReprInfo`'d (992) — the wrapper is a non-TLR function again, callable for arity-short/partial applications.
- The **fHat definition** (`fHatNewBinding`, 1002–1028): strip `<tps> vss`, split `vss` at `wf` (1010), so the taken `vssTake` (`wf` of them, 1022) plus `ep_aenvs` (1022) become fHat's args; the dropped vars go back on as inner lambdas (1013). Body = `ep_unpack` (env unpack, 1023) then optional `shortRecBinds` (a re-binding of `f` for recursive arity-short uses, 1024). `fHatBind = mkMultiLambdaBind g fHat m (ep_etps @ tps) (aenvs ∪ vssTake)` (1027) — again **one flat typar list**.

Placement assembly (`TransBindings`, 1043–1061): for `NotRec`, `bindAs = aenvBinds @ newTlrBinds` (pack binds + fHat binds first), and the wrapper rebinds are pushed outward around the continuation (`mkLetsFromBindings m rebinds e`, at 1233/1249). For `IsRec`, fHat binds + wrapper rebinds + non-TLR binds + aenv binds all go into the same `letrec` (1058).

`TransApp` (1067–1088) rewrites call sites:
- **Arity-met** TLR `f` (1071–1074): replaced by a direct fHat call — `tys := (ep_etps tyargs) @ tys` (1081), `args := aenvExprs @ args` (1083), `mkApps ... fHat ... [tys] args` (1084). The function's *reqd typars are threaded as leading type arguments at every arity-met call site.*
- **Arity-short / non-TLR** (1085–1088): the application is left as-is (`Expr.App (fx, fty, tys, args, m)` or bare `fx`). Partial application is preserved by keeping the wrapper `f`.

Lifting (`RewriteState` 897–905, `EnterInner`/`ExitInner` 908–910, `ExtractPreDecs` 918, `MakePreDecs` 939–949): fHat bindings created inside `Lambda`/`TyLambda`/`Obj`/match targets/class members are collected as "pre-decs" and hoisted to the nearest top-level point (i.e. out of the lambda). `LiftTopBinds` (935) is a deliberate no-op (886–887).

### pass5 — `RecreateUniqueBounds` (1347–1348)

`copyImplFile g OnlyCloneExprVals expr`.

### Where ctps are dropped — the tl;dr

Any typar free in a lifted lambda — whether it is a type parameter of the enclosing generic class, a method typar of the current method, or a locally generalized typar — becomes an ordinary member of `reqdTypars` (529), is packed into `ep_etps` (792), is prepended to the fHat's typar list (837) and to every call site (998/1019/1081), and is emitted by `IlxGen` as a **method** type parameter of a **static method on a non-generic module/helper class**, because the fHat has no declaring entity and no `MemberInfo`.

---

## Part 2 — Everywhere the current behavior assumes `realsig=false`

Root cause: fHat vals are created with `ParentNone` and without `ValMemberInfo`; `IlxGen` then has no enclosing generic class to attach them to, so `CountEnclosingTyparsOfActualParentOfVal` (see Part 4) returns 0 and all typars are emitted as method typars. This is specific to the **lifted** path: `IlxGen`'s `realsig+` already homes *un-lifted* closures from generic-class members as nested classes with correct class-typar signatures (Part 4). The list below is therefore exactly the set of places where TLR's lifted (fHat) machinery diverges from that shipped behavior.

1. **`mkLocalNameTypeArity` constructs the fHat with `ParentNone`** (line 89–90). `Val.DeclaringEntity` would error on such a val (TypedTree.fs:3200–3203); `IlxGen` treats the val as belonging to the current `cloc` (module class). No hosting class is ever recorded.
2. **No `MemberInfo` / home-class tracking on fHats.** `ValMemberInfo.ApparentEnclosingEntity` is never set, so `MemberApparentEntity` is unavailable (TypedTree.fs:3211–3214) and `CountEnclosingTyparsOfActualParentOfVal` returns 0 (FreeVars.fs:658–664). `IlxGen.GetMethodSpecForMemberVal` is never reached; the non-member path `ComputeStorageForFSharpFunctionOrFSharpExtensionMember` is used instead (IlxGen.fs:1649–1676), which hard-codes `ctps = []` in the returned `Method(..., [], tps, ...)` storage (1676) and homes the method on `mkILTyForCompLoc cloc` — the module class (1661–1665).
3. **All typars are method typars.** `newTps = envp.ep_etps @ tps` (837); `fHatArity = MakeSimpleArityInfo newTps (...)` (843); `fHatBind = mkMultiLambdaBind ... fHat_tps (ep_etps @ tps) ...` (1019,1027). There is no split between class generics and method generics anywhere in the file.
4. **The enclosing class generics are ignored and flattened.** pass2 collects the *entire* free-typar set of the lifted bodies (`reqdTypars0 = frees.FreeTyvars.FreeTypars`, 529) into `reqdTypars`, with no notion of ambient/class typars; `CloseReqdTypars` (577–610) unions them transitively; pack puts them wholesale in `ep_etps` (792). The fact that some typars are bound by an enclosing `Foo<'T>.M` is invisible.
5. **The ambient generic env at the binding site is flattened.** pass4's rewrite state (897–905) tracks only `rws_innerLevel` (lambda nesting) and `rws_shouldinline`; there is no tracking of an enclosing generic class, so hoisting (`MakePreDecs`) targets the module top level, not the hosting class.
6. **Call sites prepend ambient typars to the method instantiation.** `tys := (ep_etps tyargs) @ tys` (1081) — the class typars would appear inside the *method* generic argument list, which is exactly the `realsig=false` expansion `Foo.fHat<'T>(...)` rather than `Foo<'T>.fHat(...)`.
7. **`PackedReqdItems` has only `ep_etps`** (666–679) — one flat typar carrier list with no `ep_ctps` counterpart.
8. **`ReqdItemsForDefn` has no home-class field** (345–350) — an fclass's descriptor cannot name the class whose typars it closes over.
9. **Members are simply never lifted** (155, 162–165), so nothing in the pipeline has ever had to reason about "the class I'm inside of" — the `realsig=false` assumption is baked into pass1's safety check itself.
10. **The pass never reads `realsig`, so it cannot know it is "allowed" to produce member-like lifts.** With no consultation of the switch, the divergence from the shipped `realsig+` closure homing is invisible in the pass itself and only observable downstream: a lifted fHat regresses to `ctps=[]` even inside a `realsig+` build where the equivalent un-lifted closure would have been emitted correctly as a nested class of the hosting generic class.

---

## Part 3 — Exact changes to support `realsig=true`

Goal restated: under `--realsig`, a lambda lifted from inside a generic class `C<'T1..'Tn>` should compile to a **static method on `C` itself** with real signature `C<'T1..'Tn>::fHat<'U1..'Uk>(aenv1..aenvm, v1..vwf)`, where `'T1..'Tn` are the class ctps and `'U1..'Uk` are the method typars (`ep_etps @ f.tps`). The result type parameterization splits as: class generics = `ep_ctps`, method generics = `ep_etps @ tps`.

### Data-structure changes

- `ReqdItemsForDefn` (345) gains a home-class field:
  `homeClass: (TyconRef * Typars) option` —
  name the enclosing generic class and its formal typars when the fclass is defined inside one. `ReqdItemsForDefn.Initial` (361) must thread it.
- `PackedReqdItems` (666) gains `ep_ctps: Typars`; `ep_etps` is redefined to be *method-only* typars (environment typars that are not class typars). All existing consumers of `ep_etps` (837, 998, 1019, 1081) must be split into `ep_ctps` and method typars.
- A map fclass → hosting `TyconRef` must be carried (extend `Pass2_DetermineReqdItems.state`, 429, and `FlatEnvPacks`/`ChooseReqdItemPackings` signatures).
- `fHatM` in `RewriteContext` (876) stays, but each fHat now records its host class (via `ValMemberInfo`/`Parent`).

### pass2 — capture ctps at the binding site

`accBinds` (522) computes the free typars of the lifted bodies. Change: partition them by provenance —
- class typars: typars that are (alpha-equivalent to / stamped members of) the **enclosing generic class's formal typars** (`homeClass.FormalTypars`) → these become `env.homeClass`'s ctps.
- everything else continues into `reqdTypars` as before (529).

`CloseReqdTypars` (577) and `LogRequiredFrom` (469) continue to thread `reqdTypars` transitively, but `ReqdSubEnv` propagation must now also propagate the callee's home class when the caller is in the same (or a nil) class — this is what makes a lifted fn nested two classes deep still close over the outer class typars. Ctps do **not** enter `reqdTypars`; they enter the new `ep_ctps` set.

### step3 — packing

`FlatEnvPacks.packEnv` (707): set `ep_ctps = env.homeClass_typars` and `ep_etps = reqdTypars` (unchanged collection, minus any class typars). `ep_pack`/`ep_unpack` (769–777) are unaffected — they pack *values*, not typars; typars are carried structurally.

### `CreateNewValuesForTLR` (827) — the fHat becomes a static member of the hosting class

- `ep_ctps` no longer flows into `newTps` (837). Instead:
  - fHat **class generics** = `ep_ctps` (→ the hosting class, which already declares them).
  - fHat **method generics** = `ep_etps @ tps`.
- `fHatTy` (839–841) and `fHatArity` (843) are computed over the method-generic list only; the fHat's val `Type` is expressed *inside* the class (the class typars are ambient in the binding site environment).
- Set the home class on the fHat val instead of `ParentNone` (replace the hard-coded `ParentNone` in `mkLocalNameTypeArity`, 90, or call `fHat.SetDeclaringEntity (Parent hostingClass)` — TypedTree.fs:3423):
  - `val_declaring_entity <- Parent hostingClass`
  - construct a `ValMemberInfo` (TypedTree.fs:3508–3520) with `ApparentEnclosingEntity = hostingClass`, empty `ImplementedSlotSigs`, and `MemberFlags { ... MemberKind = ... }` appropriate for a generated static method.
  - This is the single mechanical change that redirects `IlxGen` from the non-member path to the ctps-aware member path (Part 4).

### The wrapper (rebinding of `f`, `fRebinding` 983–1000)

Stays a non-TLR shim that: instantiates both class typars and method typars, constructs the env, and calls the fHat:
`f<tps> vss = fHat<ep_ctps, ep_etps @ tps> aenvs vss`
Concretely: (a) `tys` at (998) becomes `mkTyparTy (ep_ctps @ ep_etps @ tps)`; (b) the wrapper body's ambient class typars resolve against the enclosing class instance; (c) `aenvExprs` (986) continue to come from the binding-site env. Because the wrapper is emitted at the binding site (inside the generic class's member), its own re-generalization picks up the class typars as ambient.

### Call site — arity-met (`TransApp`, 1067–1084)

`tys := mkTyparTy (ep_ctps @ ep_etps) @ tys` (i.e. both class- and method- typar instantiations are supplied, in class-first order), `args := aenvExprs @ args`, then `mkApps ... fHat ...`. Because `fHat` is now a member of the hosting class, the `Expr.Val fHat` reference inside the class's method automatically types as `C<ep_ctps>.fHat<...>` and `IlxGen` emits the real-signature call. Nothing at the call site changes structurally beyond the typar prefix — the same shape as today (1081), but split into ctps + mtps.

### Call site — arity-short (`TransApp`, 1085–1088)

The current code preserves partial application by keeping the application of the wrapper `f` (`Expr.App (fx, fty, tys, args, m)`). Under `realsig=true` this must remain the case, but the *instantiation* must be correct for the wrapper's new shape: `f` is still `f<tps> vss` but its closure now includes the class typars and the env carriers, so a partial application `f<tps> v1..vj` (j < wf) must (a) pass through the wrapper (not fHat), and (b) supply typar instantiations that include the ambient class typars exactly as the enclosing class instance provides them. If the wrapper `fOrig` was cleared of `ValReprInfo` (992) this stays harmless — it remains an ordinary non-TLR binding that `IlxGen` can compile relative to its own enclosing scope; the "correct typar instantiation" requirement is: the wrapper must be (re)generalized over the class typars so that `f`'s own partial applications re-instantiate ctps from the ambient class instance.

### Generalization/hoisting consequences

`MakePreDecs`/`ExtractPreDecs` (918–949) currently hoist fHat bindings out of lambdas to module level. For `realsig=true`, a fHat bound inside a generic class's method should be left *inside* that class (its declaring entity is the class), so pre-dec collection must stop hoisting once the outermost *class* boundary is reached rather than continuing to the module top level (`rws_innerLevel`/`RewriteState` (897) needs awareness of the class boundary for ctps-carrying fclasses).

### Placement: the `#17607` fork is bypassed automatically

The only "lift-avoidance" in `IlxGen` today is the `effectiveCloc` fork in `AllocValReprWithinExpr` (IlxGen.fs:10610–10619), which sends non-member top-level lifts to `moduleCloc`/the init class precisely to avoid generic enclosing scopes (#17607). The fork's guard is `v.IsCompiledAsTopLevel && not v.IsMemberOrModuleBinding`. A realsig fHat made a genuine member has `MemberInfo` set (and thus `IsMemberOrModuleBinding = true`/`IsMember = true`), so the fork is **skipped** and `effectiveCloc = cloc` — the hosting class. No new placement mechanism is required in `IlxGen`; making the fHat a member naturally homes it inside the class, exactly as the existing closure-homing normalization (`AddEnclosingToEnv` to `declTref`, IlxGen.fs:9786–9787) already does for member-body closures.

### Summary of the fHat signature layout after the change

| Component | Today (`realsig=false`) | After (`realsig=true`) |
|---|---|---|
| Hosting entity | module class (`ParentNone` fHat) | generic hosting class `C<'T1..'Tn>` |
| Method typars | `ep_etps @ tps` (all flattened) | `ep_etps @ tps` (method only) |
| Class typars | (flattened into method typars) | `ep_ctps` (`C`'s own `'T1..'Tn`) |
| Emitted IL | `C_modulescope::fHat<'T1..'Tn,'U..>` | `C<'T1..'Tn>::fHat<'U..>` |

Under `realsig+` today, the *un-lifted* equivalent already emits as a nested closed class `C<'T1..'Tn>+<closure>@N<'T1..'Tn, ...>` (IlxGen.fs:9770–9788, 7288–7294). The change in this table makes the TLR-lifted form land on the same class as a static method instead.

---

## Part 4 — How `IlxGen` consumes the new data (already realsig-aware, and realsig+ already ships closure homing)

`IlxGen` already splits class vs method typars and homes static members/closed constructs on generic classes. Crucially, `--realsig+` is **shipped, existing behavior** (a real compiler switch, not a proposal), and it is exactly the machinery this work extends. Two facts confirmed by the code:

- **realsig+ exists end-to-end**: `CompilerConfig.fs:654/854/1403`, `CompilerOptions.fs:570/1093`, `TcGlobals.fs:199/1163`, threaded into `IlxGen`'s `eenv.realsig` and `g.realsig` (read at 495, 504, 884, 7289, 8877, 8948, 9770–9788, 10599, 10889, 11106, 11661, 12592, 12616, 13011). The Optimizer stores it (`Optimizer.fs:436/4761`) but never reads it.
- **Closure homing is the realsig+ behavior**: in `GenMethodForBinding` (IlxGen.fs:9770–9788), when `g.realsig` (or the `#5302` protected-field case), `eenv.cloc` is normalized to the *member's declaring type* via `AddEnclosingToEnv ... declTref.Name` (9786–9787), so closures synthesized inside a generic-class member nest **as nested closed classes inside the generic class** — not in the module class. Their *tref* uses `eenv.cloc` (`NestedTypeRefForCompLoc`, 7286), and under realsig their `initialFreeTyvars` pre-seeds the enclosing tyenv's typars (`eenv.tyenv.AsUserProvidedTypars()`, 7288–7294) so the nested closure class is generic over the class typars.

So `realsig+` today = closures that are *not* lifted become nested classes inside the generic class, generic over the class ctps, at worst internal. That is the shipped 2024 behavior the user referenced. The `realsig=false` behavior for the same constructs remains the flat-sk version. **Both coexist in the same IlxGen today.** What does not yet exist is the *TLR* variant: fHat lifted onto the hosting class as a static method with ctps in the real signature. Exactly that is the gap Parts 1–3 close.

### The member path IlxGen uses for a member-like fHat

1. **Storage computation** — `ComputeStorageForValWithValReprInfo` (IlxGen.fs:1694–1740) dispatches a val with `MemberInfo` to `ComputeStorageForFSharpMember` (1640–1644) → `GetMethodSpecForMemberVal` (1458). A TLR fHat with `ValMemberInfo` set goes down exactly this path, producing storage `Method(valReprInfo, vref, mspec, mspecW, m, ctps, mtps, ...)` (1644).
2. **The ctps/mtps split** — `GetMethodSpecForMemberVal`: `numParentTypars = CountEnclosingTyparsOfActualParentOfVal vref.Deref` (1461) = `v.MemberApparentEntity.Typars.Length` (FreeVars.fs:663–664); `let ctps, mtps = List.splitAt numParentTypars tps` (IlxGen.fs:1478). Witness info skips the ctps prefix (`GetTraitWitnessInfosOfTypars`, FreeVars.fs:652–655). The `ctps` are used to build the declaring type `... mkWoNullAppTy parentTcref (List.map mkTyparTy ctps)` (IlxGen.fs:1509–1510), i.e. `C<'T1..'Tn>`.
3. **Emission** — `GenBindingAfterDebugPoint` (8950) hits the `Method(...)` storage case (9005–9038) and passes `ctps, mtps` straight into `GenMethodForBinding` (9738). There: `ilTypars = GenGenericParams cenv eenvUnderMethLambdaTypars methLambdaTypars` (9986) — **only the method typars become IL generic parameters**; params and return type are generated under `eenvUnderMethTypeTypars`/`eenvUnderMethLambdaTypars` whose tyenv already includes the class ctps (via `EnvForTypars`/`EnvForTycon`, 1301–1309). `tref = mspec.MethodRef.DeclaringTypeRef` (10005) and `mgbuf.AddMethodDef(tref, mdef)` (10256) place the method inside the *hosting class's* IL type definition.
4. **Static member conventions apply automatically** — `ComputeMemberAccess` consumes `eenv.realsig` (8948); unit-arg elimination and access defaults follow the member path; the method lands as `C<'T1..'Tn>::fHat<'U...>` exactly as required. This is the same `AddEnclosingToEnv`-based machinery that already emits the `realsig+`/`#5302` homed closures inside generic classes (IlxGen.fs:9770–9788, 1311).

Therefore: **no `IlxGen` change is required for the core emission.** The consumer machinery is fully realsig-aware and the member path is already exercised by every real F# member; the work is entirely in the front half (Parts 1–3) teaching TLR to produce member-like fHat vals carrying `ctps`. The only place worth touching in `IlxGen` *at all* is verification that the `#17607` `effectiveCloc` fork (10610–10619) behaves for a member fHat placed inside `C<'T>` (see Part 3 "Placement"); it is guarded by `not v.IsMemberOrModuleBinding`, which a member-like fHat makes false, so it already falls through to `cloc`.

Caveats to verify during implementation (belong in `IlxGen`, not new code in TLR):
- `Val.DeclaringEntity` (3200–3203) no longer errors once `Parent` is set; but `IsGeneratedEventVal`, quoting/reflection paths, `IsIncrClassGeneratedMember`, and accessibility logic inspect `MemberInfo` fields — the generated `ValMemberInfo` must be consistent (`IsImplPostfix`, member flags, `IsDispatchSlot=false`, `IsImplemented=true`) so `IlxGen`'s three `GetMethodSpecForMemberVal` call sites (1642, 10821, 11419) and the abstract-slot skip (10007–10009) behave.
- `CountEnclosingTyparsOfActualParentOfVal` returns 0 for **extension members** too (FreeVars.fs:662) — irrelevant here since TLR fHats are ordinary instead of extension members, but worth noting so the home class is never an extension target.

---

## Part 5 — Final summary

### Structural changes (TLR side)
1. `ReqdItemsForDefn` (345): add home-class / ambient-ctps field; `Initial` (361) and `Extend` (356) thread it.
2. `PackedReqdItems` (666): add `ep_ctps`; `ep_etps` becomes method-only.
3. `Pass2_DetermineReqdItems`: state (429) + `accBinds` (522) gain class-boundary awareness; `accInstance`/`CloseReqdTypars` propagate home-class alongside `ReqdSubEnv`.
4. `FlatEnvPacks` (707): populate `ep_ctps` from the fclass's home class; strip class typars from `ep_etps`.
5. `CreateNewValuesForTLR` (827): split `newTps` (837) into class (`ep_ctps`) + method (`ep_etps @ tps`) generics; build fHat with `MemberInfo` + `Parent hostingClass` (not `ParentNone` from `mkLocalNameTypeArity`, 90).
6. `TransTLRBindings`/`fRebinding` (998) and `fHatNewBinding` (1019): use `ep_ctps @ ep_etps @ tps` and `vssTake` unchanged; wrapper instantiates ctps+tps and env.
7. `TransApp` (1081): arity-met call inst = `mkTyparTy (ep_ctps @ ep_etps) @ tys`; arity-short path (1085–1088) preserved with wrapper resolving ctps from the ambient class instance.
8. Hoisting (`ExtractPreDecs`/`MakePreDecs`, 918–949): stop at class boundary for ctps-carrying fHats.

### New fields / types
- `ReqdItemsForDefn.homeClass` (or `ambientCtps`): `(TyconRef * Typars) option`.
- `PackedReqdItems.ep_ctps: Typars`.
- `RewriteContext`/`Pass2.state`: fclass → hosting `TyconRef` map.
- fHat `Val`: `MemberInfo = Some { ApparentEnclosingEntity = host; ... }`, `Parent = Parent host`.

### Behavior invariants preserved
- Non-generic-context lifting is bit-for-bit identical today: with no enclosing class, `ep_ctps = []`, no `MemberInfo` effect? — note: to preserve exactly, only set `MemberInfo` when a home class exists (or always, and let `IlxGen` treat a `[]`-ctps static member equivalently). The wrapper/arity-met split behavior is unchanged.
- Number of typars quantified does not change; only their *placement* (class vs method) changes under `realsig`.

### Compatibility posture (confirmed)
- **Reflection compatibility is not assumed for compiler-generated members.** Generated members may be introduced at any compiler version; F# holds reflection-stable only the *names* and *signatures* of **public/protected** members. A realsig fHat is always at worst internal (genuinely `private` when homed on the class), so its addition/removal/rename changes no reflection-visible surface. This neutralizes the "new member introduces API surface" concern entirely.
- **`FSharp.Core` must remain `realsig=false`** — that is an already-understood team decision driven by SQLCLR constraints, not by any reflection/signature requirement exposed by this feature. Nothing in this design forces FSharp.Core to flip; it is a per-assembly compile switch.
- Both pathways coexist in one compiler today (realsig+ nested-class closures + realsig− flat lifts, IlxGen.fs:9770–9788/10610–10619 vs 1649–1676); this design simply adds the *lifted-on-class* variant. `realsig=false` output is baseline-locked.

### Tractability assessment
The work is **front-half confined and tractable**. Every consumer already exists:
- IlxGen's member path already splits ctps/mtps (`GetMethodSpecForMemberVal`, 1461/1478) and homes static members on the enclosing class (1509–1510, 10005); it is driven off `MemberInfo`/`MemberApparentEntity`, so a fHat made member-like is consumed with zero IlxGen changes.
- Under `realsig+` the compiler *already* emits generic-class-scoped closures with correct class-typar signatures (IlxGen.fs:9770–9788, 7288–7294) — this is shipped, working machinery (2024, #5302-era), not speculative.
- The `#17607` `effectiveCloc` fork (10610–10619) is the only "avoid the generic outer scope" mechanism, and it is keyed off `not v.IsMemberOrModuleBinding`; a member-like fHat makes that guard false, so no new placement code is needed — the fork is bypassed automatically and `effectiveCloc = cloc` (the class).
- The remaining risk is confined to the front half: getting `ep_ctps` partitioning and the `MemberInfo` construction right in TLR, and verifying the arity-short wrappers instantiate ctps from the ambient class instance (Part 3 "The wrapper"). No cross-cutting compiler changes, no reflection-compat surface (everything internal/private), FSharp.Core unaffected (stays `realsig=false` for SQLCLR, an already-understood constraint).

### Minimal patch set
1. `InnerLambdasToTopLevelFuncs.fs` — all of the above (the whole change is confined to this one file + its `.fsi` if the entry signature changes).
2. No changes to `IlxGen.fs` **required** for the split/emission (already realsig-aware, member path already ships); re-verify the `#17607` `effectiveCloc` fork (10610–10619) falls through for a member fHat (guarded by `not v.IsMemberOrModuleBinding`) — no code change expected.
3. Tests: ML/baseline expectations showing `realSignature` split (`C<'T>::fHat<'U>`) vs `realsig=false` flattening (`C::fHat<'T,'U>`); plus a `realsig+` baseline showing the equivalent nested-class closure (IlxGen.fs:9770–9788) to guard the two shapes.
4. No change needed in `Optimizer.fs` (it stores but never reads `realsig`); FSharp.Core stays on the default (`realsig=false`).

---

## References (TLR file lines)
- 89–90 `mkLocalNameTypeArity` (ParentNone); 117–129 pipeline overview; 148–165 `IsRefusedTLR`/`IsMandatoryTopLevel`; 175–245 pass1; 306–368 fclass/`ReqdItemsForDefn`; 377–378 `IsArityMet`; 380–647 pass2 (`accBinds` 522, `CloseReqdTypars` 577); 666–679 `PackedReqdItems`; 705–800 `FlatEnvPacks`; 827–856 `CreateNewValuesForTLR`; 862–1341 pass4 (`TransTLRBindings` 977, `fRebinding` 983, `fHatNewBinding` 1002, `TransBindings` 1043, `TransApp` 1067, hoisting 918–949); 1347–1348 pass5; 1354–1393 entry. `realsig` does not occur anywhere in this file.

## References (downstream)
- IlxGen.fs 1458 + 1461 + 1478 + 1509–1510 (member mspec ctps/mtps split); 1640–1644 (member storage); 1649–1676 (non-member storage — ctps=[] path); 495/504/8948/9131 (`ComputeMemberAccess`/`ComputeTypeAccess` on `g.realsig`); 9770–9788 (realsig+/#5302 closure homing — `AddEnclosingToEnv` to `declTref`); 7286 (`NestedTypeRefForCompLoc`), 7288–7294 (realsig `initialFreeTyvars` from `tyenv.AsUserProvidedTypars`); 10610–10619 (`#17607` `effectiveCloc` fork, guard `IsCompiledAsTopLevel && not v.IsMemberOrModuleBinding`); 9005–9038 (Method dispatch); 9738/9986/10005/10256 (method emission).
- TypedTreeOps.FreeVars.fs 658–664 `CountEnclosingTyparsOfActualParentOfVal`; 670 witness skip.
- CompilerConfig.fs 654/854/1403 (`realsig` storage, default false); CompilerOptions.fs 570/1093 (`--realsig+` switch); TcGlobals.fs 199/1163 (`g.realsig`); Optimizer.fs 436/4761 (stored, never read).
- TypedTree.fs 1417–1419 `ParentRef`; 3200–3203 `DeclaringEntity`; 3211–3214 `MemberApparentEntity`; 3423 `SetDeclaringEntity`; 3508–3520 `ValMemberInfo`.
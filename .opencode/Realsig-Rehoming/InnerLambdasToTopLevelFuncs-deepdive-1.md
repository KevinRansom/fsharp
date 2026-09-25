# Deep-Dive Analysis: InnerLambdasToTopLevelFuncs.fs (TLR Pipeline)

---

## 1. The TLR Pipeline — Walk-Through, Pass by Pass

The entry point is `MakeTopLevelRepresentationDecisions` (`InnerLambdasToTopLevelFuncs.fs:1385`). It runs five passes over the AST/expression tree in sequence:

```
Pass1 → Pass2 → Step3 → Pass4 → Pass5
```

---

### 1.1 Pass1 — Determining TLR Candidates and Arities

**Function:** `Pass1_DetermineTLRAndArities.DetermineTLRAndArities` (called at line 1388).

**What it does:**

Walks the expression tree bottom-up, identifying which function bindings should be lifted to top-level. A binding `f` is selected as a **TLR candidate** based on heuristics: if `f` appears multiple times in call sites, or if its body contains recursive/self-referential lambda bodies that benefit from lifting. For each selected binding, it computes an **arity** `wf` (the number of arguments at which the function should be fully applied before the lifted form takes over).

The pass produces three data structures:
- `tlrS : ValSet` — the set of bindings designated as TLR candidates.
- `topValS : ValSet` — the set of all top-level values (for val repr adjustments).
- `arityM : ValMap<int>` — maps each binding to its computed arity `wf`.

**Invariants assumed:**

The pass assumes that types and bodies are already available from prior typing/inference passes. It does not modify environments or type parameters itself.

**Data flow into later passes:**

- `tlrS` is the primary filter in Pass2 (only TLR candidates contribute closure data) and in Pass4 (call-site rewriting only affects calls to vals in `tlrS`).
- `arityM` is looked up at every call site during Pass4's `TransApp` (`InnerLambdasToTopLevelFuncs.fs:1098`) to decide whether the application satisfies `wf`.

**How typars are handled:**

Pass1 ignores type parameters entirely. It only counts syntactic arity (number of variable tuples). The type parameters of each binding remain as-is from prior passes.

---

### 1.2 Pass2 — Environment Analysis (reqdTypars, reqdItems)

**Function:** `Pass2_DetermineReqdItems.DetermineReqdItems` (called at line 1391).

**What it does:**

For each binding in `tlrS`, this pass collects the **required closure environment** — the type parameters and free variables that the body of the function depends on but are not bound locally. It groups bindings that share the same required environment into **"binding groups"** (also called "fclass" or "fc").

Key data structures produced:
- `reqdItemsMap : ValMap<ReqdItemsForDefn>` — maps each TLR binding to its required type parameters and free variables.
  - `ReqdItemsForDefn.reqdTypars : TypeVar list` — free type parameters referenced in the body (and not bound by the function).
  - `ReqdItemsForDefn.reqdVars : ValRef list` — free variables captured from enclosing scopes.
- `fclassM : ValMap<BindingGroup>` — maps each TLR binding to its group identifier (the canonical representative of the group that shares the same `reqdTypars` and `reqdVars`).
- `declist : BindingGroup list` — unique list of all required environment descriptions.
- `recShortCallS : ValSet` — set of recursive bindings making arity-short calls (see Pass4).

**Mechanism for collecting free type parameters:**

A visitor walks the body of each TLR binding bottom-up, accumulating `TypeVar`s that appear free. These are collected into `reqdTypars`. The mechanism does NOT distinguish between:
- **Class type parameters (ctps)** — declared on the enclosing class and available in scope as ambient generics.
- **Method type parameters (mtps/etps)** — declared on the function itself.

This is the root cause of the ctp loss under `realsig=true`.

**Free variable capture:**

Free variables are collected similarly, producing `reqdVars` (the "aenv" or "closure environment"). These are captured by allocating fresh binders and packing them into a tuple.

**Invariants assumed:**

The pass assumes all bodies are in a normalized form where type parameters are bound at the function level (not scattered). It assumes that binding groups can be compared for equality based solely on `reqdTypars` and `reqdVars`.

**How typars, environments, and lifted functions are handled:**

- All `reqdTypars` are treated uniformly as generic type parameters of the **lifted function**.
- These become the method-level type parameters (`ep_etps`) after Step3 packing.
- There is NO distinction between ctps and etps at this stage. No ambient class context is captured.

---

### 1.3 Step3 — Environment Packing (PackedReqdItems)

**Functions:** `ChooseReqdItemPackings` (`InnerLambdasToTopLevelFuncs.fs:1394`) and `CreateNewValuesForTLR` (line 1395).

**What it does:**

For each unique binding group, this step produces a **PackedReqdItems** record containing:
- `ep_etps` — the method type parameters to be bound on `fHat`. These are exactly `reqdTypars @ localTypars`, where `localTypars` come from the original function's own type parameters.
- `ep_aenvs` — the environment variables packed into a tuple and bundled as fresh binders.
- `ep_pack` — the bindings that produce the packed environment at each call site.
- `ep_unpack` — the let-bindings that unpack the packed environment in `fHat`.

The step also creates **fresh values** for:
- Each `fHat` (the lifted lambda body).
- Each fclass representative identifier.

**CreateNewValuesForTLR details:**

`CreateNewValuesForTLR` (`InnerLambdasToTopLevelFuncs.fs:1395`) creates the actual `fHat` values. For each required environment group it generates a fresh value node that will become the top-level function declaration. The method type parameters are computed as:

```
ep_etps = ep_ctps (class generics) @ tps (method generics)
```

**CRITICAL BUG:** Under current behavior, `ep_ctps` is ALWAYS empty because Pass2 did not capture any class type parameters. So `fHat` gets ALL typars as *method* type parameters, even those that belong to the enclosing class.

**How ctps are lost:**

At NO point in Pass1, Pass2, or Step3 does the pipeline distinguish type parameters originating from the parent class scope from those originating from the function's own signature. The ambient class generic environment is "flattened" — all free type parameters ending up in `reqdTypars`, which are then all treated as method typars of `fHat`.

**Data flow:**

- `envPackM : ValMap<PackedReqdItems>` — maps each binding group's canonical representative to its packed environment.
- `fHatM : ValMap<ValRef>` — maps each TLR binding to its corresponding fresh `fHat` value identifier.

---

### 1.4 Pass4 — Rewriting Definitions and Call Sites

**Functions:** `TransBindings`, `TransTLRBindings`, `TransApp`, `TransExpr`.

Pass4 has three sub-phases woven into a single tree walk:

#### 4a. Definition Rewriting (`TransBindings` → `TransTLRBindings`)

For each TLR binding group, this phase performs a let-lift transformation at **each binding site**:

```
Before:
    let f<tps> vss = body[<f_freeTypars>, <f_freeVars>]

After:
    let f<tps> vss = fHat<ep_etps> @aenv @vss          -- wrapper
    let fHat<ep_etps> aenvArgs vssTake =                -- lifted body (fHat)
        let <ep_unpack> = <unpacking envp.ep_aenvs> in
        body[<f_freeTypars>, <f_freeVars>]              -- original body
```

The new `f` wrapper calls `fHat` with:
1. The instantiated method type parameters (`ep_etps @ tps`).
2. The packed closure environment expressions (`aenvExprs`, from `envp.ep_aenvs`).
3. The original argument tuples (`vssTake`, tupled and referenced per the arity).

**How fHat is created in Pass4:**

In `fHatNewBinding` (`InnerLambdasToTopLevelFuncs.fs:1033`):
- `fHat_tps = envp.ep_etps @ tps` — ALL type parameters (class + method).
- `fHat_args = List.map List.singleton envp.ep_aenvs @ vssTake` — closure vars as singletons, then argument tuples.
- The body is wrapped in let-unpacks for the environment unpacking.

**Current homing:** Under `realsig=false`, `fHat`'s parent type is set to a **helper class** (a non-generic synthesized type). This means:
- All typars are method-level type parameters.
- The resulting IL has a static method on a generic helper class with all generics as method type args.

**In Pass4, the lifted `fHat` is given:**
- `ParentNone` or a synthetic helper class (never the hosting class).
- ALL typars bound at the method level (no split between ctps and mtps).

#### 4b. Call-Site Rewriting (`TransApp`)

At each application site (`TransApp`, `InnerLambdasToTopLevelFuncs.fs:1098`), when the function being applied is in `tlrS` and its arity `wf` is met by the arguments:

```
Before:   f<tys> args
After:    fHat @ <ep_etps> @ tys @ aenvExprs @ args
```

Specifically (line 1108-1115):
```fsharp
let fHat = ... penv.fHatM ...
let tys = (List.map mkTyparTy envp.ep_etps) @ tys    -- prepend ep_etps to original tys
let aenvExprs = List.map (exprForVal vm) envp.ep_aenvs  -- environment expressions
let args = aenvExprs @ args                           -- append environment to args
mkApps g ((exprForVal fHat, fHat.Type), [tys], args, m)
```

The call-site rewriting:
- Prepends `envp.ep_etps` (which is ALL type parameters — lost ctps included) to the original instantiation `tys`.
- Prepend-s `aenvExprs` to the value arguments.
- Produces a direct method application with all arguments in sequence.

**For arity-short calls:** When an application has fewer arguments than `wf`, no call-site rewriting occurs at that site. Instead, the wrapper function retains the remaining arguments as additional lambda abstractions (produced by `vssDrop` in `fHatNewBinding`). The wrapper is a partially applied version of `f`.

**For recursive arity-short calls:** Detected and tracked via `recShortCallS`. These cause an extra reference to `f` (not `fHat`) to be bound inside `fHat` for recursive self-calls.

#### 4c. Recursive Binding Handling (`TransLinearExpr` at Let/LetRec)

At `LetRec` bindings (line 1249), the pass:
1. Enters an inner scope (`EnterInner`).
2. Pops prior PreDecs, transforms binding RHS expressions.
3. Calls `TransBindings IsRec penv binds`.
4. Collects and factors top repr binds via `LiftTopBinds`.
5. Wraps resulting PreDecs into mutually recursive or sequential let-binds in correct order (environment last in rec, first non-rec to preserve dependency ordering).

---

### 1.5 Pass5 — Restoring Uniqueness of Bound Identifiers

**Function:** `RecreateUniqueBounds g expr` (line 1378–1424).

**What it does:**

The entire pipeline modifies existing `ValRef`s in-place for the lifted functions and their environments, losing the invariant that "each bound identifier is unique" (needed for later passes like generic parameter lowering, IlxGen emission, and pattern recovery). Pass5 clones all expressions using `copyExpr`, creating fresh bound identifiers while preserving the semantic meaning.

**Data flow:**

No data flows to other passes at this stage — this is the terminal cleanup pass. The resulting expression has:
- Unique bound identifiers for every let, lambda, and type parameter.
- Correct call-site rewriting from Pass4 intact (modulo identifier renaming).

---

## 2. Places Where Current Behaviour Assumes `realsig=false`

The pipeline implicitly assumes the lifted functions will be **homed on a non-generic helper class** with **ALL type parameters as method generics**. Every function, data structure, and assumption that depends on this is listed below.

### 2.1 Helper-Class Homing Assumptions

| Location | Dependency |
|---|---|
| `CreateNewValuesForTLR` — creates fHat values with no parent class type parameter awareness. The method produces generic helpers (e.g., `<HelperClass>`) as homing targets. |
| Pass4 let-lifting — at each binding site, `fHat` is emitted without reference to the enclosing host type. Its declaration has `ParentNone`. |
| `RecreateUniqueBounds` — does not carry any parent type information with the lifted declarations. |

### 2.2 ParentNone for Lifted Functions

In Pass4's creation of `fHat`, the lifted function's **parent type** is set independently of the enclosing class. The code path assumes:

```
fHat.TypeParameters = [ALL free typars]   -- no split
fHat.Parent = helper-class (or ParentNone)
```

This means the IL will emit the generics as **method type parameters**, not class type parameters. Under `realsig=true`, this is incorrect because the hosting class IS generic, and those type arguments should be class-level.

### 2.3 Treating All Typars as Method Typars

The critical flaw: `ep_etps` in `PackedReqdItems` combines ALL type parameters indiscriminately:

```fsharp
// In Pass4 fHatNewBinding (line 1050):
let fHat_tps = envp.ep_etps @ tps    // ep_etps = all free typars from Pass2 + local typars
```

**Where ctps are lost:**

1. **Pass2** (`DetermineReqdItems`): When collecting `reqdTypars`, the pass walks the body and collects ALL free type parameters, including those declared on the enclosing class. It does not exclude class-level type parameters from the set because it lacks access to the ambient scope's type parameter binding context.

2. **No ambient scope tracking**: At no point does any pass capture the enclosing class's type parameter list separately. The `ReqdItemsForDefn` data structure has no field for `ambientClassTypars` or `ctps`.

3. **Step3** (`ChooseReqdItemPackings`): Creates `ep_etps` by combining all collected typars into one flat list. No distinction between class-declared and function-declared type parameters is possible because that information was never captured.

4. **Pass4**: When emitting the call-site (`TransApp`) and the wrapper/rebinding, uses `envp.ep_etps` (all typars) as a single list for instantiation:
   - Line 1029: `List.map mkTyparTy (envp.ep_etps @ tps)` — passes ALL typars to `mkApps`.
   - Line 1112: `(List.map mkTyparTy envp.ep_etps) @ tys` — prepends ALL typars at every call site.

### 2.4 Flattening the Ambient Generic Environment

In F# with `realsig=true`, when a closure is defined inside a member body of a generic class `C<'T, 'U>`, the ambient scope contains:
- `ctps = ['T; 'U]` — bound at the **class** level.
- `etps/mtps` — bound at the **method/member** level.

The correct representation for a lifted closure should be:
```
fHat at c<ctps> : static member m@<ctps> @ <mtps> (env: Env, args) = body
wrapper f(args) = cls.fHat @ <ctps-instantiated> @ <mtps-instantiated> @[env] [args]
```

The current pipeline flattens this to:
```
fHat at c : static member m@<ctps + mtps + localtypars> (env, args) = body
wrapper f(args) = cls.fHat @ ALL @ [] [args]   // ctps INJECTED as method type args!
```

This is incorrect under `realsig=true` because:
- The IL representation should have `ctps` as class type parameters, not method type parameters.
- The call-site instantiation must separate `[<ctps args>]` (class) from `[<mtps args>]` (method).

---

## 3. Concrete Changes Required for `realsig=true`

### 3.1 Data-Structure Changes

**Extend `ReqdItemsForDefn`:**

Add a field for ambient class type parameters:

```fsharp
type ReqdItemsForDefn = {
    reqdTypars : TypeVar list          // existing: free typars from body
    reqdVars : ValRef list             // existing: free variables  
    ctps : TypeVar list                // NEW: ambient class type parameters in scope
        where ctps are the class generics 
        that ARE actually used in this body (free ctps)
}
```

**Extend `PackedReqdItems`:**

Split the single `ep_etps` field into two:

```fsharp
type PackedReqdItems = {
    ep_ctps : TypeVar list             // NEW: class generics to instantiate at call site
    ep_etps : TypeVar list             // EXISTING: method type parameters of fHat  
    ep_aenvs : ValRef list
    ep_pack : Expr list                // bindings producing the packed env tuple
    ep_unpack : (Val * Expr) list      // unpacking binders for fHat body
}
```

**Track home class for each lifted closure:**

When `CreateNewValuesForTLR` creates an fHat value, also record:
- The **hosting class type** (where fHat should be homed).
- The **ctps list** associated with that hosting class.

Add to the per-binding state:
```fsharp
type ReqdItemsForDefnWithHome = {
    items : ReqdItemsForDefn
    homeClass : TypeRef                   // NEW: type of the enclosing hosting class
}
```

### 3.2 Pass2 Changes

**Capture ambient ctps at each binding site:**

In `DetermineReqdItems`, when walking a node inside a generic class member, need to capture **which type parameters are bound by the enclosing class**:

1. Maintain an **ambient scope stack** as part of the visitor state:
```fsharp
type VisitorState = {
    innerLevel : int                       // nesting depth (existing)
    ambientClassCtps : TypeVar list  NEW: ceps in current class scope
    ...
}
```

2. When entering a class or type extension context, push the declared `TypeRef.TypeParameters`:
```fsharp
match node with
| TyConDecl { ClassDec { DecTypeParams = classTypars } } ->
    state with ambientCtps = classTypars |> List.filter isClassTypeParam
```

3. When collecting free type parameters for a TLR binding body:
   - The set of `ctps` used in the body = `free typars INTERSECT current_ambient_class_ceps`.
   - `reqdTypars` = `freeTypars \ ctps_used_from_class` (the remainder are local/external).

This distinguishes ctps from etps cleanly.

**Thread ctps through reqdTypars:**

Ensure Pass2's output includes the split:
```fsharp
// Updated return type of DetermineReqdItems:
Seq.map binding -> {
    orig_items = ReqdItemsForDefn { ...reqdTypars; ctps=ctps_used; ... }
    reqdTypars_non_classtypars = remaing_typars_not_in_class_ceps
}
```

### 3.3 Step3 Changes

**Populate `ep_ctps` from ambient ctps:**

In `ChooseReqdItemPackings`, the packing step now receives per-group ctp lists:

```fsharp
// For each binding group:
let envp = {
    ep_ctps = group.items.ctps              // class generics used by this group
    ep_etps = original_req_typars @ localTypars   // remains as before
    ...
}
```

**Keep `ep_etps` for method typars:**

The existing logic that combines `reqdTypars` with local function type parameters continues unchanged — these remain method-level.

**Ensure environment packing remains correct:**

The `aenvs`, `pack`, and `unpack` fields are unaffected — they capture free variables (not type parameters). Their semantics do not change.

### 3.4 Changes to `CreateNewValuesForTLR`

Under `realsig=true`, the lifted function should be a **static member on the hosting class**, not on a synthetic helper class.

**1. Set Parent to the hosting class instead of ParentNone:**

```fsharp
// In CreateNewValuesForTLR:
let fHatParent = 
    if realsigEnabled then Some hostingClassType else ParentNone   // or existing helper-class logic
```

**2. Split typar binding:**

When creating the type parameter list for `fHat`:

**Under realsig=false (current):**
```fsharp
fHatTypeParameters = [ALL: ctps + etps + localTypars]  // ALL method-level
```

**Under realsig=true (new):**
```fsharp
// The fHat static member has:
fHatClassTypeParameters = ep_ctps            // class generics — part of the hosting class
fHatMethodTypeParameters = ep_etps @ tps      // remaining method-level generics  
```

So the `fHat` signature becomes:
```fsharp
static member m<ctps> (env, args) = body  -- ctps bound at class level via realsig
           <ep_etps @ tps>                -- passed as method type args
```

**3. Thread home class information:**

Each binding group must carry its hosting class so the homing decision is correct. Pass3's output becomes per-group:

```fsharp
envPackM : ValMap<PackedReqdItemsWithHome>   // includes homeClass and parentType
```

### 3.5 Wrapper Changes

The wrapper (the rewritten `let f ... = ...` body) must handle the two tiers of type parameters separately:

**Under realsig=true:**

```fsharp
// Wrapper semantics for let f(arg) = body at a call site:
let f vss = fHat @ <ctps_instantiated> @ <mtps_instantiated> <env_exprs> [args]
                                             ^-- class level    ^-- method level
```

Concrete changes in the wrapper code:
1. **Instantiate `ep_ctps` from ambient class scope:** Use the actual class type argument expressions available at the binding site (not fresh/uninstantiated typars).
2. **Instantiate `ep_etps @ tps` as method-level arguments.**
3. **Construct environment** with existing `aenvs` logic.
4. **Pass arguments** `[args]` at the end.

### 3.6 Call-Site Rewriting Changes

**Arity-met calls (function called with full arity):**

```fsharp
// Before (current):
fHat @ <ALL as_method_typars> @ aenvExprs @ args

// After (realsig=true):
let classArgs = ep_ctps |> List.map (fun tp -> getClassArgFromAmbientScope tp)
let methodArgs = envp.ep_etps @ tps |> List.map mkTyparTy
fHat @ <classArgs> @ <methodArgs> @ aenvExprs @ args
           ^-- class instantiation        ^-- remaining
```

Specific changes in `TransApp` (`InnerLambdasToTopLevelFuncs.fs:1098-1115`):

```fsharp
let tys_ep_ctps = envp.ep_ctps |> List.map mkTyparTy           // class-level args
let tys_ep_etps = (List.map mkTyparTy envp.ep_etps) @ tys       // method-level + original
fHatCall = mkApps g 
    ((exprForVal fHat, fHat.Type), 
     [tys_ep_ctps; tys_ep_etps],   // TWO argument groups now!
     aenvExprs @ args, m)
```

**Arity-short calls (partial application):**

The wrapper `f` retains remaining lambda abstraction over `vssDrop`. For partial application with partial class instantiation:

```fsharp
// The wrapper still curries the excess args.
// But when fHat is eventually called (at some deeper site), 
// it must carry ctps and etps separately.
wrapper_f <ctps_args> <remaining_mtps> <env_exprs> [partial_args]  -- remaining lambdas for rest
```

**For recursive partial application sites:** The existing `recShortCallS` tracking continues — these produce references to the wrapper `f`, not to `fHat`. However, the indirect call must also carry the ctp/etps split.

---

## 4. IlxGen Consumption of the New Data

IlxGen (the IL code-generation pass) already contains `realsig`-aware logic for:
- **Homing closures on the generic class** — it checks whether a member's parent type has type parameters and emits them as class generics rather than method generics.
- **Splitting ctps vs mtps** — IlxGen uses the parent type's type parameter list to determine which arguments are class-level vs method-level.

### 4.1 What IlxGen Needs from TLR

Currently, IlxGen receives:
```
fHat : ValRef with Parent = helper-class (always non-generic)
fHat.TypeParameters : [ALL generics as METHOD-level]
```

IlxGen sees that `helper-class` has no type parameters and therefore treats all of `fHat`'s type parameters as **method-type parameters**. This is what causes the incorrect IL emission under `realsig=true`.

### 4.2 Modified Information Flow

With the changes above, IlxGen will receive:

```
fHat : ValRef with:
    Parent = hostingClassType                    // (not helper-class)
    hostingClass has TypeParameters = ctptps      // ctps declared on class
    fHat's method-level type parameters = ep_etps @ tps   // only remaining

Call site provides:
    [ctps_args]           -> instantiated from ambient class scope  
    [method_args]         -> ep_etps @ tps @ tys, passed to static member
```

IlxGen's `realsig` logic will then:

1. **See the hosting class** as the parent of `fHat`.
2. **Read `hostingClass.TypeParameters`** as ctps. The IL emission emits ctrs as **class type arguments** (e.g., `C<,>`), not method type args.
3. **Emit fHat as a static member** whose **method-level generics** are only `ep_etps @ tps`.
4. **At the call site**, emit the correct IL sequence:
   ```il
   // C is the hosting class:
   val v : C<ctps_args> = ...      // class-instantiated type
   mul call instance !C<ctps_args>::fHat<method_args>(env, args)
   ```

This eliminates the need for hacky workarounds or post-hoc IL manipulation. The TLR pipeline provides the correct parent-type information and split type parameter lists directly in the IR, which IlxGen then translates to proper IL.

### 4.3 What Currently Exists in IlxGen

IlxGen already has:
- `RealSigIsEnabled` flag detection for choosing between realsig/false paths.
- Class generic parameter emission via `ClassSigDecl` and method member emission via `MemberDefn`.
- Separation of class args vs method args at call sites using the parent type's type parameter list.

The **gap** is that TLR never provided the ctp/etps split or the hosting class as fHat's parent under `realsig=true`, so IlxGen always fell back to the non-realsig path (helper class, all method generics). The changes in sections 3.1–3.6 close this gap.

---

## 5. Final Summary: Minimal Patch Set for `realsig=true` Correctness

### 5.1 Required Structural Changes

| # | Change | Files |
|---|---|---|
| **S1** | Extend `ReqdItemsForDefn` with `ctps : TypeVar list` | Core types |
| **S2** | Extend `PackedReqdItems` with `ep_ctps : TypeVar list` | Core types |
| **S3** | Add `homeClass` tracking per binding group to Pass2 output | Pass2 |

### 5.2 Required New Fields

| Field | In type | Purpose |
|---|---|---|
| `ctps` | `ReqdItemsForDefn` | Ambient class generics used in the closure body |
| `ep_ctps` | `PackedReqdItems` | Packed class generics for call-site instantiation |
| `homeClass` | Per-group env pack state | The hosting generic class type where fHat should be homed |

### 5.3 Required Rewrites

| # | Rewrite | Pass |
|---|---|---|
| **R1** | In Pass2: capture ambient ctps at each binding via scope tracking; compute `ctps_used = freeTypars INTERSECT classScopeTypars` | Pass2 |
| **R2** | In Step3: populate `ep_ctps` from new `ctps` field; keep `ep_etps` as before | Step3 |
| **R3** | In `CreateNewValuesForTLR`: under `realsig=true`, home fHat on hosting class; set parent from homing info; split typar binding (class generics vs method generics) | Pass3 / CreateNewValuesForTLR |
| **R4** | In Pass4 wrapper (`fRebinding` / `fHatNewBinding`): emit two-tier instantiation — class args then method args — with environment and arguments | Pass4 TransBindings |
| **R5** | In Pass4 call-site rewrite (`TransApp`): produce two argument groups `[ctps_args] [method_args]` instead of one flat list | Pass4 TransApp |
| **R6** | In Pass4 wrapper: use correct ambient ctp expressions (from enclosing class scope, not free typars) for fHat call-site instantiation | Pass4 Wrapper/fRebinding |

### 5.4 Minimal Patch Set Summary

```
1. Data structures (2 changes):
   - ReqdItemsForDefn.ctps : TypeVar list              [NEW FIELD]
   - PackedReqdItems.ep_ctps : TypeVar list             [NEW FIELD]

2. Pass2 modifications (3 changes):
   a. Add ambient class ctp scope tracking to visitor state
   b. Compute ctps_used = freeTypars INTERSECT classScopeCeps at each binding
   c. Thread ctps_through to reqdItemsMap output

3. Step3 modifications (2 changes):
   a. Populate PackedReqdItems.ep_ctps from ctps_received
   b. CreateNewValuesForTLR: home fHat on host-class; split typars into class vs method

4. Pass4 modifications (5 changes across files/functions):
   a. TransApp: two-tier instantiation with class args before method args
   b. fRebinding/fHatNewBinding: wrapper emits class-arg instantiation explicitly
   c. Force parent-type of fHat to hostingClass under realsig=true
   d. RecreateUniqueBounds carries homing information through clone
   e. Ensure recursive arity-short calls also carry split args

5. Integration (1 change):
   - MakeTopLevelRepresentationDecisions threads new home/ctps data 
     through the pass pipeline
```

**Net effect:** The modified TLR pipeline provides downstream IlxGen with the correct parent class and split type parameter information, enabling correct IL emission under `realsig=true` without hacks. All ctps flow from ambient scope → Pass2 capture → Step3 packing → Pass4 call-site/binding rewriting → IlxGen IL generation, maintaining the strict separation between class-level and method-level generics throughout.

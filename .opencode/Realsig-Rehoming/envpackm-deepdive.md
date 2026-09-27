# envPackM Deep Dive  
### Pass2 / Pass3 in `InnerLambdasToTopLevelFuncs.fs`  
### Grounded in ILX split sites + ClosureHomes API

---

## 1. What `envPackM` Is

`envPackM` is a **per‑binding‑group (fclass)** description of:

> **“What must be available for the lifted body to run standalone.”**

Type (line 697):

```fsharp
type PackedReqdItems =
    { ep_etps   : Typars        // closure's required typars
      ep_aenvs  : Val list      // fresh carrier locals (one per free value)
      ep_pack   : Bindings      // let aenv_i = v_i     (at the pack/defn site)
      ep_unpack : Bindings      // let   v_i  = aenv_i  (inside fHat body) }
```

`envPackM : Zmap<BindingGroupSharingSameReqdItems, PackedReqdItems>` — keyed by fclass.  
Every TLR‑lifted function in the same mutually‑defined group shares one `PackedReqdItems`.

Comparer:

```
fclassOrder = Order.orderOn (fun b -> b.Vals) (List.order valOrder)
```

Your dump shows 3 fclasses:

```
+iter
+takeInner
+takeOuter
```

Each is its own group (no mutual recursion).  
Everything in the table is **derived**; the source is **Pass2**.

---

## 2. Where Each Field Comes From — Pass by Pass

---

### 2a. Pass1 — DetermineTLRAndArities

Produces:

- `tlrS` — lifted vals  
- `topValS` — genuine top‑levels  
- `arityM` — arity map  

Also: under `realsig`, Pass1 currently **refuses** TLR (see §4.3).

---

### 2b. Pass2 — DetermineReqdItems

Pass2 walks the impl file with `ExprFolder0`.

```fsharp
type ReqdItemsForDefn =
    { reqdTypars: Zset<Typar>
      reqdItems : Zset<ReqdItem>   // ReqdSubEnv v | ReqdVal v
      m: range }
```

#### Seeding free sets (line 553)

```fsharp
let frees = FreeInBindings tlrBs
let reqdTypars0 = frees.FreeTypars.FreeTypars |> Zset.elements
let reqdVals0   = frees.FreeLocals |> Zset.elements
let reqdVals0   = reqdVals0 |> List.filter (fclass.Contains >> not)
```

So:

- `reqdTypars0` = free typars in bodies  
- `reqdVals0`   = free values (excluding fclass members)

#### Growing sets during fold (line 533–551)

Depending on call shape:

- **arity‑met** → `ReqdSubEnv gv`  
- **arity‑short** → `ReqdVal gv`  
- **non‑TLR use** → `ReqdVal gv`

#### Typar propagation via sub‑envs

`CloseReqdTypars` (line 608):

```
reqdTypars(fclass) += reqdTypars(gv) for each ReqdSubEnv gv
```

This is why:

> **Inside a generic class, env.reqdTypars becomes exactly the class’s typars.**

Example from your dump:

- `takeInner` → `{T;U}`  
- `takeOuter` calls `takeInner` → inherits `{T;U}`  
- `takeOuter.ep_unpack` has 2 carriers because of the sub‑env.

---

### 2c. Pass3 — ChooseReqdItemPackings / FlatEnvPacks

For each fclass:

1. **Trans‑closure of vals**  
   Includes own free vals + sub‑env free vals.

2. **Filter**  
   Drop top‑levels, byrefs, generic‑constraint vals.

3. **Build carriers**  
   `mkCompGenLocal` fresh locals for each free val.

4. **Assemble PackedReqdItems**

```fsharp
ep_etps   = Zset.elements env.reqdTypars
ep_aenvs  = Zmap.values cmap
ep_pack   = [ aenv_i = v_i ]
ep_unpack = [ v_i = aenv_i ] @ sub‑env carriers
```

Key observation:

> **aenv carriers keep the original free value’s type**, including class typars.  
> This is why host typars must be ambient at the rehosting site.

---

### 2d. CreateNewValuesForTLR — Build fHat

```fsharp
let newTps    = envp.ep_etps @ f’s own tps
let newArgTys = types of aenvs @ original arg types
let fHatTy    = mkLambdaTy g newTps newArgTys ret
```

`fHat` is created with `ParentNone`, so ILX emits it as:

> **A module‑static method with all typars as method typars.**

This is the current (incorrect under realsig) behavior.

---

### 2e. Pass4 — Consumption Sites

Three places use `envPackM`:

- `fRebinding`  
- `fHatNewBinding`  
- `TransApp`

These are the sites that must be updated for rehosting.

---

## 3. The Rehosting Problem (One Line)

Under `--realsig+`, we want:

1. **fHat homed on the generic class**, not a module static  
2. **fHat’s type‑param list contains only its own method typars**  
   (class typars come from the host)

Today neither is true.

---

## 4. The Plan

Uses existing **ClosureHomes** machinery.  
No new pickled fields.  
No TypedTree changes.

---

### 4.1 Pass2 — Exclude Host Typars

Introduce:

```fsharp
type homing =
    | NoRehome
    | RehomeTo of TyconRef
```

Determine host via `ClosureHomeForVal`.

Subtract host typars from free typars:

```fsharp
reqdTypars0 = reqdTypars0all - hostTps
```

Result:

- `takeInner.reqdTypars = []`
- `ep_etps = []`

aenv carriers still mention `'T,'U` in their types — correct.

---

### 4.2 Pass3 — Add `ep_hostTyconRef`

Extend record:

```fsharp
ep_hostTyconRef : TyconRef option
```

All vals in an fclass share the same host.  
Abort if mixed hosts (should not occur).

---

### 4.3 Pass1 — Allow TLR Under realsig

Remove the refusal:

```fsharp
|| g.realsig && BodyReferencesTypeScopedPrivate e
```

Once fHat is homed inside the class, private access is legal.

---

### 4.4 Pass3 — Build fHat as a Member of the Host

If `ep_hostTyconRef = Some h`:

```fsharp
mkMemberLikeTy g h (method-only typars) (aenvs @ args) ret
markAsStaticMemberOf fHat h
```

This sets:

- `DeclaringEntity = host`
- `IsMember = true`

Alternative: “member-looking but not quite” wrapper without MemberInfo.

---

### 4.5 Pass4 — Rewrite Call Sites

Because `ep_etps` no longer contains host typars:

- `fRebinding`: `tyargsl = [tps]`
- `TransApp`: `tys = tys`
- `fHatNewBinding`: `fHat_tps = tps`

Three deletions of `ep_etps @`.

---

### 4.6 What We Do *Not* Change

- No change to `ReqdItemsForDefn`  
- No change to fclass structure  
- No change to `CloseReqdTypars`  
- No change to TypedTree or pickler  
- No change to TcGlobals (ClosureHomes already exists)  
- Only additive field: `ep_hostTyconRef`

---

## 5. Verification Plan

1. **Unit test:** After Pass2 under realsig+, `reqdTypars = []`.  
2. **Regression:** Under realsig‑, dumps identical to today.  
3. **ILX:** `--realsig+ --optimize+` matches known baseline.  
4. **Non‑generic hosts:** Should behave identically to today.  
5. **FSI:** Ensure ClosureHomes is cleared between fragments.

---

## 6. ClosureHomes Integration

Already implemented in `TcGlobals`:

- `RecordClosureHome`
- `RecordClosureHomeForVal`
- `ClosureHomeForVal`
- `ClearClosureHomes`

Used in:

- `CheckExpressions.fs` (lambda creation + let binding)
- Planned use in Pass2 + Pass3

---

## 7. Risks / Open Questions

- **ep_etps ordering** — Zset order nondeterministic  
- **Mixed-host fclasses** — abort if encountered  
- **Private member access** — verify correctness after rehome

---

## 8. Concrete Edit List

| Step | File | Section |
|------|------|---------|
| 1 | `InnerLambdasToTopLevelFuncs.fs` | §4.1 |
| 2 | same | Pass2 |
| 3 | same | Pass3 |
| 4 | same | Pass1 |
| 5 | same | Pass3 CreateNewValuesForTLR |
| 6 | same | Pass4 |
| 7 | Tests | — |

---

## One‑Line Summary

> **envPackM** bundles:  
> (a) flat typars (currently class + method),  
> (b) aenv carriers,  
> (c) pack bindings,  
> (d) unpack bindings.  
>
> Rehosting changes (a) to **method‑only typars** and tags fHat with its host, so Pass4 and Pass3 naturally stop re‑declaring ambient class typars.

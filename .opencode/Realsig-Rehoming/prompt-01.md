
# ✅ **Qwen Implementation Prompt: Rehosting Inner Lambdas Without Changing Pickled Form**

You are modifying **`InnerLambdasToTopLevelFuncs.fs`** to implement **correct rehosting of TLR‑lifted inner lambdas onto their declaring class**.  
Follow the plan below **exactly**.  
Your output must be **compilable**.  
**I will perform all testing.**

---

# 🔒 **Absolute Constraint: DO NOT CHANGE THE PICKLED FORMAT**

You must **not** introduce any change that alters the serialized TypedTree representation (“pickled form”).  
This means:

### ❌ Do NOT set:
- `Val.MemberInfo`
- `Val.IsMember = true`
- `ValReprInfo`
- `Parent = ParentSome(...)` in a way that changes pickled shape
- Any field that affects the public signature or metadata surface

### ✔ DO set:
- `DeclaringEntity = Some(hostTyconRef)`  
  **Only this. Nothing else.**

This ensures:

- fHat is homed inside the class for private‑member access  
- Host typars become ambient  
- ILX emits correct code  
- Pickled form remains **identical** under `realsig-` and `realsig+`

This is the **non‑negotiable invariant**.

---

# 📘 **Implement the Rehosting Plan**

Implement the following changes in `InnerLambdasToTopLevelFuncs.fs`:

---

## **1. Pass2 — Exclude host typars from `reqdTypars`**

Use:

```fsharp
g.ClosureHomeForVal f
```

to determine the host class for each fclass.

Then subtract host typars from the free‑typar set:

```fsharp
reqdTypars0 = freeTypars - hostTypars
```

This ensures:

```
ep_etps = method-only typars
```

and prevents class typars from being re-declared as method typars.

---

## **2. Pass3 — Add `ep_hostTyconRef` to `PackedReqdItems`**

Extend the record:

```fsharp
ep_hostTyconRef : TyconRef option
```

All vals in an fclass share the same host.  
Abort if mixed hosts appear.

This field is **not pickled**, so it is safe.

---

## **3. Pass1 — Allow TLR under realsig**

Remove the refusal:

```fsharp
g.realsig && BodyReferencesTypeScopedPrivate e
```

Once rehosting is implemented, private access is safe.

---

## **4. Pass3 — Build fHat as a “member-like” value homed inside the class**

When:

```fsharp
envp.ep_hostTyconRef = Some host
```

then:

### ✔ Build fHat’s type using `mkMemberLikeTy`  
This ensures host typars are ambient.

### ❌ Do NOT set `MemberInfo`  
### ❌ Do NOT set `IsMember = true`  
### ❌ Do NOT set any ValReprInfo that changes pickled form

### ✔ Only set:

```fsharp
fHat.DeclaringEntity <- Some(host)
```

This gives ILX the correct parent type **without changing pickled form**.

The helper remains a module-static value in the TypedTree, but ILX sees it as homed inside the class.

This is the correct shape.

---

## **5. Pass4 — Remove host typars from call sites**

Because `ep_etps` no longer contains host typars:

- In `fRebinding`:  
  ```fsharp
  tyargsl = [tps]
  ```

- In `TransApp`:  
  ```fsharp
  tys = tys
  ```

- In `fHatNewBinding`:  
  ```fsharp
  fHat_tps = tps
  ```

Delete all uses of:

```
ep_etps @ tps
```

This ensures call sites pass only method typars.

---

## **6. No other changes**

Do **not** modify:

- TypedTree types  
- Pickler  
- ReqdItemsForDefn  
- fclass structure  
- CloseReqdTypars  
- TcGlobals (ClosureHomes is already correct)

Only implement the changes described above.

---

# 📌 **Required Invariants**

Your implementation must satisfy:

- Host typars are ambient at the rehosting site  
- fHat is homed inside the class via `DeclaringEntity` only  
- fHat is **not** a member in the pickled form  
- ep_etps contains only method typars  
- aenv carriers retain class typars in their types  
- Call sites stop passing host typars  
- The compiler still builds successfully

I will test correctness.

---

# 🧩 **Deliverables**

Produce:

1. **A patch or code edits** implementing the plan  
2. **No pickled‑form changes**  
3. **Compilable code**  
4. **No testing — I will test**

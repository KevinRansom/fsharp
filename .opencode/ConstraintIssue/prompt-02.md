# ? **Copy?and?paste prompt for Qwen (switch to using closureHomes)**

You are modifying the F# compiler.  
Your task is to update the TLR pipeline so that it **uses the newly?wired declaring?type information stored in `TcGlobals.closureHomes`** instead of `TryDeclaringEntity`, which does not work for closures because they are always marked `ParentNone`.

You must replace all uses of `TryDeclaringEntity` in the TLR homing logic with lookups into `closureHomes`, keyed by the lambda’s `Unique`.

You must not change semantics, pickling, or AST shapes.  
You must only change how the homing type and its typars are retrieved.

---

## **What you must do**

### **1. Stop using `TryDeclaringEntity` for closures**

In `InnerLambdasToTopLevelFuncs.fs`, the current code determines ambient class typars using:

```fsharp
match b.Var.TryDeclaringEntity with
| Parent tcref when not tcref.IsModuleOrNamespace -> tcref.Typars
| _ -> []
```

This is incorrect for closures, because closure vals always have:

```
ParentNone
```

You must remove this logic.

---

### **2. Replace it with a lookup into `g.closureHomes`**

Use the lambda’s `Unique` to retrieve the declaring type:

```fsharp
let homeOpt =
    match g.closureHomes.TryFind b.Expr.Unique with
    | Some tcref -> Some tcref
    | None -> None
```

Then compute ambient class typars from the actual declaring type:

```fsharp
let ambientCtps0 =
    match homeOpt with
    | Some tcref -> tcref.Typars
    | None -> []
```

This replaces the old `TryDeclaringEntity`?based logic entirely.

---

### **3. Use the new ambientCtps0 in the existing realsig+ typar?splitting logic**

Replace:

```fsharp
let ambientCtps0 =
    tlrBs
    |> List.map (fun b ->
        match b.Var.TryDeclaringEntity with
        | Parent tcref when not tcref.IsModuleOrNamespace -> tcref.Typars
        | _ -> [])
    |> List.collect id
    |> Zset.ofList typarOrder
```

with:

```fsharp
let ambientCtps0 =
    tlrBs
    |> List.map (fun b ->
        match g.closureHomes.TryFind b.Expr.Unique with
        | Some tcref -> tcref.Typars
        | None -> [])
    |> List.collect id
    |> Zset.ofList typarOrder
```

This ensures the homing type’s typars come from the actual declaring type captured during typechecking.

---

### **4. Thread closureHomes through all TLR passes**

Ensure the environment record passed through:

- pass1 (TLR selection)
- pass2 (reqdItems)
- step3 (env packing)
- pass4 (rewriting)
- pass5 (final copy)

contains:

```fsharp
closureHomes : Map<Unique, TyconRef>
```

Populate it from `g.closureHomes`.

---

### **5. Use closureHomes in ILGen’s MakeTopLevelRepresentationDecisions**

Inside `MakeTopLevelRepresentationDecisions`, retrieve the declaring type:

```fsharp
let homeOpt =
    match env.closureHomes.TryFind lambdaExpr.Unique with
    | Some tcref -> Some tcref
    | None -> None
```

You may now **use** this value to determine:

- the correct homing class  
- the correct typars for the lifted helper  
- the correct IL nesting  
- the correct generic instantiation  

This replaces all uses of `TryDeclaringEntity` for closures.

---

## **Constraints**

You must not:

- modify any pickled type  
- modify `Expr.Lambda`  
- modify `Val` or `ValOptionalData`  
- change closure lifting semantics  
- change IL shape except where homing is corrected  
- change access control behavior  
- introduce new fields into AST nodes  

All new information must come from `TcGlobals.closureHomes`.

---

## **Deliverables**

1. All uses of `TryDeclaringEntity` in TLR replaced with `closureHomes` lookups.  
2. Ambient class typars computed from the actual declaring type.  
3. closureHomes threaded through all TLR passes.  
4. closureHomes used in `MakeTopLevelRepresentationDecisions`.  
5. No changes to pickling or AST shapes.

---

## **End of prompt**

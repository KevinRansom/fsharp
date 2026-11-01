# ? **Follow?up Prompt for Qwen — Update TLR Homing Logic to Use Dual?Key closureHomes**

You have already updated `TcGlobals.closureHomes` to use a **dual?key** structure:

- `byUnique : Map<Unique, TyconRef>`  
- `byVal    : Map<Val, TyconRef>`

You have also populated:

- `byUnique` in `TcIteratedLambdas`  
- `byVal` in the let/letrec binding path  

Now your task is to **switch the TLR homing logic from `TryDeclaringEntity` to the dual?key lookup**.

You must not change pickling or AST shapes.

---

## **1. Replace homing logic in TLR pass2 (accBinds)**

In `InnerLambdasToTopLevelFuncs.fs`, inside:

```
Pass2_DetermineReqdItems.accBinds
```

the current realsig+ ambient?typar logic uses:

```fsharp
b.Var.TryDeclaringEntity
```

Replace this with a dual?key lookup:

```fsharp
let homeOpt =
    match g.closureHomes.byVal.TryFind b.Var with
    | Some tcref -> Some tcref
    | None ->
        match TryFindLambdaUnique b.Expr with
        | Some u -> g.closureHomes.byUnique.TryFind u
        | None -> None
```

Then compute ambient typars from the homing type:

```fsharp
let ambientCtps0 =
    match homeOpt with
    | Some tcref -> tcref.Typars
    | None -> []
```

This replaces all uses of `TryDeclaringEntity` for closure homing.

---

## **2. Update homing lookup in MakeTopLevelRepresentationDecisions**

In the ILGen phase, inside:

```
MakeTopLevelRepresentationDecisions
```

you must use the same dual?key lookup.

When determining the homing type for a lifted helper `Val`:

```fsharp
let homeOpt =
    match g.closureHomes.byVal.TryFind v with
    | Some tcref -> Some tcref
    | None ->
        match TryFindLambdaUnique lambdaExpr with
        | Some u -> g.closureHomes.byUnique.TryFind u
        | None -> None
```

This ensures ILGen uses the correct declaring type for closures.

---

## **3. Remove all uses of TryDeclaringEntity for closure homing**

Anywhere TLR or ILGen previously used:

```fsharp
b.Var.TryDeclaringEntity
```

replace it with the dual?key lookup above.

Do **not** remove `TryDeclaringEntity` entirely — only stop using it for closure homing.

---

## **4. Do not modify any AST or pickled types**

You must not:

- add fields to `Expr`, `Val`, or `ValOptionalData`
- change pickling
- change closure lifting semantics
- change IL shape except where homing is corrected

All homing information must come from `TcGlobals.closureHomes`.

---

## **Deliverables**

1. All TLR homing logic updated to use dual?key lookup  
2. All ILGen homing logic updated to use dual?key lookup  
3. All uses of `TryDeclaringEntity` removed from closure homing  
4. No changes to pickling or AST shapes  

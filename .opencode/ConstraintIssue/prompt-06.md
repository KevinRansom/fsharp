# ? **Third Prompt for Qwen — Update Ambient?Typar Splitting + Homing Decisions Using closureHomes**

You have already implemented the dual?key `closureHomes` table:

- `closureHomes.byUnique : Map<Unique, TyconRef>`  
- `closureHomes.byVal    : Map<Val, TyconRef>`

You have also populated:

- `byUnique` in `TcIteratedLambdas`  
- `byVal` in the let/letrec binding path  

Now your task is to update the **ambient?typar splitting logic** and the **homing?class decision logic** in the TLR pipeline so they use the homing type from `closureHomes` instead of `TryDeclaringEntity`.

You must not change pickling or AST shapes.

---

## **1. Update ambient?typar splitting in Pass2 (accBinds)**

In `InnerLambdasToTopLevelFuncs.fs`, inside:

```
Pass2_DetermineReqdItems.accBinds
```

the current realsig+ ambient?typar logic uses:

```fsharp
match b.Var.TryDeclaringEntity with
| Parent tcref -> tcref.Typars
| _ -> []
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

let ambientCtps0 =
    match homeOpt with
    | Some tcref -> tcref.Typars
    | None -> []
```

This ensures ambient typars come from the actual declaring type captured during typechecking.

---

## **2. Update homing?class decision (HostingClass vs HelperClass)**

In Pass1, the homing decision is currently:

```fsharp
if g.realsig then HostingClass else HelperClass
```

This must be refined so that:

- closures whose homing type is a class ? `HostingClass`
- closures whose homing type is a module ? `HelperClass`

Replace the decision with:

```fsharp
let homeOpt =
    match g.closureHomes.byVal.TryFind f with
    | Some tcref -> Some tcref
    | None ->
        match TryFindLambdaUnique e with
        | Some u -> g.closureHomes.byUnique.TryFind u
        | None -> None

let homing =
    match homeOpt with
    | Some tcref when not tcref.IsModuleOrNamespace -> HostingClass
    | _ -> HelperClass
```

This uses the actual declaring type instead of the synthetic `TryDeclaringEntity` value.

---

## **3. Update ambient?typar filtering in Pass2**

Pass2 currently splits free typars into:

- ambient class typars  
- non?ambient typars  

Replace the ambient?typar detection with:

```fsharp
let ambientCtps0 =
    match homeOpt with
    | Some tcref -> tcref.Typars
    | None -> []
```

Then compute:

```fsharp
let ctpsUsed = Zset.inter freeTypars0 ambientCtps0
let reqdTypars0 = Zset.diff freeTypars0 ctpsUsed |> Zset.elements
```

This ensures the closure’s environment excludes class?typars belonging to the homing type.

---

## **4. Update homing lookup in MakeTopLevelRepresentationDecisions**

Inside ILGen’s:

```
MakeTopLevelRepresentationDecisions
```

replace any use of `TryDeclaringEntity` with:

```fsharp
let homeOpt =
    match g.closureHomes.byVal.TryFind v with
    | Some tcref -> Some tcref
    | None ->
        match TryFindLambdaUnique lambdaExpr with
        | Some u -> g.closureHomes.byUnique.TryFind u
        | None -> None
```

Use `homeOpt` to determine:

- the correct IL nesting  
- the correct generic instantiation  
- the correct hosting class  

---

## **Constraints**

- Do not modify any pickled type.  
- Do not add fields to `Expr`, `Val`, or `ValOptionalData`.  
- Do not change closure lifting semantics.  
- Do not change IL shape except where homing is corrected.  
- All homing information must come from `TcGlobals.closureHomes`.

---

## **Deliverables**

1. Ambient?typar splitting updated to use dual?key lookup  
2. HostingClass vs HelperClass decision updated to use dual?key lookup  
3. MakeTopLevelRepresentationDecisions updated to use dual?key lookup  
4. No changes to pickling or AST shapes  

You are modifying the F# compiler.  
Your task is to **switch the TLR homing logic from `TryDeclaringEntity` to the new `closureHomes` side table**, using a **dual?key approach** that matches the *actual* TypedTree and TLR pipeline:

- key by **Val** (the bound value `f` created in the let/letrec binding path)  
- key by **Lambda Unique** (the unique on `Expr.Lambda` / `Expr.TyLambda`, recoverable via `TryFindLambdaUnique`)  

This dual?key approach is required because:

- the helper `Val` **does not exist** inside `TcIteratedLambdas`  
- lambda uniques **do exist** there, but are not stable across optimizer passes  
- the bound `Val` **does exist** in TLR and ILGen, and is stable  
- some TLR passes only have the `Val`  
- some TLR passes only have the `Expr`  
- `TryDeclaringEntity` is always `ParentNone` for closures and cannot be used  

You must not change pickling or AST shapes.

---

## **1. Use `TryFindLambdaUnique` instead of `.Unique`**

TLR already provides:

```fsharp
let TryFindLambdaUnique expr = ...
```

Anywhere earlier prompts referenced:

```fsharp
b.Expr.Unique
lambdaExpr.Unique
```

replace with:

```fsharp
match TryFindLambdaUnique b.Expr with
| Some u -> ...
| None -> ...
```

You must **never** call `.Unique` directly on an `Expr`.

---

## **2. Implement dual?key closureHomes**

Modify `TcGlobals.closureHomes` so it stores **both** keys:

```fsharp
type ClosureHomes =
    {
        byVal    : Map<Val, TyconRef>
        byUnique : Map<Unique, TyconRef>
    }

val mutable closureHomes : ClosureHomes
```

Initialize both maps to empty.

---

## **3. Populate the Unique key in TcIteratedLambdas**  
*(the only key available at this stage)*

In `TcIteratedLambdas` (CheckExpressions.fs), after constructing the lambda expression:

```fsharp
let u = lambdaExpr.unique   // from Expr.Lambda
let home = env.eFamilyType.Value   // TyconRef

g.closureHomes <-
    { g.closureHomes with
        byUnique = g.closureHomes.byUnique.Add(u, home) }
```

At this point:

- **the helper Val does not exist yet**  
- only the lambda unique is available  
- so only `byUnique` can be populated here  

This matches the real compiler pipeline.

---

## **4. Populate the Val key in the let/letrec binding path**  
*(the moment the bound Val `f` actually exists)*

In the binding creation path (`TcLetBinding` / `AnalyzeAndMakeAndPublishRecursiveValues`), after constructing the bound `Val`:

```fsharp
let v = theBoundVal   // b.Var in TLR
match TryFindLambdaUnique rhsExpr with
| Some u ->
    match g.closureHomes.byUnique.TryFind u with
    | Some home ->
        g.closureHomes <-
            { g.closureHomes with
                byVal = g.closureHomes.byVal.Add(v, home) }
    | None -> ()
| None -> ()
```

This ties the stable `Val` to the homing type recorded earlier via the lambda unique.

This is the correct place to populate `byVal`.

---

## **5. Replace ambient?typar logic in TLR pass2 with dual?key lookup**

In `Pass2_DetermineReqdItems.accBinds`, replace:

```fsharp
b.Var.TryDeclaringEntity
```

with:

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

This is where the homing type’s typars actually matter.

---

## **6. Use dual?key lookup in MakeTopLevelRepresentationDecisions**

This function receives:

```fsharp
(amap, scope, ccu, g, expr)
```

It does **not** receive an env record.

When you need the homing type for a lifted helper `Val`:

```fsharp
let homeOpt =
    match g.closureHomes.byVal.TryFind v with
    | Some tcref -> Some tcref
    | None ->
        match TryFindLambdaUnique lambdaExpr with
        | Some u -> g.closureHomes.byUnique.TryFind u
        | None -> None
```

This is the correct place to use the `Val` key, because ILGen always knows the helper `Val`.

---

## **Constraints**

- Do not modify any pickled type.  
- Do not add fields to `Expr`, `Val`, or `ValOptionalData`.  
- Do not change closure lifting semantics.  
- Do not change IL shape except where homing is corrected.  
- All new information must come from `TcGlobals.closureHomes`.

---

## **Deliverables**

1. closureHomes updated to store both Val and Unique keys  
2. TcIteratedLambdas populates the Unique key  
3. let/letrec binding path populates the Val key  
4. TLR pass2 uses whichever key is available  
5. MakeTopLevelRepresentationDecisions uses the Val key  
6. No changes to pickling or AST shapes  

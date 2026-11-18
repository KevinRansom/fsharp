# ? **Prompt for Qwen — Update closureHomes to Dual?Key (Val + Unique)**  
*(No changes to TLR homing yet)*

You are modifying the F# compiler.  
Your task is **only** to update the `closureHomes` side table in `TcGlobals` so that it supports a **dual?key lookup**:

- key by **Lambda Unique** (from `Expr.Lambda` / `Expr.TyLambda`, via `TryFindLambdaUnique`)  
- key by **Val** (the bound value created later in the let/letrec binding path)

This prompt does **not** ask you to modify TLR homing logic or `TryDeclaringEntity`.  
We will do that in a later prompt.

You must not change pickling or AST shapes.

---

## **1. Update TcGlobals.closureHomes to store both keys**

Replace the existing single?map `closureHomes` with a dual?key structure:

```fsharp
type ClosureHomes =
    {
        byVal    : Map<Val, TyconRef>
        byUnique : Map<Unique, TyconRef>
    }

val mutable closureHomes : ClosureHomes
```

Initialize both maps to empty in the TcGlobals constructor.

---

## **2. Populate the Unique key in TcIteratedLambdas**  
*(the only key available at this stage)*

Inside `TcIteratedLambdas` (CheckExpressions.fs), after constructing the lambda expression:

```fsharp
let u = lambdaExpr.unique
let home = env.eFamilyType.Value   // TyconRef

g.closureHomes <-
    { g.closureHomes with
        byUnique = g.closureHomes.byUnique.Add(u, home) }
```

Notes:

- The closure helper `Val` does **not** exist yet at this point.  
- Only the lambda unique is available.  
- So only `byUnique` is populated here.

---

## **3. Populate the Val key in the let/letrec binding path**  
*(the moment the bound Val actually exists)*

In the binding creation path (`TcLetBinding` / `AnalyzeAndMakeAndPublishRecursiveValues`), after constructing the bound `Val`:

```fsharp
let v = theBoundVal
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

---

## **4. Do not change any TLR logic yet**

Do **not** modify:

- `TryDeclaringEntity`
- ambient?typar logic
- Pass1/Pass2/Pass4
- ILGen homing decisions

We will update those in a separate prompt after this dual?key table is implemented.

---

## **Constraints**

- Do not modify any pickled type.  
- Do not add fields to `Expr`, `Val`, or `ValOptionalData`.  
- Do not change closure lifting semantics.  
- Do not change IL shape.  
- Only update `TcGlobals.closureHomes` and the two population sites.

---

## **Deliverables**

1. `closureHomes` updated to dual?key structure  
2. Unique key populated in `TcIteratedLambdas`  
3. Val key populated in let/letrec binding path  
4. No other compiler logic changed  

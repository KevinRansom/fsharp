**You are modifying the F# compiler.  
Your task is to add a mechanism that preserves the declaring type of inner lambdas and pass that information through to `MakeTopLevelRepresentationDecisions`.  
You must not use the information in that function; simply pass it through and silence unused?value warnings with `ignore`.  
The mechanism must be invisible to the pickle machinery.**

It is the follow on from analysis you did that created this file:
    .opencode\ConstraintIssue\InnerLambdaAnalysis.md

---

## **Requirements**

### **1. Capture the declaring type at the last point it exists**

In `TcIteratedLambdas` (in `CheckExpressions.fs`), before calling `KeepFamilyRegionForClosure`, capture:

```fsharp
let homeTypeOpt = env.eFamilyType   // TyconRef option
```

This is the last moment the compiler knows the enclosing type of an inner lambda.

---

### **2. Add a compiler?internal side table keyed by `Unique`**

Add a mutable map to the compiler environment used during TLR/ILGen (for example, inside the environment record passed through closure?lifting):

```fsharp
val mutable closureHomes : Map<Unique, TyconRef>
```

Initialize it to `Map.empty`.

This table:

- must **not** be serialized  
- must **not** be added to any pickled type  
- must exist only in the in?memory compiler state

---

### **3. Populate the table when constructing the typed lambda**

After calling `mkMultiLambda` inside `TcIteratedLambdas`, insert:

```fsharp
let expr = mkMultiLambda m vspecs (bodyExpr, resultTy)

match homeTypeOpt with
| Some tyconRef ->
    cenv.closureHomes <- cenv.closureHomes.Add(expr.Unique, tyconRef)
| None -> ()
```

Do not modify `Expr.Lambda` itself.

---

### **4. Thread the table into TLR and ILGen**

Ensure that `closureHomes` is threaded into:

- `InnerLambdasToTopLevelFuncs`
- `MakeTopLevelRepresentationDecisions`

Add parameters or extend the environment record so these functions receive the table.

---

### **5. Retrieve and ignore the value in `MakeTopLevelRepresentationDecisions`**

Inside `MakeTopLevelRepresentationDecisions`, retrieve the home type for a lambda:

```fsharp
let homeOpt =
    match env.closureHomes.TryFind lambdaExpr.Unique with
    | Some tyconRef -> Some tyconRef
    | None -> None

ignore homeOpt
```

You must not use the value yet — only pass it through.

---

## **Constraints**

- Do **not** modify any pickled type (`Expr`, `Val`, `ValOptionalData`, etc.).
- Do **not** change closure lifting behavior.
- Do **not** change access control behavior.
- Do **not** change IL generation.
- The new mechanism must be metadata only, threaded but unused.

---

## **Deliverables**

1. The new `closureHomes` table definition.  
2. The modification to `TcIteratedLambdas`.  
3. The threading of the table into TLR.  
4. The retrieval and `ignore` call inside `MakeTopLevelRepresentationDecisions`.  
5. Zero changes to pickled data structures.


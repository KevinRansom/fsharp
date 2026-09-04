# Linq.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the F# compiler. This is the public API signature for the quotation-to-LINQ translator, `LeafExpressionConverter`, which converts a subset of F# quotations into `System.Linq.Expressions` expression trees so F# query expressions can be consumed by LINQ providers.

## Namespace
- `Microsoft.FSharp.Linq.RuntimeHelpers`

## Module: `LeafExpressionConverter`
### Functions (public)
- `ImplicitExpressionConversionHelper : 'T -> Expression<'T>` — marker used inside quotations to signal a specific conversion when building a LINQ expression. Not for direct use. When converting F# expression trees to LINQ, `<c>LinqExpressionHelper(e)</c>` transforms the same as `e`, so it acts purely as a marker.
- `MemberInitializationHelper : 'T -> 'T` — marker recognizing a LINQ member-initialization pattern in a quotation. Not for direct use.
- `NewAnonymousObjectHelper : 'T -> 'T` — marker recognizing anonymous-object construction in a quotation. Not for direct use.
- `QuotationToExpression : Expr -> Expression` — converts a subset of F# quotations to a LINQ expression, for the subset represented by the C# expression syntax.
- `QuotationToLambdaExpression : Expr<'T> -> Expression<'T>` — converts a typed F# quotation to a LINQ lambda expression.
- `EvaluateQuotation : Expr -> objnull` — evaluates a subset of F# quotations by first converting to a LINQ expression.
- `SubstHelper : Expr * Var array * objnull array -> Expr<'T>` — runtime helper used to evaluate nested quotation literals (generalized result type).
- `SubstHelperRaw : Expr * Var array * objnull array -> Expr` — runtime helper used to evaluate nested quotation literals (untyped).

### Active pattern (internal)
- `val internal (|SpecificCallToMethod|_|) : RuntimeMethodHandle -> (Expr -> (Expr option * Reflection.MethodInfo * Expr list) option)` — matches quotation trees for a specific method given its runtime method handle; used internally to recognize calls to the many operators.

## Key design notes
- All marker functions are documented as "should not be called directly" (with obsolete-comment intent); they raise `NotSupportedException` if ever executed.
- The `.fsi` exposes only the public API plus one internal active pattern; the internal translation machinery (`ConvExprToLinqInContext`, `ConvEnv`, operator active patterns, predicates) is hidden.
- The namespace also declares the namespacedoc "Library functionality associated with converting F# quotations to .NET LINQ expression trees."

## Notable behavior
- `QuotationToExpression`/`EvaluateQuotation` work only on the subset of quotations congruent with C# LINQ expression syntax; the tuple field of `QuotationToLambdaExpression` set by generic `Expr<'T>` mapping.
- `SubstHelper*` are designed for evaluation of nested quotation literals (i.e., inner `` `...` `` quotations encountered during translation).
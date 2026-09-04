# Linq.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the F# compiler. This file implements the bridge between F# quotations and .NET LINQ expression trees: `LeafExpressionConverter` turns a subset of F# quotations into `System.Linq.Expressions.*` nodes, which is what enables LINQ providers (e.g. Entity Framework) to translate F# query expressions into SQL. It is a runtime support module, not part of the compiler pipeline itself.

## Namespace
- `Microsoft.FSharp.Linq.RuntimeHelpers`

## Module: `LeafExpressionConverter`
The entire implementation lives in this one module.

### Marker helpers (not callable from user code)
Each raises `NotSupportedException` if called directly; they exist so the quotation-to-LINQ translator can recognize them as markers inside quotations.
- `MemberInitializationHelper: ('T -> 'T)` — marks a LINQ "member initialization" pattern (object init `new Foo(a=1, b=2)`) inside a quotation. Emitted by `QueryExtensions.fs` (C#-style member init), also handled via active pattern `MemberInitializationQ`.
- `NewAnonymousObjectHelper: ('T -> 'T)` — marks construction of an anonymous object (`new { a = 1 }`), handled via `NewAnonymousObjectQ`.
- `ImplicitExpressionConversionHelper: ('T -> Expression<'T>)` — marker satisfying C#'s design where the C# compiler passes an argument/type `T` where a `Expression<T>` is expected; the translator simply erases this marker and rewrites the inner expression.

### Internal types and constants
- `type ConvEnv` (`[<NoEquality; NoComparison>]`) — carries `varEnv : Map<Var, Expression>`, the mapping from F# quotation variables to already-created LINQ `ParameterExpression`s.
- `asExpr` — upcasts any expression to `Expression`.
- `isNamedType typ` — true for array/byref/pointer-free types (used for `equivHeadTypes`).
- `getUnionCaseCoercionType objOpt declaringType` — when a property is declared on a specific union case class whose base is itself a union type, returns `Some declaringType` so the object argument can be `Expression.TypeAs`-coerced.
- `equivHeadTypes ty1 ty2` — head-type equivalence (ignores generic arguments), also used by `NullableConstruction` and string-concat special-casing.
- `isFunctionType typ`, `getFunctionType typ` — recognize/peel F# function types `A -> B`.
- `StringConcat` — cached `MethodInfo` for `String.Concat(obj, obj)` used for C#-compatible `+` on strings.
- `SubstHelperRaw`, `SubstHelper<'T>` — runtime helpers that substitute free variables of a nested quotation with given values (`Var array` × `objnull array`); backing handlers for the LINQ expression tree `QuoteTyped`/`QuoteRaw` cases via `substHelperMeth`/`substHelperRawMeth`.
- `showAll` — `BindingFlags.Public ||| BindingFlags.NonPublic` used when precomputing reflection info.
- `getNonNullableType typ` — strips `Nullable<>`.
- `(-->)` — sugar for `FSharpType.MakeFunctionType`.

### "Can LINQ Expressions handle this natively?" predicates
Each determines whether LINQ's built-in expression node constructors are legal for a given type; otherwise the translator falls back to the corresponding F# operator as a user-defined method (per `CodeDom`/`System.Linq.Expressions` internal checks in dotnet/runtime):
- `isLinqExpressionsInteger typ` — integral primitive types (byte/sbyte/int16/int32/int64/uint16/uint32/uint64), non-enum, nullable stripped.
- `isLinqExpressionsSimpleShift left right` — integer with `int` shift count.
- `isLinqExpressionsArithmeticType typ` — adds float/double to the integral set.
- `isLinqExpressionsArithmeticTypeButNotUnsignedInt typ` — arithmetic minus unsigned ints (used for unary negate, which LINQ can't do on unsigned).
- `isLinqExpressionsIntegerOrBool typ` — integral types plus bool (bitwise/unary not).
- `isLinqExpressionsNumeric typ` — integral/floating plus char (comparison operations).
- `isLinqExpressionsStructurallyEquatable typ` — numeric, bool, or enum.
- `isLinqExpressionsComparable typ` — same as numeric.
- `isLinqExpressionsEquatable typ` — structurally equatable plus `obj`.
- `isLinqExpressionsConvertible source dest` — identity/reference primitive conversions, including boxed-enum handling and reference conversions (down/up/interface), mirroring `TypeUtils` in dotnet/runtime.

### Active patterns for quotation matching
`SpecificCallToMethodInfo minfo` matches `Call` expressions to a specific method (by metadata token + generic method definition); `(|SpecificCallToMethod|_|)` wraps a method handle. On top of these, the module defines a large set of match helpers used by `ConvExprToLinqInContext` to pattern-match F# operator/function calls inside quotations:
- Comparisons: `PhysicalEqualityQ`, `GenericEqualityQ`, `EqualsQ`, `NotEqQ`, `GreaterQ`, `GreaterEqQ`, `LessQ`, `LessEqQ`.
- Non-structural/static comparisons (e.g. `NonStructuralComparison.(=)`): `StaticEqualsQ`, `StaticGreaterQ`, etc.
- Nullable operators on both "argument nullable" and "both nullable" variants: `NullableEqualsQ`, `EqualsNullableQ`, `NullableEqualsNullableQ`, `NullableGreaterQ`, `...Eq...`, `...Less...`, etc.
- Arithmetic: `NullablePlusQ`, `NullablePlusNullableQ`, `PlusNullableQ` (+ same for minus, multiply, divide, modulo).
- Plain operators: `NotQ`, `NegQ`, `PlusQ`, `DivideQ`, `MinusQ`, `MultiplyQ`, `ModuloQ`, `ShiftLeftQ`, `ShiftRightQ`, `BitwiseAndQ`, `BitwiseOrQ`, `BitwiseXorQ`, `BitwiseNotQ`.
- Checked operators: `CheckedNeg`, `CheckedPlusQ`, `CheckedMinusQ`, `CheckedMultiplyQ`.
- Conversions: `ConvCharQ`, `ConvDecimalQ`, `ConvFloatQ`, `ConvFloat32Q`, `ConvSByteQ`, `ConvInt16Q`, `ConvInt32Q`, `ConvIntQ`, `ConvInt64Q`, `ConvByteQ`, `ConvUInt16Q`, `ConvUInt32Q`, `ConvUInt64Q`, `ConvIntPtrQ`, `ConvUIntPtrQ`, plus `ConvInt8Q`/`ConvUInt8Q`/`ConvDoubleQ`/`ConvSingleQ` (which target `Microsoft.FSharp.Core.ExtraTopLevelOperators.ToSByte`/`ToByte`/`ToDouble`/`ToSingle`), checked variants `CheckedConv*Q`, and nullable variants `ConvNullable*Q`.
- Special: `MakeDecimalQ` (decimal literals), `UnboxGeneric`, `TypeTestGeneric`, `ArrayLookupQ` (single type-parameter `GetArray`), `ImplicitExpressionConversionHelperQ`, `MemberInitializationHelperQ`, `NewAnonymousObjectHelperQ`.
- `(|GenericArgs|)` extracts a call's generic arguments; `(|Sequentials|)` flattens sequential expressions into a list.
- `(|MemberInitializationQ|_|)` extracts `(init, propSets)` from a `MemberInitializationHelper` call.
- `(|NewAnonymousObjectQ|_|)` extracts `(ctor, args)` from a `NewAnonymousObjectHelper` call.
- `(|NullableConstruction|_|)` detects `new Nullable<_>(arg)` so it can become `Expression.Convert` (as C# emits).

### Core translation
- `ConvExprToLinqInContext env inp : Expression` — recursive quotation→LINQ translator handling: `Var`, `Value`, `AndAlso`, `OrElse`, `Coerce`, `UnboxGeneric`, `TypeTest`, `FieldGet`, `TupleGet` (flattens nested tuples), `PropertyGet`/`PropertySet`, `Call` (with the many operator special-cases listed above, member init, anonymous object init, string concat), `CallWithWitnesses` (injects witness args then re-translates), `Application` (with `InvokeFast2/3/4` optimizations for curried calls, gated by `!NO_CURRIED_FUNCTION_OPTIMIZATIONS`, and plain `Invoke`), `NewRecord`, `NewArray`, `DefaultValue`, `NewUnionCase`, `UnionCaseTest` (tag-method/property comparison), `NewObject`, `NewDelegate`, `NewTuple` (builds nested `Expression.New` for large tuples), `IfThenElse`, `QuoteTyped`/`QuoteRaw` (via `SubstHelper` calls substituting free vars), `Let` (properly scoped `Expression.Block` with assign — avoids `Lambda.Invoke` which EF Core can't translate), `Lambda` (to `Func<_,_>`/`Action<_>` then `FuncConvert.ToFSharpFunc`), `Sequential`, `VarSet`, `FieldSet`, `PropertySet`.
- Unsupported quotations raise `NotSupportedException` via `failConvert` (message includes the printed quotation).
- Operator translation helpers: `transUnaryOp`, `transShiftOp`, `transBinOp`, `transBoolOpNoWitness`, `transBoolOp`, `transConv` — each emits a built-in LINQ node when legal, otherwise binds the corresponding F# dynamic operator as a generic user-defined method.
- `ConvObjArg env objOpt coerceTo` — handles optional object arguments (static calls pass `null`) with optional union-case coercion.
- `ConvExprsToLinq`, `ConvVarToLinq`, `ConvExprToLinq` (empty env), `QuotationToExpression`, `QuotationToLambdaExpression`.
- `EvaluateQuotation e : objnull` — compiles a quotation through LINQ: short-circuits literal `Value` expressions; wraps unit-returning expressions in an `Action<unit>` (since `Func` can't return `void`); re-raises the inner exception of `TargetInvocationException`; on `FX_NO_QUOTATIONS_COMPILE` raises `NotSupportedException`.

## Key design note
`Let` and sequential/assignment handling were reworked so generated trees use `Expression.Block` + `Expression.Assign` rather than `Lambda.Invoke`, because EF Core cannot translate `Invoke` nodes. `Nullables` are constant-vs-null comparisons: F# follows C# semantics (`liftToNull = false`).

## Notable behavior
- The translator intentionally handles only the subset of quotations expressible as C# LINQ expression syntax; anything else `failConvert`.
- Marker helpers must never be executed — they exist purely to be recognized inside quotations and are erased during translation (issue: extra top-level operator conversions `ToSByte`/`ToByte`/`ToDouble`/`ToSingle` are also recognized).
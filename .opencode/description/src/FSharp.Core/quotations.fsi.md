# quotations.fsi

## Overview

This is the signature (interface) file for `quotations.fs`, in namespace `Microsoft.FSharp.Quotations`. It declares the public API for F# code quotations: the `Var` and `Expr`/`Expr<'T>` types (with all their construction members), the `Patterns`, `DerivedPatterns`, and `ExprShape` modules. It is heavily documented with XML (reference docs and IntelliSense), each element carrying `<summary>`, `<param>`, `<returns>`, and `<example>` blocks.

## `type Var` (`FSharpVar`, `[<Sealed>]`)

Information at the binding site of a variable:

- `member Type: Type`, `member Name: string`, `member IsMutable: bool`.
- `new: name: string * typ: Type * ?isMutable: bool -> Var`.
- `static member Global: name: string * typ: Type -> Var` — fetches or creates a variable from a global pool of shared variables indexed by name and type (with an example showing two calls return the same `Var`).
- `interface IComparable`.

## `type Expr` (`FSharpExpr`, `[<Class>]`)

"Quoted expressions annotated with System.Type values."

**Instance members:**
- `Substitute: substitution: (Var -> Expr option) -> Expr` — capture-avoiding substitution; renames variables on capture.
- `GetFreeVars: unit -> seq<Var>` — the free variables.
- `Type: Type` — the type of the expression.
- `CustomAttributes: Expr list`.
- `ToString: full: bool -> string`.

**Static construction members** (each takes the appropriate `MethodInfo`/`PropertyInfo`/`FieldInfo`/`ConstructorInfo`/`Type`/`Var` plus argument `Expr list`s and returns an `Expr`): `AddressOf`, `AddressSet`, `Application`, `Applications`, `Call` (static and instance overloads), `CallWithWitnesses` (static and instance overloads — includes witness methods), `Coerce`, `IfThenElse`, `ForIntegerRangeLoop`, `FieldGet`/`FieldSet` (static & instance), `Lambda`, `Let`, `LetRecursive`, `NewObject`, `DefaultValue`, `NewTuple`, `NewStructTuple` (both assembly-based and netstandard constructs), `NewRecord`, `NewArray`, `NewDelegate`, `NewUnionCase`, `PropertyGet`/`PropertySet`, `Quote`, `QuoteRaw`, `QuoteTyped`, `Sequential`, `TryWith`, `TryFinally`, `TupleGet`, `TypeTest`, `UnionCaseTest`, `Value` (typed and `objnull`-based), `ValueWithName`, `WithValue`, `Var`, `VarSet`, `WhileLoop`.

**Reflection / serialization members:**
- `Cast: source: Expr -> Expr<'T>`.
- `TryGetReflectedDefinition: methodBase: MethodBase -> Expr option`.
- `Deserialize: qualifyingType: Type * spliceTypes: Type list * spliceExprs: Expr list * bytes: byte array -> Expr` (and `Deserialize40` which also takes `referencedTypes`).
- `RegisterReflectedDefinitions: assembly: Assembly * resource: string * serializedValue: byte array -> unit` (with and without `referencedTypes`).
- `GlobalVar<'T> : name: string -> Expr<'T>`.

## `type Expr<'T>` (`FSharpExpr\`1`, `[<Class>]`)

The typed counterpart to `Expr`; exposes `member Raw: Expr` (the underlying untyped expression).

## `module Patterns` (`ModuleSuffix`)

"Represents specifications of a subset of F# expressions" as active patterns used for matching and deconstruction. Provides the recognizers: `Var`, `Application`, `Lambda`, `Let`/`LetRaw`/`LetRecursive`/`LetRecRaw`, `Quote`/`QuoteRaw`/`QuoteTyped`, `IfThenElse`, `NewTuple`, `NewStructTuple`, `DefaultValue`, `NewRecord`, `NewUnionCase`, `UnionCaseTest`, `TupleGet`, `Coerce`, `TypeTest`, `NewArray`, `AddressOf`/`AddressSet`, `TryFinally`/`TryWith`, `VarSet`, `Value`/`ValueObj`/`ValueWithName`/`WithValue`, `Sequential`, `ForIntegerRangeLoop`, `WhileLoop`, `PropertyGet`/`PropertySet`, `FieldGet`/`FieldSet`, `NewObject`, `Call`/`CallWithWitnesses`, `NewDelegate`, and internal helpers `Comb0/1/2/3`, `FrontAndBack`, `IteratedLambda`, `NLambdas`. (Serialization helpers are internal, not part of the signature.)

## `module DerivedPatterns`

Convenience patterns built on `Patterns`: constant patterns `Bool`, `String`, `Single`, `Double`, `Char`, `SByte`, `Byte`, `Int16`, `UInt16`, `Int32`, `UInt32`, `Int64`, `UInt64`, `Unit`, `Decimal`; multi-argument `Lambdas`/`Applications` and `TupledLambda`/`TupledApplication`; `AndAlso`, `OrElse`; `SpecificCall` (matches a specific method call); and `MethodWithReflectedDefinition`, `PropertyGetterWithReflectedDefinition`, `PropertySetterWithReflectedDefinition`.

## `module ExprShape`

The generic shape framework:
- `ShapeVar: input: Expr -> Choice<Var,(Var*Expr),(objnull*Expr list)>` — a three-way decomposition (the signature encodes `ShapeVar`/`ShapeLambda`/`ShapeCombination`).
- `RebuildShapeCombination: shape: objnull * arguments: Expr list -> Expr` — reconstructs an expression from a `ShapeCombination` value.

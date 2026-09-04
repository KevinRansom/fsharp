# quotations.fs

## Overview

This file (namespace `Microsoft.FSharp.Quotations`) is the **core quotation types and functions** in FSharp.Core. It defines the data structures used to represent F# code as data (F# quotations / expression trees), the `Var` variable type, the `Patterns` matching module, the `Expr` construction API (static members), the `DerivedPatterns` convenience patterns, and the `ExprShape` generic shape-recursion module. It also implements quotation serialization/deserialization and reflected-definition support.

## `early module Helpers`

Internal helpers: right/left linear combinator accumulation (`qOneOrMoreRLinear`, `qOneOrMoreLLinear`, `mkRLinear`, `mkLLinear`), reflection binding-flags constants, `isDelegateType`/`getDelegateInvoke`, `checkNonNull`, `getTypesFromParamInfos`.

## `type Var` (`FSharpVar`)

Represents a bound variable in a quotation:

- Properties: `Name`, `Type`, `IsMutable`, `Stamp` (a globally unique id from an `Interlocked.Increment`ed counter; `Var` equality is **reference equality**).
- `static member Global(name, typ)` — returns a memoized, interned variable (used for top-level/global bindings), stored in a `Dictionary<string*Type, Var>`; serialization of global variables relies on this.
- Implements `IComparable` (compares by name, then type/module metadata tokens and assembly, then stamp).

## Core representation types

- `type Tree` — the raw backing structure: `CombTerm of ExprConstInfo * Expr list` (a node + child args), `VarTerm of Var`, `LambdaTerm of Var * Expr`, `HoleTerm of Type * int` (a splice hole for deserialization).
- `and ExprConstInfo` — a `[<StructuralEquality; NoComparison>]` discriminated union enumerating every expression-node kind: `AppOp`, `IfThenElseOp`, `LetOp`, `LetRecOp`/`LetRecCombOp`, `NewRecordOp`, `NewUnionCaseOp`, `UnionCaseTestOp`, `NewTupleOp`, `TupleGetOp`, instance/static `PropGet`/`PropSet`/`FieldGet`/`FieldSet`, `NewObjectOp`, instance/static `MethodCallOp`, the F# 5.0 witness-carrying `InstanceMethodCallWOp`/`StaticMethodCallWOp` (store the real method plus a witness method and witness count), `CoerceOp`, `NewArrayOp`, `NewDelegateOp`, `QuoteOp`, `SequentialOp`, `AddressOfOp`, `VarSetOp`, `AddressSetOp`, `TypeTestOp`, `TryWithOp`, `TryFinallyOp`, `ForIntegerRangeLoopOp`, `WhileLoopOp`, and non-serialized `ValueOp`/`WithValueOp`/`DefaultValueOp`.
- `and Expr` (`FSharpExpr`, `StructuredFormatDisplay("{DebugText}")`) — wraps a `Tree` plus `CustomAttributes` (a list of attribute `Expr`s). Custom `Equals`/`GetHashCode` implement **structural equality** with several normalization rules: `ValueWithName` equals `Value`; witness-carrying calls equal their non-witness equivalents (strip `WOp`/witness args). `ToString(full)` renders via the structured-print layout engine (`GetLayout`), with a `DebugText` shortcut.
- `and Expr<'T>` (`FSharpExpr\`1`) — typed variant, `inherit Expr` and exposes `member Raw` (upcast to untyped `Expr`).

## `module Patterns` (`ModuleSuffix`)

Provides both the **recognizers** (active patterns) and the internal `mk*` **constructors** used by the `Expr` static API.

First a set of internal arity/high-level combinators: `(E)`, `FrontAndBack`, `Comb0/1/2/3`, then the **main active patterns** (each `[<CompiledName("XxxPattern")>]`, returning the structured components of the node): `Var`, `Application`, `Lambda` (with `IteratedLambda`/`NLambdas`), `Quote`, `QuoteRaw`, `QuoteTyped`, `IfThenElse`, `NewTuple`, `NewStructTuple`, `DefaultValue`, `NewRecord`, `NewUnionCase`, `UnionCaseTest`, `TupleGet`, `Coerce`, `TypeTest`, `NewArray`, `AddressSet`, `TryFinally`, `TryWith`, `VarSet`, `Value`, `ValueObj`, `ValueWithName`, `WithValue`, `AddressOf`, `Sequential`, `ForIntegerRangeLoop`, `WhileLoop`, `PropertyGet`, `PropertySet`, `FieldGet`, `FieldSet`, `NewObject`, `Call`, `CallWithWitnesses`, `LetRaw`, `Let`, `NewDelegate`, `LetRecursive`.

The module also contains `ByteStream` (binary reader) and `SimpleUnpickle`/de-serialization logic: quotations are serialized to byte arrays (see `Expr.Deserialize`/`RegisterReflectedDefinitions`); `Instantiable<'T>` represents a deserialized object awaiting instantiation, and helper patterns `NoTyArgs`/`OneTyArg` are matched during unpickling. Reflected definition lookup (`tryGetReflectedDefinitionInstantiated`, `registerReflectedDefinitions`) is implemented here too.

## `type Expr with` static and instance API

The `Expr` type's public members (defined in a `type Expr with` augmentation):

- Instance: `Substitute` (capture-avoiding substitution of a mapping from `Var` to `Expr`), `GetFreeVars()`, `Type`.
- Static **constructors** (each typically `checkNonNull` then delegates to an internal `mk*`): `AddressOf`, `AddressSet`, `Application`, `Applications`, `Call` (static/instance and `CallWithWitnesses`), `Coerce`, `IfThenElse`, `ForIntegerRangeLoop`, `FieldGet`/`FieldSet`, `Lambda`, `Let`, `LetRecursive`, `NewObject`, `DefaultValue`, `NewTuple`, `NewStructTuple`, `NewRecord`, `NewArray`, `NewDelegate`, `NewUnionCase`, `PropertyGet`/`PropertySet`, `Quote`/`QuoteRaw`/`QuoteTyped`, `Sequential`, `TryWith`, `TryFinally`, `TupleGet`, `TypeTest`, `UnionCaseTest`, `Value`, `ValueWithName`, `WithValue`, `Var`, `VarSet`, `WhileLoop`.
- Reflection/other: `TryGetReflectedDefinition(methodBase)`, `Cast(source)`, `Deserialize`/`Deserialize40`, `RegisterReflectedDefinitions`, `GlobalVar<'T>(name)`.

## `module DerivedPatterns`

Higher-level, convenience active patterns built on `Patterns`:

- Constant patterns returning values: `Bool`, `String`, `Single`, `Double`, `Char`, `SByte`, `Byte`, `Int16`, `UInt16`, `Int32`, `UInt32`, `Int64`, `UInt64`, `Unit`, `Decimal`.
- `TupledLambda`, `TupledApplication` and the multi-arg `Lambdas`, `Applications` (reverse the compiler's tupled-parameter encoding).
- `AndAlso`, `OrElse` (reverse compilation of `&&`/`||` into `IfThenElse`).
- `SpecificCall template` — matches any call to the given method (by metadata token / generic method definition), returning `(obj, typeArgs, args)`; used widely (e.g. in `Query.fs`).
- `MethodWithReflectedDefinition`, `PropertyGetterWithReflectedDefinition`, `PropertySetterWithReflectedDefinition` — return the reflected-definition body when the given method/property has `[<ReflectedDefinition>]`.

## `module ExprShape`

The recommended generic shape framework for writing bottom-up traversal functions without listing every node:

- `ShapeCombination(shape, args)`, `ShapeLambda(var, body)`, `ShapeVar(var)` — a three-way active pattern.
- `RebuildShapeCombination(shape, args)` — reconstructs an `Expr` from a `ShapeCombination` value (the `shape` box encodes the `ExprConstInfo` + custom attributes, so attributes/args are preserved). Implemented as a big match over every `ExprConstInfo` kind calling the corresponding `mk*` constructor.

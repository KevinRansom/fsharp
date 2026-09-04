# reflect.fsi

## Overview

Signature file (namespace `Microsoft.FSharp.Reflection`) that defines the public API for **reflection over F# value/type representations**. It augments `System.Reflection` with awareness of F# constructs: records, discriminated unions, tuples, functions, modules, and exception declarations. The signature mirrors the implementation in `reflect.fs` and carries extensive XML documentation, including code examples and remarks that document the pre-computation (`PreCompute*`) performance benefit.

## `type UnionCaseInfo` (`[<Sealed>]`) — line 19

Describes a single case of a discriminated union type:

- `Name: string` — the case name.
- `DeclaringType: Type` — the type in which the case occurs.
- `GetCustomAttributes: unit -> obj array`, `GetCustomAttributes: attributeType: Type -> obj array`, and `GetCustomAttributesData: unit -> IList<CustomAttributeData>` — custom attributes on the case.
- `GetFields: unit -> PropertyInfo array` — the case's field properties.
- `Tag: int` — the integer tag identifying the case.

## `type FSharpValue` (`[<AbstractClass; Sealed>]`) — line 195

Static operations that construct or deconstruct live F# values:

- Records: `GetRecordField(record, info)`, `PreComputeRecordFieldReader(info)`, `MakeRecord(recordType, values, ?bindingFlags)`, `GetRecordFields(record, ?bindingFlags)`, `PreComputeRecordReader(recordType, ?bindingFlags)`, `PreComputeRecordConstructor(recordType, ?bindingFlags)`, `PreComputeRecordConstructorInfo(recordType, ?bindingFlags)`.
- Unions: `MakeUnion(unionCase, args, ?bindingFlags)`, `GetUnionFields(value, unionType, ?bindingFlags)` (returns `UnionCaseInfo * objnull array`), `PreComputeUnionTagReader`, `PreComputeUnionTagMemberInfo`, `PreComputeUnionReader`, `PreComputeUnionConstructor`, `PreComputeUnionConstructorInfo`.
- Exceptions: `GetExceptionFields(exn, ?bindingFlags)`.
- Tuples: `MakeTuple(tupleElements, tupleType)`, `GetTupleField(tuple, index)`, `GetTupleFields(tuple)`, `PreComputeTupleReader`, `PreComputeTuplePropertyInfo`, `PreComputeTupleConstructor`, `PreComputeTupleConstructorInfo`.
- Functions: `MakeFunction(functionType, implementation)` — builds a typed function from an untyped `(objnull -> objnull)` implementation.

Many signatures use `[<DynamicallyAccessedMembers(DynamicallyAccessedMemberTypes.All)>]` on `Type` arguments to support AOT/linker analysis. The `PreCompute*` members return compiled delegates for performance (they avoid per-call `MethodInfo.Invoke` overhead).

## `type FSharpType` (`[<AbstractClass; Sealed>]`) — line 540

Static type-level queries and type builders:

- Queries: `GetRecordFields`, `GetUnionCases` (returns `UnionCaseInfo array`), `IsRecord`, `IsUnion`, `IsTuple`, `IsFunction`, `IsModule`, `IsExceptionRepresentation`, `GetExceptionFields`.
- Builders: `MakeFunctionType(domain, range)`, `MakeTupleType(types)` and `MakeTupleType(asm, types)`, `MakeStructTupleType(asm, types)` and `MakeStructTupleType(types)`.
- Decomposition: `GetTupleElements`, `GetFunctionElements`.

## `module FSharpReflectionExtensions` (`[<AutoOpen>]`) — line 728

Extension/additional overloads appended to `FSharpValue` (records/unions/exceptions) and `FSharpType` (records/unions/exceptions). Unlike the base members (which take raw `?bindingFlags: BindingFlags`), these take a friendlier `?allowAccessToPrivateRepresentation: bool` and translate it to binding flags — the public way to opt into reflection over private F# representations.

## `module internal ReflectionUtils` — line 1028

Internal helper (also visible in the signature): `val toBindingFlags: allowAccessToNonPublicMembers: bool -> BindingFlags`.

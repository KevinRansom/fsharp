# reflect.fs

## Overview

This file (namespace `Microsoft.FSharp.Reflection`) implements **reflection over F# values**: it detects whether an object's type represents an F# record, discriminated union, tuple, function, module, or exception, and provides tools to construct and deconstruct such values. It exposes the `FSharpType`, `FSharpValue`, and `UnionCaseInfo` types, plus `FSharpReflectionExtensions` for opt-in access to private representations. Much of the low-level work uses reflection over `CompilationMappingAttribute` and (for performance) compiled `System.Linq.Expressions` accessors.

## internal modules

- `module internal ReflectionUtils` — converts an `allowAccessToNonPublicMembers : bool` into `BindingFlags` (`Public` or `Public ||| NonPublic`).
- `module internal Impl` (AutoOpen) — the core implementation:

  **Type tests & helpers:** `isNamedType`, `equivHeadTypes`, and `isOptionType`/`isFunctionType`/`isListType` (by generic head type). Binding-flag constants (`instancePropertyFlags`, `staticFieldFlags`, ...) and `getInstancePropertyInfo`/`getInstancePropertyInfos`/`getInstancePropertyReader`.

  **Expression-tree compilation (fast readers/constructors):** `compilePropGetterFunc`, `compileRecordOrUnionCaseReaderFunc`, `compileRecordConstructorFunc`, `compileUnionCaseConstructorFunc`, `compileUnionTagReaderFunc`, `compileTupleConstructor`, `compileTupleReader` — these build and compile `Func<...>`/`Action` lambdas via `System.Linq.Expressions`, avoiding repeated `MethodInfo.Invoke` overhead for the `PreCompute*` APIs.

  **Attribute decompilation:** `findCompilationMappingAttribute(AllowMultiple)` (reads real attribute instances or `CustomAttributeData` for reflection-only assemblies), `tryFindCompilationMappingAttributeFromType`, `sequenceNumberOfMember`, `sequenceNumberOfUnionCaseField`, `belongsToCase`, `isFieldProperty`, `tryFindSourceConstructFlagsOfType`.

  **Union decompilation:** `getUnionTypeTagNameMap` (name→tag map, handling the nested `Tags` type or single-case unions and the `List`/`Option` special cases), `getUnionCaseTyp`, `getUnionTagConverter`, `isUnionType`, `isConstructorRepr`/`unionTypeOfUnionCaseType`, `fieldsPropsOfUnionCase`, `getUnionCaseRecordReader(Compiled)`, `getUnionTagReader(Compiled)`, `getUnionTagMemberInfo`, `isUnionCaseNullary`, `getUnionCaseConstructorMethod`/`getUnionCaseConstructor(Compiled)`, and `checkUnionType` (with private-vs-not error messages).

  **Tuple decompilation:** `simpleTupleNames`, `isTupleType`, `maxTuple`/`tupleEncField` (tuple nesting at index 7), nested `module TupleFromSpecifiedAssembly` (builds `System.Tuple`/`ValueTuple` types targeting a given assembly, with per-assembly `Dictionary` caches), `mkTupleTypeNetStandard`, `getTupleTypeInfo`, `orderTupleProperties`/`orderTupleFields`, `getTupleConstructorMethod`/`getTupleCtor`/`getTupleElementAccessors`/`getTupleReader`/`getTupleConstructor`/`getTupleConstructorInfo`/`getTupleReaderInfo`.

  **Record/function/module/exception decompilation:** `getFunctionTypeInfo`, `isModuleType`, `isClosureRepr`, `isRecordType`, `fieldPropsOfRecordType`, `getRecordReader(Compiled)`, `getRecordConstructorMethod`/`getRecordConstructor(Compiled)`, `isExceptionRepr`, `getTypeOfReprType`, and `checkExnType`, `checkRecordType`, `checkTupleType`.

## `type UnionCaseInfo(typ, tag)` (`[<Sealed>]`)

Describes a single discriminated-union case:

- `Name` (from the tag converter, cached), `DeclaringType`, `Tag`.
- `GetFields()` — the `PropertyInfo`s of the case's fields.
- `GetCustomAttributes()`, `GetCustomAttributes(attributeType)`, `GetCustomAttributesData()` — attributes of the case's constructor method.
- Overrides `ToString` (`"Type.CaseName"`), `GetHashCode` (`typ.GetHashCode() + tag`), and `Equals` (declaring type + tag).

## `type FSharpType` (`[<AbstractClass; Sealed>]`)

Static queries and type-construction helpers:

- Predicates: `IsTuple`, `IsRecord(?bindingFlags)`, `IsUnion(?bindingFlags)`, `IsFunction`, `IsModule`, `IsExceptionRepresentation(?bindingFlags)`.
- Type building: `MakeFunctionType(domain, range)`, `MakeTupleType(types)` (netstandard) and `MakeTupleType(asm, types)`, `MakeStructTupleType(types)` and `MakeStructTupleType(asm, types)` (nested for >7 types).
- Decomposition: `GetTupleElements(tupleType)`, `GetFunctionElements(functionType)`, `GetRecordFields(recordType, ?bindingFlags)`, `GetUnionCases(unionType, ?bindingFlags)` (returns `UnionCaseInfo[]`), `GetExceptionFields(exceptionType, ?bindingFlags)`.

## `type DynamicFunction<'T1,'T2>`

An internal helper (`inherit FSharpFunc<obj->obj, obj>`) used by `FSharpValue.MakeFunction` to wrap a dynamically-invoked `objnull -> objnull` implementation into a typed `'T1 -> 'T2` closure.

## `type FSharpValue` (`[<AbstractClass; Sealed>]`)

Static constructors/readers over live objects:

- Records: `MakeRecord`, `GetRecordField`, `GetRecordFields`, plus `PreComputeRecordFieldReader`, `PreComputeRecordReader`, `PreComputeRecordConstructor`, `PreComputeRecordConstructorInfo`.
- Functions: `MakeFunction(functionType, implementation)`.
- Tuples: `MakeTuple`, `GetTupleFields`, `GetTupleField`, plus `PreComputeTupleReader`, `PreComputeTuplePropertyInfo`, `PreComputeTupleConstructor`, `PreComputeTupleConstructorInfo`.
- Unions: `MakeUnion`, `GetUnionFields` (returns `(UnionCaseInfo * objnull array)`), plus `PreComputeUnionConstructor(Info)`, `PreComputeUnionTagReader`, `PreComputeUnionTagMemberInfo`, `PreComputeUnionReader`.
- Exceptions: `GetExceptionFields(exn)`.

Each `PreCompute*` returns a compiled delegate (via the expression-tree functions above) for performance.

## `module FSharpReflectionExtensions`

Provides *extension-style* overloads on `FSharpType` and `FSharpValue` that accept `?allowAccessToPrivateRepresentation : bool` (instead of raw `BindingFlags`), translating that bool via `getBindingFlags` and delegating to the corresponding `FSharpType`/`FSharpValue` member. (This is how the friendly public API opts into private union/record/exception representations.)

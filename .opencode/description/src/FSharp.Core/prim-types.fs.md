# prim-types.fs

## Overview

This is the largest file in FSharp.Core (~7360 lines). It defines most of the fundamental **types**, **attributes**, the **`LanguagePrimitives`** module, and the **`Operators`** module that provide the low-level semantics (comparison, equality, hashing, arithmetic, parsing, enums, measures) used throughout the F# language and standard library. Unlike `prim-types-prelude.fs` (pure abbreviations), this file contains real implementations, mostly written as inline functions backed by raw IL (`(# "..." #)`) and by `HashCompare` from a linked source file.

It is organized as a sequence of namespaces with (mostly) a single top-level `Microsoft.FSharp.Core` block:

## Core types and attributes (`namespace Microsoft.FSharp.Core`)

- `type Unit()` / `and unit = Unit` — the unit type.
- Enums controlling generated-code metadata: `SourceConstructFlags`, `CompilationRepresentationFlags`, `StructAttributes` (via raw bit flags for `struct`/`seq`).
- A large collection of **attribute types**: `SealedAttribute`, `AbstractClassAttribute`, `EqualityConditionalOnAttribute`, `ComparisonConditionalOnAttribute`, `AllowNullLiteralAttribute`, `VolatileFieldAttribute`, `DefaultAugmentationAttribute`, `CLIEventAttribute`, `CLIMutableAttribute`, `AutoSerializableAttribute`, `DefaultValueAttribute`, `EntryPointAttribute`, `ReferenceEqualityAttribute`, `StructuralComparisonAttribute`, `StructuralEqualityAttribute`, `NoEqualityAttribute`, `CustomEqualityAttribute`, `CustomComparisonAttribute`, `NoComparisonAttribute`, `ReflectedDefinitionAttribute`, `CompiledNameAttribute`, `StructAttribute`, `MeasureAttribute`, `MeasureAnnotatedAbbreviationAttribute`, `InterfaceAttribute`, `ClassAttribute`, `LiteralAttribute`, `FSharpInterfaceDataVersionAttribute`, `CompilationMappingAttribute`, `CompilationSourceNameAttribute`, `CompilationRepresentationAttribute`, and others.

- `module internal ExperimentalAttributeMessages` — text strings for experimental/preview features (e.g. `RequiresPreview`, `NotSupportedYet`).

- `namespace Microsoft.FSharp.Core.CompilerServices` — contains type-provider related types; `namespace System.Diagnostics.CodeAnalysis` — nullable-analysis attributes used by the compiler.

- Back in `Microsoft.FSharp.Core`, the **measure-annotated primitive aliases**: `float<'Measure>`, `float32<'Measure>`, `decimal<'Measure>`, `int<'Measure>`, `sbyte<'Measure>`, `int16<'Measure>`, `int64<'Measure>`, `nativeint<'Measure>`, `uint<'Measure>`, `byte<'Measure>`, `uint16<'Measure>`, `uint64<'Measure>`, `unativeint<'Measure>`, plus aliases `double`/`single`/`int8`/`int32`/`uint8`/`uint32` etc. Also `type byref<'T> = (# "!0&" #)` (managed reference).

- `module ByRefKinds` — `In`/`Out`/`InOut` marker types for `inref`/`outref`/`byref`.
- `module internal BasicInlinedOperations` — low-level inline helpers: `unboxPrim`, `box`, `convPrim`, `not`, primitive comparisons/arithmetic over `int`/`int64`/`uint64`/`char`, `ignore`, `length`/`zeroCreate`/`get`/`set` (array IL), `typeof`/`typedefof`/`sizeof`, `unsafeDefault`, `isinstPrim`, `castclassPrim`, `notnullPrim`, `mask`.
- `module internal TypeOfUtils` and `module TupleUtils` — `combineTupleHashes`/`combineTupleHashCodes` helpers.

## `module LanguagePrimitives` (lines ~621-3703)

The central module. Key public members:

- **Generic comparison / equality / hashing** (wrapping `HashCompare`): `GenericEquality`, `GenericEqualityER`, `GenericEqualityWithComparer`, `GenericComparison`, `GenericComparisonWithComparer`, `GenericLessThan`, `GenericGreaterThan`, `GenericLessOrEqual`, `GenericGreaterOrEqual`, `GenericMinimum`, `GenericMaximum`, `GenericHash`, `GenericLimitedHash`, `GenericHashWithComparer`, `PhysicalEquality`, `PhysicalHash`, `GenericComparer`, `GenericEqualityComparer`, `GenericEqualityERComparer`.
- **Comparers / equality comparers** published as objects: `MakeGenericEqualityComparer<'T>()`, `MakeGenericLimitedEqualityComparer<'T>(limit)`, `FastGenericEqualityComparer<'T>`, `FastLimitedGenericEqualityComparer<'T>`, `MakeGenericComparer<'T>()`, `FastGenericComparer<'T>`, `FastGenericComparerCanBeNull<'T>`, plus per-primitive comparers (`CharComparer`, `StringComparer`, `Int32Comparer`, ...). Internal `FastGenericComparerTable<'T>` type-indexed tables let the CLR optimize array sorts.
- **Enums**: `EnumOfValue`, `EnumToValue`.
- **Measures**: `[Int16|SByte|Int32|Int64|IntPtr|UInt16|UInt32|UInt64|Byte|UIntPtr|Float|Float32|Decimal]WithMeasure` — each `retype`s the underlying primitive (no runtime cost).
- **Numeric parsing** (`int32`, `int64`, etc. semantics — only `AllowLeadingSign`, disallowing white space): internal string scanners (`get0OXB`, `getSign32`, `getSign64`, `removeUnderscores`), then `ParseUInt32`, `ParseInt32`, `ParseInt64`, `ParseUInt64`, and IL-converted `ParseByte`, `ParseSByte`, `ParseInt16`, `ParseUInt16`, `ParseIntPtr`, `ParseUIntPtr`, `ParseDouble`, `ParseSingle`. Supports decimal, hex (`0x`), binary (`0b`), octal (`0o`) forms.
- **Zero/One**: `GenericZero<^T>` / `GenericOne<^T>` with static optimization over all primitives, and dynamic fallback via type-indexed tables (`GenericZeroDynamicImplTable<'T>`, `GenericOneDynamicImplTable<'T>`) that read a `Zero`/`One` static property on nominal types; exposed as `GenericZeroDynamic` / `GenericOneDynamic`.
- **Dynamic operator dispatch** (legacy path when no built-in primitive applies and no witness supplied): helper `Type` extensions `GetSingleStaticMethodByTypes` / `GetSingleStaticConversionOperatorByTypes`, `UnaryDynamicImpl`, `BinaryDynamicImpl`, and cached `UnaryOpDynamicImplTable<'OpInfo,'T,'U>` / `BinaryOpDynamicImplTable<'OpInfo,'T1,'T2,'U>`. The actual generic operators are `AdditionDynamic`, `SubtractionDynamic`, `MultiplyDynamic`, `DivisionDynamic`, `ModulusDynamic`, each doing `type3eq`-driven primitive selection with raw IL (`add`/`sub`/`mul`/`div`/`div.un`/`rem`/`rem.un`) and falling back to dynamic `op_Addition`/`op_Subtraction`/etc. lookup for nominal types (as well as `UnaryNegationDynamic`, comparison ops, and `op_Explicit` dynamic conversion via `conv`/`conv.ovf.*` IL).

## `Choice` types, functional types (`namespace Microsoft.FSharp.Core`)

- `Choice<'T1,'T2>` through `Choice<'T1,...,'T7>` discriminated unions (`FSharpChoice\`2`..`7`) with structural equality/comparison.
- `exception MatchFailureException of string * int * int`.
- Abstract `FSharpTypeFunc` (with `Specialize<'T>`) and `FSharpFunc<'T,'Res>` (with `Invoke`).
- `module OptimizedClosures` — `FSharpFunc<'T,'U,'V>` (with `Adapt`) that detects curried funcs taking two args and calls them directly without boxed closures.

## `namespace Microsoft.FSharp.Collections` / private helpers / `System.Runtime.CompilerServices`

- `module PrivateListHelpers` (internal list utilities), plus `IsByRefLikeAttribute`/`IsReadOnlyAttribute` in `System.Runtime.CompilerServices`.

## `module Operators` (lines ~4399-7305)

The standard F# operator/function module. Highlights:

- **Seq / boxing**: `seq`, `unbox`, `box`, `tryUnbox`.
- **Null handling** (for nullable reference types and `Nullable<'T>`): `isNull`, `isNotNull`, `isNullV`, `nonNull`, `nonNullV`, `nullArgCheck`, and active patterns `(|Null|NonNull|)`, `(|NullV|NonNullV|)`, `(|NonNullQuick|)`, `(|NonNullQuickV|)`, plus `withNull`, `withNullV`, `nullV`.
- **Exceptions / asserts**: `raise`, `failwith`, `invalidArg`, `nullArg`, `invalidOp`, `rethrow`, `reraise`, `Failure`, `(|Failure|_|)`.
- **Tuple / ignore**: `fst`, `snd`, `ignore`.
- **Refs**: `ref`, `(:=)`, `(!)`.
- **Pipeline / composition**: `|>`, `||>`, `|||>`, `<|`, `<||`, `<|||`, `>>`, `<<`, string concatenation `^`.
- **defaults**: `defaultArg`, `defaultValueArg`, `defaultIfNull`, `defaultIfNullV`.
- **Comparison / ordering** (generic): `<`, `>`, `>=`, `<=`, `=`, `<>`, `compare`, `max`, `min`.
- **Arithmetic** (`+`, `-`, unary `~-`, `*`, `/`, `%`, `**`, `~+`) and **bitwise** (`&&&` and, `|||` or, `^^^` xor, `~~~` not, `<<<` shift-left, `>>>` shift-right) — each written inline over primitive types with raw IL, with **static optimization** (`when ^T : <prim> = ...`) and **dynamic dispatch** fallback to `LanguagePrimitives.xxxDynamic` (and ultimately static-member lookup) for nominal types.
- **Conversions / math**: `abs`, `sign`, `float`, `float32`, `int8`/`sbyte`, `uint8`/`byte`, `int16`, `uint16`, `int32`/`int`, `uint32`/`uint`, `int64`, `uint64`, `nativeint`, `unativeint`, `char`, `enum`, `decimal`, `string`, `toString`, `printf`/`printfn`/`sprintf` (these delegate to the `Printf` module generated in `printf.fs`).
- **functional `id`**, `%` modulo, `**` power (via `LanguagePrimitives` / `Math.Pow`), and `op_Explicit`-style conversions.

The `Operators` module is auto-opened (F# implicit operators) and provides the operators that appear in normal user code.

## `namespace Microsoft.FSharp.Control` (tail)

- `module LazyExtensions` — extension members on `System.Lazy<'T>`: `Create`, `CreateFromValue`, and deprecated `IsDelayed`/`IsForced`/`Force`/`SynchronizedForce`/`UnsynchronizedForce` bridging to `Lazy`'s `IsValueCreated`/`Value` (with `DynamicallyAccessedMembers` on the type parameter for trimming).
- `type Lazy<'T> = System.Lazy<'T>` and `` 'T ``lazy`` `` abbreviation.
- Event abstractions: `IDelegateEvent<'Delegate>`, `IEvent<'Delegate,'Args>`, `IEvent<'Args>` (via `IEvent<Handler<'Args>,'Args>`), and `type Handler<'Args> = delegate of sender:objnull * args:'Args -> unit` (compiled as `FSharpHandler\`1`).

Because so much depends on raw IL and inline static optimization, this file is essentially the compiled "back half" of the F# runtime surface, complementing `prim-types-prelude.fs`, `HashCompare` and the per-module files (e.g. `printf.fs`).

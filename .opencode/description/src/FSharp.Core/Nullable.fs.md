# Nullable.fs

## Overview

This file (namespace `Microsoft.FSharp.Linq`) provides support for working with `System.Nullable<'T>` values, primarily intended for use inside F# **query expressions**. It contains two modules:

1. `NullableOperators` (`[<AutoOpen>]`) — custom comparison and arithmetic operators that treat a null/nullable value as "no value", yielding `false` / an empty nullable instead of throwing.
2. `Nullable` (`[<RequireQualifiedAccess>]`, `[<ModuleSuffix>]`) — functions that convert a `Nullable` value to a different underlying type through `op_Explicit`.

## Module `NullableOperators`

All operators here are primarily for use in F# queries. They follow a naming convention where `?` on the left (first character) or right (third character) indicates which operand is `Nullable<'T>`:

- A leading `?` (e.g. `?>=`) — the nullable value is on the **left**.
- A leading `<`/`>`/`=` and trailing `?` (e.g. `>=?`) — the nullable value is on the **right**.
- Both markers (e.g. `?>=?`) — both operands are nullable.

### Comparison operators

Return `bool` and never throw on null — a null operand simply makes the comparison `false`:

- Nullable left: `?>=`, `?>`, `?<=`, `?<`, `?=`, `?<>` — evaluate only when `x.HasValue` (e.g. `x.HasValue && x.Value >= y`).
- Nullable right: `>=?`, `>?`, `<=?`, `<?`, `=?`, `<>?`.
- Both nullable: `?>=?`, `?>?`, `?<=?`, `?<?`, `?=?`, `?<>?` — require both to have values for the non-null comparison; equality (`?=?`) considers two nulls equal.

### Arithmetic operators (inline)

These require a static member `( + )`, `( - )`, `( * )`, `( % )`, `( / )` and propagate the `Nullable` status: if the nullable operand(s) have a value they compute and wrap in `Nullable(...)`, otherwise they return an empty `Nullable()`:

- Nullable left: `?+`, `?-`, `?*`, `?%`, `?/` — `if x.HasValue then Nullable(x.Value op y) else Nullable()`.
- Nullable right: `+?`, `-?`, `*?`, `%?`, `/?`.
- Both nullable: `?+?`, `?-?`, `?*?`, `?%?`, `?/?`.

## Module `Nullable` (conversion functions)

All conversion functions are `inline`, take `value: Nullable< ^T >`, and follow this pattern:

```
if value.HasValue then Nullable(convert value.Value) else Nullable()
```

Each requires `^T : (static member op_Explicit : ^T -> <target>)` with a default of `int`. Functions (with their `[<CompiledName>]`):

- `uint8`/`byte` (`ToUInt8`/`ToByte`) → `Nullable<byte>`
- `int8`/`sbyte` (`ToInt8`/`ToSByte`) → `Nullable<sbyte>`
- `int16`, `uint16` (`ToInt16`/`ToUInt16`)
- `int`, `uint` (`ToInt`/`ToUInt`)
- `int32`, `uint32` (`ToInt32`/`ToUInt32`)
- `int64`, `uint64` (`ToInt64`/`ToUInt64`)
- `float32`, `single` (`ToFloat32`/`ToSingle`) → `Nullable<float32>`
- `float`, `double` (`ToFloat`/`ToDouble`) → `Nullable<float>`
- `nativeint`, `unativeint` (`ToIntPtr`/`ToUIntPtr`)
- `decimal` (`ToDecimal`)
- `char` (`ToChar`) — numeric inputs converted per UTF-16
- `enum` (`ToEnum`) — `value: Nullable<int32> -> Nullable< ^U >` when `^U : enum<int32>`

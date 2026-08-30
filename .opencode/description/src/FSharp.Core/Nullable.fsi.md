# Nullable.fsi

## Overview

This is the public API signature for the nullable-value operators and conversions (namespace `Microsoft.FSharp.Linq`). It declares two modules used primarily inside F# query expressions.

## Module `NullableOperators`

Marked `[<AutoOpen>]`. Comparison operators (all return `bool`, with `'T : comparison` or `'T : equality` as appropriate, and never throw on null):

- Nullable on left: `?>=`, `?>`, `?<=`, `?<`, `?=`, `?<>` — `Nullable<'T> -> 'T -> bool`.
- Nullable on right: `>=?`, `>?`, `<=?`, `<?`, `=?`, `<>?` — `'T -> Nullable<'T> -> bool`.
- Both nullable: `?>=?`, `?>?`, `?<=?`, `?<?`, `?=?`, `?<>?` — `Nullable<'T> -> Nullable<'T> -> bool`.

Arithmetic operators (`inline`, require a static member `( + )`, `( - )`, `( * )`, `( % )`, `( / )`; result wrapped in `Nullable`):

- Nullable on left: `?+`, `?-`, `?*`, `?%`, `?/`.
- Nullable on right: `+?`, `-?`, `*?`, `%?`, `/?`.
- Both nullable: `?+?`, `?-?`, `?*?`, `?%?`, `?/?`.

## Module `Nullable`

Marked `[<RequireQualifiedAccess>]` with `[<CompilationRepresentation(ModuleSuffix)>]`. Conversion functions, each `inline value: Nullable< ^T > -> Nullable<target>` requiring `^T : (static member op_Explicit : ^T -> target)` and a default of `int` (except `uint`, default `uint`; and `enum`, which converts `Nullable<int32>` via an enum constraint):

- `uint8` (`ToUInt8`) → `Nullable<uint8>`; `byte` (`ToByte`) → `Nullable<byte>`
- `int8` (`ToInt8`) → `Nullable<int8>`; `sbyte` (`ToSByte`) → `Nullable<sbyte>`
- `int16`, `uint16`
- `int`, `uint`
- `int32`, `uint32`
- `int64`, `uint64`
- `float32`, `single`
- `float`, `double`
- `nativeint`, `unativeint`
- `decimal`
- `char`
- `enum< ^U >` — `value: Nullable<int32> -> Nullable< ^U >` when `^U : enum<int32>`

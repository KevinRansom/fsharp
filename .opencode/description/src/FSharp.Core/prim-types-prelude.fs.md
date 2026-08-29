# prim-types-prelude.fs

## Overview

This file (namespace `Microsoft.FSharp.Core`) is the "prelude" of primitive type definitions, parsed by the F# compiler very early during the build (its exact filename is depended upon by graph-based type-checking). It defines the fundamental **type abbreviations** and **measure/array/pointer primitive types** that the rest of FSharp.Core assumes to exist.

## Basic type abbreviations

Each is defined as an alias for a corresponding CLR type (via `type ... = System.X`):

- `obj = System.Object`
- `objnull = obj | null` — `System.Object` or null (nullable reference types)
- `exn = System.Exception`
- `nativeint = System.IntPtr`, `unativeint = System.UIntPtr`
- `string = System.String`
- Floating point: `float32 = System.Single`, `float = System.Double`, `single = System.Single`, `double = System.Double`
- Signed integers: `sbyte = System.SByte`, `int8 = System.SByte`, `int16 = System.Int16`, `int32 = System.Int32`, `int64 = System.Int64`, `int = int32`
- Unsigned integers: `byte = System.Byte`, `uint8 = System.Byte`, `uint16 = System.UInt16`, `uint32 = System.UInt32`, `uint64 = System.UInt64`, `uint = uint32`
- `char = System.Char`, `bool = System.Boolean`, `decimal = System.Decimal`

## Array type abbreviations

Multidimensional array types, defined via raw type slots (`(# "... #)`), one per rank from 1 to 32:

- ```[]``<'T> = (# "!0[]" #)` — one-dimensional array.
- `[,]`, `[,,]`, `[,,,]`, `[,,,,]`, ... up to `[,,,,...,]` (32 dims), each expanding `!0[0 ..., ...]` with the appropriate number of dimensions.

Also:
- `array<'T> = 'T[]` — the F# `array` abbreviation (a .NET `'T[]`).

## Pointer types

- `nativeptr<'T when 'T : unmanaged> = (# "native int" #)` — a typed native/unmanaged pointer.
- `voidptr = (# "void*" #)` — an untyped native pointer.
- `ilsigptr<'T> = (# "!0*" #)` — a Common IL (Intermediate Language) signature pointer.

These raw type slots emit the corresponding CLR pointer type directly.

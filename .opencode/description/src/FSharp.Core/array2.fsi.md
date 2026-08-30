# array2.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. This is the public API signature for the `Array2D` module (implementation in `array2.fs`), documenting the exposed operations for rank-2 arrays.

## Namespaces
- `Microsoft.FSharp.Collections`

## Module: Array2D
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Array2D`

Public surface (each with XML docs, parameter/return descriptions and examples):

- `base1: 'T[,] -> int` — base-index (lower bound) of the first dimension.
- `base2: 'T[,] -> int` — base-index (lower bound) of the second dimension.
- `copy: 'T[,] -> 'T[,]` — new array with same elements; basing propagated.
- `blit: source -> sourceIndex1 -> sourceIndex2 -> target -> targetIndex1 -> targetIndex2 -> length1 -> length2 -> unit` — block copy of a rectangular region between two arrays, with bounds checking (`NotSupportedException`/`ArgumentException` mentioned for negative indices or counts beyond limits).
- `init: length1 -> length2 -> (int -> int -> 'T) -> 'T[,]` — creates an array from a per-cell generator.
- `create: length1 -> length2 -> 'T -> 'T[,]` — array filled with a constant value.
- `zeroCreate: length1 -> length2 -> 'T[,]` — array of `Unchecked.defaultof<'T>` entries.
- `initBased: base1 -> base2 -> length1 -> length2 -> (int -> int -> 'T) -> 'T[,]` — based array with generator.
- `createBased: base1 -> base2 -> length1 -> length2 -> 'T -> 'T[,]` — based constant-filled array.
- `zeroCreateBased: base1 -> base2 -> length1 -> length2 -> 'T[,]` — based default-filled array.
- `iter: ('T -> unit) -> 'T[,] -> unit` — apply action to each element.
- `iteri: (int -> int -> 'T -> unit) -> 'T[,] -> unit` — index-aware iteration.
- `length1: 'T[,] -> int` — first-dimension length.
- `length2: 'T[,] -> int` — second-dimension length.
- `map: ('T -> 'U) -> 'T[,] -> 'U[,]` — element transform, basing propagated.
- `mapi: (int -> int -> 'T -> 'U) -> 'T[,] -> 'U[,]` — indexed transform, basing propagated.
- `rebase: 'T[,] -> 'T[,]` — convert non-zero-based input to zero-based output.
- `set: 'T[,] -> index1 -> index2 -> value -> unit` — element write.
- `get: 'T[,] -> index1 -> index2 -> 'T` — element read.

## Notable documentation behavior
- Module-level remarks explain how CLI multi-dimensional arrays may be non-zero-based and that `map`/`mapi` propagate basing, while `zeroCreateBased`/`createBased`/`initBased` create such arrays.
- Each signature carries `<example>` blocks showing usage and expected results.
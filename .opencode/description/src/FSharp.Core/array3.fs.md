# array3.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler; implements the `Array3D` and `Array4D` modules for rank-3 and rank-4 rectangular arrays.

## Namespaces
- `Microsoft.FSharp.Collections`

## Module: Array3D
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Array3D`

Operations on `'T[,,]` arrays, again using IL `ldlen.multi`/`newarr.multi` intrinsics for fast dimension reads.

### Internal helper
- `checkNonNull argName arg` — inline null check raising `nullArg`.

### Functions
- `length1/length2/length3 array` — dimension lengths via `ldlen.multi 3 0/1/2`.
- `get array index1 index2 index3` — element read via indexer.
- `set array index1 index2 index3 value` — element write via indexer.
- `zeroCreate length1 length2 length3` — `newarr.multi 3 !0` allocation; validates all lengths non-negative (`invalidArgInputMustBeNonNegative`).
- `create length1 length2 length3 initial` — `zeroCreate` + triple nested loop fill.
- `init length1 length2 length3 initializer` — generator via adapted `FSharpFunc<_,_,_,_>`.
- `iter action array` — apply action to each element (row-major nested loops).
- `map mapping array` — transform into new `zeroCreate`d array.
- `iteri action array` — index-aware iteration via adapted 4-arg closure.
- `mapi mapping array` — indexed transform via adapted 4-arg closure.

## Module: Array4D
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Array4D`

Operations on `'T[,,,]` arrays:

- `length1/length2/length3/length4 array` — dimension lengths via `ldlen.multi 4 0/1/2/3`.
- `zeroCreate length1 length2 length3 length4` — `newarr.multi 4 !0`; validates all lengths non-negative.
- `create length1 length2 length3 length4 initial` — allocation + 4-deep fill loop.
- `init length1 length2 length3 length4 initializer` — generator via adapted 5-arg `FSharpFunc`.
- `get array i1 i2 i3 i4` / `set array i1 i2 i3 i4 value` — indexer element access.

## Key design notes
- Array3D/Array4D modules do not support non-zero-based arrays; everything assumes lower bound 0.
- High-arity closures are adapted via `OptimizedClosures.FSharpFunc` to avoid per-cell closure allocation during loops.
- `Array3D` iter/map loops allocate no intermediate closures beyond the adapted function.
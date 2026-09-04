# array3.fsi

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler. Public API signature for rank-3 (`Array3D`) and rank-4 (`Array4D`) array operations (implementations in `array3.fs`).

## Namespaces
- `Microsoft.FSharp.Collections`

## Module: Array3D
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Array3D`

Public surface (with XML docs and examples):

- `create: length1 -> length2 -> length3 -> initial: 'T -> 'T[,,]` — constant-filled 3-D array.
- `init: length1 -> length2 -> length3 -> initializer: (int -> int -> int -> 'T) -> 'T[,,]` — generator-built array.
- `get: array -> index1 -> index2 -> index3 -> 'T` — element read.
- `iter: ('T -> unit) -> 'T[,,] -> unit` — apply action to each element.
- `iteri: (int -> int -> int -> 'T -> unit) -> 'T[,,] -> unit` — index-aware iteration.
- `length1/length2/length3: 'T[,,] -> int` — dimension lengths.
- `map: ('T -> 'U) -> 'T[,,] -> 'U[,,]` — element transform.
- `mapi: (int -> int -> int -> 'T -> 'U) -> 'T[,,] -> 'U[,,]` — indexed transform.
- `set: array -> index1 -> index2 -> index3 -> value -> unit` — element write.
- `zeroCreate: length1 -> length2 -> length3 -> 'T[,,]` — default-filled array.

## Module: Array4D
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Array4D`

Public surface:

- `create: length1 -> length2 -> length3 -> length4 -> initial: 'T -> 'T[,,,]` — constant-filled 4-D array.
- `init: length1 -> length2 -> length3 -> length4 -> initializer: (int -> int -> int -> int -> 'T) -> 'T[,,,]` — generator-built array.
- `length1/length2/length3/length4: 'T[,,,] -> int` — dimension lengths.
- `zeroCreate: length1 -> length2 -> length3 -> length4 -> 'T[,,,]` — default-filled array.
- `get: array -> index1 -> index2 -> index3 -> index4 -> 'T` — element read.
- `set: array -> index1 -> index2 -> index3 -> index4 -> value -> unit` — element write.

## Notable documentation behavior
- `Array3D.map`/`mapi` remarks note that basing is propagated even though the module operates on standard zero-based arrays by default.
- Signatures include `<example>` blocks for creation, iteration and access.
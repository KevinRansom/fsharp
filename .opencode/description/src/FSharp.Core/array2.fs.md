# array2.fs

## Pipeline role
Part of FSharp.Core, the standard library shipped with the compiler; this file implements the `Array2D` module providing operations for rank-2 rectangular arrays.

## Namespaces
- `Microsoft.FSharp.Collections`

## Module: Array2D
`[<CompilationRepresentation(ModuleSuffix)>] [<RequireQualifiedAccess>] module Array2D`

The implementation concentrates on performing the primitive array operations via low-level IL typing hints (`(# "ldlen.multi 2 0" array : int #)` etc.) so the F# compiler can inline polymorphic IL for 2-D arrays.

### Internal helper
- `checkNonNull argName arg` — inline null check that raises `ArgumentNullException` via `nullArg`.

### Primitive operations (IL-backed)
- `length1 array` — returns length of first dimension (`ldlen.multi 2 0`).
- `length2 array` — returns length of second dimension (`ldlen.multi 2 1`).
- `base1 array` — returns lower bound of first dimension via `array.GetLowerBound(0)`.
- `base2 array` — returns lower bound of second dimension via `array.GetLowerBound(1)`.
- `get array index1 index2` — element read (`ldelem.multi 2 !0`).
- `set array index1 index2 value` — element write (`stelem.multi 2 !0`).
- `zeroCreate length1 length2` — allocates a zero-initialized array (`newarr.multi 2 !0`); validates lengths are non-negative.
- `zeroCreateBased base1 base2 length1 length2` — creates a based (non-zero lower bound) array; fast path to `zeroCreate` when both bases are 0, otherwise uses `Array.CreateInstance` cast to `'T[,]`.
- `createBased base1 base2 length1 length2 initial` — `zeroCreateBased` + nested loop filling every element with `initial`.
- `initBased base1 base2 length1 length2 initializer` — `zeroCreateBased` + adapted 2-arg `FSharpFunc` invoked per cell.

### Higher-order operations
- `create length1 length2 value` — `createBased 0 0` shortcut.
- `init length1 length2 initializer` — `initBased 0 0` shortcut.
- `iter action array` — apply `action` to every element in row-major order.
- `iteri action array` — apply `(int -> int -> 'T -> unit)` with indices; function adapted via `OptimizedClosures.FSharpFunc<_,_,_,_>`.
- `map mapping array` — build new array via `initBased`, propagating the source basing.
- `mapi mapping array` — indexed map with adapted closures, basing propagated.
- `copy array` — shallow copy that preserves basing (built with `initBased`).
- `rebase array` — converts a based array to a zero-based array of the same dimensions.
- `blit source s0 s1 target t0 t1 count1 count2` — block copy with full bounds checking on both source and target (lower bounds and extents along both axes), raising `ArgumentException` diagnostics for out-of-range indices/counts.

## Key design notes
- Uses IL `ldlen.multi`/`ldelem.multi`/`stelem.multi`/`newarr.multi` intrinsic fragments so array read/write/length code is emitted without array normalization overhead.
- All length-creating functions validate negative lengths using `invalidArgInputMustBeNonNegative`.
- Basing (non-zero lower bounds) is preserved across `map`, `mapi`, and `copy` and handled explicitly by the `*Based` creation family.
- Module carries `#nowarn "3218"` to permit parameter names shadowing the module functions `length1`/`length2`.
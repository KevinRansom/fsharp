# nativeptr.fs

## Overview

This file defines the `NativePtr` module (namespace `Microsoft.FSharp.NativeInterop`) containing operations on **native pointers** (`nativeptr<'T>`). These functions are all `inline` and emit raw IL via the `(# "..." #)` intrinsic syntax, so using them may produce unverifiable code. The module is `[<RequireQualifiedAccess>]` with `[<CompilationRepresentation(ModuleSuffix)>]`. Every function is marked `[<NoDynamicInvocation>]` and has a corresponding IL opcode in its raw body.

## Module `NativePtr`

### Conversions

- `ofNativeInt address` (`OfNativeIntInlined`) — turns a `nativeint` machine address into a typed `nativeptr<'T>` (coercion, no IL op).
- `toNativeInt address` (`ToNativeIntInlined`) — turns a typed `nativeptr<'T>` back into a `nativeint`.
- `ofVoidPtr` / `toVoidPtr` — convert to/from the untyped `voidptr`.
- `ofILSigPtr` / `toILSigPtr` — convert to/from a Common IL signature pointer `ilsigptr<'T>`.
- `toByRef address` (`ToByRefInlined`) — converts a typed native pointer into a managed pointer `byref<'T>`.

### Pointer arithmetic and access

- `add address index` (`AddPointerInlined`) — returns a pointer offset by `index * sizeof<'T>` (uses the `sizeof` intrinsic). Computed as `toNativeInt address + nativeint index * sizeof<'T>` then converted back.
- `get address index` (`GetPointerInlined`) — dereferences `address` at element `index`; emits `ldobj` ("load object") IL.
- `set address index value` (`SetPointerInlined`) — stores `value` into element `index`; emits `stobj`.
- `read address` (`ReadPointerInlined`) — dereferences the pointer directly; emits `ldobj`.
- `write address value` (`WritePointerInlined`) — stores `value` directly; emits `stobj`.

### Allocation and lifecycle

- `stackalloc count` (`StackAllocate`) — allocates `count * sizeof<'T>` bytes on the stack; emits `localloc`.
- `nullPtr<'T>` (`NullPointer`) — returns the null native pointer (`0n`); constrained to `'T : unmanaged`.
- `isNullPtr address` (`IsNullPointer`) — tests whether the pointer is null; emits `ceq` ("compare equal").
- `clear address` (`ClearPointerInlined`) — zeroes out the value at the pointer; emits `initobj`.

### Block operations

- `initBlock address value count` (`InitializeBlockInlined`) — fills `count` bytes starting at `address` with the byte `value`; emits `initblk`.
- `copy destination source` (`CopyPointerInlined`) — copies the value at `source` to `destination`; emits `cpobj`.
- `copyBlock destination source count` (`CopyBlockInlined`) — copies `count * sizeof<'T>` bytes from `source` to `destination`; emits `cpblk`.

All block sizes are computed in bytes; `initBlock`'s `count` is in bytes (`uint32`), while `copyBlock`'s `count` is an element count multiplied by `sizeof<'T>`.

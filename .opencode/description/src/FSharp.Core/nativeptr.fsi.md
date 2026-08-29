# nativeptr.fsi

## Overview

This is the public API signature for the `NativePtr` module (namespace `Microsoft.FSharp.NativeInterop`), exposing operations on native pointers. The signature adds `[<Unverifiable>]` attributes to highlight that these operations may generate unverifiable code. The module is `[<RequireQualifiedAccess>]` with `[<CompilationRepresentation(ModuleSuffix)>]`; every binding is `inline` and `[<NoDynamicInvocation>]`, with a `[<CompiledName>]`.

## Module `NativePtr`

Exposed API (all functions take a typed `nativeptr<'T>` where relevant):

### Conversions

- `ofNativeInt : address: nativeint -> nativeptr<'T>` (`OfNativeIntInlined`)
- `toNativeInt : address: nativeptr<'T> -> nativeint` (`ToNativeIntInlined`)
- `ofVoidPtr : address: voidptr -> nativeptr<'T>` (`OfVoidPtrInlined`)
- `toVoidPtr : address: nativeptr<'T> -> voidptr` (`ToVoidPtrInlined`)
- `ofILSigPtr : address: ilsigptr<'T> -> nativeptr<'T>` (`OfILSigPtrInlined`)
- `toILSigPtr : address: nativeptr<'T> -> ilsigptr<'T>` (`ToILSigPtrInlined`)
- `toByRef : address: nativeptr<'T> -> byref<'T>` (`ToByRefInlined`)

### Pointer arithmetic and access

- `add : address: nativeptr<'T> -> index: int -> nativeptr<'T>` (`AddPointerInlined`) — pointer offset by `index * sizeof<'T>`.
- `get : address: nativeptr<'T> -> index: int -> 'T` (`GetPointerInlined`) — dereferences the element at `index`.
- `read : address: nativeptr<'T> -> 'T` (`ReadPointerInlined`) — dereferences the pointer.
- `write : address: nativeptr<'T> -> value: 'T -> unit` (`WritePointerInlined`) — stores a value.
- `set : address: nativeptr<'T> -> index: int -> value: 'T -> unit` (`SetPointerInlined`) — stores a value by index.

### Allocation and lifecycle

- `stackalloc : count: int -> nativeptr<'T>` (`StackAllocate`).
- `nullPtr<'T when 'T : unmanaged> : nativeptr<'T>` (`NullPointer`, also `[<GeneralizableValue>]`).
- `isNullPtr : address: nativeptr<'T> -> bool` (`IsNullPointer`).
- `clear : address: nativeptr<'T> -> unit` (`ClearPointerInlined`).

### Block operations

- `initBlock : address: nativeptr<'T> -> value: byte -> count: uint32 -> unit` (`InitializeBlockInlined`).
- `copy : destination: nativeptr<'T> -> source: nativeptr<'T> -> unit` (`CopyPointerInlined`).
- `copyBlock : destination: nativeptr<'T> -> source: nativeptr<'T> -> count: int -> unit` (`CopyBlockInlined`), copying `count * sizeof<'T>` bytes.

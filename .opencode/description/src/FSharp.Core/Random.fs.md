# Random.fs

## Overview

This small file (namespace `Microsoft.FSharp.Core`) defines an internal helper type, `ThreadSafeRandom`, that provides a shared, thread-safe `System.Random` instance. It exists to give the FSharp.Core library a single random number generator that can be safely used from multiple threads.

## `type internal ThreadSafeRandom` (`[<AbstractClass; Sealed>]`)

- A private `[<ThreadStatic>]` static field `random: Random` (with `[<DefaultValue>]`). Because it is `[<ThreadStatic>]`, each thread gets its own instance, avoiding contention on the shared `Random`'s internal seed state.
- `static member private Create()` — annotated `[<MethodImpl(MethodImplOptions.NoInlining)>]` to prevent the field read being hoisted/inlined in a way that would be unsafe across threads; it allocates a fresh `Random()` and stores it in the thread-static slot.
- `static member Shared` — returns the thread-static `Random`, lazily calling `Create()` if the thread has none yet. The comment notes callers must not pass the returned `Random` object to other threads.

The whole type is `internal`, so it is only used within FSharp.Core.

# Random.fsi

## Overview

This is the signature (interface) file for `Random.fs`, in namespace `Microsoft.FSharp.Core`.

## `type internal ThreadSafeRandom` (`[<AbstractClass; Sealed>]`)

Declares only the public-by-signature surface of the helper:
- `static member Shared: Random` — a lazily-created, thread-safe shared `System.Random` instance.

Because the type is `internal`, this helper is not part of FSharp.Core's publicly documented API; it is only a module-internal utility.

# fsiattrs.fs

> Pipeline role: Assembly-attribute glue for the F# Interactive settings library — opens `FSharp.Compiler.Interactive.Settings` automatically so the `fsi` object is in scope by default inside FSI sessions.
> Namespace: `module FSharp.Compiler.Interactive.Attributes` (line 3).

---

## Implementation

- `[<assembly: AutoOpen("FSharp.Compiler.Interactive.Settings")>] do ()` — when the FSI execution context loads this assembly, the `Settings` module's `fsi` value is auto-opened into scope. Companion assembly attribute file reused with `fsiaux.fs` (which repeats the same `AutoOpen` for its module).

---

## Related

- Pairs with `fsiaux.fs`/`fsiaux.fsi` (the actual `IEventLoop`/`InteractiveSession` definitions).
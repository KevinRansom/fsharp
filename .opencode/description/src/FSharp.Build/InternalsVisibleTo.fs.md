# InternalsVisibleTo.fs

> Pipeline role: Assembly attribute hunky — declares `[<InternalsVisibleTo("VisualFSharp.UnitTests, PublicKey=...")>]` so the internal compiler surface is testable from the unit-test suite.
> Namespace: `Microsoft.FSharp` is the declared namespace block, but the file's actual content is an assembly attribute.
> Note: nested under `FSharp.Build` in the source tree purely by layout.

---

## Implementation

- `namespace Microsoft.FSharp` (only so the file bottom `do ()` has a location; the namespace here is incidental).
- `[<assembly: System.Runtime.CompilerServices.InternalsVisibleTo("VisualFSharp.UnitTests, PublicKey=00240000...")>] do ()` — grants `VisualFSharp.UnitTests` full visibility over the `Microsoft.FSharp` internals (the F# compiler assemblies team this chased to the CompilerPlugin test runner and the IDE test host).

---

## Related

- Companion grants live inside `src/Compiler/*` `AssemblyInfo`-style files; this one specifically feeds `VisualFSharp.UnitTests`.
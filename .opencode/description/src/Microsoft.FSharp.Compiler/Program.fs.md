# Program.fs

> Pipeline role: Dummy entry point for the `Microsoft.FSharp.Compiler` assembly used in build configuration only (the real compiler lives in `fsc\fscmain.fs` and `fsi\fsimain.fs`; this file satisfies the `Exe` output format's need for a `main`).
> Namespace: (global, no module header).

---

## Implementation

- `[<EntryPoint>] let main _ = 0` — two-line stub returning `0`; never really executed by shipped products. Exists because the `Microsoft.FSharp.Compiler` project output is configured as an executable when built standalone; the assembly's actual consumers link against it as a library.

---

## Related

- Replaced in `fsc`/`fsi` executables by `CommandLineMain`/`InteractiveMain` respectively.
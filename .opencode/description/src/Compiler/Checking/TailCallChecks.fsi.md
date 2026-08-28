# TailCallChecks.fsi

**Purpose**
Public contract for the TailCall analysis pass. Declares the single entry point `CheckImplFile`, which
performs tail-call analysis on the optimized TAST of a file: for functions annotated with the
`[<TailCall>]` attribute, it warns if they are called in a non-tail-recursive manner within the function's
recursive scope. The traversal is analogous to the `PostInferenceChecks` phase and does not mutate the
`ModuleOrNamespaceContents`.

**Namespace(s)**
`module internal FSharp.Compiler.TailCallChecks`

**Public API surface** (complete)
- `CheckImplFile: g: TcGlobals -> amap: Import.ImportMap -> reportErrors: bool -> implFileContents: ModuleOrNamespaceContents -> unit` — perform the TailCall analysis on the optimized TAST for a file.

**Significant notes**
- The pass is *read-only* on the TAST (per the doc comment: "The ModuleOrNamespaceContents aren't mutated
  in any way by performing this check"); its only observable effect is diagnostics (the
  `chkNotTailRecursive` warning).
- `reportErrors` controls whether diagnostics are raised as errors (e.g. in test/CI builds) or warnings.
- The pass must run *after* optimization (hence "optimized TAST") because tail blockers such as
  `newobj`/`super`/constrained calls, byref arguments, and DllImport are most visible in the lowered form.

**Cross-references**
- `TailCallChecks.fs` — implementation (`TailCall`/`TailCallReturnType` types, `CheckForNonTailRecCall`,
  the recursive `Check*` family, `hasTailCallAttrib`).
- `PostInferenceChecks.fsi` (sibling) — the analogous byref/limit post-check pass; same phase ordering and
  same `TcGlobals`/`ImportMap`/`reportErrors`/`ModuleOrNamespaceContents` parameter shape.
- `AttributeChecking.fsi` (sibling) — definition of `TailCallAttribute` / `WellKnownValAttributes` used to
  detect the annotation.
- `CheckDeclarations.fsi` (sibling) — drives the post-inference passes over a file.

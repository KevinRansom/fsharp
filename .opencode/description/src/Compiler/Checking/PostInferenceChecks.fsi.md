# PostInferenceChecks.fsi

**Purpose**
Public contract for the checks performed on the TAST of a file after type inference is complete. Exposes
the single `CheckImplFile` entry point (used by `CheckDeclarations` after inference) and the `Limit`
abstraction (byref escape-limit computation) which is separately importable "to allow testing".

**Namespace(s)**
`module internal FSharp.Compiler.PostTypeCheckSemanticChecks`

**Modules / Types declared**
- `CheckImplFile: TcGlobals -> ImportMap -> bool (reportErrors) -> InfoReader -> CompilationPath list (internalsVisibleToPaths) -> CcuThunk -> ConstraintSolver.TcValF -> DisplayEnv -> ModuleOrNamespaceType -> ModuleOrNamespaceContents -> Attribs (extraAttribs) -> (bool * bool) -> bool (isInternalTestSpanStackReferring) -> bool * StampMap<AnonRecdTypeInfo>` — the single public function. Returns a success flag plus stamps of anonymous record type info.
- `module Limit` — the byref-escape limit abstraction (exposed for testing):
  - `LimitFlags` (`[System.Flags]`) — `None = 0b00000`, `ByRef = 0b00001`, `ByRefOfSpanLike = 0b00011`, `ByRefOfStackReferringSpanLike = 0b00101`, `SpanLike = 0b01000`, `StackReferringSpanLike = 0b10000`.
  - `Limit` (`[Struct]`) — record `{ scope: int; flags: LimitFlags }`. `scope` is "to which scope can a Val safely escape"; 0 = top-level/unlimited, 1 = top-level local (e.g. `let x = &y` cannot be at top level), increasing with nested let/method/module nesting.
  - `NoLimit: Limit` — no limit applies.
  - `CombineTwoLimits: Limit -> Limit -> Limit` — meet of two limits (a Val must obey both simultaneously); if neither limits byref/span-like, the resulting scope is 0.

**Significant notes**
- The fsi's doc comments explain why `Limit.scope` exists (tracking where a Val may legally escape, which
  is scope-sensitive: a top-level function may return a byref type, an inner function may not) and what the
  commonly-used scope values (0, 1) mean.
- `CheckImplFile` takes `internalsVisibleToPaths` so the check can enforce friend-assembly accessibility,
  `CcuThunk` so it can look across the compilation unit, and `ConstraintSolver.TcValF` so it can
  materialize value references consistently with the checking pass.
- The doc comment states the module is unlikely to be used outside PostInferenceChecks except via this
  entry point, and that `Limit` is exposed specifically to permit testing.

**Cross-references**
- `PostInferenceChecks.fs` — implementation (env record, `LimitVal`/`CheckExpr*`, `CheckEntityDefn`, re-raise safety checks).
- `ConstraintSolver.fsi` (sibling) — `TcValF` signature.
- `CheckDeclarations.fsi` (sibling) — caller of `CheckImplFile`.
- `TailCallChecks.fsi` — the other post-inference file-level check (tail-call).
- `MethodOverrides.fsi` — `FinalTypeDefinitionChecksAtEndOfInferenceScope` is the parallel end-of-scope check at the type level.

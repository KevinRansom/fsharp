# InnerLambdasToTopLevelFuncs.fs

**Purpose**: Implements TLR — "Top-Level Representation" decisions. It determines which inner (nested) functions of a compilation unit should be hoisted to top-level methods taking an explicit "closure" argument for the free values they need, versus remaining closed over via local cells. This is the F# pass that turns inner lambdas into top-level functions with required-item (free-variable) parameters.

**Namespace / module declared**: `FSharp.Compiler.InnerLambdasToTopLevelFuncs` (internal module; contract in `InnerLambdasToTopLevelFuncs.fsi`)

**API surface**:
- `MakeTopLevelRepresentationDecisions: ImportMap -> PerFileNamingScope -> CcuThunk -> TcGlobals -> CheckedImplFile -> CheckedImplFile` — the single entry point; runs all four passes over an implementation file.

**Pipeline structure (named internal modules/lets)**:
- `Pass1_DetermineTLRAndArities` — first decides which functions get top-level representation and computes their (arity, typar) representation info; uses helpers `IsMandatoryTopLevel`, `IsMandatoryNonTopLevel`, `IsRefusedTLR`, `ShouldInline`-related filtering (`GetValsBoundUnderShouldInline`), and `BodyReferencesTypeScopedPrivate`.
- `Pass2_DetermineReqdItems` — for each top-level-repr function, determines the *required items* (`ReqdItem`s: `ReqdSubEnv f` for nested functions, `ReqdVal v` for free values) it needs in scope. `BindingGroupSharingSameReqdItems` groups functions that share the same required items; `ReqdItemsForDefn` accumulates them (typed under given typars).
- `PackedReqdItems` / `FlatEnvPacks` / `ChooseReqdItemPackings` — groups free values into shared "environment packs" so multiple functions can close over the same heap cell instead of duplicating.
- `CreateNewValuesForTLR` — mint fresh `Val`s for the hoisted top-level representations, using `PerFileNamingScope` naming (`mkLocalNameTypeArity`) based on the chosen arities (`MakeSimpleArityInfo`).
- `Pass4_RewriteAssembly` — rewrites the file: definitions become the top-level forms (rebinding `this`/free-value arguments back to local names), call sites are updated to pass the required items.

**Internal helpers**:
- `Tree<'T>` + `fringeTR`/`emptyTR` — tiny helper type for tree fringe operations.
- `Zmap` re-export; `destApp`; `showTyparSet`.
- `isDelayedRepr`, `IsArityMet`.
- `RecreateUniqueBounds` — rebuild `unique`-type bindings after rewriting.
- `verboseTLR` / `internalError` — diagnostics scaffolding.

**Significant internal logic**:
- Refinement order: mandatory top-level (e.g. used as first-class values) vs. mandatory non-top-level (e.g. captures type-scoped private state or is inline-refused), then TLR for the rest.
- Required-item analysis is the core: a function's "environment" is the set of free *values and functions* it refers to, which must be threaded through as explicit arguments in the hoisted form; shared environments are packed to reuse one allocation.
- Recursive/mutual bindings are handled together; a binding group with a shared required-items set is a unit of the decision.

**Cross-references**:
- Signature: `InnerLambdasToTopLevelFuncs.fsi`.
- Pipeline sibling in `src/Compiler/Optimize/` (detupling, lowering passes, `Optimizer.fs`).
- Produces `Val`s with `ValReprInfo` (arities) that later drives `LowerCalls.fs` / `Optimizer.fs` inlining and `EraseClosures.fs` at ILX level.
- Depends on `ImportMap`/`CcuThunk` (`FSharp.Compiler.Import`), `TcGlobals`, `PerFileNamingScope` (`FSharp.Compiler.CompilerGlobalState`), and `TypedTree`.
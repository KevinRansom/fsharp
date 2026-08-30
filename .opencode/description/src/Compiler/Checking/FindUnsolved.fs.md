# FindUnsolved.fs

**Purpose**: Finds all unsolved (free) inference type variables remaining after type inference has completed for an entire checked file/module. Used at the end of a file's checking to collect `Typar`s that were never resolved or generalized.

**Namespace(s)**: `module internal FSharp.Compiler.FindUnsolved`

**Public API surface**:
- `UnsolvedTyparsOfModuleDef : g: TcGlobals -> amap: ImportMap -> denv: DisplayEnv -> mdef: ModuleOrNamespaceContents -> extraAttribs: Attrib list -> Typar list`
  — walks the checked module contents (`ModuleOrNamespaceContents`) and the extra attributes, accumulating every typar that is still in an unsolved (inference) state; returns the collected `Typar list`.

**Internal structure** (in the .fs):
- A small local env ADT `type env = | NoEnv` (line ~17) tracking whether an accumulator is currently "inside" a scope that suppresses reporting (e.g. inside a type-parameter declaration where typars are legitimately named).
- `type cenv = { g: TcGlobals; amap: ImportMap; denv: DisplayEnv }` (line ~20) bundles the globals needed by the accumulators.
- `accExpr (cenv) (env) expr` (line ~44, `let rec`) — traverses a single TAST `Expr`, collecting unsolved typars in its type annotations, argument types, and nested expressions. Large because it pattern-matches over all the TAST `Expr` cases.
- `accModuleOrNamespaceDefs cenv env defs` (line ~284, `let rec`) — traverses `ModuleOrNamespaceContents` defs (bindings, member defs, type defs) and their type schemes, delegating expression traversal to `accExpr`.

**Significant internal logic**:
- The walk is deliberately conservative about *where* typars are "declared" vs. "referenced": a typar appearing in a declaration's own typar list is not reported, but a typar appearing in a body or in a position not bound by a nearby declaration is an unsolved inference variable. The `env` ADT distinguishes these scopes.
- `extraAttribs` are checked in addition to the module contents so that attribute expressions (which may contain fresh inference variables) are not missed.

**Cross-references**: `FindUnsolved.fsi` (contract), `TcGlobals`/`ImportMap` (from `import.fs`), TAST types in `TypedTree` (`ModuleOrNamespaceContents`, `Expr`, `Typar`), `CheckDeclarations.fs` (the file-checking driver that would invoke this at the end of a file), `ConstraintSolver.fs` (where unsolved typars normally get resolved).

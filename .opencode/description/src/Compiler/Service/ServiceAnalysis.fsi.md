# ServiceAnalysis.fsi

**Purpose**: Public contract for `ServiceAnalysis.fs` — three "analysis" modules that, given a `FSharpCheckFileResults`, report (a) unused `open` statements, (b) unnecessarily-qualified names that can be simplified, and (c) unused declarations.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## Modules declared

- **`module UnusedOpens`**
  - `getUnusedOpens: checkFileResults: FSharpCheckFileResults * getSourceLineStr: (int -> string) -> Async<range list>` — "get all unused open declarations in a file".
- **`module SimplifyNames`**
  - `type SimplifiableRange = { Range: range; RelativeName: string }` — "the range of a name that can be simplified" and "the relative name that can be applied to a simplifiable name".
  - `getSimplifiableNames: checkFileResults * getSourceLineStr -> Async<seq<SimplifiableRange>>` — "get all ranges that can be simplified in a file".
- **`module UnusedDeclarations`**
  - `getUnusedDeclarations: checkFileResults * isScriptFile: bool -> Async<seq<range>>` — "get all unused declarations in a file".

## Public API surface

- Exactly the three entry points above plus `SimplifiableRange`. No other types are public in this contract — the internal `OpenedModule`/`OpenedModuleGroup`/`OpenStatement` machinery in the `.fs` is not exposed.

## Internal helpers / active patterns

- None re-exported; the `.fs` `OpenedModule.RevealedSymbolsContains`, `OpenedModuleGroup.Create`, and `isPotentiallyUnusedDeclaration` heuristics are all internal.

## Significant internal logic (contract notes)

- All three are `Async` and accept `Async.CancellationToken` for cooperative cancellation in the implementation (see `ServiceAnalysis.fs`).
- `getSimplifiableNames` returns the *unnecessary prefix range* (not the full name range) with the suggested relative name — callers draw a "simplify" squiggle on that prefix.
- `getUnusedDeclarations` takes `isScriptFile` because in scripts a declaration is "unused" only if it is also file-private (or the file is a script); this distinction shows up in the returned ranges.

## Cross-references

- Input: `FSharpCheckFileResults` (see `FSharpCheckerResults.fsi`) — specifically `GetAllUsesOfAllSymbolsInFile`, `OpenDeclarations`, `IsRelativeNameResolvableFromSymbol`.
- Position/name reconstruction uses `QuickParse.GetPartialLongNameEx` (see `QuickParse.fsi`) and `range`/`Position` from `FSharp.Compiler.Text`.
- Consumed by the editor tooling (Visual F#, F# Language Server) for "remove unused open", "simplify name" and gray-out-unused-declarations features.

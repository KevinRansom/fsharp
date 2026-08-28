# ServiceAnalysis.fs

**Purpose**: "Analysis" queries over a checked project file that power editor refactoring-style suggestions: unused `open` statements, unnecessarily-qualified names that can be shortened, and unused declarations. These are computed from `FSharpCheckFileResults` (i.e. after type checking) plus a cheap source-line reader.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## Modules / Types declared

- **`module UnusedOpens`**
  - `OpenedModule(entity, isNestedAutoOpen)` — wraps an `FSharpEntity` plus a lazily-computed `revealedSymbols` set (nested entities, record fields, union cases, extension members guarded by `[<Extension>]`, active-pattern cases, enum literal fields); `RevealedSymbolsContains(symbol)`.
  - `OpenedModuleGroup` — `{ OpenedModules: OpenedModule[] }` with `static member Create(modul)` that recurses into `[<AutoOpen>]` nested modules.
  - `OpenStatement` — `{ OpenedGroups: OpenedModuleGroup list; Range: range }` — one `open` decl, expanded to auto-opens.
  - `getUnusedOpens: FSharpCheckFileResults * (int -> string) -> Async<range list>` — collects symbol uses, finds which `open` statements reveal no used symbol, and returns the unused-open ranges.
- **`module SimplifyNames`**
  - `SimplifiableRange` — record `{ Range: range; RelativeName: string }`.
  - `getSimplifiableNames: FSharpCheckFileResults * (int -> string) -> Async<seq<SimplifiableRange>>` — for each use with a qualifying plid, computes the *necessary* prefix via `IsRelativeNameResolvableFromSymbol` (walking the plid until the name still resolves) and reports the drop-able prefix range plus the relative name.
- **`module UnusedDeclarations`**
  - `isPotentiallyUnusedDeclaration` — excludes records/DUs/interfaces/modules/classes/namespaces (too expensive to trace), override/base/constructor members, and `FSharpParameter`s.
  - `getUnusedDeclarationRanges` — uses `GetAllUsesOfAllSymbolsInFile`, flags definition sites with no uses (script files or file-private decls, name not starting with `_`).
  - `getUnusedDeclarations: FSharpCheckFileResults * bool -> Async<seq<range>>` — top-level entry point.

## Public API surface

- `UnusedOpens.getUnusedOpens`, `SimplifyNames.getSimplifiableNames` (+ `SimplifiableRange`), `UnusedDeclarations.getUnusedDeclarations` — all per the `.fsi`.

## Internal helpers / active patterns

- `symbolHash` — `HashIdentity` over `FSharpSymbol` using `GetEffectivelySameAsHash`/`IsEffectivelySameAs` so `OpenedModule.RevealedSymbolsContains` keys correctly.
- `getPlidLength` — total char width of a prefix list (for range arithmetic).
- `filterOpenStatements` — matches symbol uses against opened groups (skips uses that come from definitions or the open statement itself).

## Significant internal logic

- **UnusedOpens**: for each use, check whether any `OpenedModuleGroup.RevealedSymbols` contains the used symbol — if none of a given open's groups contribute, the whole statement is unused. Uses async + `Async.CancellationToken` for cooperative cancellation.
- **SimplifyNames**: works off `GetAllUsesOfAllSymbolsInFile`, groups by (line, plid start col), keeps the rightmost use per plid, then walks the plid backward using `IsRelativeNameResolvableFromSymbol` to find the shortest resolvable prefix; the dropped prefix is the `Range` and the full dotted name is `RelativeName`.
- **UnusedDeclarations**: conservative exclusions (records/DUs/modules, overrides, parameters) reflect the documented comment that full use-traversal of composite types is too expensive and that FCS results for overrides are inconsistent.
- Both `SimplifyNames` and `UnusedOpens` require a `getSourceLineStr: int -> string` to fetch the source text for the relevant line (avoids holding the full file).

## Cross-references

- Contract: `ServiceAnalysis.fsi`.
- Input type: `FSharpCheckFileResults` (see `FSharpCheckerResults.fs/.fsi`) — specifically `GetAllUsesOfAllSymbolsInFile`, `OpenDeclarations`, and `IsRelativeNameResolvableFromSymbol`.
- `QuickParse.GetPartialLongNameEx` is used by `SimplifyNames` to reconstruct the qualified name at a position (see `QuickParse.fs`).
- Consumed by language-service features in tools (Visual F#, F# LSP) to drive "remove unused open", "simplify name", and gray-out-unused-declarations.

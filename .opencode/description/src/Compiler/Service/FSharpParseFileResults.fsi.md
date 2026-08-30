# FSharpParseFileResults.fsi

**Purpose**: Public contract for `FSharpParseFileResults` — "represents the results of parsing an F# file and a set of analysis operations based on the parse tree alone." The type is sealed and its constructor is internal, so clients only get instances from `FSharpChecker.ParseFile` / `ParseAndCheckFileInProject`.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## Types declared

- **`FSharpParseFileResults`** (sealed, public)
  - `ParseTree: ParsedInput` — the syntax tree.
  - `FileName: string`, `Diagnostics: FSharpDiagnostic[]`, `ParseHadErrors: bool`, `DependencyFiles: string[]` (files whose change invalidates the build).
  - Parse-tree-only position queries (all in one line of the fsi summary):
    - `TryRangeOfNameOfNearestOuterBindingContainingPos: pos -> range option`
    - `TryRangeOfParenEnclosingOpEqualsGreaterUsage: pos -> (range * range * range) option`
    - `TryRangeOfStringInterpolationContainingPos`, `TryRangeOfExprInYieldOrReturn`, `TryRangeOfRecordExpressionContainingPos`
    - `TryIdentOfPipelineContainingPosAndNumArgsApplied: pos -> (Ident * int) option`
    - `IsPosContainedInApplication: pos -> bool`, `IsTypeName: range -> bool`
    - `TryRangeOfFunctionOrMethodBeingApplied`, `GetAllArgumentsForFunctionApplicationAtPosition`
    - `TryRangeOfRefCellDereferenceContainingPos`, `TryRangeOfExpressionBeingDereferencedContainingPos`
    - `TryRangeOfReturnTypeHint: pos * ?skipLambdas -> range option`
    - `FindParameterLocations: pos -> ParameterLocations option`
    - `IsPositionContainedInACurriedParameter`, `IsTypeAnnotationGivenAtPosition`, `IsPositionWithinTypeDefinition`, `IsBindingALambdaAtPosition`, `IsPositionWithinRecordDefinition`
    - `GetNavigationItems: unit -> NavigationItems`
    - `ValidateBreakpointLocation: pos -> range option`
  - `internal new: diagnostics * input: ParsedInput * parseHadErrors * dependencyFiles -> FSharpParseFileResults`.

## Public API surface

- The whole public surface is this one class. The fsi deliberately marks the constructor internal so result objects are only produced by the checker.

## Internal helpers / active patterns

- Referenced external types: `ParsedInput`/`Ident` (`FSharp.Compiler.Syntax`), `FSharpDiagnostic` (`FSharp.Compiler.Diagnostics`), `ParameterLocations` (`ServiceParamInfoLocations.fsi`), `NavigationItems` (`ServiceNavigation.fsi`), `range`/`pos` (`FSharp.Compiler.Text`).

## Significant internal logic (contract notes)

- Everything here is parse-tree-based (no type info) — these queries must work on incomplete/errored code for editor responsiveness, in contrast to `FSharpCheckFileResults` queries which require a successful check.
- `TryIdentOfPipelineContainingPosAndNumArgsApplied` documents its semantics in the fsi (e.g. `[1..10] |> List.map` yields the `|>` ident and 1 applied arg).
- `TryRangeOfReturnTypeHint` returns `None` when a type annotation is already present.

## Cross-references

- Implemented in `FSharpParseFileResults.fs` (same file also defines `CompletionContext` and friends used by declaration lists).
- Created by `FSharpChecker.ParseFile` / `GetBackgroundParseResultsForFileInProject` / `ParseAndCheckFileInProject` (see `service.fsi`).
- Optional input to `FSharpCheckFileResults.GetDeclarationListInfo` for location-based decl filtering (see `FSharpCheckerResults.fsi`).

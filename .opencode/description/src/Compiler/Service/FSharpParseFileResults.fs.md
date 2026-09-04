# FSharpParseFileResults.fs

**Purpose**: Implementation of `FSharpParseFileResults` — the handle to a parsed F# file carrying the `ParsedInput` AST, parse diagnostics, dependency files, and a battery of cheap AST-based position queries used by the language service (nearest binding, pipeline ident, record/class contexts, breakpoint validation, navigation items, parameter-info locations). Also defines the `CompletionContext` vocabulary for declaration lists.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## Types / Modules declared

- **`module SourceFileImpl`** — `IsSignatureFile` (extension check), `GetImplicitConditionalDefinesForEditing` (the `COMPILED`/`INTERACTIVE` + `EDITING` defines implied when editing).
- **`CompletionPath`** — typedef `string list * string option` (plid * residue).
- **`FSharpInheritanceOrigin`** (union) — `Class`/`Interface`/`Unknown`.
- **`InheritanceContext`** (union) — `Class`/`Interface`/`Unknown`.
- **`RecordContext`** (union) — `CopyOnUpdate of range * CompletionPath`, `Constructor of typeName`, `New of path`.
- **`CompletionContext`** (union) — `Invalid`, `Inherit of InheritanceContext * CompletionPath`, `RecordField of RecordContext`, `RangeOperator`, `ParameterList of pos * HashSet<string>`, `AttributeApplication`, `OpenDeclaration of isOpenType`, `PatternType`.
- **`FSharpParseFileResults`** (sealed) — main type, see above.

## Public API surface

- `ParseTree: ParsedInput`, `FileName`, `Diagnostics`, `ParseHadErrors`, `DependencyFiles`.
- Position queries: `TryRangeOfNameOfNearestOuterBindingContainingPos`, `TryRangeOfParenEnclosingOpEqualsGreaterUsage`, `TryRangeOfStringInterpolationContainingPos`, `TryRangeOfExprInYieldOrReturn`, `TryRangeOfRecordExpressionContainingPos`, `TryIdentOfPipelineContainingPosAndNumArgsApplied`, `IsPosContainedInApplication`, `IsTypeName`, `TryRangeOfFunctionOrMethodBeingApplied`, `GetAllArgumentsForFunctionApplicationAtPosition`, `TryRangeOfRefCellDereferenceContainingPos`, `TryRangeOfExpressionBeingDereferencedContainingPos`, `TryRangeOfReturnTypeHint`, `FindParameterLocations` (returns `ParameterLocations`), `IsPositionContainedInACurriedParameter`, `IsTypeAnnotationGivenAtPosition`, `IsPositionWithinTypeDefinition`, `IsBindingALambdaAtPosition`, `IsPositionWithinRecordDefinition`, `GetNavigationItems`, `ValidateBreakpointLocation`.
- Internal constructor from `(diagnostics, input, parseHadErrors, dependencyFiles)`.

## Internal helpers / active patterns

- AST walk code over `ParsedInput` implementing each position query (local functions inside the class; e.g. pipeline ident scanning, record/class context detection).
- Active patterns/helpers for matching decl items (`|Binding|_|`-style local patterns in the walk code).

## Significant internal logic

- All queries are pure functions of the `ParsedInput` AST — no type information needed, which is why they must remain cheap and correct on incomplete code (mid-typing).
- `TryIdentOfPipelineContainingPosAndNumArgsApplied` counts already-applied args for `|>`/`>>` pipelines, feeding parameter info.
- `FindParameterLocations`/`ParameterLocations` (see `ServiceParamInfoLocations.fs`) drive C#-style parameter hints for F# curried/pipelined applications.
- `GetNavigationItems` produces the outline items (modules, types, members) for the editor outline view; `ValidateBreakpointLocation` finds the innermost executable range containing a position.

## Cross-references

- Contract: `FSharpParseFileResults.fsi`.
- `NavigationItems` from `ServiceNavigation.fs`; `ParameterLocations` from `ServiceParamInfoLocations.fs`.
- Consumed by `FSharpChecker.ParseFile` (see `service.fs`) and by `FSharpCheckFileResults.GetDeclarationListInfo` as an optional parse-tree filter (see `FSharpCheckerResults.fs`).
- `ParsedInput`/`Ident` come from `FSharp.Compiler.Syntax`.

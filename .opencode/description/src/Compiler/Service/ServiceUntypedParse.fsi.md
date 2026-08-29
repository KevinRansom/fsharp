# ServiceUntypedParse.fsi

**Signature file only** (no `.fs` implementation in scope; it describes the legacy `FSharp.Compiler.SourceCodeServices` parse-result API surface). Declares the classic "untyped parse" result type and the legacy completion-context helpers.

## Pipeline role

`FSharpChecker` service-layer file (legacy API namespace `FSharp.Compiler.SourceCodeServices`): after a file has been parsed without type checking, `FSharpParseFileResults` exposes the syntax tree plus quick syntax-only queries used by IDEs — parameter-info locations, function-application argument ranges, type-annotation/binding-lambda checks, navigation items, breakpoint validation, dependency files, and parse errors. The surrounding `CompletionPath`/`InheritanceContext`/`RecordContext`/`CompletionContext`/`ModuleKind`/`EntityKind` types are the older, smaller predecessors of the ones in `ServiceParsedInputOps` (which extends them with `Type`, `Pattern`, `MethodOverride`, `RecordSpread`, `UnionCaseFieldsDeclaration`, etc. in `FSharp.Compiler.EditorServices`).

## Namespaces

- `FSharp.Compiler.SourceCodeServices` with `open System.Collections.Generic`, `FSharp.Compiler.Range` (legacy range module?), `FSharp.Compiler.SyntaxTree` (legacy AST types).

## Public types (declared)

- `type FSharpParseFileResults` (`[<Sealed>]`) — the parse outcome:
  - `member ParseTree: ParsedInput option` — the syntax tree.
  - `member FindNoteworthyParamInfoLocations: pos: pos -> FSharpNoteworthyParamInfoLocations option` — ParameterInfo activation data.
  - `member GetAllArgumentsForFunctionApplicationAtPosition: pos: pos -> range list option` — ranges of all curried arguments.
  - `member IsTypeAnnotationGivenAtPosition: pos -> bool`.
  - `member IsBindingALambdaAtPosition: pos -> bool`.
  - `member FileName: string`.
  - `member GetNavigationItems: unit -> FSharpNavigationItems` — navbar model.
  - `member ValidateBreakpointLocation: pos: pos -> range option` — innermost breakpoint-able range.
  - `member DependencyFiles: string[]`.
  - `member Errors: FSharpErrorInfo[]`; `member ParseHadErrors: bool`.
  - `internal new: errors: FSharpErrorInfo[] * input: ParsedInput option * parseHadErrors: bool * dependencyFiles: string[] -> FSharpParseFileResults` — internal constructor.
- `module SourceFile` (public):
  - `val IsCompilable: string -> bool`; `val MustBeSingleFileProject: string -> bool`.
- `type CompletionPath = string list * string option` (plid * residue).
- `type InheritanceContext` — `Class | Interface | Unknown`.
- `type RecordContext` — `CopyOnUpdate of range * CompletionPath | Constructor of string | New of CompletionPath`.
- `type CompletionContext` — `Invalid | Inherit of InheritanceContext * CompletionPath | RecordField of RecordContext | RangeOperator | ParameterList of pos * HashSet<string> | AttributeApplication | OpenDeclaration of isOpenType: bool | PatternType`.
- `type ModuleKind` — `{ IsAutoOpen: bool; HasModuleSuffix: bool }`.
- `type EntityKind` — `Attribute | Type | FunctionOrValue of isActivePattern: bool | Module of ModuleKind`.

## Modules

- `module UntypedParseImpl` (public) — implementation-detail entry points bridging to the `FSharp.Compiler.EditorServices.ParsedInput` logic:
  - `TryFindExpressionASTLeftOfDotLeftOfCursor: pos * ParsedInput option -> (pos * bool) option`.
  - `GetRangeOfExprLeftOfDot: pos * ParsedInput option -> range option`.
  - `TryFindExpressionIslandInPosition: pos * ParsedInput option -> string option`.
  - `TryGetCompletionContext: pos * ParsedInput * lineStr: string -> CompletionContext option`.
  - `GetEntityKind: pos * ParsedInput -> EntityKind option`.
  - `GetFullNameOfSmallestModuleOrNamespaceAtPoint: ParsedInput * pos -> string[]`.
- `module SourceFileImpl` (internal):
  - `val IsInterfaceFile: string -> bool`.
  - `val AdditionalDefinesForUseInEditor: isInteractive: bool -> string list`.

## Relation to .fs

There is no corresponding `.fs` doc in this set; the `.fsi` constrains the public surface of the legacy untyped-parse layer. The specific member behaviors (parse-tree shape, `FSharpNoteworthyParamInfoLocations`, `FSharpNavigationItems`, error reporting) come from the shared service infrastructure documented alongside `ServiceParsedInputOps`, `ServiceParamInfoLocations`, and `ServiceNavigation`. Note this file's context types place completion logic in the older `CompletionContext` without the `RecordSpread`/`Pattern`/`MethodOverride`/`Type`/`UnionCaseFieldsDeclaration`/`TypeAbbreviationOrSingleCaseUnion` cases the newer `ServiceParsedInputOps.fsi` provides.
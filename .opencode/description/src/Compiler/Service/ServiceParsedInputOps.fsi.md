# ServiceParsedInputOps.fsi

**Signature for `ServiceParsedInputOps.fs`.** Declares the service-layer operations that query an untyped `ParsedInput` for the F# IDE: completing identifiers, computing completion contexts (records, inherits, patterns, parameter lists, attributes, open declarations, method overrides), resolving unresolved identifiers, and related helpers.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. Given a caret `pos` and the current (untyped) parse tree, these functions answer: where is the expression left of the dot (`GetRangeOfExprLeftOfDot`, `TryFindExpressionASTLeftOfDotLeftOfCursor`), what expression island is under the caret for debugger evaluation (`TryFindExpressionIslandInPosition`), what kind of completion list to show (`TryGetCompletionContext`), how to qualify/open a namespace to fix an unresolved identifier (`TryFindInsertionContext`, `FindNearestPointToInsertOpenDeclaration`, `AdjustInsertionPoint`), what kind of entity a position denotes (`GetEntityKind`), the full name of the innermost module/namespace at a point (`GetFullNameOfSmallestModuleOrNamespaceAtPoint`), and the long identifier ending at a position (`GetLongIdentAt`).

## Namespaces

- `FSharp.Compiler.EditorServices` with `open System.Collections.Generic`, `FSharp.Compiler.Syntax`, `FSharp.Compiler.Text`.

## Public types (declared)

- `type CompletionPath = string list * string option` — `(plid, residue)`.
- `type InheritanceContext` (`[<RequireQualifiedAccess>]`) — `Class | Interface | Unknown`.
- `type RecordContext` (`[<RequireQualifiedAccess>]`) — `CopyOnUpdate of range * CompletionPath | Constructor of string | Empty | New of path: CompletionPath * isFirstField: bool | Declaration of isInIdentifier: bool`.
- `type RecordSpreadContext` (`[<RequireQualifiedAccess>]`) — `Declaration | Construction`.
- `type PatternContext` (`[<RequireQualifiedAccess>]`) — union-case-field contexts:
  - `PositionalUnionCaseField of fieldIndex: int option * isTheOnlyField: bool * caseIdRange: range`
  - `NamedUnionCaseField of fieldName: string * caseIdRange: range`
  - `UnionCaseFieldIdentifier of referencedFields: string list * caseIdRange: range`
  - `RecordFieldIdentifier of referencedFields: (string * range) list`
  - `Other`.
- `type MethodOverrideCompletionContext` (`[<RequireQualifiedAccess; NoComparison; Struct>]`) — `Class | Interface of mInterfaceName: range | ObjExpr of mExpr: range`.
- `type CompletionContext` (`[<RequireQualifiedAccess>]`) — `Invalid | Inherit of ctx * path | RecordField of RecordContext | RecordSpread of RecordSpreadContext | RangeOperator | ParameterList of pos * HashSet<string> | AttributeApplication | OpenDeclaration of isOpenType: bool | Type | UnionCaseFieldsDeclaration | TypeAbbreviationOrSingleCaseUnion | Pattern of PatternContext | MethodOverride of ctx: MethodOverrideCompletionContext * enclosingTypeNameRange: range * spacesBeforeOverrideKeyword: int * hasThis: bool * isStatic: bool * spacesBeforeEnclosingDefinition: int`.
- `type ModuleKind` — `{ IsAutoOpen: bool; HasModuleSuffix: bool }`.
- `type EntityKind` (`[<RequireQualifiedAccess>]`) — `Attribute | Type | FunctionOrValue of isActivePattern: bool | Module of ModuleKind`.
- `type ScopeKind` (`[<RequireQualifiedAccess>]`) — `Namespace | TopModule | NestedModule | OpenDeclaration | HashDirective`.
- `type InsertionContext` (`[<RequireQualifiedAccess>]` record) — `ScopeKind` + `Pos: pos`.
- `type OpenStatementInsertionPoint` (`[<RequireQualifiedAccess>]`) — `TopLevel | Nearest`.
- `type ShortIdent = string`; `type ShortIdents = ShortIdent[]`.
- `type MaybeUnresolvedIdent` — `{ Ident: ShortIdent; Resolved: bool }`.
- `type InsertionContextEntity` — `{ FullRelativeName: string; Qualifier: string; Namespace: string option; FullDisplayName: string; LastIdent: ShortIdent }`.

## Module `ParsedInput` (public)

- `val TryFindExpressionASTLeftOfDotLeftOfCursor: pos: pos * parsedInput: ParsedInput -> (pos * bool) option` — position of the end of the expression left of the dot; the bool is `true` when the caret is after the dot but before an identifier.
- `val GetRangeOfExprLeftOfDot: pos: pos * parsedInput: ParsedInput -> range option`.
- `val TryFindExpressionIslandInPosition: pos: pos * parsedInput: ParsedInput -> string option` — dotted expression ready for debugger evaluation.
- `val TryGetCompletionContext: pos: pos * parsedInput: ParsedInput * lineStr: string -> CompletionContext option`.
- `val GetEntityKind: pos: pos * parsedInput: ParsedInput -> EntityKind option`.
- `val GetFullNameOfSmallestModuleOrNamespaceAtPoint: pos: pos * parsedInput: ParsedInput -> string[]`.
- `val TryFindInsertionContext` (curried `int -> ParsedInput -> MaybeUnresolvedIdent[] -> OpenStatementInsertionPoint -> …`) — returns a function from `(requiresQualifiedAccessParent option, autoOpenParent option, entityNamespace option, entity)` to `(InsertionContextEntity * InsertionContext)[]` showing how to qualify/open each candidate entity.
- `val FindNearestPointToInsertOpenDeclaration: int -> ParsedInput -> ShortIdents -> OpenStatementInsertionPoint -> InsertionContext`.
- `val GetLongIdentAt: parsedInput: ParsedInput -> pos: pos -> LongIdent option`.
- `val AdjustInsertionPoint: getLineStr: (int -> string) -> ctx: InsertionContext -> pos`.

## Module `SourceFileImpl` (internal)

- `val IsSignatureFile: string -> bool` — `.fsi` check (case-insensitive).
- `val GetImplicitConditionalDefinesForEditing: isInteractive: bool -> string list` — `["INTERACTIVE"; "EDITING"]` or `["COMPILED"; "EDITING"]`.

## Relation to .fs

The `.fs` implements everything with internal walkers and helpers: expression-range visitors for dot-completions, a very large `SyntaxVisitorBase` for `TryGetCompletionContext` (plus an attributes line-text fallback `TryGetCompletionContextOfAttributes`), the whole pattern `TryGetCompletionContextInPattern`, insert-context computation (`Entity.tryCreate`, `tryFindNearestPointAndModules`, `findBestPositionToInsertOpenDeclaration`, script `#r`/`#load` handling in `FindNearestPointToInsertOpenDeclaration`), a `getLongIdents` dictionary for `GetLongIdentAt`, and the internal module `SourceFileImpl`. The `.fs` also contains internal-only additions (`FSharpInheritanceOrigin`, `FSharpModule`, and the internal `Entity` helper module) that the signature does not expose.
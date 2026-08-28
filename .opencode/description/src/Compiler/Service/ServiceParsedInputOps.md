# ServiceParsedInputOps

**Purpose:** A large collection of helpers that operate on the **untyped** parse tree (`ParsedInput`/`SynModuleOrNamespace`) to answer context questions an IDE needs: what kind of thing is being completed/inserted at a position, where to insert an `open` declaration, what the entity/module namespace is, and assorted syntactic context records used by completion, code fixes, and refactoring. One of the largest service modules (≈2400 lines in the .fs).

**Namespace(s):** `FSharp.Compiler.EditorServices`

## Declared types / modules
- `SourceFileImpl` (internal module): `IsSignatureFile`, `GetImplicitConditionalDefinesForEditing`.
- `CompletionPath` (typedef): `string list * string option` (leading path + residue).
- `InheritanceContext` (union, `RequireQualifiedAccess`): `Class | Interface | Unknown`.
- `RecordContext` (union, `RequireQualifiedAccess`): `CopyOnUpdate | Constructor | Empty | New | Declaration`.
- `RecordSpreadContext` (union, `RequireQualifiedAccess`): `Declaration | Construction`.
- `PatternContext` (union, `RequireQualifiedAccess`): `PositionalUnionCaseField`, `NamedUnionCaseField`, `UnionCaseFieldIdentifier`, `RecordFieldIdentifier`, `Other` — precise context for pattern-completion of case/record fields.
- `MethodOverrideCompletionContext` (struct union, `RequireQualifiedAccess`): `Class | Interface of mInterfaceName range | ObjExpr of mExpr range`.
- `CompletionContext` (union, `RequireQualifiedAccess`): the main context enum — `Invalid`, `Inherit`, `RecordField`, `RecordSpread`, `RangeOperator`, `ParameterList`, `AttributeApplication`, `OpenDeclaration`, `Type`, `UnionCaseFieldsDeclaration`, `TypeAbbreviationOrSingleCaseUnion`, `Pattern of PatternContext`, `MethodOverride` (with `enclosingTypeNameRange`, `spacesBeforeOverrideKeyword`, `hasThis`, `isStatic`, `spacesBeforeEnclosingDefinition`).
- `ShortIdent` / `ShortIdents` (typedefs): `string` / `string[]`.
- `MaybeUnresolvedIdent` (record): `{ Ident: ShortIdent; Resolved: bool }`.
- `ModuleKind` (record): `IsAutoOpen`, `HasModuleSuffix`.
- `EntityKind` (union, `RequireQualifiedAccess`): `Attribute | Type | FunctionOrValue of isActivePattern | Module of ModuleKind`.
- `ScopeKind` (union, `RequireQualifiedAccess`): `Namespace | TopModule | NestedModule | OpenDeclaration | HashDirective`.
- `InsertionContext` (record, `RequireQualifiedAccess`): `ScopeKind` + `Pos: pos` for where to insert an `open`.
- `OpenStatementInsertionPoint` (union, `RequireQualifiedAccess`): `TopLevel | Nearest`.
- `InsertionContextEntity` (record, `RequireQualifiedAccess`): data for unresolved-identifier resolution code fixes — `FullRelativeName`, `Qualifier`, `Namespace`, `FullDisplayName`, `LastIdent`.
- `FSharpModule` (record): module idents + range.
- `Entity` (module): entity-kind / module traversal helpers over the parse tree.
- `ParsedInput` (public module): the main query surface (below).
- `Scope` (type, line ~2398 in the .fs): lexical-scope bookkeeping used by insertion-context logic.

## Public API surface (`ParsedInput` module)
- `TryFindExpressionASTLeftOfDotLeftOfCursor`, `GetRangeOfExprLeftOfDot` — find the receiver of a `.member` access at a cursor.
- `TryFindExpressionIslandInPosition` — extract an "island" text around a position.
- `TryGetCompletionContext: pos * ParsedInput * lineStr -> CompletionContext option` — the central context-detection entry point.
- `GetEntityKind`, `GetFullNameOfSmallestModuleOrNamespaceAtPoint` — entity kind / module-namespace lookup.
- `TryFindInsertionContext` — given a partially-qualified name, produce candidate `InsertionContextEntity * InsertionContext` pairs (RQA parent, auto-open parent, entity namespace, entity idents).
- `FindNearestPointToInsertOpenDeclaration` — pick the nearest legal `open` insertion point.
- `GetLongIdentAt` — the long identifier at a position.
- `AdjustInsertionPoint` — refine the insertion line based on surrounding text (directive/comments, etc.).

## Internal helpers / notable details
- `CompletionContext` detection is pattern-heavy: it walks back from the cursor to classify whether the user is typing in an `inherit`, record construction/spread, attribute, type, union-case-field, or method-override context, each carrying the data a completion provider needs (ranges, spaces, `this`, static flag, already-set parameter names).
- `TryFindInsertionContext` is the workhorse for "add `open`" / "qualify" code fixes — note it returns a **function** parameterized over the entity's (RQA-parent, auto-open, namespace, idents) so the caller can defer the decision until they've chosen a target symbol.
- The `Scope` type plus `ScopeKind` encode the nested lexical structure so the right scope is chosen for insertion.

## Significant internal logic
- The module is deliberately large because it centralizes *all* syntactic context analysis; several public entry points (`TryGetCompletionContext`, `TryFindInsertionContext`) share internal traversals to avoid re-parsing the tree.
- Handles edge cases around `#light`/`#` directives, auto-open modules, module-suffix attributes, and `RequireQualifiedAccess` when computing insertion context (see `EntityKind.Module` and `ModuleKind`).

## Cross-references
- `src/Compiler/SyntaxTree` (`SynExpr`, `SynPat`, `SynType`, `SynModuleDecl`, `SynModuleOrNamespace`)
- `ServiceParseTreeWalk.fs` (generic AST traversal — this module builds higher-level context queries on similar foundations)
- `ServiceAssemblyContent.fs` (reuses `EntityKind`/`LookupType` concepts for resolved symbols)
- `FSharpCheckerResults.fs` (service entry points: `TryGetCompletionContext`, etc.)
- Language-server completion / code-action providers (consumers)

# ServiceDeclarationLists

**Purpose:** Implements the service's "declaration list" and "method group" APIs: given an `InfoReader` (checked-project symbol info at a range), it produces editor-ready lists of completion items (`DeclarationListInfo`) and method-overload groups (`MethodGroup`) with pretty-printed descriptions, XML docs, glyphs, and accessibility — the backbone of IntelliSense/completion in F# tooling.

**Namespace(s):** `FSharp.Compiler.EditorServices`

## Declared types / modules
- `ToolTipElementData` (record, `RequireQualifiedAccess`): one tooltip element — main `RichText` description, `FSharpXmlDoc`, type-mapping text, remarks, optional `FSharpSymbol`; static inner `Create` constructor.
- `ToolTipElement` (discriminated union): `None | Group of ToolTipElementData list | CompositionError of string`; static `Single` constructor.
- `ToolTipText` (union): wraps the list of elements to display.
- `CompletionItemKind` (enum union, `RequireQualifiedAccess`): `SuggestedName | Field | Property | Method of isExtension | Event | Argument | CustomOperation | Other`.
- `UnresolvedSymbol` (record): full name / display name / namespace for unresolved (assembly-side) symbols.
- `CompletionItem` (internal record): one completion candidate — the `ItemWithInst`, its kind, own-member flag, minor priority, type reference, optional `UnresolvedSymbol`, and custom insert/display text overrides.
- `DeclarationListHelpers` (AutoOpen module): shared helpers — `FormatOverloadsToList`, `CompletionItemDisplayPartialEquality`, `RemoveDuplicateCompletionItems`, `RemoveExplicitlySuppressedCompletionItems`, `RemoveDuplicateModuleRefs`, `FormatStructuredDescriptionOfItem`, plus the mutable `ToolTipFault` diagnostic sink.
- `DescriptionListsImpl` (internal module): the heavy formatting engine (see below).
- `MethodGroupItemParameter` (sealed class): one parameter of an overload — name, canonical sort key, rich-text display, optional flag.
- `DeclarationListItem` (sealed class): one entry in a declaration list — `NameInList` (no backticks, display), `NameInCode` (with backticks, insertion), `Description` (`ToolTipText`), `Glyph` (`FSharpGlyph`), `Accessibility`, `Kind`, `IsOwnMember`, `MinorPriority`, `FullName`, `IsResolved`, `NamespaceToOpen` (obsolete `Name` property retained for compat).
- `DeclarationListInfo` (sealed class): `Items: DeclarationListItem[]` plus `IsForType`/`IsError`; internal static `Create`, `Error`, `Empty`.
- `MethodGroupItem` (sealed class): documentation + description + return type + parameter array of one group member; `HasParameters`, `HasParamArrayArg`, `StaticParameters`.
- `MethodGroup` (sealed class): shared `MethodName` + `Methods: MethodGroupItem[]`; internal `Create`/`Empty`.

## Public API surface
- Construction of `DeclarationListInfo` / `MethodGroup` happens via internal `static member Create`/`Error`/`Empty` (used by `FSharpCheckerResults.fs` `GetDeclarations`/`GetMethodGroups`); consumers read the public members above.

## Internal helpers (notable, `DescriptionListsImpl`)
- `isFunction`, `printCanonicalizedTypeName`, `PrettyParamOfRecdField` / `PrettyParamOfUnionCaseField` — pretty-print record/union case field parameters to `RichText`.
- `ParamOfParamData`, `PrettyParamsOfParamDatas`, `PrettyParamsOfTypes` — render parameter lists (incl. param-array, opt-in args) and return types.
- `StaticParamsOfItem` — static argument (`TP<42,"foo">`) parameters.
- `PrettyParamsAndReturnTypeOfItem` — large recursive formatter for an item's full signature in a tooltip.
- `GlyphOfItem` — maps typed `Item` to an `FSharpGlyph` (see ServiceConstants).
- `SelectMethodGroupItems` — chooses which items in a group are methods vs. other constructs.
- `FormatStructuredDescriptionOfItem` — top-level formatting of a single item into a `ToolTipElement`.

## Significant internal logic
- Uses `FSharp.Compiler.NicePrint` / `TypedTreeOps` pretty layout with `SimplerDisplayEnv`, squashed to a configurable width (`PrintUtilities.squashToWidth`), then converted via `toRichText`.
- Duplicate removal uses partial-equality comparers built from `ItemDisplayPartialEquality` over the typechecker globals `TcGlobals`.
- `RemoveExplicitlySuppressedCompletionItems` filters items that the compiler flags as suppressed from IntelliSense (e.g. `FSharpList`, `Option` aliases).
- `isForType` detection (for `DeclarationListInfo`) checks for `AnonRecdField` items or items with a type reference.
- `ToolTipFault` mutable + `simulateError` lets formatting failures surface as diagnostics through the normal diagnostic pipeline.

## Cross-references
- `FSharp.Compiler.TypedTree` / `TypedTreeOps` (`Item`, `ItemWithInst`, `TyconRef`, symbol display)
- `FSharp.Compiler.InfoReader` (`GetXmlCommentForItem`, etc.)
- `ServiceConstants.fs` (`FSharpGlyph`)
- `ServiceAssemblyContent.fs` (`UnresolvedSymbol`, `EntityKind`, `LookupType` interplay)
- `FSharpCheckerResults.fs` (orchestrates GetDeclarations/GetMethodGroups)

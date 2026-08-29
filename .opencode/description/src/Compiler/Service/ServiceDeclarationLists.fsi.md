# ServiceDeclarationLists.fsi

**Signature for `ServiceDeclarationLists.fs`.** Declares the public "declaration list" and "method group" object model of the FSharp.Compiler.Service: the data behind IntelliSense completion lists (`DeclarationListItem`/`DeclarationListInfo`), tooltip elements (`ToolTipElement`/`ToolTipText`), and parameter-help/method-overload lists (`MethodGroup`/`MethodGroupItem`/`MethodGroupItemParameter`).

## Pipeline role

`FSharpChecker` service-layer API for F# IDE/tooling. Given the `Item`/`ItemWithInst` representations of resolved names plus a `DisplayEnv`, this surface produces editor-ready, display-oriented data: named completion entries (with display vs. code text, glyph, accessibility, priority), structured tooltips built from `RichText`/tagged layouts and `FSharpXmlDoc`, and method overload groups with per-parameter rich text for parameter-info windows. `DeclarationListHelpers` exposes the shared formatting/ dedup helpers.

## Namespaces

- `FSharp.Compiler.EditorServices` — with `open System`, `FSharp.Compiler.NameResolution`, `FSharp.Compiler.InfoReader`, `FSharp.Compiler.Symbols`, `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.Text`, `FSharp.Compiler.TypedTree`, `FSharp.Compiler.TypedTreeOps`, `FSharp.Compiler.AccessibilityLogic`.

## Public types

- `type ToolTipElementData` (`[<RequireQualifiedAccess>]` record):
  - `Symbol: FSharpSymbol option`; `MainDescription: RichText`; `XmlDoc: FSharpXmlDoc`; `TypeMapping: RichText list` (typar instantiation text after xml); `Remarks: RichText option` (extra trailing text); `ParamName: string option`.
  - `static member internal Create: mainDescription * xml * ?typeMapping * ?paramName * ?remarks * ?symbol -> ToolTipElementData`.
- `type ToolTipElement` (`[<RequireQualifiedAccess>]` union) — instances hold **no** compiler-resource references:
  - `None`
  - `Group of elements: ToolTipElementData list` (one type/method etc., possibly an overload group)
  - `CompositionError of errorText: string`
  - `static member Single: mainDescription * xml * ?typeMapping * ?paramName * ?remarks * ?symbol -> ToolTipElement`.
- `type ToolTipText = ToolTipText of ToolTipElement list` — information for building a tooltip box; holds no compiler resources.
- `type CompletionItemKind` (`[<RequireQualifiedAccess>]` union): `SuggestedName | Field | Property | Method of isExtension: bool | Event | Argument | CustomOperation | Other`.
- `type UnresolvedSymbol` (record): `FullName: string`, `DisplayName: string`, `Namespace: string[]`.
- `type CompletionItem` (internal record):
  - Fields: `ItemWithInst: ItemWithInst`, `Kind: CompletionItemKind`, `IsOwnMember: bool`, `MinorPriority: int`, `Type: TyconRef option`, `Unresolved: UnresolvedSymbol option`, `CustomInsertText: string voption`, `CustomDisplayText: string voption`.
  - `member Item: Item` (from `ItemWithInst.Item`).
- `type DeclarationListItem` (`[<Sealed>]`, holds a weak reference to compiler resources):
  - `member Name: string` — **obsolete**, renamed to `NameInList`.
  - `member NameInList: string` — display text (no backticks).
  - `member NameInCode: string` — text to insert into code (with backticks if needed).
  - `member Description: ToolTipText`; `member Glyph: FSharpGlyph`; `member Accessibility: FSharpAccessibility`; `member Kind: CompletionItemKind`; `member IsOwnMember: bool`; `member MinorPriority: int`; `member FullName: string`; `member IsResolved: bool`; `member NamespaceToOpen: string option`.
- `type DeclarationListInfo` (`[<Sealed>]`, weak reference):
  - `member Items: DeclarationListItem[]`; `member IsForType: bool`; `member IsError: bool`.
  - `static member internal Create: infoReader * ad: AccessorDomain * m: range * denv: DisplayEnv * getAccessibility:(Item -> FSharpAccessibility) * items: CompletionItem list * currentNamespace: string[] option * isAttributeApplicationContext: bool -> DeclarationListInfo`.
  - `static member internal Error: message: string -> DeclarationListInfo`.
  - `static member Empty: DeclarationListInfo`.
- `type MethodGroupItemParameter` (`[<Sealed>]`):
  - `member ParameterName: string`; `member CanonicalTypeTextForSorting: string`; `member Display: RichText`; `member IsOptional: bool`.
- `type MethodGroupItem` (`[<Sealed; NoEquality; NoComparison>]`) — a method or a single non-overloaded item (union case, named function value):
  - `member XmlDoc: FSharpXmlDoc`; `member Description: ToolTipText`; `member ReturnTypeText: RichText`; `member Parameters: MethodGroupItemParameter[]`; `member HasParameters: bool`; `member HasParamArrayArg: bool`; `member StaticParameters: MethodGroupItemParameter[]` (static args like `TP<42,"foo">`).
- `type MethodGroup` (`[<Sealed>]`):
  - `internal new: string * MethodGroupItem[] -> MethodGroup`.
  - `member MethodName: string`; `member Methods: MethodGroupItem[]`.
  - `static member internal Create: InfoReader * AccessorDomain * range * DisplayEnv * ItemWithInst list -> MethodGroup`.
  - `static member internal Empty: MethodGroup`.

## Internal module

- `module DeclarationListHelpers` (internal):
  - `val FormatStructuredDescriptionOfItem: isDecl: bool -> InfoReader -> AccessorDomain -> range -> DisplayEnv -> ItemWithInst -> FSharpSymbol option -> int option -> ToolTipElement` — the core structured tooltip formatter.
  - `val RemoveDuplicateCompletionItems: TcGlobals -> CompletionItem list -> CompletionItem list`.
  - `val RemoveExplicitlySuppressedCompletionItems: TcGlobals -> CompletionItem list -> CompletionItem list` — filters `FSharpList`, `Option`, etc.
  - `val mutable ToolTipFault: string option` — global fault-test switch.
  - `val emptyToolTip: ToolTipText`.

## Relation to .fs

The signature exposes the editor-facing objects and helpers; the matching `.fs` contains the full implementations: the `FormatItemDescriptionToToolTipElement` case-by-case prettifier, `DescriptionListsImpl` (glyph computation, parameter/return-type prettification, method-group item selection), the sort/group/pipeline inside `DeclarationListInfo.Create`, and the `MethodGroup.Create` caching (`ConditionalWeakTable`). All `ToolTip*` rendering uses `RichText`/`Layout` rather than strings to stay editor-agnostic.
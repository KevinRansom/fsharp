# ServiceDeclarationLists.fs

Full implementation of the declaration/method-overload object model for the FSharp.Compiler.Service. Produces editor-ready completion entries, structured tooltips, and parameter-info method groups from the internal `Item`/`ItemWithInst` resolution and `DisplayEnv`/`NicePrint` layout machinery.

## Pipeline role

`FSharpChecker` service-layer API for F# IDE/tooling. Two jobs:
1. **Declaration lists** — take `CompletionItem list` (resolved `ItemWithInst` or unresolved `UnresolvedSymbol`) and produce a `DeclarationListInfo` of sortable, groupable, deduplicated `DeclarationListItem`s with display/how-to-insert text, glyphs, accessibility, tooltips, and "namespace to open" hints.
2. **Method groups (parameter info)** — take `ItemWithInst list` and render a `MethodGroup` with overloads, per-parameter rich display text, canonical sorting keys, return types, xml docs, and (optionally) type-provider static parameters.

Everything printed goes through `FSharp.Compiler.Text` `Layout`/`RichText`, keeping the output editor-agnostic. Tooltip computations are wrapped in `DiagnosticsScope.Protect` so a single failing item yields `ToolTipElement.CompositionError` rather than aborting.

## Namespaces / opens

- `FSharp.Compiler.EditorServices` with `open` of `NicePrint`, `Internal.Utilities.Library(.Extras)`, `AbstractIL.Diagnostics`, `AccessibilityLogic`, `Diagnostics`, `DiagnosticsLogger`, `Infos`, `InfoReader`, `NameResolution`, `Symbols` (incl. `SymbolHelpers`), `Syntax.PrettyNaming`, `TcGlobals`, `Text` (+ `Range`, `Layout`, `LayoutRender`, `TaggedText`), `TypedTree`, `TypedTreeBasics`, `TypedTreeOps`.

## Data types

- `ToolTipElementData` record — fields `Symbol`, `MainDescription: RichText`, `XmlDoc: FSharpXmlDoc`, `TypeMapping: RichText list`, `Remarks`, `ParamName`; `Create` static with optional args.
- `ToolTipElement` (`[<RequireQualifiedAccess>]`) — `None | Group of ToolTipElementData list | CompositionError of string`; `Single` helper builds a one-element `Group`.
- `ToolTipText = ToolTipText of ToolTipElement list`.
- `CompletionItemKind` (`[<RequireQualifiedAccess>]`) — `SuggestedName | Field | Property | Method of isExtension: bool | Event | Argument | CustomOperation | Other`.
- `UnresolvedSymbol` record — `FullName`, `DisplayName`, `Namespace: string[]`.
- `CompletionItem` record — `ItemWithInst`, `Kind`, `IsOwnMember`, `MinorPriority`, `Type: TyconRef option`, `Unresolved: UnresolvedSymbol option`, `CustomInsertText`, `CustomDisplayText`; member `Item = x.ItemWithInst.Item`.

## Module `DeclarationListHelpers` (`[<AutoOpen>]`)

- `let mutable ToolTipFault: string option` — if set, `FormatOverloadsToList` first raises a simulated type-check error (`PhasedDiagnostic`, severity Error) through `simulateError` — a test hook.
- `emptyToolTip = ToolTipText []`.
- `FormatOverloadsToList infoReader m denv item minfos symbol width : ToolTipElement` — renders each `MethInfo` via `prettyLayoutOfMethInfoFreeStyle`, attaches `GetXmlCommentForMethInfoItem` xml, typar mapping (`FormatTyparMapping`), squashes to `width`, returns `ToolTipElement.Group`.
- `CompletionItemDisplayPartialEquality g` — `IPartialEqualityComparer<CompletionItem>` delegating to `ItemDisplayPartialEquality` (compares display names only).
- `RemoveDuplicateCompletionItems g items` — `IPartialEqualityComparer.partialDistinctBy`.
- `RemoveExplicitlySuppressedCompletionItems g items` — filters `IsExplicitlySuppressed` (e.g. uppercase `FSharpList`, `Option`).
- `RemoveDuplicateModuleRefs modrefs` — dedup by `fullDisplayTextOfModRef`.
- `OutputFullName displayFullName ppF fnF r` — emits "Full name: ..." line only when `displayFullName` is true (def used for tooltips? actually gated: prints when `not displayFullName` with colon+fnF; returns emptyL otherwise).
- `pubpathOfValRef` / `pubpathOfTyconRef`.
- `FormatItemDescriptionToToolTipElement displayFullName infoReader ad m denv item symbol width` — the central per-`Item` prettifier (see below). Sets `showCsharpCodeAnalysisAttributes = true` in the display env.
- `FormatStructuredDescriptionOfItem isDecl infoReader ad m denv item symbol width` — wraps `FormatItemDescriptionToToolTipElement` in `DiagnosticsScope.Protect m ... ToolTipElement.CompositionError`.

### Case-by-case tooltip layouts (in `FormatItemDescriptionToToolTipElement`)

- `Item.ImplicitOp(_, { contents = Some(TraitConstraintSln.FSMethSln(vref=vref)) })` → refactor to `Item.Value vref` and recurse.
- `Item.Value vref` / `Item.CustomBuilder _` → `layoutQualifiedValOrMember` + full-name remark + type mapping.
- `Item.UnionCase` → "union case" word + `TyconRef.unionCase.field -> type` layout.
- `Item.ActivePatternResult` / `Item.ActivePatternCase` → "active pattern result"/"active recognizer" layouts.
- `Item.ExnCase` → `layoutExnDef` + full-name remark.
- `Item.RecdField` (incl. `IsFSharpException` argument rendering; literal value via `layoutConst`).
- `Item.UnionCaseField`, `Item.NewDef` (pattern variable), `Item.ILField` (with literal), `Item.Event`.
- `Item.Property` → `prettyLayoutOfPropInfoFreeStyle`.
- `Item.CustomOperation(customOpName, usageText, Some minfo)` → "custom operation: usage" + "(…args…)" and "Calls Builder.method".
- `Item.CtorGroup` / `Item.MethodGroup` → `FormatOverloadsToList`.
- `Item.DelegateCtor` → delegate signature parentheses layout.
- `Item.Types(_, TType_app _)` / `Item.UnqualifiedType` → `layoutTyconDefn` with `shortTypeNames=true`, `showDocumentation=false`, full-name remark.
- `Item.TypeVar` → `prettyLayoutOfTypar`; `Item.Trait` → `prettyLayoutOfTrait` with `shortConstraints=false`.
- `Item.ModuleOrNamespaces` → namespace/module keyword + "From first/next ..." provenance lines for non-namespaces.
- `Item.AnonRecdField` → anonymous record field layout.
- `Item.OtherName(ident=Some id,...)`, `Item.SetterArg` (delegates to inner item).
- Fall-through cases → `ToolTipElement.None` (implicit ops, uncurried types, empty lists, etc.).

## `MethodGroupItemParameter` (sealed class)

Constructor `(name, canonicalTypeTextForSorting, display: RichText, isOptional)`. Members: `ParameterName`, `CanonicalTypeTextForSorting`, `Display`, `IsOptional`.

## Module `DescriptionListsImpl` (internal, `[<AutoOpen>]`)

- `isFunction g ty`, `printCanonicalizedTypeName g denv tauTy` — strips abbreviations/erasure, clears open paths, `stringOfTy` (stable sort key).
- `PrettyParamOfRecdField` / `PrettyParamOfUnionCaseField` — argument layouts from `RecdField`s (skip generated UCS field name when `isGenerated`).
- `ParamOfParamData` / `PrettyParamsOfParamDatas` — build parameter `MethodGroupItemParameter`s from `ParamData`; optional args get `?`; `ParamArrayAttribute` prefix; uses `prettyLayoutOfInstAndSig` for prettified types/constraints.
- `PrettyParamsOfTypes` — non-named parameters variant (used for values/union cases).
- `StaticParamsOfItem infoReader m denv item` (`#if !NO_TYPEPROVIDERS`) — static parameters of type-provider items via `ItemIsWithStaticArguments`, `Import.ImportProvidedType`.
- `PrettyParamsAndReturnTypeOfItem infoReader m denv item` — per `Item`:
  - `Item.Value`: if `ValReprInfo = None` (let-bindings in types/local fns) uses type-only approach; else uses `GetValReprTypeInFSharpForm`, takes the *first* curried argument group, adjusts return type, appends constraints to return layout.
  - `Item.UnionCase`: generated-field-aware param list + generalized union type as return.
  - `Item.ActivePatternCase`: args/res via `stripFunTy`, with a per-case type for multi-case APs.
  - `Item.ExnCase`, `Item.RecdField`, `Item.AnonRecdField`, `Item.ILField`, `Item.Event` — no params, simple return layout.
  - `Item.Property`: `pinfo.GetParamDatas` + `GetPropertyType`.
  - `Item.CtorGroup` / `Item.MethodGroup` (non-empty): head overload's first param group + return type.
  - `Item.Trait`: logical argument types + return type.
  - `Item.CustomBuilder`: delegates to `Item.Value`.
  - `Item.CustomOperation` (with method): unary op args or empty (bespoke syntax).
  - `Item.DelegateCtor`: delegate signature as single param.
  - remaining/empty cases → `([], emptyL)`.
- `GlyphOfItem denv item : FSharpGlyph` — maps item → glyph:
  - value: function → `Method`, literal → `Constant`, else `Variable`.
  - types via `reprToGlyph` (F# union/record/class/interface/struct/delegate/enum, IL class/struct/interface/enum/else delegate, asm/measure/provided → `Typedef`).
  - tuple/typar/function fallbacks; `UnionCase`/`ActivePattern*` → `EnumMember`; exception → `Exception`; fields → `Field`; event → `Event`; property → `Property`; ctors/ops → `Method`; all-extension `MethodGroup` → `ExtensionMethod`; `Trait` → `Method`; `TypeVar` → `TypeParameter`; modules/namespaces; `NewDef`/`OtherName`/`SetterArg` → `Variable`; empty lists → `Error`. Inner exploration protected by `protectAssemblyExploration FSharpGlyph.Class`.
- `SelectMethodGroupItems g m item` — decides which items participate in parameter info:
  - `CtorGroup` → each ctor separately; `MethodGroup` → each overload separately.
  - Values/`RecdField`/`UnionCase`/`ExnCase` only if function-like/non-nullary; `Property` only if indexer; `DelegateCtor`, `CustomOperation`, provided-with-static-args → themselves; everything else → `[]`.

## `DeclarationListItem` (sealed class)

Constructor `(textInDeclList, textInCode, fullName, glyph, info, accessibility, kind, isOwnMember, priority, isResolved, namespaceToOpen)`.
- `Name`/`NameInList` — display text; `NameInCode` — insertion text.
- `Description` — `SuggestedName` kind → "Suggested name" text; `Choice1Of2(items, infoReader, ad, m, denv)` → tooltips for every grouped item via `FormatStructuredDescriptionOfItem`; `Choice2Of2` → pre-computed `ToolTipText`.
- Plus `Glyph`, `Accessibility`, `Kind`, `IsOwnMember`, `MinorPriority`, `FullName`, `IsResolved`, `NamespaceToOpen`.

## `DeclarationListInfo` (sealed class)

- Static helpers: `fsharpNamespace = [|"Microsoft"; "FSharp"|]`, `empty`, `isOperatorItem` (single value/method/union-case item whose name `IsOperatorDisplayName`), `isActivePatternItem`.
- Members: `Items`, `IsForType`, `IsError`.
- `static member Create(infoReader, ad, m, denv, getAccessibility, items, currentNamespace, isAttributeApplicationContext)`:
  1. `isForType` = any item with `Type.IsSome` or anon-record field.
  2. `RemoveExplicitlySuppressedCompletionItems`.
  3. Priority adjustment: interfaces get 1000+arity, types `1+arity`, delegate ctors 1000+arity, ctor groups `1000+10*arity` (so they're removed by dedup in favor of the type); `IsOwnMember` set by comparing item's `Type` with the member's declaring tycon.
  4. Sort by `MinorPriority`, then flatten to normalized consecutive priorities.
  5. Sort unresolved items last (to prefer file-check results over `GetAssemblyContent` "all entities"), dedup via `RemoveDuplicateCompletionItems`, group by full name (unresolved: `ns.displayName`; resolved: `CustomDisplayText` or `Item.DisplayName`).
  6. RFC-1137 handling (when `PreferExtensionMethodOverPlainProperty` enabled): if a group has both a `Property` and an extension `Method`, split them into separate entries; otherwise keep one item per group.
  7. Filter out operator items and active patterns (as values); cut the `Attribute` suffix in attribute-application contexts; compute `fullName` and `namespaceToOpen` (skipping `Microsoft.FSharp` and prefixing relative to the current namespace).
  8. Build `DeclarationListItem`s with `Choice1Of2` info and `getAccessibility item.Item`; return `DeclarationListInfo(Array.ofList decls, isForType, false)`.
- `Error message` → a single `<Note>` error item (`FSharpGlyph.Error`, `Choice2Of2` composition-error tooltip), `IsError=true`.
- `Empty`.

## `MethodGroupItem` / `MethodGroup`

- `MethodGroupItem(description, xmlDoc, returnType: RichText, parameters, hasParameters, hasParamArrayArg, staticParameters)` — plain property bag.
- `MethodGroup`:
  - `methodOverloadsCache = ConditionalWeakTable<ItemWithInst, MethodGroupItem[]>` (perf; BUG 413009).
  - constructor normalizes zero-arg methods (single `unit` param → `[||]`) and sorts overloads by `(param count, canonical types)` for stable output / unit tests.
  - `Create infoReader ad m denv items` — for each `ItemWithInst`: cache-hit → reuse; else `SelectMethodGroupItems`, for each flat item compute `PrettyParamsAndReturnTypeOfItem` (protected), a `FormatStructuredDescriptionOfItem` description, `HasParamArrayArg`, `HasParameters=false` for provided-type-with-static-args, return type, xml, and type-provider `StaticParameters`.
  - `Empty`.

## Key behaviors / notes

- `ToolTipFault` simulates a diagnostic to prove fault-tolerance paths.
- Deduplication is *partial-equality* based (display-name equality), which intentionally merges `DelegateCtor`/`DefaultStructCtor` entries into their types.
- `MethodGroup` keeps a weak cache so parameter info recomputation is memoized per `ItemWithInst`.
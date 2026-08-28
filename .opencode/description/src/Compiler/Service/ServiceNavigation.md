# ServiceNavigation

**Purpose:** Provides "go to definition"-style navigation data from the **untyped** parse tree: the classic two-tier navigation bar (`NavigationItems` of top-level declarations + nested members), and the newer flat "navigate to item" model (`NavigableItem[]`) used by symbol listing/naming queries in the language service. No type-checking is required — everything is derived from `ParsedInput`/`SynModuleOrNamespace`.

**Namespace(s):** `FSharp.Compiler.EditorServices`

## Declared types / modules
- `NavigationItemKind` (union, `RequireQualifiedAccess`): `Namespace | ModuleFile | Exception | Module | Type | Method | Property | Field | Other`.
- `NavigationEntityKind` (union, `RequireQualifiedAccess`): `Namespace | Module | Class | Exception | Interface | Record | Enum | Union`.
- `NavigationItem` (sealed class): one navigation bar item — `LogicalName`, `UniqueName` (conflict-avoiding), `Glyph` (`FSharpGlyph`), `Kind`, `Range`, `BodyRange`, `IsSingleTopLevel`, `EnclosingEntityKind`, `IsAbstract`, `Access: SynAccess option`.
- `NavigationTopLevelDeclaration` (record): top-level `NavigationItem` + its `Nested: NavigationItem[]`.
- `NavigationItems` (sealed class): `Declarations: NavigationTopLevelDeclaration[]` — the `GetNavigationItems` result shape.
- `NavigationImpl` (module): the workhorse — builds items from `SynModuleOrNamespace` lists, computes member ranges, disambiguates duplicate names ("name_i_of_n"), maps member kinds to glyphs/navigation kinds.
- `Navigation` (public module): minimal surface — `val getNavigation: ParsedInput -> NavigationItems` (internal `empty`).
- `NavigableItemKind` (union, `RequireQualifiedAccess`): `Module | ModuleAbbreviation | Exception | Type | ModuleValue | Field | Property | Constructor | Member | EnumCase | UnionCase`.
- `NavigableContainerType` (union, `RequireQualifiedAccess`): `File | Namespace | Module | Type | Exception`.
- `NavigableContainer` (sealed class): `Type`, `FullName` (empty for a file), `Name`.
- `NavigableItem` (record): `Name`, `NeedsBackticks`, `Range`, `IsSignature`, `Kind`, `Container`.
- `NavigateTo` (public module): `val GetNavigableItems: ParsedInput -> NavigableItem[]`.

## Public API surface
- `Navigation.getNavigation : ParsedInput -> NavigationItems` — two-tier navigation bar data from a checked/parse input.
- `NavigateTo.GetNavigableItems : ParsedInput -> NavigableItem[]` — flat list of navigable items with container info (used by "navigate to symbol" style queries).

## Internal helpers (notable, `NavigationImpl`)
- Range computation helpers: `unionRangesChecked`, `rangeOfDecls`/`rangeOfDecls2`, `moduleRange`, `fldspecRange`, `bodyRange` — build enclosing ranges by unioning child declaration ranges.
- `createDecl`/`createDeclLid` — create a top-level navigation item, tracking name collisions via a dictionary to produce unique display names.
- `createMember`/`createMemberLid` — create nested member items.
- `processBinding` — pattern-matches `SynBinding` (long-ident member names, property get/set, plain ident) to decide `NavigationItemKind`/`FSharpGlyph` and merges identifier range with expression range.
- `getNavigationFromImplFile` — the main entry for implementation files; walks nested namespaces/modules, types (records, unions, enums, classes), and member definitions.

## Significant internal logic
- Duplicate handling: when the same logical name appears multiple times (overloads/redefinitions), the `uniqueName` helper generates `name_N_of_M` to keep entries distinguishable in UI drop-downs.
- Range semantics: `Range` is the declaration's range (e.g. identifier + head), `BodyRange` extends over the full definition body — useful for "go to definition" and outlining.
- The two public namespaces (classic `NavigationItems` vs. flat `NavigableItem`) coexist for backward compatibility with older tooling and newer flat symbol browsing respectively.

## Cross-references
- `src/Compiler/SyntaxTree` (`SynBinding`, `SynMemberDefn`, `SynTypeDefn`, `SynModuleOrNamespace`, `SynAccess`)
- `ServiceParseTreeWalk.fs` (generic AST walking infrastructure sometimes used alongside)
- `ServiceConstants.fs` (`FSharpGlyph`)
- `FSharpCheckerResults.fs` (`GetNavigationItems` public entry point)

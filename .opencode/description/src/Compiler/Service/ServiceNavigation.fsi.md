# ServiceNavigation.fsi

**Signature for `ServiceNavigation.fs`.** Declares the AST-based navigation-bar and "navigate to" APIs of the FSharp.Compiler.Service: `Navigation.getNavigation` produces the type/member dropdown model, `NavigateTo.GetNavigableItems` produces a flat list of navigable symbols for Go-to-Definition-style lists.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. The navigation bar of an F# editor is populated from a pure untyped-parse walk of `ParsedInput` (no typecheck needed): top-level entities (module/namespaces → left drop-down) and their members (right drop-down), each carrying a display name, unique name (de-duplicated via `_idx_of_total` suffixes), glyph, `range`/`bodyRange`, containing-entity kind, abstractness, and accessibility. `NavigateTo` provides a separate flat structure (`NavigableItem` with a `NavigableContainer` tree) used for symbol search / navigate-to-anything.

## Namespaces

- `FSharp.Compiler.EditorServices` with `open FSharp.Compiler.Syntax`, `FSharp.Compiler.Text`.

## Public types (declared)

- `type NavigationItemKind` (`[<RequireQualifiedAccess>]`) — `Namespace | ModuleFile | Exception | Module | Type | Method | Property | Field | Other`.
- `type NavigationEntityKind` (`[<RequireQualifiedAccess>]`) — `Namespace | Module | Class | Exception | Interface | Record | Enum | Union`.
- `type NavigationItem` (`[<Sealed>]`) — one navigation-bar entry:
  - `member LogicalName: string`; `member UniqueName: string`; `member Glyph: FSharpGlyph`; `member Kind: NavigationItemKind`; `member Range: range`; `member BodyRange: range`; `member IsSingleTopLevel: bool`; `member EnclosingEntityKind: NavigationEntityKind`; `member IsAbstract: bool`; `member Access: SynAccess option`.
- `type NavigationTopLevelDeclaration` (`[<NoEquality; NoComparison>]` record): `Declaration: NavigationItem`, `Nested: NavigationItem[]`.
- `type NavigationItems` (`[<Sealed>]`) — `member Declarations: NavigationTopLevelDeclaration[]`.
- `module Navigation` (`[<RequireQualifiedAccess>]`, public):
  - `val internal empty: NavigationItems`.
  - `val getNavigation: ParsedInput -> NavigationItems`.
- `type NavigableItemKind` (`[<RequireQualifiedAccess>]`) — `Module | ModuleAbbreviation | Exception | Type | ModuleValue | Field | Property | Constructor | Member | EnumCase | UnionCase`.
- `type NavigableContainerType` (`[<RequireQualifiedAccess>]`) — `File | Namespace | Module | Type | Exception`.
- `type NavigableContainer` (`[<Sealed>]`):
  - `member Type: NavigableContainerType`; `member FullName: string` (empty string for files); `member Name: string`.
- `type NavigableItem` (record): `Name: string`, `NeedsBackticks: bool`, `Range: range`, `IsSignature: bool`, `Kind: NavigableItemKind`, `Container: NavigableContainer`.
- `module NavigateTo` (`[<RequireQualifiedAccess>]`, public):
  - `val GetNavigableItems: ParsedInput -> NavigableItem[]`.

## Relation to .fs

The `.fs` implements these with internal helpers: `NavigationImpl` (the two big walkers `getNavigationFromImplFile` / `getNavigationFromSigFile` with name-de-duplication and `NavigationItem.Create`/`WithUniqueName`), the `Navigation` dispatch on `ParsedInput`, and `NavigateTo.GetNavigableItems` whose `NavigableContainer` in the implementation is an algebraic union (`File of fileName | Container of containerType * nameParts * parent`) with the listed member projection functions. The signature pins the public API; the `.fs` adds `bodyRange`, `WithUniqueName`, and `Create` extensions on `NavigationItem` not visible in the signature.
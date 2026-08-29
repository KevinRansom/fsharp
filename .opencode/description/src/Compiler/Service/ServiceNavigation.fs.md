# ServiceNavigation.fs

Full implementation of navigation-bar and "navigate to" data extraction from untyped parse trees.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. Two features, both pure AST walks (`ParsedInput`, no type checking):
1. `Navigation.getNavigation parsedInput` → `NavigationItems`, i.e. the left+right navigation-bar dropdown model. The impl file walker `NavigationImpl.getNavigationFromImplFile` and the signature-file walker `getNavigationFromSigFile` produce `NavigationTopLevelDeclaration`s: module/namespace/type/exception declarations with their nested members, all de-duplicated through a `name_<idx>_of_<total>` unique-name scheme.
2. `NavigateTo.GetNavigableItems parsedInput` → flat `NavigateTo.NavigableItem[]`, each item tagged with a `NavigableContainer` describing its containing file/namespace/module/type/exception, `Name`, `NeedsBackticks`, `Range`, `IsSignature`, and `Kind`. Used for symbol search / navigate-to.

## Namespaces / opens

- `FSharp.Compiler.EditorServices` with `open System`, `System.Collections.Generic`, `FSharp.Compiler.Syntax`, `FSharp.Compiler.SyntaxTreeOps`, `FSharp.Compiler.Text`, `FSharp.Compiler.Text.Range`.

## Enum types

- `NavigationItemKind` (`[<RequireQualifiedAccess>]`) — `Namespace | ModuleFile | Exception | Module | Type | Method | Property | Field | Other`.
- `NavigationEntityKind` (`[<RequireQualifiedAccess>]`) — `Namespace | Module | Class | Exception | Interface | Record | Enum | Union`.

## `NavigationItem` (sealed class)

Constructor `(uniqueName, logicalName, kind, glyph, range, bodyRange, singleTopLevel, enclosingEntityKind, isAbstract, access)`.
- Members: `bodyRange`, `UniqueName`, `LogicalName`, `Glyph`, `Kind`, `Range`, `BodyRange`, `IsSingleTopLevel`, `EnclosingEntityKind`, `IsAbstract`, `Access` (plain accessors).
- `WithUniqueName(uniqueName)` — copies with a new unique name.
- `static member Create(name, kind, glyph, range, bodyRange, singleTopLevel, enclosingEntityKind, isAbstract, access)` — with `UniqueName=""`.

## `NavigationTopLevelDeclaration` / `NavigationItems`

- Record `{ Declaration: NavigationItem; Nested: NavigationItem[] }`.
- `NavigationItems(declarations: NavigationTopLevelDeclaration[])` with `member Declarations`.

## Module `NavigationImpl` (internal)

Range helpers:
- `unionRangesChecked r1 r2` — treat `range0` as identity, otherwise `unionRanges`.
- `rangeOfDecls2 f decls` / `rangeOfDecls` — fold `bodyRange`s.
- `moduleRange idm others` — union of the module-end range and others' ranges.
- `fldspecRange` — union of field ranges (`SynUnionCaseKind.Fields`) or the type range (`FullType`).
- `bodyRange mBody decls` — union of decl ranges with `mBody`.

### `getNavigationFromImplFile (modules: SynModuleOrNamespace list)`

- `names` dictionary + `addItemName`/`uniqueName` (`"%s_%d_of_%d" name idx total`) for name-conflict resolution.
- Declaration creators: `createDeclLid` (base-prefixed long id → left drop-down), `createDecl`, `createTypeDecl`, and member creators `createMemberLid`/`createMember` (right drop-down; `Range = BodyRange = m`).
- `processBinding isMember enclosingEntityKind isAbstract synBinding`:
  - Range fix for typed properties: `SynExpr.Typed` → inner expr range.
  - `SynPat.LongIdent` + member flags: glyph/kind by `MemberKind` (`Method` glyph `OverridenMethod` if `IsOverrideOrExplicitImpl`; `Property` for property kinds); `lid` shown without the receiver (`_thisVar :: nm :: _` → tail) with range merged to the member-name range.
  - Non-member `SynPat.LongIdent` → `Field` glyph `Field`.
  - `SynPat.Named`/`As … Named` → field/method glyph, `NavigationItemKind.Field`.
  - Else `[]`.
- `processExnDefnRepr`/`processExnDefn` — exception declarations (`FSharpGlyph.Exception`, `NavigationItemKind.Exception`, `EnclosingEntityKind.Exception`), with nested members from `SynExceptionDefn` member defns.
- `processTycon baseName synTypeDefn`:
  - `SynTypeDefnRepr.Exception` → exception handling.
  - `ObjectModel` → class glyph, nested = object members @ top members.
  - `SynTypeDefnSimpleRepr.Union` → union glyph `Union`, case members (`Other`/`Struct`).
  - `Enum` → enum glyph `Enum`, case members (`Field`/`EnumMember`).
  - `Record` → type glyph `Type`, field members (`Field`/`Field`).
  - `TypeAbbrev` → `Typedef` glyph, nested = top members.
- `processMembers members enclosingEntityKind` → `(m2, items)`:
  - Handles `LetBindings` (fields), `Member`/single `GetSetMember` (methods), `ValField`, `AutoProperty` (emits one entry per get/set accessor with the getter/setter accessibility via `access.GetSetAccessNoCheck()`), `AbstractSlot` (`OverridenMethod`, `IsAbstract=true`), `NestedType` → `failwith "tycon as member????"`, nested `Interface` members, get+set pairs.
  - Returns the union range and flattened items.
- `processNestedDeclarations decls` — right-drop-down `let` bindings at module level (`false, NavigationEntityKind.Module`).
- `processNavigationTopLevelDeclarations (baseName, decls)`:
  - `ModuleAbbrev` → module glyph.
  - `NestedModule` → module declaration + recursion into its decls with extended base name; `mBody` = union of nested decls and submodule ranges.
  - `Types` → `processTycon` per type; `Exception` → `processExnDefn`.
- Top-level assembly: `singleTopLevel = modules.Length = 1`. For each module: base name is shown only when there are multiple top-level modules; `kind` = `ModuleFile`/`Namespace` by `IsModule`; mBody = nested decls ∪ module range ∪ other. Top-level item created with `NavigationItem.Create(nm, kind, FSharpGlyph.Module, m, mBody, singleTopLevel, NavigationEntityKind.Module, false, access)`.
- Final pass: assign unique names to declarations and nested items (`WithUniqueName`), sort nested by `LogicalName`, sort top-level declarations by `LogicalName`.

### `getNavigationFromSigFile (modules: SynModuleOrNamespaceSig list)`

Mirror of the impl walker using `Map`-based name tracking and the `Syn*Sig` node types:
- `processExnRepr`/`processExnSig` (via `SynExceptionSig`).
- `processTycon` over `SynTypeDefnSig`/`SynTypeDefnSigRepr` — same union/enum/record/abbrev handling as the impl side, all with `isSignature=true` context.
- `processSigMembers` — `SynMemberSig.Member` (methods; get/set split by kind and accessor accessibility) and `SynMemberSig.ValField` (fields).
- `processNestedSigDeclarations` — module `val` declarations as methods.
- `processNavigationTopLevelSigDeclarations` — module abbreviations, nested modules, types, exceptions.
- Signature-specific dedup: nested items filtered by `Array.distinctBy (Range, BodyRange, LogicalName, Kind)`.

## Module `Navigation` (`[<RequireQualifiedAccess>]`)

- `getNavigation parsedInput` — dispatches `SigFile` → `getNavigationFromSigFile file.Contents`, `ImplFile` → `getNavigationFromImplFile file.Contents`.
- `empty = NavigationItems([||])`.

## `NavigateTo` feature

Types:
- `NavigableItemKind` (`[<RequireQualifiedAccess>]`) — `Module | ModuleAbbreviation | Exception | Type | ModuleValue | Field | Property | Constructor | Member | EnumCase | UnionCase` (with `ToString` override `sprintf "%+A"`).
- `NavigableContainerType` — `File | Namespace | Module | Type | Exception`.
- `NavigableContainer` (algebraic union in the implementation): `File of fileName: string | Container of containerType: NavigableContainerType * nameParts: string list * parent: NavigableContainer` with:
  - `FullName` — `textOfPath` of the concatenated name parts (empty for files).
  - `Type` — the container kind.
  - `Name` — last name part (empty for unnamed containers; file name for files).
- `NavigableItem` record — `Name`, `NeedsBackticks`, `Range`, `IsSignature`, `Kind`, `Container`.

`GetNavigableItems parsedInput`:
- Helpers: `convertToDisplayName` (demangles logical operator names via `ConvertValLogicalNameToDisplayNameCore`), `addLongIdent` (module/types — long idents, backticks check over path, `Range = rangeOfLid`), `addIdent` (single-ident items), `addModule`, `addModuleAbbreviation`, `addExceptionRepr` (also produces a new `Exception` container), `addComponentInfo` (pushes a `Container(containerType, pathOfLid lid, parent)` for types/modules), `addValSig`, `addField`, `addEnumCase`, `addUnionCase`.
- `mapMemberKind` — `Constructor`/`ClassConstructor` → `Constructor`; property kinds → `Property`; `Member` → `Member`.
- `addBinding synBinding itemKind container` — resolves kind from `itemKind` fallback member flags, and matches head pattern: `SynPat.LongIdent` with `[ _; id ]` (instance member), `[ id ]` (function), `Named`/`As…Named` (value).
- Recursive walkers:
  - Signature side: `walkSigFileInput` → `walkSynModuleOrNamespaceSig` (module/namespace containers) → `walkSynModuleSigDecl` (module abbrev, exception, namespace fragment, nested module, types, module-level `val`) → `walkSynTypeDefnSig` → `walkSynMemberSig`.
  - Impl side: `walkImplFileInput` → `walkSynModuleOrNamespace` → `walkSynModuleDecl` (exception defn, bindings, module abbrev, nested module, types) → `walkSynTypeDefn` → `walkSynTypeDefnRepr` → `walkSynTypeDefnSimpleRepr` (enum cases, record fields, union cases) → `walkSynMemberDefn` (abstract slot, auto property, interface members, members, get-set members, nested types, val fields, let bindings as `Field` items).
- Signature/impl dispatch by `ParsedInput`, returns `result.ToArray()`.

## Notes

- Navigation-bar data is entirely deriving from `ParsedInput`, so it works on untyped syntax and is cheap to refresh on every keystroke.
- Unique-name generation (`name_idx_of_total`) resolves ambiguous equal-named declarations deterministically for the VS nav-dropdown.
- `processMembers` intentionally `failwith`s on `SynMemberDefn.NestedType` (unsupported "tycon as member") — a known limitation vigilantly kept visible.
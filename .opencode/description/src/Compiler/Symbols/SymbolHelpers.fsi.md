# SymbolHelpers.fsi

**Purpose**
Internal (non-public) helper contract used by the symbol system (`Symbols.fs`) and the compiler
service to answer questions about `Item`s (name-resolution results over typed trees or imported
assemblies): source locations, file names, full names, suppression, attributes, method-group
expansion, XML documentation lookup (text vs. .xml-file signature), partial equality for de-
duplication, F1 keyword lookup, and type-provider static-argument inspection. These are the work-
horses behind `FSharpSymbol`/`FSharpEntity` member implementations.

**Namespace(s)**
`namespace FSharp.Compiler.Symbols` (declared `rec`); references `Internal.Utilities.Library`,
`FSharp.Compiler`, `TcGlobals`, `Infos`, `NameResolution`, `InfoReader`, `Text`, `Xml`,
`TypedTree`, `TypedTreeOps`.

**Modules / Types declared**
- `FSharpXmlDoc` (union, `[RequireQualifiedAccess]`, public) — describes documentation for an item:
  `None` (no docs) | `FromXmlText of XmlDoc` (in-memory text) | `FromXmlFile of dllName: string *
  xmlSig: string` (docs to be found in the DLL's .xml file under the given signature key).
  Documented as holding no references to compiler resources (safe to cache/hand off).
- `module SymbolHelpers` (internal).

**Public API surface (internal module vals)**
- `ParamNameAndTypesOfUnaryCustomOperation : TcGlobals -> MethInfo -> ParamNameAndType list` —
  arg names/types for a custom operator.
- `GetXmlCommentForItem : InfoReader -> range -> Item -> FSharpXmlDoc` — resolve docs (with
  `<inheritdoc>` expansion) for any item.
- `GetXmlCommentForMethInfoItem : InfoReader -> range -> Item -> MethInfo -> FSharpXmlDoc`.
- `RemoveDuplicateItems : TcGlobals -> ItemWithInst list -> ItemWithInst list` — de-duplicate
  using `ItemDisplayPartialEquality`.
- `RemoveExplicitlySuppressed : TcGlobals -> ItemWithInst list -> ItemWithInst list` (and
  `IsExplicitlySuppressed : TcGlobals -> Item -> bool`).
- `GetF1Keyword : TcGlobals -> Item -> string option` — F1 help keyword for quick info.
- `rangeOfItem : TcGlobals -> bool option -> Item -> range option` — declaration (or signature/
  implementation) location.
- `fileNameOfItem : TcGlobals -> string option -> range -> Item -> string`.
- `FullNameOfItem : TcGlobals -> Item -> string`.
- `ccuOfItem : TcGlobals -> Item -> CcuThunk option` — which compilation unit/assembly the item
  lives in.
- `IsAttribute : InfoReader -> Item -> bool`.
- `SelectMethodGroupItems2 : TcGlobals -> range -> ItemWithInst -> ItemWithInst list` — expand a
  "method group" (overloads) item into concrete items.
- `SimplerDisplayEnv : DisplayEnv -> DisplayEnv` and
  `ItemDisplayPartialEquality : TcGlobals -> IPartialEqualityComparer<Item>` — equality used for
  QuickInfo de-duplication.
- `FormatTyparMapping : DisplayEnv -> TyparInstantiation -> Layout list` — render an instantiation
  (`typar → type` mapping).
- Type-provider active patterns (`#if !NO_TYPEPROVIDERS`, each `[<return: Struct>]`):
  - `(|ItemIsProvidedType|_|) : TcGlobals -> Item -> TyconRef voption`
  - `(|ItemIsWithStaticArguments|_|) : range -> TcGlobals -> Item -> Tainted<ProvidedParameterInfo>[] voption`
  - `(|ItemIsProvidedTypeWithStaticArguments|_|) : range -> TcGlobals -> Item -> Tainted<ProvidedParameterInfo>[] voption`

**Internal helpers / active patterns**
The .fs adds: `EnvMisc2` module with `maxMembers = GetEnvInteger "FCS_MaxMembersInQuickInfo" 10`
(QuickInfo cap); private range helpers per item kind (`rangeOfValRef`, `rangeOfEntityRef`,
`rangeOfPropInfo`, `rangeOfMethInfo`, `rangeOfEventInfo`, `rangeOfUnionCaseInfo`,
`rangeOfRecdField`, `rangeOfRecdFieldInfo`); the recursion `ccuOfItem`; `computeCcuOfTyconRef`;
XmlDoc pipeline (`GetXmlDocFromLoader`, `GetXmlDocHelpSigOfItemForLookup`,
`tryGetImplicitInheritTarget` and its `tryBase*Target` helpers — override/base-type resolution
for `<inheritdoc/>`, `GetXmlCommentForItemAux` doing the actual expansion, `parseCref`-style
lookup); the `(|ItemWhereTypIsPreferred|_|)` pattern; a large `ItemDisplayPartialEquality`
implementation (type-head comparison, `valRefEq`); and `FullDisplayEnv`-related helpers.

**Significant notes**
- `GetXmlCommentForItem` is the single entry point tooling uses for `FSharpSymbol.XmlDoc`; it
  handles every `Item` shape (value refs, tycon refs, union cases, active patterns, record
  fields, props/events, methods, module refs) and falls back through the XmlDoc loader, including
  implicit `<inheritdoc/>` targets computed by `tryGetImplicitInheritTarget` (base slot, base
  type, ctor targets).
- `ItemDisplayPartialEquality` implements "same display signature" so QuickInfo doesn't show
  duplicate overloads.
- All functions require an `InfoReader`/`TcGlobals` — they never stand alone; pair with
  `SymbolEnv` from `Symbols.fs`.

**Cross-references**
- `SymbolHelpers.fs` — implementations.
- `Symbols.fs` — nearly every `FSharpSymbol` member delegates here (`FullName`,
  `DeclarationLocation`, `IsExplicitlySuppressed`, `XmlDoc`).
- `XmlDocInheritance.fs` — `expandInheritDocFromXmlText` is invoked by the XmlDoc expansion path.
- `XmlDocSigParser.fs` — parses XML doc comment IDs (cref format) used in the XmlDoc lookup.

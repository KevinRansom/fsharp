# SymbolHelpers.fs

**Purpose**
Internal implementation of the `SymbolHelpers` contract (declared in `SymbolHelpers.fsi`). It
sits between the public symbol layer (`Symbols.fs`) and compiler internals (`InfoReader`,
`NameResolution`, `TypedTree`, XML docs) to answer practical questions about an `Item`: where it
is declared, which file/CCU it belongs to, whether it is suppressed or an attribute, how to expand
overload groups, its XML documentation (including `<inheritdoc>` expansion and .xml signature
keys), and how to display/deduplicate it in QuickInfo.

**Namespace(s)**
`namespace FSharp.Compiler.Symbols`

**Modules / Types declared (implementation)**
- `FSharpXmlDoc` — union defined here (matching the .fsi): `None` | `FromXmlText of XmlDoc` |
  `FromXmlFile of dllName * xmlSig`.
- `module EnvMisc2` — `maxMembers = GetEnvInteger "FCS_MaxMembersInQuickInfo" 10` (QuickInfo
  member cap, overridable via environment variable).
- `module SymbolHelpers` (internal) — the full implementation.

**Notable functions (private/public)**
- Per-item range helpers: `rangeOfValRef`, `rangeOfEntityRef`, `rangeOfPropInfo`,
  `rangeOfMethInfo` (g + minfo), `rangeOfEventInfo`, `rangeOfUnionCaseInfo`, `rangeOfRecdField`,
  `rangeOfRecdFieldInfo`, then the recursive `rangeOfItem (g) (preferFlag: bool option) item` —
  `Some true` prefers the *signature* location, `Some false` the *implementation* location.
- CCU helpers: `computeCcuOfTyconRef`, `ccuOfMethInfo`, recursive `ccuOfItem` (resolves which
  `CcuThunk` declares the item, walking method-info/entity-ref cases).
- `fileNameOfItem` (with `qualProjectDir` optional qualification).
- `ParamNameAndTypesOfUnaryCustomOperation` — extracts param names/types (projection-parameter
  aware) for a custom operator `MethInfo`.
- XML doc pipeline:
  - `mkXmlComment`, `GetXmlDocFromLoader` (fetches `XmlDoc` from an `InfoReader`).
  - `GetXmlDocHelpSigOfItemForLookup` (recursive; computes the .xml signature string for each
    item kind).
  - `tryGetImplicitInheritTarget` — computes the implicit `<inheritdoc/>` source:
    `tryBaseTypeTarget`, `overriddenMemberBaseTypes` (declaring slot + direct base),
    `tryBaseMethodTarget`, `tryBasePropertyTarget`, `tryBaseCtorTarget`.
  - `GetXmlCommentForItemAux` — performs the actual doc lookup/expansion; builds an
    `implicitTargetCrefOpt` + `resolveCref` pair and calls into the inheritance expander
    (`makeExpandedXmlDoc` in `Symbols.fs`) when `<inheritdoc` is present.
  - `GetXmlCommentForItem`, `GetXmlCommentForMethInfoItem` — public dispatch over all `Item`
    shapes (value/tycon/union case/active pattern/record field/property/event/method/module refs).
- `GetF1Keyword` — F1 keyword per item kind, including `getKeywordForMethInfo` (constructs
  `typeString`/`paramString` for overloads) and module/namespace full-name assembly.
- Dedup/suppression: `RemoveDuplicateItems` (uses `ItemDisplayPartialEquality`),
  `IsExplicitlySuppressed` (checks `NonVersionableAttribute`-style suppression via
  `generalizedTyconRef eqns`), `RemoveExplicitlySuppressed`.
- `SimplerDisplayEnv` (a display env with reduced info), `ItemDisplayPartialEquality`
  (large partial-equality closure; includes `equalHeadTypes`, `valRefEq g vref1 vref2` for value
  identity, and type-arg structural comparison).
- `FormatTyparMapping` — `Layout`-based rendering of a `TyparInstantiation`.
- Active patterns: `(|ItemWhereTypIsPreferred|_|)`; type-provider patterns under
  `#if !NO_TYPEPROVIDERS`: `(|ItemIsProvidedType|_|)`, `(|ItemIsWithStaticArguments|_|)`,
  `(|ItemIsProvidedTypeWithStaticArguments|_|)`, and the helper
  `(|ItemIsProvidedMethodWithStaticArguments|_|)` which calls `PApplyWithProvider`/
  `GetStaticParameters` via `Tainted` computations.
- `SelectMethodGroupItems2` — expands method-group overloads to a concrete list.

**Internal helpers / active patterns**
Most of the helpers above; `IsAttribute` inspects the item's tycon (generalized) and compares to
`System.Attribute`; `FullNameOfItem` builds a dotted path using `definiteNamespace` detection
over module refs.

**Significant notes**
- This is the *internal* workhorse module: nearly every `FSharpEntity`/`FSharpSymbol` property in
  `Symbols.fs` (FullName, DeclarationLocation, IsExplicitlySuppressed, XmlDoc, XmlDocSig) routes
  through one of these functions.
- XmlDoc resolution handles both in-memory (`XmlDoc` text) and compiled (`dllName + xmlSig`)
  cases — the `FSharpXmlDoc` union is the boundary type.
- The type-provider patterns are conditionally compiled (`NO_TYPEPROVIDERS`); they surface
  `Tainted<ProvidedParameterInfo>[]` static arguments so FCS can display provided members.
- `EnvMisc2.maxMembers` lets builds/CI control QuickInfo fan-out.

**Cross-references**
- `SymbolHelpers.fsi` — the contract (must remain in sync with this file's val signatures).
- `Symbols.fs` — primary consumer; see `Impl` module calls and `FSharpSymbol.IsExplicitlySuppressed` /
  `FSharpEntity.XmlDoc`.
- `XmlDocInheritance.fs` — provides `expandInheritDocFromXmlText` used by the inheritance path in
  `GetXmlCommentForItemAux`.
- `XmlDocSigParser.fs` — parses doc-comment IDs (cref format) that appear in .xml lookups.

# Symbols.fs

**Purpose**
Implementation of the public symbol API contract declared in `Symbols.fsi`. It wraps the internal
compiler representation (`TypedTree` `Item`s, entity/value/tycon refs, `CcuThunk`s, pickled
assemblies) in the read-only, "as seen by the F# language" classes (`FSharpSymbol` and subtypes),
giving each symbol a stable identity that works uniformly for in-memory compilations and imported
pickled DLLs. This is the layer the compiler service (FCS) exposes to tooling, analyzers, and
scripting.

**Namespace(s)**
`namespace rec FSharp.Compiler.Symbols`

**Modules / Types declared (per .fsi, implemented)**
See `Symbols.fsi.md` for the full type listing; this file implements:
- `FSharpAccessibility` — wraps `Accessibility` + `?isProtected`; `Public|Internal|Private` pattern.
- `SymbolEnv` — holds `g`, `amap`, `thisCcu`, `thisCcuTyp`, `infoReader`, `tcImports`, and a
  `LightweightTcValForUsingInBuildMethodCall` closure (`tcValF`).
- `Impl` (internal module) — helpers: `protect`, `makeReadOnlyCollection`, `makeXmlDoc`, cref
  parsing (`parseCref`, `parseNestedTypeAlternativePath`), XmlDoc lookup
  (`tryGetXmlDocText`, `tryFindMemberXmlDoc`, `tryFindEntityByPath`, `tryFindEntityInCcu`,
  `tryGetDocByCref`, `buildCrefResolver`), inheritdoc expansion
  (`tryGetInheritDocXmlText`, `makeExpandedXmlDoc`, `makeElaboratedXmlDoc`,
  `getImplicitTargetCrefForEntity`, `getImplicitTargetCrefForMember`), rescope/accessibility
  (`rescopeEntity`, `entityIsUnresolved`, `checkForCrossProjectAccessibility`,
  `getApproxFSharpAccessibilityOfMember`/`OfEntity`), `getLiteralValue`, `getXmlDocSigForEntity`.
- `FSharpDisplayContext` — `Empty`, `WithShortTypeNames`, prefix/suffix generic-parameter styles.
- `FSharpSymbol` — base class; lazy `item: unit -> Item` evaluation; `Create` statics;
  `FullName`/`DisplayName`/locations delegate to `SymbolHelpers`; attribute lookup via
  `TryGetAttribute<'T>`/`HasAttribute<'T>`; `IsEffectivelySameAs` via
  `ItemsAreEffectivelyEqual(cenv.g, ...)`, hash via `ItemsAreEffectivelyEqualHash`.
- `FSharpEntity`, `FSharpUnionCase`, `FSharpField` (with `FSharpFieldData` and
  `FSharpAnonRecordTypeDetails`), `FSharpAccessibilityRights`, `FSharpActivePatternCase`/`Group`,
  `FSharpGenericParameter`, `FSharpStaticParameter`, constraint classes
  (`FSharpGenericParameterConstraint`, `...MemberConstraint`, `...DelegateConstraint`,
  `...DefaultsToConstraint`), `FSharpInlineAnnotation`, `FSharpMemberOrFunctionOrValue` (with
  `FSharpMemberOrValData`; aliases `FSharpMemberOrVal`, `FSharpMemberFunctionOrValue`),
  `FSharpType`, `FSharpAttribute`, `FSharpParameter`, `FSharpDelegateSignature`,
  `FSharpAbstractParameter`, `FSharpAbstractSignature`, `FSharpAssemblySignature`,
  `FSharpAssembly`, `FSharpOpenDeclaration`.

**Public API surface**
All members match `Symbols.fsi`. Implementation notes on the key ones:
- `FSharpSymbol.IsEffectivelySameAs(other)` — delegates to the `Item` equality function in
  `TypedTreeOps` (`ItemsAreEffectivelyEqual`); used by "uses of symbol" queries.
- `FSharpEntity` — ~100 read-only members dispatched off the inner `EntityRef`; type classification
  (`IsFSharpRecord`, `IsFSharpUnion`, `IsEnum`, `IsDelegate`, `IsInterface`, `IsMeasure`,
  `IsFSharpModule`, `IsNamespace`, `IsProvided*`) reads `Entity` flags and the
  `CompiledRepresentation` union; naming members read `DisplayNameCore`, compiled name,
  `AccessPath` etc.; `AsType()` builds a `FSharpType` ground type; `UnionCases`,
  `MembersFunctionsAndValues`, `FSharpFields`, `NestedEntities` wrap `IList` via
  `makeReadOnlyCollection`.
- `FSharpMemberOrFunctionOrValue` — dispatched off `FSharpMemberOrValData` (wrapping `ValRef` or
  `MethInfo`); `Is*` predicates consult `ValRepr` and member flags; `FullType`/
  `CurriedParameterGroups`/`ReturnParameter` go through `InfoReader`/`NameResolution` helpers;
  `GetWitnessPassingInfo` and `FormatRichText` use the display environment.
- `FSharpType` — the largest member set in the file (~200 lines from line 2950); `Format`/
  `FormatRichText` call the layout engine with `cenv`'s display env; `Is*` type classifiers call
  `TypedTreeOps` (e.g. `isTupleTy`, `isFunctionTy`, `isArrayTy`, `isMeasureTy`,
  `isAnonRecdTy`); `StripAbbreviations`, `ErasedType`, `Instantiate`, `Prettify` statics.
- `FSharpAttribute` — `AttributeType`, `ConstructorArguments`, `NamedArguments`, `Format`,
  `IsAttribute<'T>`.
- `FSharpAssembly`/`FSharpAssemblySignature` — wrap `CcuThunk`/`ModuleOrNamespaceType`;
  `FindEntityByPath`, `Entities`, `Attributes`.

**Internal helpers / active patterns / extension members**
- `Impl.protect`, `Impl.makeReadOnlyCollection`, `Impl.makeXmlDoc` — shared by all symbol classes.
- `Impl.(|Public|Internal|Private|)` pattern over `TAccess`.
- XmlDoc/inheritdoc pipeline: `buildCrefResolver`, `tryGetInheritDocXmlText`,
  `makeExpandedXmlDoc` (calls `XmlDocInheritance.expandInheritDocFromXmlText`), and
  `getImplicitTargetCrefForEntity`/`ForMember` (base-type override target for bare `<inheritdoc/>`).
- `Impl.checkForCrossProjectAccessibility` and the `getApproxFSharpAccessibilityOf*` functions
  translate IL accessibility into F# visibility for imported code.

**Significant internal logic**
- Laziness: `FSharpSymbol` stores `item: unit -> Item` so symbol creation is cheap and
  heavy lifting is deferred until first member access — matters when tooling enumerates entities.
- Unresolved assemblies: `entityIsUnresolved` marks symbols whose `CcuThunk` fails to load;
  most members either throw a descriptive error or return a safe value; several `Try*` members
  are the "safe" variants.
- Cross-project accessibility: internal members get synthesized accessibility based on the
  declaring entity's accessibility (IL has no notion of protected-member scoping the way C# does).
- `getImplicitTargetCrefFor*` computes the default `<inheritdoc/>` target (closest base override
  or base type) which `SymbolHelpers.GetXmlCommentForItem` consumes.
- `FSharpType.Prettify` statically renames inference typars to `'a`, `'b`, ... for display.

**Cross-references**
- `Symbols.fsi` — the contract this file implements.
- `Exprs.fs` — `FSharpExpr` nodes carry these symbol types (`FSharpType` etc.).
- `SymbolHelpers.fs` — `SymbolHelpers.IsExplicitlySuppressed`, `FullNameOfItem`, `rangeOfItem`,
  `GetXmlCommentForItem` are called by nearly every symbol member.
- `SymbolPatterns.fs` — active patterns built on the `Is*` predicates declared here.
- `XmlDocInheritance.fs` / `XmlDocSigParser.fs` — backing `XmlDoc` expansion and cref parsing used
  by the `XmlDoc`/`XmlDocSig` members.
- `FSharpDiagnostic.fsi` — extended data exposes these symbols for type mismatches, sig/impl conformance.

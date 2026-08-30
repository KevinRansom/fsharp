# NameResolution.fs

**Purpose**
Core of name resolution in the F# type-checker: resolves simple and (long) qualified identifiers to symbols
(`Item`s) in expression, pattern, and type positions, managing the layered `NameResolutionEnv`, extension
members (F#-style and C#-style), type name lookup (with arity), record/union/active-pattern items, and the
creation of inference typars. It also implements the `ITypecheckResultsSink` plumbing used to report name
resolutions, expression typing, open declarations, and related symbol uses back to the language-service
layer. A very large module (~4500+ lines).

**Namespace(s)**
`module internal FSharp.Compiler.NameResolution`

**Modules / Types declared** (see `NameResolution.fsi` for the contract)
- `NameResolver` — resolution context holding `TcGlobals`, `ImportMap`, `InfoReader`, and an instantiation generator.
- `Item` — the discriminated union of resolution results (Value, UnionCase, ActivePatternResult/Case, ExnCase, RecdField, Trait, UnionCaseField, AnonRecdField, NewDef, ILField, Event, Property, MethodGroup, CtorGroup, DelegateCtor, Types, CustomOperation, CustomBuilder, TypeVar, ModuleOrNamespaces, ImplicitOp, OtherName, SetterArg, UnqualifiedType...).
- `ItemWithInst`, `FieldResolution`, `ExtensionMember` (FSExtMem / ILExtMem with `ExtensionMethodPriority`).
- `NameResolutionEnv` — record of all lookup tables (unqualified items, pat items, modules/namespaces, field labels, tycons by access name, extension members, typars).
- `ArgumentContainer`, `EnclosingTypeInst`, `FullyQualifiedFlag`, `ExtraDotAfterIdentifier`, `BulkAdd`, `CheckForDuplicateTyparFlag`, `TypeNameResolutionFlag`, `TypeNameResolutionStaticArgsInfo`, `TypeNameResolutionInfo`.
- `ItemOccurrence` (struct), `CapturedNameResolution`, `TcResolutions`, `TcSymbolUseData`, `TcSymbolUses` — language-service capture structures.
- `FormatStringCheckContext`, `ITypecheckResultsSink`, `TcResultsSinkImpl`, `TcResultsSink` — results-sink plumbing.
- `ResultCollectionSettings`, `LookupIsInstance`, `LookupKind`, `WarnOnUpperFlag`, `PermitDirectReferenceToGeneratedType`, `AfterResolution`, `ShouldNotifySink`, `ResolveCompletionTargets`, `ExplicitOrSpread<'E,'S>`.
- `NoConstructorsAvailableForType`, `IndeterminateType`, `UpperCaseIdentifierInPattern` — exceptions.

**Core resolution functions**
- `ResolveLongIdentAsModuleOrNamespace` — long id → module/namespace (with sub-module auto-open handling).
- `ResolveExprLongIdent`, `ResolveLongIdentAsExprAndComputeRange`, `ResolveExprDotLongIdentAndComputeRange` — expression-position long-ident resolution (the last two also compute terminal identifier ranges, #14284).
- `ResolveTypeLongIdent`, `ResolveTypeLongIdentInTyconRef` — type-position resolution; returns `EnclosingTypeInst * TyconRef * TypeInst`.
- `ResolvePatternLongIdent` — pattern-position resolution (union case, exn, field, literal).
- `ResolveField`, `ResolveNestedField` — record/class field paths (nested record field paths for spreads and nested updates).
- `ResolveObjectConstructor` — `new X()` constructor resolution.
- `ResolvePartialLongIdent`, `ResolveCompletionsInType`, `GetVisibleNamespacesAndModulesAtPoint`, `IsItemResolvable` — intellisense/autocomplete oriented lookups.
- `TryToResolveLongIdentAsType`, `ResolveProvidedTypeNameInEntity` — provided-type / type-lookup helpers.

**Type lookup helpers**
- `LookupTypeNameInEnvNoArity` / `LookupTypeNameInEnvHaveArity` / `LookupTypeNameInEnvMaybeHaveArity`.
- `LookupTypeNameInEntity*` family (`HaveArity`, `NoArity`, `MaybeHaveArity`) for nested types.
- `GetNestedTyconRefsOfType`, `MakeNestedType`, `GetNestedTypesOfType` — nested type resolution including type instantiations.
- `GetRecordFieldsInScope`, `getRecordTyconsInScope`, `ResolvePartialLongIdentToClassOrRecdFields`, `ResolveRecordOrClassFieldsOfType` — record/class field lookup for intellisense.

**Extension member machinery**
- `IsTyconRefUsedForCSharpStyleExtensionMembers`, `IsTypeUsedForCSharpStyleExtensionMembers`, `IsMethInfoPlainCSharpStyleExtensionMember`, `GetTyconRefForExtensionMembers`.
- `ComputeCSharpStyleExtensionMembers`, `GetCSharpStyleIndexedExtensionMembersForTyconRef` (private).
- `IntrinsicMethInfosOfType`, `ExtensionMethInfosOfTypeInScope`, `AllMethInfosOfTypeInScope` — gather intrinsic + extension methods.
- `IntrinsicPropInfosOfTypeInScope`, `SelectPropInfosFromExtMembers`, `ExtensionPropInfosOfTypeInScope`, `AllPropInfosOfTypeInScope`.
- `IsExtensionMethCompatibleWithTy` — checks the 'this' argument of an extension method is compatible with the target type.
- `TrySelectExtensionMethInfoOfILExtMem` — selects a compatible IL extension method for a type.
- `NextExtensionMethodPriority` — per-`open` priority stamp used to order extension members.

**Add-to-env functions** (`Add*ToNameEnv`)
- `AddFakeNamedValRefToNameEnv`, `AddFakeNameToNameEnv`, `AddValRefToNameEnv`, `AddActivePatternResultTagsToNameEnv`, `AddTyconRefsToNameEnv`, `AddExceptionDeclsToNameEnv`, `AddModuleAbbrevToNameEnv`, `AddModuleOrNamespaceRef(ToNameEnv|sToNameEnv|sContentsToNameEnv)`, `AddTypeContentsToNameEnv`, `AddDeclaredTyparsToNameEnv`, `AddStaticContentOfTypeToNameEnv`, `AddValRefsToItems`, `AddValRefToExtensionMembers`, `AddValRefsToActivePatternsNameEnv`, `AddValRefsToNameEnvWithPriority`.

**Typar / inference-type creation**
- `FreshenTycon`, `FreshenTyconWithEnclosingTypeInst`, `FreshenUnionCaseRef`, `FreshenRecdFieldRef`.
- `NewAnonTypar`, `NewNamedInferenceMeasureVar`, `NewInferenceMeasurePar`, `NewErrorTypar/Type/Measure`, `NewInferenceType(s)`.
- `FreshenTypar`, `FreshenAndFixupTypars`, `FreshenTypeInst`, `FreshenTypars`, `FreshenMethInfo`.

**Sink plumbing**
- `WithNewTypecheckResultsSink`, `TemporarilySuspendReportingTypecheckResultsToSink`, `RunWithBufferedReporting` (commit-or-drop buffered reporting).
- `CallEnvSink`, `RegisterUnionCaseTesterForProperty` (#16621), `CallNameResolutionSink`, `CallNameResolutionSinkReplacing`, `CallMethodGroupNameResolutionSink`, `CallRelatedSymbolSink`, `CallExprHasTypeSink`, `CallExprHasTypeSinkSynthetic`, `CallOpenDeclarationSink`.
- `TcResultsSinkImpl` constructors and `GetResolutions`, `GetSymbolUses`, `GetOpenDeclarations`, `GetFormatSpecifierLocations`.

**Equality / hash for Items**
- `ItemsAreEffectivelyEqual`, `ItemsAreEffectivelyEqualHash` — up-to-signature equality + companion hash for caching/comparison.

**Other notable internals**
- `ActivePatternElemsOfModuleOrNamespace` / `...OfVal` / `...OfValRef` — cached active-pattern element maps.
- `UnionCaseRefsInTycon`, `UnionCaseRefsInModuleOrNamespace`, `TryFindTypeWithUnionCase`, `TryFindTypeWithRecdField` — used for union-case/field disambiguation by name.
- `ResolveUnqualifiedItem` — final step turning a lookup hit into a resolved `Item` (with freshening).
- `ChooseMethInfosForNameEnv`, `ChoosePropInfosForNameEnv`, `ChooseFSharpFieldInfosForNameEnv`, `ChooseILFieldInfosForNameEnv`, `ChooseEventInfosForNameEnv` — filter member sets for name env insertion.
- `AddEntityForProvidedType`, `ResolveProvidedTypeNameInEntity` — type provider entity integration.

**Significant internal logic**
- Name resolution is layered: unqualified items are in a `LayeredMap` (innermost shadowing), extension members are kept per-tycon with a `TyconRefMultiMap`, and C#-style extension members are materialized via `ComputeCSharpStyleExtensionMembers` (and indexed ones via `GetCSharpStyleIndexedExtensionMembersForTyconRef`).
- Type names are looked up both by mangled name (`List`) and demangled name+arity (`List,1`), supporting static-args information (`TypeNameResolutionStaticArgsInfo.DefiniteEmpty` / `FromTyArgs n`).
- `ItemsAreEffectivelyEqual` walks the full `Item` union and compares payload contents (val refs, tycon refs, meth info groups, etc.); a companion `ItemsAreEffectivelyEqualHash` keeps the pair consistent for use in hash-based structures.
- `RunWithBufferedReporting` is used around speculative resolution (e.g. overload resolution tries) to avoid reporting noise to the language service; it commits only if `commitWhen` succeeds.
- C#-style extension member detection (`IsMethInfoPlainCSharpStyleExtensionMember`, `GetTyconRefForExtensionMembers`) drives whether a member appears in the extension-member map, and `ExtensionMethodPriority` stamps the `open` order so later `open`s win in `TrySelectExtensionMethInfoOfILExtMem`.

**Cross-references**
- `NameResolution.fsi` — full contract.
- `CheckExpressions.fs` (Expressions dir) — primary caller of `ResolveExprLongIdent` / `ResolveLongIdentAsExprAndComputeRange`.
- `CheckPatterns.fs` (sibling) — calls `ResolvePatternLongIdent`.
- `CheckBasics.fsi` (sibling) — `TcEnv` embeds a `NameResolutionEnv`.
- `MethodCalls.fsi` — `CalledMeth` constructor takes a `NameResolutionEnv option`.
- `MethodOverrides.fsi` — `CheckDispatchSlotsAreImplemented` threads a `NameResolutionEnv`.
- `RelatedSymbolUse.fs` — `RelatedSymbolUseKind` consumed by `CallRelatedSymbolSink`.
- `NicePrint.fsi` — rendering of `Item`s in error messages.
- `Infos.fs`/`Import.fs` (sibling dirs) — `TyconRef`, `ValRef`, `ModuleOrNamespaceRef` resolution backends.

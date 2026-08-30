# NameResolution.fsi

**Purpose**
Public contract (internal module) for the F# checker's name-resolution subsystem. Declares the resolution
context (`NameResolver`), the result union (`Item`), the layered resolution environment (`NameResolutionEnv`),
all the lookup/add flags and helper record types, the long-identifier resolution entry points used by the
expression/type/pattern checkers, and the `ITypecheckResultsSink` / `TcResultsSink` plumbing that reports
resolutions, expression typing, and related symbol uses to the language-service layer.

**Namespace(s)**
`module internal FSharp.Compiler.NameResolution`

**Types declared**
- `NameResolver` — context: `g`, `amap`, `InfoReader`, an instantiation generator; `languageSupportsNameOf` flag.
- `Item` — union of resolution results (Value, UnionCase, ActivePatternResult/Case, ExnCase, RecdField, Trait, UnionCaseField, AnonRecdField, NewDef, ILField, Event, Property, MethodGroup, CtorGroup, DelegateCtor, Types, CustomOperation, CustomBuilder, TypeVar, ModuleOrNamespaces, ImplicitOp, OtherName, SetterArg, UnqualifiedType...); members `DisplayNameCore`, `DisplayName`.
- `ItemWithInst` + `(|ItemWithInst|)` pattern + `ItemWithNoInst` — item paired with a `TyparInstantiation`.
- `ArgumentContainer` — what a named argument belongs to (method or provided type).
- `EnclosingTypeInst = TypeInst`; `FieldResolution of RecdFieldInfo * bool` (deprecation flag).
- `ExtensionMember` — `FSExtMem of ValRef * ExtensionMethodPriority` | `ILExtMem of TyconRef * MethInfo * ExtensionMethodPriority`; `Priority` member.
- `NameResolutionEnv` — large record of lookup tables (unqualified items, pat items, modules/namespaces incl. fully-qualified, field labels, record/union type insts, tycons by access / demangled name / arity, extension members indexed and unindexed, typars); `static member Empty`, `DisplayEnv`, `FindUnqualifiedItem`.
- `FullyQualifiedFlag` (`FullyQualified | OpenQualified`), `ExtraDotAfterIdentifier`, `BulkAdd`, `CheckForDuplicateTyparFlag`.
- `TypeNameResolutionFlag` (`ResolveTypeNamesToCtors | ResolveTypeNamesToTypeRefs`); `TypeNameResolutionStaticArgsInfo` (`DefiniteEmpty`, `FromTyArgs`); `TypeNameResolutionInfo` (`Default`, `ResolveToTypeRefs`).
- `ItemOccurrence` (struct) — `Binding | Use | UseInType | UseInAttribute | Pattern | Implemented | RelatedText | Open | InvalidUse`.
- `CapturedNameResolution`, `TcResolutions`, `TcSymbolUseData`, `TcSymbolUses` — language-service capture containers.
- `FormatStringCheckContext` — source text + line-start positions for format-string parsing.
- `ITypecheckResultsSink` — abstract sink: `NotifyEnvWithScope`, `NotifyExprHasType`, `NotifyExprHasTypeSynthetic`, `NotifyNameResolution`, `NotifyMethodGroupNameResolution`, `NotifyFormatSpecifierLocation`, `NotifyRelatedSymbolUse`, `NotifyOpenDeclaration`, `CurrentSourceText`, `FormatStringCheckContext`.
- `TcResultsSinkImpl` — sink collector; `TcResultsSink` — redirectable wrapper (`NoSink`, `WithSink`).
- `ResultCollectionSettings` (`AllResults | AtMostOneResult`), `LookupIsInstance` (`Ambivalent | Yes | No`), `LookupKind` (`RecdField | Pattern | Expr | Type | Ctor`), `WarnOnUpperFlag`, `PermitDirectReferenceToGeneratedType`, `AfterResolution` (`DoNothing | RecordResolution`), `ShouldNotifySink`, `ResolveCompletionTargets`.
- `ExplicitOrSpread<'Explicit,'Spread>` + `(|ExplicitOrSpread|)` pattern.
- Exceptions `NoConstructorsAvailableForType`, `IndeterminateType`, `UpperCaseIdentifierInPattern`.

**Key public values** (representative; full set in .fs)
- `ActivePatternElemsOfModuleOrNamespace`.
- Env construction: `AddFakeNamedValRefToNameEnv`, `AddFakeNameToNameEnv`, `AddValRefToNameEnv`, `AddActivePatternResultTagsToNameEnv`, `AddTyconRefsToNameEnv`, `AddExceptionDeclsToNameEnv`, `AddModuleAbbrevToNameEnv`, `AddModuleOrNamespaceRef(s)(Contents)ToNameEnv`, `AddTypeContentsToNameEnv`, `AddDeclaredTyparsToNameEnv`.
- Sink plumbing: `WithNewTypecheckResultsSink`, `TemporarilySuspendReportingTypecheckResultsToSink`, `RunWithBufferedReporting`, `CallEnvSink`, `RegisterUnionCaseTesterForProperty`, `CallNameResolutionSink(Replacing)`, `CallMethodGroupNameResolutionSink`, `CallRelatedSymbolSink`, `CallExprHasTypeSink(Synthetic)`, `CallOpenDeclarationSink`.
- Member gathering: `AllPropInfosOfTypeInScope`, `ExtensionPropInfosOfTypeInScope`, `AllMethInfosOfTypeInScope`, `IsExtensionMethCompatibleWithTy`.
- Typar/inference creation: `FreshenRecdFieldRef`, `NewAnonTypar`, `NewNamedInferenceMeasureVar`, `NewInferenceMeasurePar`, `NewInferenceType`, `NewByRefKindInferenceType`, `NewErrorType`, `NewErrorMeasure`, `NewInferenceTypes`, `FreshenTypars`, `FreshenMethInfo`, `FreshenAndFixupTypars`, `FreshenTypeInst`.
- Equality/hash: `ItemsAreEffectivelyEqual`, `ItemsAreEffectivelyEqualHash`.
- Long-ident resolution: `ResolveLongIdentAsModuleOrNamespace`, `ResolveObjectConstructor`, `ResolveLongIdentInType`, `ResolvePatternLongIdent`, `ResolveTypeLongIdentInTyconRef`, `ResolveTypeLongIdent`, `ResolveField`, `ResolveNestedField`, `ResolveExprLongIdent`, `getRecordFieldsInScope`, `getRecordTyconsInScope`, `ResolvePartialLongIdentToClassOrRecdFields`, `ResolveRecordOrClassFieldsOfType`, `ResolveLongIdentAsExprAndComputeRange`, `ResolveExprDotLongIdentAndComputeRange`, `FakeInstantiationGenerator`, `TryToResolveLongIdentAsType`.
- IntelliSense: `ResolvePartialLongIdent`, `ResolveCompletionsInType`, `GetVisibleNamespacesAndModulesAtPoint`, `IsItemResolvable`, `TrySelectExtensionMethInfoOfILExtMem`.

**Significant notes**
- The fsi documents the rationale for `Item.OtherName` (FCS `FSharpParameter` symbols, including the missing-identifier case for unnamed parameters of function-typed values).
- `LookupIsInstance` is documented as currently only applied to filter extension methods with a static/instance mismatch.
- `AfterResolution.RecordResolution` carries the callbacks the checker must fire to record a completed symbol use (instantiation, or resolved overload/override) for the language service.
- `TcResolutions.CapturedMethodGroupResolutions` is documented as a fallback checked when no captured regular name resolution is found.

**Cross-references**
- `NameResolution.fs` — implementation of the entire contract.
- `RelatedSymbolUse.fs` — `RelatedSymbolUseKind` used in `NotifyRelatedSymbolUse` / `CapturedRelatedSymbolUses`.
- `MethodCalls.fsi` — consumes `NameResolutionEnv` in the `CalledMeth` constructor.
- `MethodOverrides.fsi` — `CheckDispatchSlotsAreImplemented(OverridesAreAllUsedOnce)` take `NameResolutionEnv`.
- `NicePrint.fsi` — rendering of items/types in resolution diagnostics.
- `CheckBasics.fsi` (sibling) — `TcEnv` carries a `NameResolutionEnv`.
- `Infos.fs` / `Import.fs` (sibling dirs) — symbol tables walked by resolution.

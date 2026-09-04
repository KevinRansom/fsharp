# Symbols.fsi

**Purpose**
The central public contract of the F# compiler's symbol system. It defines the abstract
"as seen by the F# language" type hierarchy (`FSharpSymbol` and its subtypes) that links parsed,
typed declarations to a stable semantic identity across compilation units, signature files, and
pickled assemblies. Compiler API clients (FCS, analyzers, scripting) read all entities, members,
types, fields, generic parameters, and attributes through this interface; the matching `Symbols.fs`
implements it against the internal `TypedTree` / `Item` representation.

**Namespace(s)**
`namespace rec FSharp.Compiler.Symbols` (declared `rec`, so `Exprs.fsi` in the same directory can
refer into it). Also references many internal compiler namespaces: `FSharp`, `AccessibilityLogic`,
`CheckDeclarations`, `CompilerImports`, `Import`, `InfoReader`, `NameResolution`, `Syntax`, `Text`,
`TypedTree`, `TypedTreeOps`, `TcGlobals`.

**Modules / TypeDefs / Classes / Records / Unions / Structs declared**
- `SymbolEnv` (class, internal) — bundle of compiler state (g, thisCcu, thisCcuTyp, tcImports, amap, infoReader) handed to every symbol.
- `FSharpAccessibility` (class) — wraps internal `Accessibility`; IsPublic/IsPrivate/IsInternal/IsProtected.
- `FSharpDisplayContext` (class) — capture of a location's display rules for formatting types/signatures; `Empty` plus `WithShortTypeNames`, prefix/suffix generic-parameter tweaks.
- `FSharpObsoleteDiagnosticInfo` (record, `[<Struct>]`) — IsError, DiagnosticId, Message, UrlFormat.
- `FSharpSymbol` (abstract class) — base for all symbols; identity, names, location, accessibility, attributes, `IsEffectivelySameAs` / `GetEffectivelySameAsHash`.
- `FSharpAssembly` (class) — QualifiedName, Contents (FSharpAssemblySignature), FileName, SimpleName, IsFSharp, IsProviderGenerated.
- `FSharpAssemblySignature` (class) — Entities, Attributes, FindEntityByPath, TryGetEntities.
- `FSharpEntity` (class) — type/module definition symbol; the workhorse. Many `Is*` type-classifiers, naming (LogicalName/CompiledName/Display/AccessPath/Namespace/Qualified/Full), generic parameters, members, fields, union cases, abbreviations, interfaces, base type, XmlDoc/XmlDocSig, safe `Try*` accessors.
- `FSharpDelegateSignature` (class) — DelegateArguments (name+type), DelegateReturnType.
- `FSharpAbstractParameter` (class) — Name, Type, IsInArg/IsOutArg/IsOptionalArg, Attributes.
- `FSharpAbstractSignature` (class) — abstract slot: arguments/return, method+type generic params, DeclaringType, Name.
- `FSharpUnionCase` (class) — union case symbol: Name, DeclaringEntity, HasFields, Fields, ReturnType, CompiledName, XmlDoc.
- `FSharpAnonRecordTypeDetails` (class) — compiled form of anon records: Assembly, EnclosingCompiledTypeNames, CompiledName, SortedFieldNames.
- `FSharpField` (class) — record/union/exception/anon-record field: IsMutable/IsLiteral/IsVolatile/IsStatic, IsAnonRecordField, IsUnionCaseField, FieldType, LiteralValue, Property/Field Attributes.
- `FSharpAccessibilityRights` (class) — rights of a compilation to access symbols (ccu + AccessorDomain).
- `FSharpGenericParameter` (class) — typar symbol: Name, IsMeasure, IsSolveAtCompileTime, IsCompilerGenerated, Constraints.
- `FSharpStaticParameter` (class, NO_TYPEPROVIDERS) — type-provider static parameter.
- `FSharpGenericParameterMemberConstraint` (class) — MemberSources, MemberName, MemberIsStatic, arg/return types.
- `FSharpGenericParameterDelegateConstraint` (class) — DelegateTupledArgumentType, DelegateReturnType.
- `FSharpGenericParameterDefaultsToConstraint` (class) — DefaultsToPriority, DefaultsToTarget.
- `FSharpGenericParameterConstraint` (class) — discriminates all constraint kinds (coerces-to, defaults-to, nullness, comparison, equality, unmanaged, member, non-nullable, reference type, simple-choice, default-constructor, enum, delegate, allows-refstruct).
- `FSharpInlineAnnotation` (union, `[RequireQualifiedAccess]`) — AlwaysInline | OptionalInline | NeverInline | AggressiveInline.
- `FSharpMemberOrFunctionOrValue` (class) — method/property/event/function/value/extension-member symbol; the largest surface (see API section).
- `FSharpParameter` (class) — a parameter: Name, DeclarationLocation, Type, Attributes, IsParamArrayArg/IsOutArg/IsInArg/IsOptionalArg.
- `FSharpActivePatternCase` (class) — Name, Index, DeclarationLocation, Group, XmlDoc.
- `FSharpActivePatternGroup` (class) — Name, Names, IsTotal, OverallType, DeclaringEntity.
- `FSharpType` (class) — the F# view of a `TType`: abbreviation, type definition, tuple/function/array/measure, anon-record, generic parameter, nullness; formatting, instantiation, interface/base-type, erased form.
- `FSharpAttribute` (class) — custom attribute: AttributeType, ConstructorArguments, NamedArguments, Format, IsAttribute<'T>.
- `FSharpOpenDeclaration` (sealed class) — open declaration: LongId, Target, Range, Modules, Types, AppliedScope, IsOwnNamespace.

**Public API surface (significant, not exhaustive)**
Symbols all expose the `FSharpSymbol` identity API: `Assembly`, `FullName`,
`DeclarationLocation`, `DisplayName`/`DisplayNameCore`, `IsEffectivelySameAs`,
`GetEffectivelySameAsHash`, `IsExplicitlySuppressed`, abstract `Accessibility`,
abstract `Attributes`, `TryGetAttribute<'T>`, `HasAttribute<'T>`, `ObsoleteDiagnosticInfo`.

- `FSharpEntity.AsType` → FSharpType; `UnionCases`; `MembersFunctionsAndValues`;
  `NestedEntities`; `FSharpFields`; `AbbreviatedType`; `GenericParameters`;
  `AllInterfaces`/`DeclaredInterfaces`; `BaseType`; `FSharpDelegateSignature`;
  `IsFSharpRecord`/`IsFSharpUnion`/`IsValueType`/`IsEnum`/`IsDelegate`/`IsInterface`/
  `IsFSharpModule`/`IsNamespace`/`IsMeasure`/`IsFSharpAbbreviation`, and more.
- `FSharpMemberOrFunctionOrValue`: `FullType`, `CurriedParameterGroups`, `ReturnParameter`,
  `GenericParameters`, `DeclaringEntity`/`ApparentEnclosingEntity`/`ApparentEnclosingType`,
  `IsMember`/`IsMethod`/`IsProperty`/`IsFunction`/`IsValue`/`IsConstructor`/`IsActivePattern`/
  `IsExtensionMember`/`IsEvent`/`IsDispatchSlot`, `InlineAnnotation`, `GetOverloads`,
  `GetterMethod`/`SetterMethod`, `IsPropertyGetterMethod`/`IsPropertySetterMethod`,
  `FormatRichText`, `GetValSignatureText`, `GetWitnessPassingInfo`, `FullTypeSafe`.
- `FSharpType`: `Format`/`FormatWithConstraints`/`FormatRichText`, `GenericArguments`,
  `IsTupleType`/`IsFunctionType`/`IsArrayType`/`IsMeasureType`/`IsGenericParameter`,
  `TypeDefinition`, `StripAbbreviations`, `Instantiate`, `ErasedType`, static `Prettify`
  (overloads for single/list/parameter/curried-parameters).
- `FSharpAssemblySignature.FindEntityByPath : string list -> FSharpEntity option`.

**Internal helpers / active patterns / extension members**
- `SymbolEnv` and the `internal new` / `internal` members (e.g. `FSharpSymbol.Create`,
  `FSharpSymbol.SymbolEnv`, `FSharpSymbol.Item`) are the internal bridge from `Item` to the
  public surface. This .fsi is the *contract*; the .fs holds the `Impl` module and all the
  `match on item` dispatch.
- `FSharpType.Prettify` statics and `internal Type: TType` accessor.

**Significant internal logic**
- `IsEffectivelySameAs` + `GetEffectivelySameAsHash` implement the "same symbol in F# source"
  equivalence (sees through signature/implementation and maps constructors to their type) — the
  relation used by `GetUsesOfSymbol`.
- `FSharpAccessibility` wraps internal `Accessibility` + a `?isProtected: bool`.
- `FSharpDisplayContext` captures `(TcGlobals -> DisplayEnv)` so formatting is location-sensitive.
- Constraint classes (`FSharpGenericParameterConstraint` + the three sub-constraint classes)
  expose the full `TyparConstraint` structure used for display & signature generation.

**Cross-references**
- `Exprs.fsi`/`Exprs.fs` — the `FSharpExpr` tree and `FSharpAssemblyContents` consume these symbols.
- `SymbolPatterns.fs` — active patterns over `FSharpSymbol` and derivatives (e.g. `FSharpEntity`, `Record`).
- `FSharpDiagnostic.fsi` — diagnostics embed many of these symbols via ExtendedData members.
- `XmlDocSigParser.fs` / `XmlDocInheritance.fs` — backing `XmlDoc`/`XmlDocSig` members.
- `SymbolHelpers.fs` — internal helpers for quick-info/attribute/XmlDoc resolution over `Item`.

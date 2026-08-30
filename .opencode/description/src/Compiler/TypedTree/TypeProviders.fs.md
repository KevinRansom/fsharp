# TypeProviders.fs

> Pipeline role: Compiler-side type provider implementation — the "#! weapon" for F# 3.0+ type providers. Loads design-time provider components, instantiates them via reflection (`TypeProviderConfig`), wraps every `System.Reflection` object a provider hands back in `Tainted<_>` + `ProvidedTypeContext` (the "Type → ILTypeRef/TyconRef" interpretation for `<Generate>`d types), validates/resolves/link types across the provider/IL boundary, and validates provided attributes & member invoker expressions. `#if !NO_TYPEPROVIDERS`-compiled.
> Namespace: `FSharp.Compiler` — `module internal rec FSharp.Compiler.TypeProviders` (line 5).

---

## Module: `type` `FSharp.Compiler.TypeProviders.NullableArray` (internal, declared at line 26)

Reflection-friendly nullable array helper (builder for `'T[] | null` used by reflection-wrap property accessors).

---

## Exceptions & designations

- `type TypeProviderDesignation = TypeProviderDesignation of string` (24) — how the type provider is designated in a `[<TypeProvider>]` attribute.
- `exception ProvidedTypeResolution of range * exn` (32) / `exception ProvidedTypeResolutionNoRange of exn` (34) — "Raised when a type provider has thrown an exception"; the `PApply`-family converts these into `TypeProviderError`s that surface as compiler diagnostics.
- Helper combos: `type ProviderGeneratedType = ProviderGeneratedType of ilOrigTyRef * ilRenamedTyRef * ProviderGeneratedType list` (i.e. `<Generate>`d types and their nested generated types) and `ProvidedAssemblyStaticLinkingMap` for the "static linking" feature.

---

## Entry points

- `toolingCompatiblePaths: unit -> string list` — the `Editor`/`Design`/`.` relative paths searched for the design-time component when `designTimeName` is relative (used when the runtime assembly has no explicit design-time component).
- `CreateTypeProvider (typeProviderImplementationType, runtimeAssemblyPath, resolutionEnvironment, isInvalidationSupported, isInteractive, systemRuntimeContainsType, systemRuntimeAssemblyVersion, m)` (104) — finds a `TypeProviderConfig` (single-arg) or parameterless constructor; constructs `TypeProviderConfig(systemRuntimeContainsType, ReferencedAssemblies = ..., ResolutionFolder = ..., RuntimeAssembly = ..., TemporaryFolder = ..., IsInvalidationSupported = ..., IsHostedExecution= isInteractive, SystemRuntimeAssemblyVersion = ...)`; `protect` re-raises activation exceptions as `TypeProviderError(etTypeProviderConstructorException...)`; falls back to `Activator.CreateInstance` for the parameterless ctor; otherwise `TypeProviderError(etProviderDoesNotHaveValidConstructor())`.
- `GetTypeProvidersOfAssembly (runtimeAssemblyFilename, ilScopeRefOfRuntimeAssembly, designTimeName, resolutionEnvironment, isInvalidationSupported, isInteractive, systemRuntimeContainsType, systemRuntimeAssemblyVersion, compilerToolPaths, m)` (149) — the main discovery: validates the design-time assembly name; **ignores providers pointing at the very file being compiled** (compat check comparing `designTimeAssemblyName.Name` to `Path.GetFileNameWithoutExtension outputFile`, lines 175–180); otherwise `GetTypeProviderImplementationTypes` scans `[<TypeProvider>]` attribute + `TypeProvider.resolve` and yields `(resolver, ilScopeRef)`, and wraps into `Tainted<_>.CreateAll`, returning `Tainted<ITypeProvider> list`. `TypeProviderError`s are iterated into `errorR` diagnostics with their categorized numbers.
- `GetDiscoveredTypeProviders` (module provider listing used by tooling) — enumerates type providers of an assembly for the `showExtensionResolution` diagnostics.

---

## Reflective access helpers — `unmarshal` and friends (line 204)

- `unmarshal (t) = t.PUntaintNoFailure id` — raw object from a `Tainted<_>`.
- `TryTypeMember`, `TryTypeMemberArray`, `TryTypeMemberNonNull`, and each `Try{Munge}` helper — run a `PApply(f, m)` inside a try, catching `TypeProviderError` and producing `errorR`/`error` diagnostics (`etUnexpectedExceptionFromProvidedTypeMember`), recovery values, and array-empty fallbacks.
- Active patterns `(|Member|_|)` (514) / `(|Arg|_|)` (517) over `CustomAttributeNamedArgument`/`CustomAttributeTypedArgument` for reading provider attributes without reflection exceptions.

---

## Provided* reflection wrap-types

Each is declared `[<Sealed>]`, wraps a `System.Reflection` object plus a `ProvidedTypeContext`, and taints all `System.Type`-yielding members (so a provided `Type`'s members cannot escape the context). Static `Create`/`CreateNonNull`/`CreateArray`/`CreateNoContext`, plus `TaintedEquals`/`TaintedGetHashCode` (based on handle identity), `ApplyContext`. Key members exercised by the checker:

- `ProvidedMemberInfo` — base: `Name`, `MemberType`, `DeclaringType` (`ProvidedType` tainted), `Module`.
- `ProvidedType` (with `ProvidedTypeComparer` singleton at 280) — `IsSuppressRelocate`/`IsErased`, `IsGenericType`, `Namespace`, `FullName`, `IsArray`, `GetInterfaces`, `Assembly`, `BaseType`, `GetNestedType(s)`/`GetAllNestedTypes`, generic arg/def accessors, `TryGetILTypeRef`/`TryGetTyconRef` (via context), `RenderTypeAbbreviations`? and `getSqlType`-style F# provision.
- `ProvidedMethodInfo` / `ProvidedMethodBase` / `ProvidedConstructorInfo` — `GetParameters`, `GetGenericArguments`, `IsStatic`/`IsDefined`...
- `ProvidedFieldInfo`, `ProvidedPropertyInfo` (arities/accessors), `ProvidedEventInfo` (`AddHandler`/`RemoveHandler`), `ProvidedParameterInfo`, `ProvidedAssembly`.
- `IProvidedCustomAttributeProvider` + `ProvidedCustomAttributeProvider` wrapping `ITypeProvider -> seq<CustomAttributeData>`.
- `ProvidedExpr` / `ProvidedExprType` / `ProvidedVar` — wrap the F# quotations tree (`Expr<ProvidedExpr>`), context snapped through `QuotationTranslator`/`ILProxy`; used to absorb the provider's `MethodInfo` bodies.
- `ProvidedTypeContext` — `static Empty`, `static Create`, `GetDictionaries`, `RemapTyconRefs: (obj -> obj) -> ProvidedTypeContext`, `TryGetILTypeRef`/`TryGetTyconRef`; carries the dictionary of `<Generate>`d type names → `ILTypeRef`/`TyconRef`s.

---

## Type provider validation & linking

The big public surface (each `Tainted<_>`-based, range-parameterised):

- `ValidateAttributesOfProvidedType`, `ValidateExpectedName`, `ValidateProvidedTypeAfterStaticInstantiation`.
- `ResolveProvidedType`/`TryResolveProvidedType`, `ILPathToProvidedType`, `TryApplyProvidedMethod`, `TryApplyProvidedType`, `TryLinkProvidedType`.
- `GetProvidedNamespaceAsPath` (via `tryNamespace`, line 1209), `GetFSharpPathToProvidedType` (via `encContrib`, 1256, and `declaringTypes`, 1060, and `walkUpNestedClasses`, 1410), `GetOriginalILAssemblyRefOfProvidedType`/`GetOriginalILTypeRefOfProvidedType`/`GetILTypeRefOfProvidedType`, `IsGeneratedTypeDirectReference`.
- `DisplayNameOfTypeProvider`.
- `GetInvokerExpression` — the static-inlining hoisting of provided method bodies into the generated assembly.
- `ValidateMatchingProvidedType`? / pruning of erased types used by `SyntheticMaps`.

---

## Related

- Builds on: `tainted.fs` (`Tainted<_>`, `PApply`/`PUntaint`), `TypedTree.fs` (`TyconRef`, `EntityRef`, `ILTypeRef`), `TcGlobals`, `FSharp.Core.CompilerServices` (`ITypeProvider`, `TypeProviderConfig`, `TypeProviderError`).
- Used by: `TcImports`/`TcGlobals` loading, `AssemblyInfo.fs` (assembly providers), `FSharp.Compiler.TypeProviders` extension writers, `IlxGen` (consumes `ProvidedAssemblyStaticLinkingMap`).
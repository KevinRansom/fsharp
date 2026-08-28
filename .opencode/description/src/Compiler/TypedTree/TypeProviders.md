# TypeProviders.fs

**Purpose**: The compiler-side type provider implementation. Compiles only under `#if !NO_TYPEPROVIDERS`. Implements the "F# type provider" infrastructure: loads and instantiates design-time (`[<TypeProvider>]`) components from a design-time assembly (`GetTypeProviderImplementationTypes`/`CreateTypeProvider`/`GetTypeProvidersOfAssembly`), wraps every reflection object the provider returns in `Provided*` types (`ProvidedType`, `ProvidedMethodBase`, `ProvidedMethodInfo`, `ProvidedParameterInfo`, `ProvidedFieldInfo`, `ProvidedPropertyInfo`, `ProvidedEventInfo`, `ProvidedConstructorInfo`, `ProvidedExpr`, `ProvidedVar`, `ProvidedAssembly`, `ProvidedMemberInfo`, plus `ProvidedTypeContext` for the `System.Type -> ILTypeRef/Tycon` remap for `<Generate>`d types), validates provided types (`ValidateAttributesOfProvidedType`, `ValidateExpectedName`, `ValidateProvidedType{AfterStaticInstantiation,Definition}`), and links them into the compilation (`ResolveProvidedType`, `TryLinkProvidedType`, `TryApplyProvidedType/Method`). All provider calls are guarded by `Tainted<'T>` (see `tainted.fs`) so failures are attributed to the provider.

**Namespace(s)**: `FSharp.Compiler` (module `internal rec FSharp.Compiler.TypeProviders`).

**Declared types**:
- `TypeProviderDesignation = TypeProviderDesignation of string` — a newtype for a provider's name.
- `exception ProvidedTypeResolution of range * exn` / `exception ProvidedTypeResolutionNoRange of exn` — raised on provider failure.
- `ResolutionEnvironment` (record) — `ResolutionFolder`, `OutputFile: string option`, `ShowResolutionMessages: bool`, `GetReferencedAssemblies: unit -> string[]`, `TemporaryFolder: string` — the configuration passed to provider components.
- `ProvidedTypeContext` (`[<Sealed>]`) — the "Type → ILTypeRef" and "Type → TyconRef" remapping context for `<Generate>`d (non-erased) types; `TryGetILTypeRef`, `TryGetTyconRef`, `static Empty`, `static Create(dict1, dict2)`, `GetDictionaries`, `RemapTyconRefs: (obj -> obj) -> ProvidedTypeContext`.
- `ProvidedType` (`[<Sealed; Class>]`, `inherit ProvidedMemberInfo`) — wraps a `System.Type`; exposes the F#-relevant surface: `IsSuppressRelocate`, `IsErased`, `IsGenericType`, `Namespace`, `FullName`, `IsArray`, `Get{Interfaces,NestedType(s),AllNestedTypes}`, `Assembly`, `BaseType`, methods/properties/fields/enums/etc.
- `IProvidedCustomAttributeProvider` — interface for custom-attribute providers.
- `ProvidedCustomAttributeProvider` — wraps `(ITypeProvider -> seq<CustomAttributeData>)`.
- `ProvidedMemberInfo` — wraps a `MemberInfo` with the provider context.
- `ProvidedParameterInfo`, `ProvidedAssembly` (wraps `Assembly`), `ProvidedMethodBase` (wraps `MethodBase`; `GetProvidedParameters`, `Invoke`, etc.), `ProvidedFieldInfo`, `ProvidedMethodInfo`, `ProvidedPropertyInfo`, `ProvidedEventInfo`, `ProvidedConstructorInfo`.
- `ProvidedExprType` (`[<Sealed>]`) — wraps `FSharp.Quotations.Expr` with the provider context.
- `ProvidedExpr` (`[<Sealed; Class>]`, `inherit ProvidedMemberInfo`) — wraps a quotation; `Provider`, `Expr`, `Get{Arguments,Body,Head}`, etc.
- `ProvidedVar` — wraps a free `Var` in a quotation.
- `ProviderGeneratedType = ProviderGeneratedType of ilOrigTyRef * ilRenamedTyRef * ProviderGeneratedType list` — the nested list of generated (non-erased) types to be emitted.
- `ProvidedAssemblyStaticLinkingMap` — the mapping from provided types to their static-linking info for the `<Generate>`d assembly.

**Public/used API surface**:
- `toolingCompatiblePaths: unit -> string list` — relative paths searched for design-time components.
- `GetTypeProviderImplementationTypes (runtimeAsm, designTimeName, m, toolPaths)` — load the design-time assembly and find `[<TypeProvider>]`-marked types.
- `CreateTypeProvider (implType, runtimeAsmPath, resolutionEnvironment, isInvalidationSupported, isInteractive, ...)` — reflection-invoke the provider constructor with a `ResolutionEnvironment`-based `TypeProviderContext` (and, for invalidation, `ITypeProviderContext` plumbing).
- `GetTypeProvidersOfAssembly (runtimeAsm, ilScopeRef, designTimeName, resolutionEnvironment, isInvalidationSupported, isInteractive, systemRuntimeContainsType, systemRuntimeAssemblyVersion, toolPaths, m)` — end-to-end "give me the `Tainted<ITypeProvider>` for this assembly"; raises `TypeProviderError` on failure.
- `DisplayNameOfTypeProvider: Tainted<ITypeProvider> * range -> string`.
- `unmarshal: Tainted<_> -> _` (internal: `PUntaintNoFailure id`).
- `TryTypeMember` / `TryTypeMemberArray` / `TryTypeMemberNonNull` / `TryMemberMember` — safe reflective member access (attribute provider failures to the provider).
- `ValidateNamespaceName`, `bindingFlags` (a `BindingFlags` value for member lookup), `ProvidedTypeComparer` (identity comparer), `CheckAndComputeProvidedNameProperty`, `ValidateAttributesOfProvidedType`, `ValidateExpectedName`, `ValidateProvidedTypeAfterStaticInstantiation`, `ValidateProvidedTypeDefinition`, `ResolveProvidedType`, `TryResolveProvidedType`, `ILPathToProvidedType`, `ComputeMangledNameForApplyStaticParameters`, `TryApplyProvided{Method,Type}`, `TryLinkProvidedType`, `GetPartsOfNamespaceRecover`, `GetProvidedNamespaceAsPath`, `GetFSharpPathToProvidedType`, `GetOriginalIL{Assembly,Type}RefOfProvidedType`, `GetILTypeRefOfProvidedType`, `IsGeneratedTypeDirectReference`, `GetInvokerExpression`.

**Significant internal logic**: Every value flowing from the provider is wrapped in `Tainted<_>`; reflective access goes through `Try*Member*` helpers under the provider `Lock`, with `recover` defaults so a missing member doesn't crash. `ProvidedTypeContext` is the *only* place the compiler tracks the `System.Type -> ILTypeRef/TyconRef` mapping for `<Generate>`d types (used by `IsGeneratedTypeDirectReference` and the static-linking pass). `TryLinkProvidedType` is where erasure vs. `<Generate>` is decided and `ProviderGeneratedType`/`ProvidedAssemblyStaticLinkingMap` get populated for the ILXGen phase.

**Cross-references**: `TypeProviders.fsi` (contract), `tainted.fs`/`tainted.fsi` (guarding), `TypedTree.fs`/`TypedTreeBasics.fs` (produces `TyconRef`/`EntityRef`/`ILTypeRef`), `TcGlobals.fs` (`AttribInfo`s), `AssemblyInfo.fs` (consumer of `GetTypeProvidersOfAssembly`), `ILXGen` (consumes `ProvidedAssemblyStaticLinkingMap`), `FSharp.Core.CompilerServices` (`ITypeProvider`, `TypeProviderContext`), `FSharp.Quotations` (`Expr`, `Var`).

# TypeProviders.fsi

**Purpose**: Contract for the compiler-side type provider implementation ("Extension typing, validation of extension types, etc."). Declares the `Provided*` wrap-types over the `System.Reflection` objects a design-time type provider returns (`ProvidedType`, `ProvidedMethodBase`, `ProvidedMethodInfo`, `ProvidedParameterInfo`, `ProvidedFieldInfo`, `ProvidedPropertyInfo`, `ProvidedEventInfo`, `ProvidedConstructorInfo`, `ProvidedAssembly`, `ProvidedMemberInfo`, `ProvidedExpr(Ty)pe`, `ProvidedVar`), the `ProvidedTypeContext` (the `System.Type -> ILTypeRef/TyconRef` remap for `<Generate>`d types), `ResolutionEnvironment`, `TypeProviderDesignation`, the `ProvidedTypeResolution(NoRange)` exceptions, and the end-to-end entry point `GetTypeProvidersOfAssembly`. Compiled only `#if !NO_TYPEPROVIDERS`.

**Namespace(s)**: `FSharp.Compiler` — `module internal rec FSharp.Compiler.TypeProviders`.

**Declared types (signatures)**:
- `type TypeProviderDesignation = TypeProviderDesignation of string`.
- `exception ProvidedTypeResolution of range * exn` / `exception ProvidedTypeResolutionNoRange of exn` — "Raised when a type provider has thrown an exception."
- `type ResolutionEnvironment` — `ResolutionFolder: string`, `OutputFile: string option`, `ShowResolutionMessages: bool` (whether `--showextensionresolution` was supplied), `GetReferencedAssemblies: unit -> string[]`, `TemporaryFolder: string`.
- `[<Sealed>] type ProvidedTypeContext` — "context used to interpret information in the closure of `System.Type`, `System.MethodInfo` ... coming from the type provider"; the "Type → ILTypeRef" and "Type → Tycon" remap (empty for erased types); `TryGetILTypeRef`, `TryGetTyconRef`, `static Empty`, `static Create`, `GetDictionaries`, `RemapTyconRefs: (obj -> obj) -> ProvidedTypeContext` (the `'obj` is a `TyconRef`, boxed due to a forward reference).
- `[<Sealed; Class>] type ProvidedType` — `inherit ProvidedMemberInfo`; `IsSuppressRelocate/IsErased/IsGenericType/Namespace/FullName/IsArray/GetInterfaces/Assembly/BaseType/GetNestedType(s)/GetAllNestedTypes/...`.
- `[<Sealed>] type IProvidedCustomAttributeProvider`, and `ProvidedCustomAttributeProvider` (wraps `ITypeProvider -> seq<CustomAttributeData>`).
- `[<Sealed; Class>] type Provided{MemberInfo,Type,MethodBase,MethodInfo,ParameterInfo,FieldInfo,PropertyInfo,EventInfo,ConstructorInfo,Assembly,Expr,Var}` — the reflection wrap-types, each exposing the F#-relevant `System.Reflection` surface (via `Tainted<_>`/`ProvidedTypeContext`).
- `ProviderGeneratedType = ProviderGeneratedType of ilOrigTyRef * ilRenamedTyRef * ProviderGeneratedType list` and `ProvidedAssemblyStaticLinkingMap` — the `<Generate>`d-type bookkeeping.

**Public API surface** (module level):
- `val toolingCompatiblePaths: unit -> string list` — relative paths searched for design-time components.
- `val GetTypeProvidersOfAssembly: runtimeAssemblyFilename * ilScopeRefOfRuntimeAssembly * designTimeName * ResolutionEnvironment * isInvalidationSupported * isInteractive * systemRuntimeContainsType * systemRuntimeAssemblyVersion * compilerToolPaths * range -> Tainted<ITypeProvider> list` — "Find and instantiate the set of ITypeProvider components for the given assembly reference."
- `val DisplayNameOfTypeProvider: Tainted<ITypeProvider> * range -> string` — "supply a human-readable name suitable for error messages."
- And the provider-validation/linking functions (each takes a `Tainted<_>` and a `range` and returns a `Tainted<_>` or `Tainted<_> option`): `ValidateAttributesOfProvidedType`, `ValidateExpectedName`, `ValidateProvidedTypeAfterStaticInstantiation`, `ResolveProvidedType`, `TryResolveProvidedType`, `ILPathToProvidedType`, `TryApplyProvided{Method,Type}`, `TryLinkProvidedType`, `GetProvidedNamespaceAsPath`, `GetFSharpPathToProvidedType`, `GetOriginalIL{Assembly,Type}RefOfProvidedType`, `GetILTypeRefOfProvidedType`, `IsGeneratedTypeDirectReference`, `GetInvokerExpression`.

**Notes**: The `.fs` also contains `unmarshal`, the `Try*Member*` reflective-access helpers, and the `NullableArray` module, which are implementation-only.

**Cross-references**: `TypeProviders.fs` (implementation), `tainted.fs` (guarding), `TypedTree.fs` (`TyconRef`/`EntityRef`/`ILTypeRef`), `TcGlobals.fs`, `AssemblyInfo.fs` (consumer), `ILXGen` (consumes the static-linking map), `FSharp.Core.CompilerServices`/`FSharp.Quotations`.

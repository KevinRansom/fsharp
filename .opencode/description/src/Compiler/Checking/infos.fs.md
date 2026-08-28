# infos.fs

**Purpose**: Defines the compiler-internal "Info" representations — the rich data the Checking phase builds to describe types, methods, properties, fields, union cases, events, and their parameters/attributes, by layering `MethInfo`/`PropInfo`/`ILFieldInfo`/`RecdFieldInfo`/`UnionCaseInfo`/`EventInfo` over raw AbstractIL metadata (`ILMethInfo`/`ILTypeInfo`/etc.) and F# typed declarations. It is the central data model shared by constraint solving, info reading, name resolution, and attribute checking.

**Namespace(s)**: `module internal FSharp.Compiler.Infos`

**Parameter / argument info types** (infos.fs around lines 162-350):
- `ValRef with` extension members: `IsFSharpEventProperty`, `IsVirtualMember`, `IsDispatchSlotMember`, `IsDefiniteFSharpOverrideMember`, `IsFSharpExplicitInterfaceImplementation`, `ImplementedSlotSignatures`, plus `SplitMemberSigIntoParamListAndRetTy`-style helpers for member signatures (lines ~31-160).
- `ExtensionMethodPriority = uint64` (line 162) — "later-introduced extension methods via `open` get priority in overload resolution".
- `OptionalArgCallerSideValue` (line 168) — `Constant of ILFieldInit` | `DefaultValue` | `MissingValue` | `WrapperForIDispatch` | `WrapperForIUnknown` | `PassByRef of TType * OptionalArgCallerSideValue`.
- `OptionalArgInfo` (line 177) — `NotOptional` | `CalleeSide` | `CallerSide of OptionalArgCallerSideValue`; static members `FieldInitForDefaultParameterValueAttrib`, `FromILParameter` (includes the VB rules for `IDispatchConstant`/`IUnknownConstant`), `ValueOfDefaultParameterValueAttrib`; `member IsOptional`.
- `CallerInfo` (line 234) — `NoCallerInfo` | `CallerLineNumber` | `CallerMemberName` | `CallerFilePath`.
- `ReflectedArgInfo` (line 243) — `None` | `Quote of bool` with `AutoQuote`.
- `ParamNameAndType` (line 253) and `ParamData` (line 263) — full parameter info for the type-checker / language service (paramarray, in/out, optional arg info, caller info, reflected-arg info, name, type).
- `ParamAttribs` (line 274) — the "adhoc" variant unifying the same fields except name/type; `CrackParamAttribsInfo : TcGlobals -> TType * ArgReprInfo -> ParamAttribs`.
- `ILFieldInit with` extension (line 344) — helpers over the field-init values used for default parameters (incl. `FromProvidedObj`).

**IL metadata wrapper types**:
- `ILTypeInfo` (line 420) — `ILTypeInfo of TcGlobals * TType * ILTypeRef * ILTypeDef`; static `FromType`; members: `Instantiate`, `ILScopeRef`, `ILTypeRef`, `IsValueType`, `Name`, `RawMetadata`, `TcGlobals`, `ToAppType` (the compiled nominal type — e.g. .NET tuple for F# tuple), `ToType`, `TyconRefOfRawMetadata`, `TypeInstOfRawMetadata`.
- `ILMethParentTypeInfo` (line 476) — `IlType of ILTypeInfo` | `CSharpStyleExtension of declaring: TyconRef * apparent: TType`; `ToType`.
- `ILMethInfo` (line 487) — `ILMethInfo of g * ilType: ILMethParentTypeInfo * ilMethodDef: ILMethodDef * ilGenericMethodTyArgs: Typars`; ~40 read-only properties over the IL method definition (`ApparentEnclosingAppType`, `ApparentEnclosingType`, `DeclaringTyconRef`, `DeclaringTypeInst`, `FormalMethodTypars`, `IsAbstract`, `IsClassConstructor`, `IsConstructor`, `IsFinal`, `IsILExtensionMethod`, `IsInstance`, `IsNewSlot`, `IsProtectedAccessibility`, `IsStatic`, `IsVirtual`, `MetadataScope`, parameter counts, etc.).

**F# "info" types** (the F#-flavored layer):
- `MethInfo` (line 664) — the unified F# method info, either an `ILMethInfo`, an F#-member `ValRef`-based, or a provided-method; provides the full F# view: formal method typars, parameter lists, return type, object type, accessibility, extension-method info, optional args, etc. (a very large type, ~900 lines of members).
- `ILFieldInfo` (line 1551) — `ILFieldInfo of ILTypeInfo * ILFieldDef`, with `ApparentEnclosingType`, `IsStatic`, `IsConst`, `IsLiteral`, `TyconRef`, `TcGlobals`, etc.
- `RecdFieldInfo` (line 1691) — `RecdFieldInfo of Field of ILFieldInfo` | `RecdField of RecdFieldRef * RecdField` — the union of .NET and F# record/class field views.
- `UnionCaseInfo` (line 1732) — `UnionCaseInfo of F#UnionCase of UnionCaseRef * UnionCase` | `ProvidedUnionCase ...` or `IL`-side, presenting the F# union-case view.
- `ILPropInfo` (line 1774) — `ILPropInfo of ILTypeInfo * ILPropertyDef`; `IsIndexer` and friends.
- `PropInfo` (line 1874) — the unified property view (`.NET` | F# `ValRef` getter/setter pair | provided), spanning ~400 lines of members (e.g. getter/setter `ValRef`s, event property detection, indexer flag).
- `ILEventInfo` (line 2292) — `ILEventInfo of ILTypeInfo * ILEventDef`.
- `EventInfo` (line 2374) — the unified event view over the IL/provided/CLI-event-property forms.
- `CompiledSig = CompiledSig of argTys: TType list list * returnTy: TType option * formalMethTypars: Typars * formalMethTyparInst: TyparInstantiation` (line 2573).

**Module-level functions / vals**:
- `nonStandardEventError : string -> range -> exn` (line ~1058 in .fsi) — raised for malformed CLI event patterns.
- `FindDelegateTypeOfPropertyEvent` — find the delegate type of a property-style event.
- `stripByrefTy : TcGlobals -> TType -> TType`.
- `CompiledSigOfMeth : g -> amap -> m -> MethInfo -> CompiledSig` (line ~1079) — canonical parameter/return signature.
- Equivalence checks: `MethInfosEquivByPartialSig`, `MethInfosEquivByNameAndPartialSig`, `PropInfosEquivByNameAndPartialSig`, `MethInfosEquivByNameAndSig`, `PropInfosEquivByNameAndSig` (lines ~1082-1120) — used by InfoReader override/hide rules and by method-override checking.
- `SettersOfPropInfos` / `GettersOfPropInfos : PropInfo list -> (MethInfo * PropInfo option) list` (lines ~1123-1125).
- Active pattern `(|DifferentGetterAndSetter|_|) : PropInfo -> (ValRef * ValRef) voption` (line ~1128) — detect a property whose getter and setter differ.

**Significant internal logic**:
- The two-layer design (raw `IL*Info` → F#-flavored `MethInfo`/`PropInfo`/`RecdFieldInfo`/`UnionCaseInfo`/`EventInfo`) lets one set of F# APIs work uniformly over .NET metadata, F# declared members, and type-provider provided members.
- `OptionalArgInfo.FromILParameter` (line ~197) implements the subtle rules: VB `IDispatchConstant`/`IUnknownConstant`, .NET optional args, F# callee-side optionals, and `paramarray`, including reading `DefaultParameterValue` attributes into `ILFieldInit`.
- Extension-method recognition flows through `ILMethParentTypeInfo.CSharpStyleExtension` and the `IsExtensionMember`/`ILExtensionMethod*` tests, so `MethInfo.ApparentEnclosingType` differs from `DeclaringTyconRef` for C#-style extension methods.

**Cross-references**: `infos.fsi` (contract), `import.fs` (source of the `IL*` metadata), `infoReader.fs` (reads/caches these infos per type), `attributeChecking.fs` (attribute views are part of these infos), `constraintSolver.fs` (constraint solving over `MethInfo`/`TraitConstraintInfo`), `methodOverrides.fs` (override checking using `MethInfosEquivByNameAndSig` etc.), `signatureHash.fs` (uses `CompiledSig`).

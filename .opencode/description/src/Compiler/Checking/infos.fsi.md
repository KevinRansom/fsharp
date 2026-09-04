# infos.fsi

**Purpose**: Public contract for the "Info" data model of the F# compiler: the rich representations (`MethInfo`, `PropInfo`, `RecdFieldInfo`, `UnionCaseInfo`, `EventInfo`, `IL*Info`) that the Checking phase builds to describe .NET metadata, F# declared members, and type-provider provided members behind one uniform API. This is the reference surface for InfoReader, ConstraintSolver, AttributeChecking, MethodOverrides, and SignatureHash.

**Namespace(s)**: `module internal FSharp.Compiler.Infos`

**Extension of TAST (lines 19-36)**:
- `type ValRef with` extension members: `IsFSharpEventProperty : TcGlobals -> bool`, `IsVirtualMember : bool`, `IsDispatchSlotMember : bool`, `IsDefiniteFSharpOverrideMember : bool`, `IsFSharpExplicitInterfaceImplementation : TcGlobals -> bool`, `ImplementedSlotSignatures : SlotSig list`.

**Top-level functions (non-type)**:
- (Type-provider only) `GetCompiledReturnTyOfProvidedMethodInfo : amap -> m -> Tainted<ProvidedMethodBase> -> TType option`.
- `ReparentSlotSigToUseMethodTypars : g -> ovByMethValRef: ValRef -> slotsig: SlotSig -> SlotSig` — reverse-map a slot signature to terms of the overriding method's typars.
- `MakeSlotParam : TType * ArgReprInfo -> SlotParam`; `MakeSlotSig : ... -> SlotSig` — build slot signatures.

**Parameter / argument info types** (lines 57-149):
- `ExtensionMethodPriority = uint64` (line 57) — later-introduced extension methods get priority in overload resolution.
- `OptionalArgCallerSideValue` (60) — `Constant of ILFieldInit` | `DefaultValue` | `MissingValue` | `WrapperForIDispatch` | `WrapperForIUnknown` | `PassByRef of TType * OptionalArgCallerSideValue`.
- `OptionalArgInfo` (69) — `NotOptional` | `CalleeSide` | `CallerSide of OptionalArgCallerSideValue`; `static member FieldInitForDefaultParameterValueAttrib : Attrib -> ILFieldInit option`, `FromILParameter : ... -> OptionalArgInfo` (including VB `IDispatchConstant`/`IUnknownConstant` rules), `ValueOfDefaultParameterValueAttrib : Attrib -> Expr option`, `member IsOptional : bool`.
- `CallerInfo` (99) — `NoCallerInfo` | `CallerLineNumber` | `CallerMemberName` | `CallerFilePath`.
- `ReflectedArgInfo` (106, `<RequireQualifiedAccess>`) — `None` | `Quote of bool`, `member AutoQuote`.
- `ParamNameAndType` (114) — for use by the language service; members `FromArgInfo`, `FromMember`, `Instantiate`, `InstantiateCurried`.
- `ParamData` (128) — full parameter info for the type-checker: `isParamArray * isInArg * isOut * optArgInfo * callerInfo * nameOpt * reflArgInfo * ttype`.
- `ParamAttribs` (140) — adhoc variant of `ParamData` minus name/type.
- `CrackParamAttribsInfo : TcGlobals -> TType * ArgReprInfo -> ParamAttribs` (149).

**IL metadata wrappers** (153-190):
- `ILTypeInfo` (153) — `ILTypeInfo of TcGlobals * TType * ILTypeRef * ILTypeDef`; `static member FromType`, `Instantiate`, `ILScopeRef`, `ILTypeRef`, `IsValueType`, `Name`, `RawMetadata`, `TcGlobals`, `ToAppType`, `ToType`, `TyconRefOfRawMetadata`, `TypeInstOfRawMetadata`.
- `ILMethParentTypeInfo` (182) — `IlType of ILTypeInfo` | `CSharpStyleExtension of declaring: TyconRef * apparent: TType`; `ToType`.
- `ILMethInfo` (190) — `ILMethInfo of g * ilType * ilMethodDef * ilGenericMethodTyArgs`; ~40 accessors for the IL method (see .fsi lines 190-304).

**F#-flavored info types** (305-1057):
- `MethInfo` (305) — the unified F# method view (see .fsi 305-567 for the full member surface).
- `ILFieldInfo` (567), `RecdFieldInfo` (636), `UnionCaseInfo` (678), `ILPropInfo` (718), `PropInfo` (782), `ILEventInfo` (933), `EventInfo` (970) — each unifies the raw IL view, F# declared view, and (for the applicable ones) provided view, with a large member surface per type.

**Functions and helpers on the info types** (1058-1128):
- `nonStandardEventError : string -> range -> exn`.
- `FindDelegateTypeOfPropertyEvent`.
- `stripByrefTy : TcGlobals -> TType -> TType`.
- `CompiledSig = CompiledSig of argTys * returnTy * formalMethTypars * formalMethTyparInst` (1070).
- `CompiledSigOfMeth : g -> amap -> m -> MethInfo -> CompiledSig` (1079).
- Equivalence / name-and-sig checks (1082-1120): `MethInfosEquivByPartialSig`, `MethInfosEquivByNameAndPartialSig`, `PropInfosEquivByNameAndPartialSig`, `MethInfosEquivByNameAndSig`, `PropInfosEquivByNameAndSig`.
- `SettersOfPropInfos` / `GettersOfPropInfos : PropInfo list -> (MethInfo * PropInfo option) list` (1123/1125).
- Active pattern `(|DifferentGetterAndSetter|_|) : PropInfo -> (ValRef * ValRef) voption` (1128).

**Cross-references**: `infos.fs` (implementation), `import.fsi` (provides `ILTypeRef`/`ILMethInfo` etc.), `infoReader.fsi` (consumer), `attributeChecking.fsi` (attribute views on these infos), `constraintSolver.fsi` (uses `MethInfo`, `TraitConstraintInfo`), `methodOverrides.fsi` (uses the equiv-predicate family), `signatureConformance.fsi`/`signatureHash.fsi` (signature comparison uses `CompiledSig`).

# TypedTree.fs

## Pipeline role

This file belongs to the TypedTree folder of the F# compiler and is the *implementation* side of `TypedTree.fsi`. It defines the central typed abstract syntax -- the fully *checked* intermediate representation produced by the type checker and consumed by optimization, code generation (`IlxGen`), signature emission, quotation translation and the IDE services. Its purpose is to represent the post-inference program with identity-carrying nodes (`Val`/`Entity`/`Tycon`/`UnionCase`/`RecdField` plus their `Stamp`ed `Ref` types), so later phases can do reference-based recognition. The `.fsi.md` inventories every declared type; this document details the implementation specifics: union case payloads, the member functions on nodes, and the `Construct` factory API.

## Header, module

- Copyright header (Microsoft, `License.txt`); `/// Defines the typed abstract syntax intermediate representation used throughout the F# compiler.`
- `module internal rec FSharp.Compiler.TypedTree` — the `rec` permits mutual recursion across all these interdependent types (needed already inside the module).

The file (~6572 lines) is one contiguous module, ordered roughly "small value/flag types → Entity machinery → UnionCase/RecdField → ModuleOrNamespace → Vallinkage → Ref types → TType → Attribs/Const → decision trees → Expr/TOp → slots/open/impl-files → CCUs → free vars → Construct".

## Flags and small types

- `ValFlags(flags: int64)` — `[<Flags>]` encoded bitfield for `Val` (inline status, mutability, generalization state, `IsGeneratedMember` etc.); static `OfPickledBits`.
- `ValRecursiveScopeInfo`, `TyparDynamicReq`, `ValInline`, `ValMutability`, `ValBaseOrThisInfo`.
- `TyparFlags`, `EntityFlags` (`[<Flags>]`, hides compiler flags like `IsStaticMember`, `IsMeasure`, `IsDelegate`, `IsRecord`, `IsUnion`, `IsEnum`, `IsClass`, `IsInterface`, `IsException`; `ReservedBitForPickleFormatTyconReprFlag` guards the pickle format).
- `Stamp = int64`, `StampMap<'T>`, `EntityFlags.ReservedBitForPickleFormatTyconReprFlag`.

## Entity definitions

- `PublicPath`, `SyntaxAccess`, `CompilationPath`, `Accessibility`, `Accessibility.TypedTree` path helpers (`DemangleEntityName`).
- `EntityOptionalData` / `EntityData` (`NewEmptyEntityOptData`).
- `Entity` — `[<Sealed>]`-ish record of `entity_*` fields; `NewUnlinked` creates an entity with a fresh stamp and a deliberate "unlinked" state used during incremental service checking (the `New`/`NewUnlinked` pair appears for `Entity`, `Typar` and `Val`).
- `TyconRepresentation` (`Class|Struct|Enum|Record|Union|Other`), `TILObjectReprData`, `TProvidedTypeInfo`, `FSharpTyconData`, `TyconAugmentation` (`Create()`, `GetModuleType`…), `CompiledTypeRepr` (an `ILTypeRef` "computed and cached by later phases", *not* pickled; holds an optional `ILType` for non-generic types), `ParentRef`, `EntityFlags`.
- `UnionCase` / `RecdField` / `ExceptionInfo` / `TyconUnionData` / `TyconRecdFields` — the declared `UnionCase`/`RecdField` nodes (name, `RecdFields`/`FieldType`, flags, attribs, access).
- `ModuleOrNamespaceType` — contents of a module/namespace: an ordered `QueueList` of `vals` + `tycons` (`NewModuleOrNamespaceType`), kind `ModuleOrNamespaceKind` (`Module | Namespace`). `ModuleOrNamespace = Entity`, `Tycon = Entity` (aliases).

## Typars and constraints

- `Typar` — declared generic/measure parameter *or* type-inference variable; carries `TyparData` with flags (rigidity `Static|Free|Delayed`, kind `Type|Measure`, dynamic request), `ConstraintSolutions`, a mutable `TyparSolution`-ish cell and a `TyparReprInfo` slot; `NewUnlinked` for service mode.
- `TyparConstraint` (`Type`/`Trait`, with `Static` requirement); `TraitWitnessInfo`, `TraitConstraintInfo` (+ `MemberLogicalName`, `CompiledObjectAndArgumentTypes`, `CompiledReturnType` and `TParent`/`Support`/`IsInstance` derived views), `TraitConstraintSln` (the record of a solved member constraint).

## Vals

- `ValOptionalData` / `ValData` / `Val` — central checked value node (`[<DebuggerDisplay>]`), fields incl. `ValLinkage: ValLinkageFullKey`, `Typars`, attribs, `ValMemberInfo` (`[<Sealed>]`), `ValReprInfo` in optional data, `ActualParent`, and the `ValBaseOrThisInfo`. `ValLinkagePartialKey`/`ValLinkageFullKey` power cross-CCU identity; picked from `cname+argTypes+retTy` ("partial") plus the optional linkage type.
- `NonLocalValOrMemberRef`/`ValPublicPath` and the path-dereferencing helpers `TryDerefEntityPath`, `TryDerefEntityPathViaProvidedType`.

## References (ref unregistered)

- `EntityRef` (`ERefLocal | ERefNonLocal | ERefNonLocalPreResolved`), `ValRef` (`VRefLocal | VRefNonLocal | VRefNonLocalPreResolved`), `ModuleOrNamespaceRef = EntityRef`, `TyconRef = EntityRef`, `UnionCaseRef`, `RecdFieldRef` — the "reference" layer used pervasively; local vs nonlocal so a self-contained typed tree can be built and re-linked across CCUs. See `.fsi.md` for the case payloads/accessors (`TryDeref`, `Deref`, `LogicalName`, `Stamp`…).

## Types

- `TType` — checked type with the `TTypar|TGenericParam|TArrow|TAnonymous|TAmbientUnit|TAbbrev|TApp|TEnumVal|TDelayed|TMeasure|TRawMetadata|TDelegate|TUnion…` union; the `TType_app`/`TType_tuple`/… construction helpers live in `TypedTreeBasics`/`TypedTreeOps`.
- `AnonRecdTypeInfo` (with `NewUnlinked`, `Create(ccu,tupInfo,ids)`), `TupInfo` (struct/reference tuple marker), `Measure`, `TypeInst`, `TTypes`.

## Attribs

- `WellKnownEntityAttribs`/`WellKnownValAttribs` — `WellKnownAttribs<Attrib, _>` instantiations for O(1) flag lookup.
- `Attrib` — `Attrib(tyconRef, kind, unnamedArgs, propVal, appliedToAGetterOrSetter, targetsOpt, range)`; `AttribKind`; `AttribExpr` ("We keep both source expression and evaluated expression around to help intellisense and signature printing"); `AttribNamedArg`; `Attrib targets` for use-site filtering.

## Constants and decision trees

- `Const` — checked constants (ints, floats, strings, chars, units, the `Const.Zero` etc.); the `Const` with a `TType` is what `Expr.Const` carries.
- `DecisionTree`/`DecisionTreeCase`/`DecisionTreeTest` (with `ActivePatternReturnKind` and the `DecisionTreeTest.ActivePatternCase` referencing `ActivePatternElemRef`)/`DecisionTreeTarget` (pre-bound `boundVals`, `targetExpr`, plus `debugPoint` and `isStateVarFlags` for state-machine works). "Pattern matching has been compiled down to a decision tree by this point."
- `Bindings`/`Binding` (`val`, `expr`, `debugPoint`), `ValReprInfo` (`ArgInfos` — the `ValReprInfo` has `ArgInfos`, `RetInfo`, `HasThisArg`, `Typars`-in-or-out), `ArgReprInfo`, `TyparReprInfo`.

## `Expr`

`[<NoEquality; NoComparison; RequireQualifiedAccess>]` union with the full payload spelling:

- `Const(value, range, constType)`; `Val(valRef, flags: ValUseFlag, range)` (flag relevant for object-model members: base calls/special ctor use).
- `Sequential(expr1, expr2, kind: SequentialOpKind, range)` — `"a;b"`, `"let a=… in b;c"`, `"a then b"` (OO ctor chaining).
- `Lambda(unique, ctorThisValOpt, baseValOpt, valParams, bodyExpr, range, overallType)` — multiple `vspec`s because `(fun x y -> …)` is normally tupled; kept convenient for compiling as a static method with several args.
- `TyLambda(unique, typeParams, bodyExpr, range, overallType)` — r.h.s. of polymorphic lets/first-class polymorphism.
- `App(funcExpr, formalType, typeArgs, args, range)` — normalized so `(f x y)` is a single `App` with `args=[x;y]`; `formalType` prevents over-application during instantiation.
- `LetRec(bindings, bodyExpr, range, frees: FreeVarsCache)`; `Let(binding, bodyExpr, range, frees)`.
- `Obj(unique, objTy, baseVal, ctorCall, overrides, interfaceImpls, range)` — object expression.
- `Match(debugPoint, inputRange, decision, targets: DecisionTreeTarget array, fullRange, exprType)` — "a more complicated form of 'let'" whose range is the matched-expression range (used for all decision-tree execution).
- `StaticOptimization(conditions, expr, alternativeExpr, range)` — pm'd optimized expression choice for overloaded operators.
- `Op(op: TOp, typeArgs, args, range)` — "An intrinsic applied to some (strictly evaluated) arguments"; a few ops (`TryWith`, `While`, `IntegerForLoop`) expect lambda-normalized args.
- `Quote(quotedExpr, quotationInfo, isFromQueryExpression, range, quotedType)` — the quotation node; `quotationInfo` is a *mutable* `option ref` (marked "MUTABILITY: this use of mutability is awkward and perhaps should be removed") filled in by the picker with the `(ILTypeRef list * TTypes * Exprs * ExprData)` pairs for the 20/40 formats.
- `WitnessArg(traitInfo, range)` — witness argument for quotations; the doc comment shows how `sin x` in a quotation becomes `Deserialize(<@ sin$W _spliceHole1 _spliceHole2 @>, [| WitnessArg(witnessForSin), x |])`.
- `TyChoose(typeParams, bodyExpr, range)` — free choice of typars from minimization of polymorphism at let-rec, resolved later.
- `Link of Expr ref` — placeholder for recursively-bound variables during checking of recursive bindings; replaced and eliminated after.
- `DebugPoint(DebugPointAtLeafExpr, Expr)`.
- Members: `DebugText = ToDebugString(3)` (also `override ToString`), `ToDebugString depth` (bounded pretty printer), and `Range` — the single dispatch that reads the `m` field from every payload-carrying case (and follows through `Link`/`DebugPoint`).

## `TOp`

`[<RequireQualifiedAccess>]` opcode union (tag line at a glance): `UnionCase ucref`, `ExnConstr`, `Tuple tupInfo`, `AnonRecd`/`AnonRecdGet`, `Array`, `Bytes of byte[]`/`UInt16s of uint16[]` (parser tables and embedded data), `While(spWhile, marker)`/`IntegerForLoop(spFor, spTo, style)`/`TryWith(spTry, spWith)`/`TryFinally` (lambda-encoded, carrying the debug points), `Recd(constructionInfo, tcref)` (self-referential ctor support), `ValFieldSet/Get/GetAddr`, `UnionCaseTagGet`, `UnionCaseProof` ("a coercion proving case membership to enable verifiable field access"), `UnionCaseFieldGet/GetAddr/Set`, `ExnFieldGet/Set`, `TupleFieldGet`, `ILAsm(instrs, retTypes)`, `RefAddrGet`, `Coerce`, `Reraise`, `Return`, `Goto`/`Label` (state-machine), `TraitCall TraitConstraintInfo` (pseudo method call for `op_Addition`-style overloads), `LValueOp(lValueOp, vref)`, and the big `ILCall(isVirtual, isProtected, isStruct, isCtor, valUseFlag, isProperty, noTailCall, ilMethRef, enclTypeInst, methInst, retTypes)`. Has `DebugText` and a diagnostic `ToString`.

Supporting kinds in this tail region: `RecordConstructionInfo`, `ConstrainedCallInfo` (`Some ty` = .NET 2.0 constrained call with the static type of the object argument), `ForLoopStyle`, `SpecialWhileLoopMarker`, `SequentialOpKind`, `LValueOperation`, `ValUseFlag`, `StaticOptimization` (`tyconRule|valRule|PropertyRule`), `ObjExprMethod` (`TObjExprMethod(slotsig, attribs, methTyparsOfOverridingMethod, methodParams, methodBodyExpr, m)`), `SlotSig`/`SlotParam` (`TSlotSig(methodName, declaringType, declaringTypeParameters, methodTypeParameters, slotParameters, returnTy)`), `OpenDeclaration`.

## Implementation-file / assembly nodes, CCUs

- `ModuleOrNamespaceContents`/`ModuleOrNamespaceBinding`/`CheckedImplFile` (`CheckedImplFile(qualifiedNameOfFile, pragmas, signature, contents, hasExplicitEntryPoint, isScript, anonRecdTypeInfo)`), `CheckedImplFileAfterOptimization`, `CheckedAssemblyAfterOptimization`.
- `CcuTypeForwarderTree`/`CcuTypeForwarderTable` (`Root = CcuTypeForwarderTree.Empty`; immutable-dictionary tree of `System.Type` forwarders) with `Create(target, modules, types, appliedScope, isOwnNamespace)` building the `OpenDeclaration`.`OpenPlainModule`/`OpenType` representation.
- `CcuReference = string`, `CcuThunk` (the relinkable, lazily-loaded handle to a compilation unit — either `CcuThunkLoaded` or `CcuThunkIL`; `Create`, `CreateDelayed`), `CcuResolutionResult`, `CcuData`, `PickledCcuInfo` ("the information saved in the assembly signature data resource for an F# assembly").

## Free variables

- `FreeLocals = Zset<Val>`, `FreeTypars = Zset<Typar>`, `FreeTycons = Zset<Tycon>`, `FreeRecdFields = Zset<RecdFieldRef>`, `FreeUnionCases = Zset<UnionCaseRef>`, `FreeTyvars`, and `FreeVars` (includes trait solutions etc.) — "Computed and cached by later phases (never cached type checking). Cached in expressions. Not pickled." `FreeVarsCache` is the amortized computation wrapper (`NewFreeVarsCache = newCache()`).

## `type Construct()` — the factory

`type Construct() =` (not a static class; called via `Construct.New*`). Notable members:

- **Keying**: `KeyTyconByDecodedName` (key by `NameArityPair` from `DecodeGenericTypeName`), `KeyTyconByAccessNames` (emits *both* `List` and `List`1` keys so generic types are reachable under either mangled or demangled name; comment notes the List/List`1 duality).
- **Module/namespace**: `NewModuleOrNamespaceType mkind tycons vals` (QueueList-based), `NewEmptyModuleOrNamespaceType` (avoids building the two empty QueueLists), `NewEmptyFSharpTyconData kind`, `NewModuleOrNamespace cpath access id xml attribs mtype`.
- **Provided types** (`#if !NO_TYPEPROVIDERS`): `NewProvidedTyconRepr` — builds `TProvidedTypeRepr { ResolutionEnvironment; ProvidedType; LazyBaseType (LazyWithContext, resolving `BaseType` and importing the system type); UnderlyingTypeOfEnum; IsDelegate (checks non-generic direct base `System.Delegate`/`MulticastDelegate`); IsEnum; IsStructOrEnum; IsInterface; IsSealed; IsAbstract; IsClass; IsErased; IsSuppressRelocate }`. `NewProvidedTycon` — stamps, name from provided type, `TyparKind.Measure/Type`, default `TAccess []`, default `CompPath(ilScopeRef, SyntaxAccess.Unknown, GetFSharpPathToProvidedType …)`, public path from nested cpath, `entity_attribs=WellKnownEntityAttribs.Empty` (fetched on demand), `TyconAugmentation.Create()`, and internal accessibility ("Generated types get internal accessibility").
- **Case/field/union tables**: `MakeRecdFieldsTable ucs`, `MakeUnionCases ucs`, `MakeUnionRepr ucs`.
- **Node constructors**: `NewTypar (kind, rigid, SynTypar(…), isFromError, dynamicReq, attribs, eqDep, compDep)`, `NewRigidTypar nm m`, `NewUnionCase id tys retTy attribs docOption access`, `NewExn cpath id access repr attribs doc`, `NewRecdField stat konst id nameGenerated ty isMutable isVolatile pattribs fattribs docOption access secret`, `NewTycon (cpath, nm, m, access, reprAccess, kind, typars, doc, usesPrefixDisplay, preEstablishedHasDefaultCtor, hasSelfReferentialCtor, mtyp)` (fields never know typar constraints — those live in `SynTycon`-side data), `NewILTycon nlpath (nm,m) tps (scoref, enc, tdef) mtyp` (from raw `ILTypeDef` metadata), `NewVal(…)` (large — see `.fsi.md` `ValData` fields: name, logname, m, mutability, attribs, compressRepr, memberInfo, typars, tgv, letrecinfo, inline, ty, linkage, valReprInfo, taccess, pubpath, recdInfo, xml, isCompGen, isCompilerGenerated, isGeneratedMember, isRecursive, ...), `NewCcuContents sref m nm mty`, `NewModifiedTycon f orig`, `NewModifiedModuleOrNamespace f orig`, `NewModifiedVal f orig`, `NewClonedModuleOrNamespace orig`, `NewClonedTycon orig`, and `ComputeDefinitionLocationOfProvidedItem` (locates the definition site of a provided item for error reporting).

## Key implementation notes

- Identity model: `Val.Linkage` + `Val.Typars`, and tycon `Stamp`, are what make cross-CCU reference equality (via `valRefEq`/`unionCaseRefEq`/`prim*RefEq` in `TypedTreeBasics`/`TcGlobals`) possible — the reason the "well-known" compiler intrinsics are pinned once in `TcGlobals`.
- `Expr.App` normalization and the `Link`/`TyChoose` "placeholder then rewrite" patterns are the conventions later transformation passes (e.g. `TypedTreeOps.Remapping`, optimization passes) rely on.
- `ModuleOrNamespaceType` uses `QueueList` (F# order-preserving queue) rather than `list` for its `vals`/`tycons` accumulators.

## Relation to the signature

Implements every declaration of `TypedTree.fsi`; module attribute `[<AutoOpen>]`d constructs (`ModuleOrNamespaceKind`, `Stamp`) come from `TypedTreeBasics`, which this file depends on. Consumers: `Checker.fs` (builder), `TypedTreeOps.*` (attribute flags, free vars, remap, transforms), `Optimizer`, `IlxGen`, `TypedTreePickle`, `TypeProviders`, `QuotationPickler` — each cross-referenced with the `.fsi.md`.
# TypedTree.fsi

**Purpose**: Contract for the central typed AST. Declares the checked types (`Val`, `Entity`/`Tycon`/`ModuleOrNamespace`, `UnionCase`, `RecdField`, `Expr`, `TOp`, `Const`, `TType`, `Typar`, `TraitConstraintInfo`, `ValRef`/`EntityRef`/`TyconRef`/`UnionCaseRef`/`RecdFieldRef`, `Nullness`, `CcuThunk`/`CcuData`/`PickledCcuInfo`), the flags (`ValFlags`, `TyparFlags`, `EntityFlags`), the path/accessibility types (`PublicPath`, `SyntaxAccess`, `CompilationPath`, `Accessibility`), the decision-tree types (`DecisionTree`, `DecisionTreeCase`, `DecisionTreeTest`, `DecisionTreeTarget`), and the free-vars types. This is the "checked" tree produced by the checker (hence the task's `ExprVal`/`TypedVal`/`TypedModule`/`TypedMember`/`TypedConstructor`/`TypedProperty`/`TypedParameter` concepts map to `Expr`/`Val`/`Entity`/`UnionCase`/`RecdField` here).

**Namespace(s)**: `FSharp.Compiler` — `module internal rec FSharp.Compiler.TypedTree`.

**Key declared types (contract)**:
- `Stamp = int64`, `StampMap<'T>`.
- `ValInline` (inherited val), `ValRecursiveScopeInfo`, `ValMutability`, `TyparDynamicReq`, `ValBaseOrThisInfo`.
- `ValFlags(flags: int64)`, `TyparKind` (Type|Measure), `TyparRigidity` (Static|Free|Delayed), `TyparFlags` (`[<Flags>]`), `EntityFlags` (`[<Flags>]`: `IsStaticMember`, `IsStaticParam`, `IsInline`, `IsMeasure`, `IsDelegate`, `IsRecord`, `IsUnion`, `IsEnum`, `IsClass`, `IsInterface`, `IsException`, `IsDelegateOrDelegate...`).
- `ModuleOrNamespaceKind` (Module|Namespace), `PublicPath = string[]`, `SyntaxAccess`, `CompilationPath`, `EntityOptionalData`.
- `Entity` — the checked entity (name, typars, attribs, constraints, members, `UnionCases`/`RecdFields`, `ExceptionInfo`, `ModuleOrNamespaceType` for module kinds).
- `EntityData = Entity`, `ParentRef`, `CompiledTypeRepr`, `TyconAugmentation`, `TyconRepresentation` (Class|Struct|Enum|Record|Union|Other), `TILObjectReprData`, `TProvidedTypeInfo`, `FSharpTyconKind`, `FSharpTyconData`, `TyconRecdFields`, `TyconUnionCases`, `TyconUnionData`.
- `UnionCase` (case name, fields, `Attribs`, `Access`), `RecdField` (name, `Type`, `Mutable`, `Attribs`, `Access`), `ExceptionInfo`, `ModuleOrNamespaceType` (checked module body), `ModuleOrNamespace = Entity`, `Tycon = Entity`.
- `Accessibility` (Public|Internal|Private with `CompilationPath`), `TyparOptionalData`, `TyparData = Typar`, `Typar`, `TyparConstraint` (Type|Trait; with `Static` req).
- `TraitWitnessInfo`, `TraitConstraintInfo`, `TraitConstraintSln`.
- `ValLinkagePartialKey` (name + param types + return type signature), `ValLinkageFullKey(partialKey, typeForLinkage)`, `ValOptionalData`, `ValData = Val`, `Val` (central checked value), `ValMemberInfo`, `NonLocalValOrMemberRef`, `ValPublicPath`.
- `NonLocalEntityRef(path: string[], id: string, compPath, publicPath, access, ccu)`, `EntityRef(ERefLocal|ERefNonLocal|ERefNonLocalPreResolved)`, `ModuleOrNamespaceRef = EntityRef`, `TyconRef = EntityRef`, `ValRef(VRefLocal|VRefNonLocal|VRefNonLocalPreResolved)`, `UnionCaseRef`, `RecdFieldRef`.
- `NullnessInfo`, `Nullness` (KnownAmbivalentToNull|KnownWithNull|KnownWithoutNull|NullnessVar), `NullnessVar`.
- `TType` (checked type: `TTypar|TGenericParam|TArrow|TAnonymous|TAmbientUnit|TAbbrev|TApp|TEnumVal|TDelayed|TMeasure|TRawMetadata|TDelegate|TUnion...`), `TypeInst`, `TTypes`, `AnonRecdTypeInfo`, `TupInfo`, `Measure`.
- `WellKnownEntityAttribs = WellKnownAttribs<Attrib, WellKnownEntityAttributes>`, `WellKnownValAttribs = WellKnownAttribs<Attrib, WellKnownValAttributes>`, `Attribs = Attrib list`, `AttribKind` (Constructor|EnumVal|Literal|...), `Attrib`, `AttribExpr`, `AttribNamedArg`.
- `Const` (checked constants), `DecisionTree`, `DecisionTreeCase`, `ActivePatternReturnKind`, `DecisionTreeTest`, `DecisionTreeTarget`, `Bindings`, `Binding`, `ActivePatternElemRef`.
- `ValReprInfo`, `ArgReprInfo`, `TyparReprInfo`, `Typars`, `Exprs`, `Vals`.
- `Expr` (central checked expression) — `Const, Val, Sequential, Lambda, TyLambda, App, LetRec, Let, Obj, Match, StaticOptimization, Op, Quote, WitnessArg, TyChoose, Link, DebugPoint`; `DebugText`, `ToDebugString`, `Range`.
- `TOp` (checked operator/intrinsic: `TOp_Nil, TOp_Next, TOp_Try, TOp_TryWith, TOp_Sequence, TOp_AddressOf, TOp_ValueCast, TOp_MeasureCast, TOp_FieldGet, TOp_FieldSet, TOp_RecordGet, TOp_RecordSet, TOp_UnionTag, TOp_UnionGet, TOp_AddressSet, ...`).
- `RecordConstructionInfo`, `ConstrainedCallInfo`, `SpecialWhileLoopMarker`, `ForLoopStyle`, `LValueOperation`, `SequentialOpKind`, `ValUseFlag`, `StaticOptimization`, `ObjExprMethod`, `SlotSig`, `SlotParam`, `OpenDeclaration`, `ModuleOrNamespaceContents`, `ModuleOrNamespaceBinding`, `NamedDebugPointKey`.
- `CheckedImplFile`, `CheckedImplFileAfterOptimization`, `CheckedAssemblyAfterOptimization`.
- `CcuData` (checked CCU data), `CcuTypeForwarderTree`, `CcuTypeForwarderTable`, `CcuReference = string`, `CcuThunk` (either `CcuThunkLoaded` or `CcuThunkIL`), `CcuResolutionResult`, `PickledCcuInfo` (pickled CCU).
- `FreeLocals = Zset<Val>`, `FreeTypars = Zset<Typar>`, `FreeTycons = Zset<Tycon>`, `FreeRecdFields = Zset<RecdFieldRef>`, `FreeUnionCases = Zset<UnionCaseRef>`, `FreeTyvars`, `FreeVarsCache`, `FreeVars`.
- `Construct` (static class with constructors: `NewTypar`, `NewTycon`, `NewModuleNamespaceType`, `NewVal`, ...).

**Notable contract notes**: The `Val.Linkage: ValLinkageFullKey` and `Val.Typars` (with `TyparFlags`) drive cross-CCU identity; `Expr.App` normalizes sequential applications into `args: Exprs`; `Expr.Match` stores a `DecisionTree` + `targets` array; `Expr.Quote` carries a `quotationInfo: option ref` (mutable) filled in by the picker; `Expr.WitnessArg` is spliced for trait witnesses. `CcuThunk` is the key indirection for cross-assembly F#/IL resolution (lazy loading).

**Cross-references**: `TypedTree.fs` (implementation), `TypedTreeBasics.fsi` (shared helpers), `TypedTreeOps.*` (attribute checking, free vars, remap, remapping, transforms), `TypedTreePickle.fs`/`.fsi`, `TypeProviders.fs`, `tainted.fs`, `QuotationPickler.fsi`, `WellKnownAttribs.fsi`, `SynthesizedTypeMaps.fs`, `TcGlobals.fsi` (well-known refs), `Checker.fs` (producer), `IlxGen.fs` (consumer), `FSharpQuotations` (de-pickles).

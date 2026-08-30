# EraseUnions.fs

**Purpose**: "Erase discriminated unions — type definition generation." Given an `IlsxUnionInfo` describing an F# discriminated union, this file generates the *IL type definitions* (class or struct) into which the union is erased: the root type's fields and constructors, the optional nested per-case types, the maker methods (`New<Case>`), the `Is<Case>` tester methods and properties, the tag field and tag infrastructure, singleton constant fields for nullary cases, optional debugger type proxies, and `[DynamicallyAccessedMembers]`/`[DynamicDependency]` attributes for trimming safety.

**Namespace / module declared**: `FSharp.Compiler.AbstractIL.ILX.EraseUnions` (internal module; contract in `EraseUnions.fsi`)

**Types declared**:
- `ILStamping` — bundles the attribute-stamping callbacks used during generation: `stampMethodAsGenerated`, `stampPropertyAsGenerated`, `stampPropertyAsNever`, `stampFieldAsGenerated`, `stampFieldAsNever`, and `mkDebuggerTypeProxyAttr`.
- `TypeDefContext` — the single context threaded through all generation: `g: TcGlobals`, `layout: UnionLayout` (from `EraseUnions.Types.fs`), `cuspec: IlxUnionSpec`, `cud: IlxUnionInfo`, `td: ILTypeDef`, `baseTy: ILType`, and `stamping: ILStamping`. Replaces the old "6-callback tuple + scattered parameter threading."
- `NullaryConstFieldInfo` — describes a nullary case's singleton static field: the case, its type, its index, the field, and whether the field lives on the root class.
- `AlternativeDefResult` — the per-case generation result: `BaseMakerMethods`, `BaseMakerProperties`, `ConstantAccessors`, `NestedTypeDefs`, `DebugProxyTypeDefs`, and `NullaryConstFields`.

**Public API surface** (per the .fsi):
- `mkClassUnionDef: (ILMethodDef -> ILMethodDef) * (ILPropertyDef -> ILPropertyDef) * (ILPropertyDef -> ILPropertyDef) * (ILFieldDef -> ILFieldDef) * (ILFieldDef -> ILFieldDef) * (ILType -> ILAttribute) -> TcGlobals -> ILTypeRef -> ILTypeDef -> IlxUnionInfo -> ILTypeDef` — "make the type definition for a union type." The 6-callback tuple is exactly the `ILStamping` record.

**Internal generation helpers** (the workhorse pipeline):
- `mkMethodsAndPropertiesForFields ctx ilTy fields` — emit `get_<Field>` instance methods + properties for one case's fields (field accessors for nested types).
- `emitDebugProxyType ctx altTy fields` — emit the nested `<altTy>@DebugTypeProxy` type (with `DebuggerTypeProxyAttribute`, a public constructor, and a `_obj` back-reference field) so the debugger can render the case cleanly.
- `emitMakerMethod ctx num alt` — emit the `New<Case>` static constructor method (name adjusted by `mkMakerName` for special helper shapes).
- `emitTesterMethodAndProperty ctx num alt` — emit `Is<Case>` method and property.
- `emitNullaryCaseAccessor` / `emitConstantAccessor` / `emitNullaryConstField` — the singleton-constant machinery for nullary cases.
- `emitNestedAlternativeType ctx num alt` — build a nested type (subtype of root) for a non-root case.
- `processAlternative ctx num alt` — the per-case driver that assembles all of the above into an `AlternativeDefResult`.
- Root-class emission: `rewriteNullableAttrForFlattenedField`, `rewriteFieldsForStructFlattening`, `rootTypeNullableAttrs`, `emitRootClassFields ctx tagFieldsInObject`, `emitRootConstructors ctx rootCaseFields tagFieldsInObject rootCaseMethods`, `emitConstFieldInitializers ctx altNullaryFields`, `emitTagInfrastructure ctx` (tag field + `get_Tag`/`set_Tag`/`Tag` property), `computeRootInstanceFields ctx rootCaseFields tagFieldsInObject`.
- `computeEnumTypeDef g td cud tagEnumFields` — synthesize an *enum-style* companion type when the union is an all-nullary tagged reference union (so it can interoperate with C# enums).
- `assembleUnionTypeDef ...` — the final assembly step that composes the root type def, the nested types, the debug proxies, the tag members, and the constant-field initializers into the one `ILTypeDef` (with `WithAbstract` / `WithSealed` set appropriately).

**Significant internal logic**:
- The generation pipeline (documented in the file's header comment):
  1. Classify the union layout (`classifyFromDef` → `UnionLayout`).
  2. For each case: classify its storage (`classifyCaseStorage` → `CaseStorage`).
  3. For each case: emit maker methods, tester properties, nested types, and debug proxies.
  4. Emit the root class: fields, constructors, tag infrastructure.
  5. Assemble everything into the final `ILTypeDef`.
- Worked examples (from the header comment):
  - `Option<'T>` → `SmallRefWithNullAsTrueValue` → `None = Null`, `Some = OnRoot`.
  - `type Color = Red | Green | Blue | Yellow` → `TaggedRefAllNullary` → all cases `Singleton`.
  - `[<Struct>] type Result<'T,'E> = Ok of 'T | Error of 'E` → `TaggedStruct` → both cases `OnRoot`.
  - `type Shape = Circle of float | Square of float | Point` → `SmallRef` → `Circle`/`Square = InNestedType`, `Point = Singleton`.
  - `type Token = Ident of string | IntLit of int | Plus | Minus | Star` → `TaggedRef` → `Ident`/`IntLit = InNestedType`, the rest `Singleton`.
- `[DynamicDependency]` and `[DynamicallyAccessedMembers]` attributes are emitted so that trimmed IL can still find the case constructors and base constructor (flag constants `DynamicDependencyPublicMembers = 0x660`, `DynamicDependencyAllCtorsAndPublicMembers = 0x7E0`).
- Debugger proxies are emitted for each alternative so that the debugger can render the case type (a public `[DebuggerTypeProxy]`-style nested type holding a `_obj` back-reference).

**Cross-references**:
- Signature: `EraseUnions.fsi`.
- Classification helpers (the two-axis model): `EraseUnions.Types.fs` (`UnionLayout`, `CaseStorage`, `classifyFromDef`, `classifyCaseStorage`, `mkMakerName`, `adjustFieldNameForList`, `CaseIdentity`, the `DiscriminateBy*` / `HasTagField` / `CaseIsNull` / `ValueTypeLayout` active patterns).
- Instruction emission: `EraseUnions.Emit.fs` (`emitLdDataTag`, `emitCastData`, `emitDataSwitch`, etc.).
- `IlxGenSupport.fs` — attribute helpers (`GetDynamicDependencyAttribute`, `GetNullableAttribute`, …) used by the stamping callbacks.
- Driven from `IlxGen.fs`; downstream of `Optimizer.fs`.
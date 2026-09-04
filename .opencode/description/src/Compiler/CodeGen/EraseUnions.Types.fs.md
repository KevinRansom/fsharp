# EraseUnions.Types.fs

**Purpose**: "Erase discriminated unions — types, classification, and active patterns." This file defines the *two-axis classification model* that drives all other union erasure logic (in `EraseUnions.fs` and `EraseUnions.Emit.fs`):
1. **`UnionLayout`** (9 cases) — how the union *type* is structured in IL, computed once per union.
2. **`CaseStorage`** (4 cases) — how each individual *case* is stored (null / singleton / on-root / nested type), computed per case.
It also exposes the exhaustive active patterns, the name / naming / field / helper utilities shared between the type-def generation and the instruction emission.

**Namespace / module declared**: `[<AutoOpen>] module internal FSharp.Compiler.AbstractIL.ILX.EraseUnionsTypes` (`[<AutoOpen>]` so consumers needn't `open` it explicitly; internal, compiler-use only).

**Types declared**:
- `[<RequireQualifiedAccess>] DataAccess` — `RawFields` (use raw field loads/stores), `ViaHelpers` (use `get_Tag` / `get_IsXxx` / `NewXxx` helpers), `ViaListHelpers` (list-specific `HeadOrDefault` / `TailOrNull` naming), `ViaOptionHelpers` (field access via helpers, raw discrimination for tag).
- `[<RequireQualifiedAccess; NoComparison; NoEquality>] UnionLayout` — the 9 possible layouts: `FSharpList baseTy`, `SingleCaseRef baseTy`, `SingleCaseStruct baseTy`, `SmallRef baseTy`, `SmallRefWithNullAsTrueValue (baseTy, nullAsTrueValueIdx)`, `TaggedRef baseTy`, `TaggedRefAllNullary baseTy`, `TaggedStruct baseTy`, `TaggedStructAllNullary baseTy`.
- `[<RequireQualifiedAccess>] CaseStorage` — `Null`, `Singleton`, `OnRoot`, `InNestedType nestedType`.
- `[<Struct>] CaseIdentity` — `{ Index: int; Case: IlxUnionCase; CaseType: ILType; CaseName: string }` — the resolved identity of a union case within a union spec.

**Public API surface** (notable top-level `let`s):
- `computeDataAccess (avoidHelpers: bool) (cuspec: IlxUnionSpec) : DataAccess` — pick the access strategy from the per-call-site `avoidHelpers` flag and the per-union `HasHelpers` setting.
- **Classification**:
  - `classifyUnion baseTy alts nullPermitted isList isStruct` (private) — the core classifier.
  - `classifyFromSpec cuspec : UnionLayout` — classify from an `IlsxUnionSpec` (used in IL instruction generation).
  - `classifyFromDef td cud baseTy : UnionLayout` — classify from an `ILTypeDef` + `IlsxUnionInfo` (used in type definition generation).
- **Active patterns** (exhaustive):
  - `(|DiscriminateByTagField|DiscriminateByRuntimeType|DiscriminateByTailNull|NoDiscrimination|) layout` — how to discriminate.
  - `(|HasTagField|NoTagField|) layout` — does the root have a `_tag` int field.
  - `(|CaseIsNull|CaseIsAllocated|) (layout, cidx)` — is a specific case the null-represented one.
  - `(|ValueTypeLayout|ReferenceTypeLayout|) layout` — struct or class.
- **Layout-based helpers** (replace the old representation-decision methods):
  - `caseFieldsOnRoot layout alt alts` — "does this non-nullary alternative fold to the root class via fresh instances."
  - `caseRepresentedOnRoot layout alt alts cidx` — "does this alternative optimize to the root class (no nested type needed)."
  - `needsSingletonField layout alt cidx` — "should a static constant field be maintained for this nullary alternative" (nullary + reference type + not null-represented).
  - `tyForAltIdxWith layout baseTy cuspec alt cidx : ILType` — the IL type of a case at a given index.
  - `tyForAltIdx cuspec alt cidx : ILType` — same, layout computed locally.
  - `tyForAlt cuspec alt : ILType` — find the index by name first, then call `tyForAltIdx`.
  - `GetILTypeForAlternative cuspec alt : ILType` — public wrapper for `tyForAlt`.
  - `classifyCaseStorage layout cuspec cidx alt : CaseStorage` — the per-case storage classification.
  - `resolveCaseWith layout baseTy cuspec cidx : CaseIdentity` — resolve a case by index using precomputed layout/base type.
- **Naming / helper utilities**:
  - `TagNil = 0`; `TagCons = 1`; `ALT_NAME_CONS = "Cons"` — list-tag constants.
  - `tagPropertyName = "Tag"`.
  - `mkMakerName cuspec nm` — the maker method name (`New<Case>` or `"<Case>"` for list/option helpers).
  - `mkTesterName nm = "Is" + nm`.
  - `mkCasesTypeRef cuspec` — the union's type ref.
  - `mkConstFieldSpecFromId` / `mkConstFieldSpec` / `constFieldName nm = "_unique_" + nm` / `constFormalFieldTy baseTy` — the singleton-constant-field naming and type helpers.
  - `adjustFieldNameForList nm` — `Head` → `HeadOrDefault`, `Tail` → `TailOrNull`.
  - `mkUnionCaseFieldId fdef` — `(LowerName, Type)` of a case field.
  - `mkUnionCaseFieldIdAndAttrs g fdef` — same + nullable attribute.
  - `refToFieldInTy ty (nm, fldTy)` — `mkILFieldSpecInTy`.
  - `formalTypeArgs baseTy` — the formal-type-arg list.
  - `mkTagFieldType ilg : ILType` — always `Int32`.
  - `mkTagFieldId ilg : (string * ILType)` — `("_tag", Int32)`.
  - `altOfUnionSpec cuspec cidx : IlxUnionCase` — index into the alternatives (with bounds check).
- **Nullness / attribute helpers**:
  - `nullnessCheckingEnabled g : bool` — is the nullness feature on.
  - `getFieldsNullability g ilf : ILAttrib option` — the `NullableAttribute` on a field, if any.

**Significant internal logic**:
- **`classifyUnion`** is the heart of the module. From `(baseTy, cases, nullPermitted, isList, isStruct)` it picks one of the 9 layouts:
  - `isList` → `FSharpList` (regardless of arity).
  - 1 case → `SingleCaseRef` or `SingleCaseStruct`.
  - 2–3 cases, not all nullary → `SmallRef` (discriminate by `isinst`) or `SmallRefWithNullAsTrueValue` (one case represented as `null`, found by index).
  - Otherwise, by struct / all-nullary: `TaggedStructAllNullary`, `TaggedStruct`, `TaggedRefAllNullary`, or `TaggedRef` (all discriminate by the `_tag` integer field).
- **`CaseStorage`** is computed *per case* given the layout, and is the primary axis used by the emit functions (`EraseUnions.Emit.fs`) to choose between a null-store, a singleton `ldsfld`, a direct root-class field, or a nested-type allocation.
- **`DataAccess`** is computed *once at the entry point* for a call site (from `avoidHelpers` + `HasHelpers`) so that the 4-way discrimination in the emit pass is a single `match` on a value rather than re-deriving the strategy per instruction.
- The module is `[<AutoOpen>]` so that its active patterns and helpers are in scope inside `EraseUnions.fs` and `EraseUnions.Emit.fs` without an explicit `open`.

**Cross-references**:
- `EraseUnions.fs` — consumes the layout / storage / helpers for type definition generation.
- `EraseUnions.Emit.fs` — consumes the active patterns and naming helpers for IL instruction emission.
- `EraseClosures.fs` — sibling erasure pass (same family of modules under `FSharp.Compiler.AbstractIL.ILX.`).
- `IlxGen.fs` — the driver that threads these through.
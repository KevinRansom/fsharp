# AugmentWithHashCompare.fsi

**Purpose**: Public contract for the hash/compare (and equals, ToString) augmentation the F# compiler adds to user-defined records and unions by default. Declares the entry points by which `CheckDeclarations` queries candidate-ness and obtains the synthesized `Val`s / `Binding`s and comparer-based equality bundle.

**Namespace(s)**: `module internal FSharp.Compiler.AugmentTypeDefinitions`

**Types declared**:
- `EqualityWithComparerAugmentation` ([<NoEquality; NoComparison; StructuredFormatDisplay("{DebugText}")>]) — `{ GetHashCode: Val; GetHashCodeWithComparer: Val; EqualsWithComparer: Val; EqualsExactWithComparer: Val }`.

**Public API surface** (val contracts):
- Expression scaffolding:
  - `mkBindNullComparison : TcGlobals -> range -> thise: Expr -> thate: Expr -> expr: Expr -> Expr`
  - `mkBindThisNullEquals`, `mkBindNullHash` — same shape, for null-safe equality/hash.
- Attribute/candidate checks:
  - `CheckAugmentationAttribs : bool -> TcGlobals -> ImportMap -> Tycon -> unit`
  - `TyconIsCandidateForAugmentationWithCompare/Equals/Hash : TcGlobals -> Tycon -> bool`
  - `TyconIsCandidateForAugmentationWithToString : g: TcGlobals * tycon: Tycon -> bool` — whether a reflection-free structural `ToString` should be generated.
- Val generation:
  - `MakeValsForCompareAugmentation : TcGlobals -> TyconRef -> Val * Val`
  - `MakeValsForCompareWithComparerAugmentation : TcGlobals -> TyconRef -> Val`
  - `MakeValsForEqualsAugmentation : TcGlobals -> TyconRef -> Val * Val`
  - `MakeValsForEqualityWithComparerAugmentation : TcGlobals -> TyconRef -> EqualityWithComparerAugmentation`
  - `MakeValsForUnionAugmentation : TcGlobals -> TyconRef -> Val list`
  - `MakeValsForToStringAugmentation : g: TcGlobals * tcref: TyconRef -> Val`
- Binding generation (produce the TAST `Binding list` published into the container):
  - `MakeBindingsForCompareAugmentation / CompareWithComparerAugmentation / EqualsAugmentation / EqualityWithComparerAugmentation : TcGlobals -> Tycon -> Binding list`
  - `MakeBindingsForUnionAugmentation : TcGlobals -> Tycon -> ValRef list -> Binding list`
  - `MakeBindingsForToStringAugmentation : g: TcGlobals * tycon: Tycon * toStringVal: Val -> Binding list`
- `TypeDefinitelyHasEquality : TcGlobals -> TType -> bool` — documented as usable once type inference is complete; beforehand only an approximation that asserts no new constraints.
- `mkRecdToString : g: TcGlobals * tcref: TyconRef * tycon: Tycon * openBrace: string * closeBrace: string -> Val * Expr` — builds a record's single-line reflection-free ToString body (recursion guard included); returns the `this` value and the body expression.

**Notes**: The .fsi exposes only the public surface; the many `mk*` expression builders (fieldwise compare/equals conjuncts, hash combiners, IL calls into `Comparer`/`EqualityComparer`, union-case dispatch) are implementation details in the `.fs` and not part of the contract.

**Cross-references**: `AugmentWithHashCompare.fs` (implementation), `CheckDeclarations.fs` (primary caller, publishes the generated Vals/Bindings), `MethodOverrides.fs` (slot publishing), `infos.fsi` (`SlotSig` types).

# AugmentWithHashCompare.fs

**Purpose**: Generates ("augments") the `Equals`, `GetHashCode`, and `CompareTo` implementations — plus comparer-parameterized variants and (recently) reflection-free `ToString` overrides — that the F# compiler adds by default to user-defined records/unions (and exception types). It synthesizes typed TAST expressions (`Expr`, `Val`, `Binding`) walking each type's fields/cases, so the resulting code is structural, null-checking, and field-order-sensitive, without reflection.

**Namespace(s)**: `module internal FSharp.Compiler.AugmentTypeDefinitions`

**Types declared**:
- `EqualityWithComparerAugmentation` record — `{ GetHashCode: Val; GetHashCodeWithComparer: Val; EqualsWithComparer: Val; EqualsExactWithComparer: Val }`, the bundle of values produced for comparer-based equality augmentation.

**Public API surface** (major vals):
- Null-handling scaffolding: `mkBindNullComparison`, `mkBindThisNullEquals`, `mkBindNullHash` — wrap a body so null `this`/`that` are compared correctly (e.g. `mkBindNullHash` maps null `thise` to hash 0, `mkBindThisNullEquals` maps this=null to `thate = null`).
- Candidate detection: `TyconIsCandidateForAugmentationWithCompare/Equals/Hash/ToString : TcGlobals -> Tycon -> bool`.
- Val/Binding generation:
  - `MakeValsForCompareAugmentation : TcGlobals -> TyconRef -> Val * Val`
  - `MakeValsForCompareWithComparerAugmentation : TcGlobals -> TyconRef -> Val`
  - `MakeValsForEqualsAugmentation : TcGlobals -> TyconRef -> Val * Val`
  - `MakeValsForEqualityWithComparerAugmentation : TcGlobals -> TyconRef -> EqualityWithComparerAugmentation`
  - `MakeBindingsForCompareAugmentation`, `MakeBindingsForCompareWithComparerAugmentation`, `MakeBindingsForEqualsAugmentation`, `MakeBindingsForEqualityWithComparerAugmentation : TcGlobals -> Tycon -> Binding list`
  - `MakeValsForUnionAugmentation`, `MakeBindingsForUnionAugmentation : TcGlobals -> Tycon -> ValRef list -> Binding list`
  - `CheckAugmentationAttribs : bool -> TcGlobals -> ImportMap -> Tycon -> unit` — validates any `Equality/Comparison`-related attributes on the type.
  - `TypeDefinitelyHasEquality : TcGlobals -> TType -> bool` — post-inference predicate asserting the type structurally supports equality.
  - `mkRecdToString` — builds a single-line, reflection-free `ToString` body for a record (returns the `this` value + body expression); `MakeValsForToStringAugmentation` / `MakeBindingsForToStringAugmentation` produce the `override ToString` slot.
- Slot-signature helpers (mostly internal here but shared): `mkIComparableCompareToSlotSig`, `mkIStructuralComparableCompareToSlotSig`, `mkGenericIEquatableEqualsSlotSig`, `mkIStructuralEquatableEqualsSlotSig`, `mkIStructuralEquatableGetHashCodeSlotSig`, `mkGetHashCodeSlotSig`, `mkEqualsSlotSig`, `mkToStringSlotSig`, and the generic (type-parameterized) `CompareTo/Equals` slot signatures.

**Internal helpers / builders** (notable ones, all in this file):
- Type/ty builders: `mkThisTy`, `mkCompareObjTy`, `mkCompareTy`, `mkCompareWithComparerTy`, `mkEqualsObjTy`, `mkEqualsTy`, `mkEqualsWithComparerTy`, `mkEqualsWithComparerTyExact`, `mkHashTy`, `mkToStringTy`, `mkHashWithComparerTy`, `mkIsCaseTy`, `mkMinimalTy`.
- Expression prim builders: `mkRelBinOp`, `mkClt`, `mkgCgt`, `mkILLangPrimTy`, `mkILCallGetComparer`, `mkILCallGetEqualityComparer`, `mkThisVar`, `mkThatAddrLocal`, `mkThatAddrLocalIfNeeded`, `mkThisVarThatVar`, `mkThatVarBind`, `mkBindThatAddr`, `mkBindThatAddrIfNeeded`.
- Field-by-field test assembly: `mkCompareTestConjuncts` (ordered `CompareTo` comparisons via a `n` accumulator), `mkEqualsTestConjuncts`.
- Per-shape bodies: `mkRecdCompare`, `mkRecdCompareWithComparer`, `mkRecdEquality`, `mkRecdEqualityWithComparer`, `mkExnEquality`, plus corresponding union-case versions (`mkUninCompare*`, `mkUninEquality*` — the module is large, ~1900 lines).
- Hash accumulation: `mkAddToHashAcc`, `mkCombineHashGenerators`, `mkShl`, `mkShr`, `mkAdd`.

**Significant internal logic**:
- The generated `CompareTo` walks fields in source order, calling `System.Collections.Comparer.Compare` on each and short-circuiting on non-zero.
- The generated `Equals` requires the other operand to be the same type/tycon before doing a fieldwise test; the "WithComparer" variants take an `IEqualityComparer<T>`/`IComparer<T>` argument.
- Null semantics: `Equals` handles null-`this`/null-`that` at the boundary; `CompareTo` follows CLR convention for ordering nulls; `GetHashCode` returns 0 for null.
- Unions augment each case separately and dispatch on the case discriminator.
- `ToString` augmentation is reflection-free, builds e.g. `{ Field1 = ...; Field2 = ... }`, and includes a recursion guard (shared mutable flag) to prevent infinite loops with self-referential values.

**Cross-references**: `AugmentWithHashCompare.fsi` (public contract), `CheckDeclarations.fs` (calls these to publish augmented vals/members on a Tycon), `infos.fs` (`SlotSig`), `infos.fsi` (same), `MethodOverrides.fs` (publishing these slots as interface implementations), `PatternMatchCompilation.fs` / `TailCallChecks.fs` (not directly related but same directory).

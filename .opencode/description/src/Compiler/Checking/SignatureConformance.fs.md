# SignatureConformance.fs

**Purpose**
Implements signature conformance checking: verifying that the implementation definition of a module/
namespace matches its signature (`fsi`), and vice-versa when the signature is derived from the
implementation. Checks that names, type parameters, types, union cases, record fields, members, attributes
(enforced F#/IL attributes), and attributes' arguments line up between the signature and implementation
(TAST), using type equivalence under a `TypeEquivEnv` (the same notion of equivalence used in the checking
pass, but comparing *two* already-checked trees rather than solving).

**Namespace(s)**
`module internal FSharp.Compiler.SignatureConformance`

**Modules / Types declared** (top-level; the `Checker` class contains most of the logic)
- `TypeMismatchSource` — `NullnessOnlyMismatch | RegularMismatch` — distinguishes nullness-only mismatches (for better diagnostics) from regular type mismatches.
- Exceptions (all carry a `DisplayEnv`/`InfoReader`/`RichText` builder for rendering the mismatch):
  - `RequiredButNotSpecified of DisplayEnv * ModuleOrNamespaceRef * string * (RichTextBuilder -> unit) * range`
  - `ValueNotContained of TypeMismatchSource * DisplayEnv * InfoReader * ModuleOrNamespaceRef * Val * Val * (RichText * RichText * RichText -> RichText)`
  - `UnionCaseNotContained of DisplayEnv * InfoReader * Tycon * UnionCase * UnionCase * (RichText * RichText -> RichText)`
  - `FSharpExceptionNotContained of DisplayEnv * InfoReader * Tycon * Tycon * (RichText * RichText -> RichText)`
  - `FieldNotContained of TypeMismatchSource * DisplayEnv * InfoReader * Tycon * Tycon * RecdField * RecdField * (RichText * RichText -> RichText)`
  - `InterfaceNotRevealed of DisplayEnv * TType * range`
  - `ArgumentsInSigAndImplMismatch of sigArg: Ident * implArg: Ident`
  - `DefinitionsInSigAndImplNotCompatibleAbbreviationsDiffer of DisplayEnv * Tycon * Tycon * TType * TType * range`
- `AttributeConformance` (private module) — enforces well-known attribute requirements on impl vs. sig
  (enforced `WellKnownValAttributes` / `WellKnownEntityAttributes` sets, `enforcedValsMask`,
  `enforcedEntitiesMask`, `displayName`, `rangeOfMissing`, `checkEnforced`); `checkVal` /
  `checkEntity` apply per-value and per-entity enforcement.
- `Checker` — the main checker, parameterized over `g`, `amap`, `denv`, `remapInfo: SignatureRepackageInfo`, `checkingSig: bool`.

**`Checker` public surface**
- `member CheckSignature: TypeEquivEnv -> InfoReader -> ModuleOrNamespaceRef (impl) -> ModuleOrNamespaceType (sig) -> bool` — the main entry; returns whether the impl conforms.
- `member CheckTypars: range -> TypeEquivEnv -> Typars (impl) -> Typars (sig) -> bool`.

**`Checker` private recursive check family** (the bulk of the module)
- `checkTypeDef` — compare two `Tycon`s: kind, typars, interfaces (including user-added interfaces),
  null-union semantics, then dispatch per representation.
- `checkTypeRepr` — compare the `TyconReprInfo` of impl vs. sig (record/union/class/interface/struct/enum/
  delegate/measure/IL/provided).
- `checkTypeAbbrev` — compare type abbreviation bodies (`DefinitionsInSigAndImplNotCompatibleAbbreviationsDiffer` if they differ beyond allowed equivalences).
- `checkValInfo` / `checkVal` — compare value representation info and values (arity, arg types, return type,
  genericity, `ValUseFlags`).
- `checkExnInfo` / `checkUnionCase` / `checkField` / `checkRecordFields(ForExn)` — data-type member
  conformance (raising `UnionCaseNotContained` / `FieldNotContained` / `FSharpExceptionNotContained`).
- `checkVirtualSlots` — virtual slot (abstract method) conformance.
- `checkClassFields` — field conformance for class/struct.
- `checkMemberDatasConform` — compare member (method) data between impl and sig.
- `checkModuleOrNamespaceContents` / `checkModuleOrNamespace` — walk the module/namespace definitions,
  recursing into nested modules.
- `checkAttribs` / `checkEnforcedEntityAttribs` / `checkEnforcedValAttribs` — attribute conformance, using
  a signature→impl remap so signature attributes can be compared and propagated to the implementation.

**Top-level entry**
- `CheckNamesOfModuleOrNamespace: DisplayEnv -> InfoReader -> ModuleOrNamespaceRef -> ModuleOrNamespaceType -> bool` — first-pass check that the *names* line up between a signature and its implementation.

**Significant internal logic**
- Conformance is *parametric in the direction of checking* via the `checkingSig` flag: the same code path
  is used when the signature drives the impl (forward) vs. when the impl drives the signature (reverse),
  flipping which side is reported as authoritative.
- Type comparison uses `typeAEquiv`/`typeEquiv` from `TypeRelations`/`TypedTreeOps` over a `TypeEquivEnv`
  (with `BindEquivTypars` to relate the impl typars to the sig typars); nullness-only mismatches are
  tagged `TypeMismatchSource.NullnessOnlyMismatch` for a distinct diagnostic.
- Attribute conformance follows the spec'd algorithm: for each impl attribute, find an exact match in the
  sig (drop it), otherwise a same-type attribute (warn), otherwise keep it; the compiled form is the
  signature's attributes plus the kept impl attributes.
- `remapInfo` (`SignatureRepackageInfo` with `RepackagedEntities`/`RepackagedVals`) supplies the
  sig→impl reference map used to render and compare attribute types correctly.
- The signature→impl remap built in `Checker`'s initializer is also the remap passed to attribute
  checking so that `remapAttrib` makes sig attributes "look as if declared in the implementation".

**Cross-references**
- `SignatureConformance.fsi` — public contract (exceptions, `Checker`, `CheckNamesOfModuleOrNamespace`).
- `TypeRelations.fsi` / `TypeHierarchy.fsi` — type equivalence/subsumption primitives used in the `check*`
  family.
- `NicePrint.fsi` — rich-text rendering of the mismatching symbols in the raised exceptions.
- `SignatureHash.fs` — related "does the signature change" hashing, used for incremental recompilation
  decisions (orthogonal: conformance is *checking*, hash is *change detection*).
- `CheckDeclarations.fs` (sibling) — drives `Checker.CheckSignature` when checking a signature file, and
  the reverse when deriving a signature from an impl.
- `AttributeChecking.fsi` (sibling) — attribute evaluation/equality helpers used by `checkAttribs`.

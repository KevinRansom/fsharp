# SignatureConformance.fsi

**Purpose**
Public contract (internal module) for signature conformance checking — the relations used to verify that
a signature definition and its implementation definition agree, excluding constraint solving and method
overload resolution (which are owned by `ConstraintSolver`/`OverloadResolutionRules`). Declares the
mismatch-exception family (each carrying rendering callbacks), the `Checker` class, and the name-level
pre-check.

**Namespace(s)**
`module internal FSharp.Compiler.SignatureConformance`

**Modules / Types declared**
- `TypeMismatchSource` — `NullnessOnlyMismatch | RegularMismatch`.
- `RequiredButNotSpecified of DisplayEnv * ModuleOrNamespaceRef * string * (RichTextBuilder -> unit) * range` — exception.
- `ValueNotContained of kind: TypeMismatchSource * DisplayEnv * InfoReader * ModuleOrNamespaceRef * Val * Val * (RichText * RichText * RichText -> RichText)` — exception.
- `UnionCaseNotContained of DisplayEnv * InfoReader * Tycon * UnionCase * UnionCase * (RichText * RichText -> RichText)` — exception.
- `FSharpExceptionNotContained of DisplayEnv * InfoReader * Tycon * Tycon * (RichText * RichText -> RichText)` — exception.
- `FieldNotContained of kind: TypeMismatchSource * DisplayEnv * InfoReader * Tycon * Tycon * RecdField * RecdField * (RichText * RichText -> RichText)` — exception.
- `InterfaceNotRevealed of DisplayEnv * TType * range` — exception.
- `ArgumentsInSigAndImplMismatch of sigArg: Ident * implArg: Ident` — exception.
- `DefinitionsInSigAndImplNotCompatibleAbbreviationsDiffer of denv: DisplayEnv * implTycon: Tycon * sigTycon: Tycon * implTypeAbbrev: TType * sigTypeAbbrev: TType * range: range` — exception.
- `Checker` — class; `new: TcGlobals -> ImportMap -> DisplayEnv -> SignatureRepackageInfo (remapInfo) -> bool (checkingSig) -> Checker`.

**Public API surface**
- `Checker.CheckSignature: TypeEquivEnv -> InfoReader -> ModuleOrNamespaceRef (implModRef) -> ModuleOrNamespaceType (signModType) -> bool` — check the implementation matches the signature (or vice versa, per `checkingSig`); returns success.
- `Checker.CheckTypars: range -> TypeEquivEnv -> Typars (implTypars) -> Typars (signTypars) -> bool`.
- `CheckNamesOfModuleOrNamespace: DisplayEnv -> InfoReader -> ModuleOrNamespaceRef -> ModuleOrNamespaceType -> bool` — "the names add up" pre-check, run first.

**Significant notes**
- The exceptions carry *rendering callbacks* (`(RichText * ... -> RichText)` / `(RichTextBuilder -> unit)`)
  rather than pre-rendered text, so the message can be built lazily in the caller's display context
  (typically via `NicePrint` helpers).
- `TypeMismatchSource.NullnessOnlyMismatch` lets callers distinguish "the types differ only in nullness"
  (a warning-level diagnostic) from a genuine type mismatch (error).
- The module's doc comment scopes it explicitly: "Primary relations on types and signatures, with the
  exception of constraint solving and method overload resolution."

**Cross-references**
- `SignatureConformance.fs` — implementation (the `Checker` recursive `check*` family, `AttributeConformance`).
- `TypeRelations.fsi` / `TypeHierarchy.fsi` — equivalence and interface-relation primitives used when
  comparing types.
- `NameResolution.fsi` — `SignatureRepackageInfo`, `Remap` plumbing from the checking environment.
- `NicePrint.fsi` — type/value rendering used by the exception payload builders.
- `CheckDeclarations.fsi` (sibling) — primary caller (`CheckOneSigFile` / signature-driven impl checking).

# SignatureHash.fs

**Purpose**
Computes structural hashes of the *implied signature* of a compilation unit, used for incremental
compilation / recompilation triggering (e.g. to detect when a dependency's visible surface has changed
and require recompilation of dependents). Hashes module/namespace names and paths, type definitions
(per object-model kind: record, union, class/interface/struct, delegate, enum, abbreviation, exception,
IL), values/members, and assembly-level top attributes + platform. Respects an `ObserverVisibility` so
that accessibility-hidden members contribute a neutral hash.

**Namespace(s)**
`module internal Fsharp.Compiler.SignatureHash` (note: `Fsharp` casing, not `FSharp`)

**Modules / Types declared**
- `TyconDefinitionHash` (module) — the per-tycon hashing logic:
  - `hashRecdField` — hash a record/union field (name, field+property attribs, type, static/volatile/mutable flags); hidden fields hash to 0.
  - `hashUnionCase` / `hashUnionCases` — hash union cases **order-sensitively** (generated `Tag` members make case order observable to dependents, hence `hashListOrderMatters`).
  - `hashFsharpDelegate` — hash the slot signature (parameter type groups, order-sensitive) + F#-view return type.
  - `hashFsharpEnum` — hash enum member display names (order-insensitive).
  - `hashTyconDefn` — the main dispatcher on `TypeReprInfo`: record (fields), union (cases), delegate (slot sig), enum (member names), class/interface/struct (immediate interfaces + fields + members + supertype + kind discriminator), `TAsmRepr` (via `HashIL.hashILType`), `TMeasureableRepr`, `TILObjectRepr`, `TNoRepr` w/ abbreviation (hash the abbreviated type), F# exception (per `ExceptionInfo` repr), provided types.
  - `hashTyconDefns` — hash a set of tycons (order-insensitive over local entity refs).
  - `fullPath` — compute the namespace "path" above a module/namespace spec.
- (top-level) `calculateHashOfImpliedSignature`, `calculateSignatureHashOfFiles`, `calculateHashOfAssemblyTopAttributes`.

**Public API surface** (see `.fsi`)
- `calculateHashOfImpliedSignature: TcGlobals -> ObserverVisibility -> ModuleOrNamespaceContents -> int` — recursively hashes a module/namespace's contents: module/namespace path (`MangledPath`, order-sensitive), local name, `IsModule` flag, then contents (bindings via `HashTastMemberOrVals.hashValOrMemberNoInst`, tycons, nested modules, `TMDefLet`/`TMDefs`); `doval@`-prefixed bindings and empty pieces hash to 0 (neutral).
- `calculateSignatureHashOfFiles: CheckedImplFile list -> TcGlobals -> ObserverVisibility -> int` — order-sensitive hash over the files' implied-signature hashes (starts a `calculateSignatureHashOfFiles` diagnostic Activity).
- `calculateHashOfAssemblyTopAttributes: TopAttribs -> ILPlatform option -> int` — hashes assembly/main-method/netmodule attribute lists and a per-platform discriminator (AMD64=1…X86=5).

**Significant internal logic**
- Order sensitivity is used exactly where IL-visible order matters (union case `Tag` values, delegate
  parameter groups, module paths, file list) and order-insensitivity elsewhere (fields, members,
  interfaces, enum members) — see the in-code comment on `hashUnionCases`.
- Accessibility-aware hashing: any entity/field hidden from the `observer` contributes `0`, so
  accessibility changes on otherwise-identical declarations do *not* change the hash for an observer who
  can't see them (driven by `HashAccessibility.isHiddenToObserver`).
- `0` is the "empty/neutral" hash value; combined hashes short-circuit to 0 when a section is empty so
  empty modules don't contribute path-derived noise.
- Member hashing is delegated to `HashTastMemberOrVals.hashValOrMemberNoInst` from `CheckDeclarations`
  (instantiation-independent: generic signature shape, not a specific instantiation).
- Uses `Internal.Utilities.TypeHashing.HashTypes` combinators (`hashText`, `hashTType`, `hashListOrderMatters`,
  `hashListOrderIndependent`, `pipeToHash`, `@@`) and `HashIL` for IL-backed members.

**Cross-references**
- `SignatureHash.fsi` — public contract (three entry points).
- `CheckDeclarations.fs` (sibling) — source of `HashTastMemberOrVals` used for value/member hashing.
- `Utilities/TypeHashing` (sibling dir) — `ObserverVisibility`, `HashAccessibility`, `HashTypes`, `HashIL`.
- `SignatureConformance.fs` — related but distinct: conformance *checks* sig⟷impl; hashing *detects*
  signature change for incremental builds.
- `NicePrint.fs` — (indirect) `hashText` over display names mirrors the same name normalizations.

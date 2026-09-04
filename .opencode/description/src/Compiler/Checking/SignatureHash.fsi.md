# SignatureHash.fsi

**Purpose**
Public contract for signature hashing: entry points that compute structural hashes of a compilation unit's
implied signature (and of assembly top attributes / platform), used for recomilation triggering in
incremental builds. The hash is computed respecting an `ObserverVisibility` (who is looking).

**Namespace(s)**
`module internal Fsharp.Compiler.SignatureHash` (note: `Fsharp` casing, not `FSharp`)

**Public API surface** (complete — the module is fully specified by these three signatures)
- `calculateHashOfImpliedSignature: TcGlobals -> observer: ObserverVisibility -> expr: ModuleOrNamespaceContents -> int` — hash the implied signature of one module/namespace.
- `calculateSignatureHashOfFiles: files: CheckedImplFile list -> g: TcGlobals -> observer: ObserverVisibility -> int` — hash over a set of implementation files (order-sensitive).
- `calculateHashOfAssemblyTopAttributes: attrs: TopAttribs -> platform: ILPlatform option -> int` — hash of assembly-level attributes plus the target platform.

**Dependent types** (from other modules)
- `ObserverVisibility` — from `Internal.Utilities.TypeHashing`; controls which accessibility level the hash is computed at.
- `ModuleOrNamespaceContents` / `Tycon` / `Val` / `CheckedImplFile` / `TopAttribs` / `ILPlatform` — TAST / `CheckDeclarations` / `AbstractIL.IL` types.

**Significant notes**
- The contract deliberately exposes *only* the three hash entry points; all the per-tycon/per-member
  hashing logic (record fields, union cases, delegate slots, IL types, abbreviations, exceptions, provided
  types) is implementation detail in `SignatureHash.fs` (the `TyconDefinitionHash` module).
- Hashes are structural: dependents' recompilation is triggered by any change to the *visible* surface
  (names, order-sensitive case/delegate structure, member shapes), while accessibility-invisible changes
  are neutralized by the observer check.

**Cross-references**
- `SignatureHash.fs` — implementation (module `TyconDefinitionHash` and the three top-level functions).
- `CheckDeclarations.fsi` (sibling) — `HashTastMemberOrVals` (value/member hashing) and `TopAttribs`.
- `Utilities/TypeHashing` (sibling dir) — `ObserverVisibility`, hashing combinators.
- `SignatureConformance.fsi` — complementary: conformance checking vs. signature change detection.

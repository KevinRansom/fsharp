# ilmorph.fsi

**Purpose**
Interface contract for the IL-morphism (rewrite) module. Declares the public morphing primitives: `morphILScopeRefsInILTypeRef`, `morphILTypeRefsInILType`, the memoized whole-module morphs `morphILTypeRefsInILModuleMemoized` / `morphILScopeRefsInILModuleMemoized`, the instruction-stream morph `morphILInstrsInILCode`, and the enable/disable functions for custom-attribute-data morphing.

**Namespace(s)**
- `FSharp.Compiler.AbstractIL` (module `internal FSharp.Compiler.AbstractIL.Morphs`)

**Public API surface**
- `morphILScopeRefsInILTypeRef: (ILScopeRef -> ILScopeRef) -> ILTypeRef -> ILTypeRef` — rewrite each scope ref inside a type ref.
- `morphILTypeRefsInILType: (ILTypeRef -> ILTypeRef) -> ILType -> ILType` — rewrite each type ref inside a type.
- `morphILTypeRefsInILModuleMemoized: (string -> bool) -> (ILTypeRef -> ILTypeRef) -> ILModuleDef -> ILModuleDef` — rewrite all type refs throughout a module (with memoization across the pass; the `string -> bool` flag is the "is known set" predicate).
- `morphILScopeRefsInILModuleMemoized: (string -> bool) -> (ILScopeRef -> ILScopeRef) -> ILModuleDef -> ILModuleDef` — rewrite all scope refs throughout a module (with memoization).
- `morphILInstrsInILCode: (ILInstr -> ILInstr list) -> ILCode -> ILCode` — replace instructions with lists of instructions (e.g. lowering / inline).
- `enableMorphCustomAttributeData` / `disableMorphCustomAttributeData` — toggle the global that, when on, makes the morphs also re-encode custom-attribute payload data rather than just the attribute's method reference.

**Cross-references**
- `ilmorph.fs` (implementation), `il.fs` (ILType, ILTypeRef, ILScopeRef, ILModuleDef, ILCode, ILInstr)

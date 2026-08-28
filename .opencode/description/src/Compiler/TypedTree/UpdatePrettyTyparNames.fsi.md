# UpdatePrettyTyparNames.fsi

**Purpose**: Contract for the internal module that pretty-names type parameters of `Val`s found in signature data. Pretty naming happens for implementation file contents automatically, but not for signature data; this module exposes one helper to traverse the `ModuleOrNamespaceType` and update all typars of each found `Val`.

**Namespace(s)**: `FSharp.Compiler` — `module internal FSharp.Compiler.UpdatePrettyTyparNames`.

**Open**: `FSharp.Compiler.TypedTree`.

**Public API surface**:
- `val updateModuleOrNamespaceType: signatureData: ModuleOrNamespaceType -> unit`

**Notes**: The `TypedTreeOps` dependency present in the `.fs` is implementation-only and not part of the signature.

**Cross-references**: `UpdatePrettyTyparNames.fs` (implementation), `TypedTree.fs` (`ModuleOrNamespaceType`, `Val`).

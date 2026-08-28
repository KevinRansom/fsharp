# UpdatePrettyTyparNames.fs

**Purpose**: Ensures the type parameters of `Val`s in signature data (`.fsi` compilation results) get pretty typar names. Pretty naming happens automatically for implementation file contents, but not for signature data; this module provides helpers that traverse a `ModuleOrNamespaceType` and update all typars of every `Val` found.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.UpdatePrettyTyparNames`).

**Open dependencies**: `FSharp.Compiler.TypedTree`, `FSharp.Compiler.TypedTreeOps`, `FSharp.Compiler.Syntax.PrettyNaming` (via `PrettyTypes`).

**Declared values**:
- `updateVal: Val -> unit` (implementation detail, not in .fsi) — if the Val has typars, computes `PrettyTypes.PrettyTyparNames (fun _ -> true) List.empty v.Typars` and assigns them with `PrettyTypes.AssignPrettyTyparNames`.
- `updateEntity: Entity -> unit` (recursive) — recurses over `entity.ModuleOrNamespaceType.AllEntities` and applies `updateVal` to `AllValsAndMembers`.
- `updateModuleOrNamespaceType: ModuleOrNamespaceType -> unit` — public entry point; iterates `ModuleAndNamespaceDefinitions`.

**Public API surface** (per .fsi): only `val updateModuleOrNamespaceType: signatureData: ModuleOrNamespaceType -> unit`.

**Significant internal logic**: Simple recursive traversal of the entity/namespace tree; each `Val` with non-empty `Typars` is pretty-named using the all-`true` filter (include every typar).

**Cross-references**: `TypedTree.fs` (`Val`, `Entity`, `ModuleOrNamespaceType`), `TypedTreeOps` (`prettyNames` context), `Syntax/PrettyNaming.fs` (`PrettyTyparNames`, `AssignPrettyTyparNames`); invoked on signature data after checking (e.g. from `Checker.fs`/`AssemblyLoader` path).

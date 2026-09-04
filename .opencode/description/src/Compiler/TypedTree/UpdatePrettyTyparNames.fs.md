# UpdatePrettyTyparNames.fs

## Pipeline role

This file belongs to the TypedTree folder of the F# compiler. It is a tiny internal helper module used while creating signature data: the typars of `Val`s stored in signature data should also be "pretty named" (given their short, readable names), which already happens for implementation-file contents but not for signature data. This module walks a `ModuleOrNamespaceType` (the signature data) and pretty-names the typars of every `Val` found, including those nested in entities.

## Module and contents

- `module internal FSharp.Compiler.UpdatePrettyTyparNames` — internal module.
- Opens `FSharp.Compiler.TypedTree` and `FSharp.Compiler.TypedTreeOps`.

### Functions

- `let updateVal (v: Val)` — if `v.Typars` is non-empty, computes pretty names via `PrettyTypes.PrettyTyparNames (fun _ -> true) List.empty v.Typars` and assigns them with `PrettyTypes.AssignPrettyTyparNames v.Typars nms`.
- `let rec updateEntity (entity: Entity)` — recursively updates every entity in `entity.ModuleOrNamespaceType.AllEntities`, then updates every `Val`/member in `entity.ModuleOrNamespaceType.AllValsAndMembers` via `updateVal`.
- `let updateModuleOrNamespaceType (signatureData: ModuleOrNamespaceType)` — iterates `signatureData.ModuleAndNamespaceDefinitions`, calling `updateEntity` on each.

There is no `.fsi` for this module.
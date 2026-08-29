# GenerateILLinkSubstitutions.fs

> Pipeline role: MSBuild task that generates the `ILLink.Substitutions.xml` file listing the F# metadata resources to be **removed** during IL linking (trimming). Removes the `FSharpSignature*`, `FSharpOptimization*`, `FSharpSignatureInfo`, and `FSharpOptimizationInfo` embedded resources so a trimmed app does not carry F# compiler metadata payloads the runtime no longer reads.
> Namespace: `FSharp.Build` (line 17).

---

## `type GenerateILLinkSubstitutions() = inherit Task()`

**Properties** (all xmldoc-commented):

- `AssemblyName: string` (required) — "Assembly name to use when generating resource names to be removed" (`[<Required>]`).
- `IntermediateOutputPath: string` (required) — "Intermediate output path for storing the generated file".
- `GeneratedItems: ITaskItem[]` (`[<Output>]`) — "Generated embedded resource items", a single `TaskItem` for `ILLink.Substitutions.xml`.

**`Execute()`** (line 35):

- Builds `resourcePrefixes` — the set:
  - `FSharpSignature{Compressed}{Data,DataB}` (4 variants),
  - `FSharpOptimization{Compressed}{Data,DataB}` (4 variants),
  - `FSharpOptimizationInfo`, `FSharpSignatureInfo` (14 prefixes total).
- Emits XML:

```xml
<?xml version="1.0" encoding="utf-8"?>
<linker>
  <assembly fullname="{AssemblyName}">
    <resource name="{prefix}.{AssemblyName}" action="remove"></resource>
  </assembly>
</linker>
```

- Writes to `Path.Combine(IntermediateOutputPath, "ILLink.Substitutions.xml")`, creating the directory as needed; sets `LogicalName` metadata on the produced `TaskItem` and returns `true`.

---

## Related

- Wired into the F# `.NET` trimming targets (`Microsoft.FSharp.Targets`/`FSharp.NET.Sdk`) for `PublishTrimmed` scenarios; consumes the resource names produced by `FSharpSignatureData`/`FSharpOptimizationData` in-fill (`fsc`) metadata emission.
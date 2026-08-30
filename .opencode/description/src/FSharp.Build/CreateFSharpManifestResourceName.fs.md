# CreateFSharpManifestResourceName.fs

> Pipeline role: MSBuild task deriving F# resource (manifest resource) names for `@(EmbeddedResource)` items the way F# expects — mostly delegating to `CreateCSharpManifestResourceName` but with a toggle for "standard" (C#-style, root-namespace + folder path) names.
> Namespace: `FSharp.Build` (line 3).

---

## `type CreateFSharpManifestResourceName public () = inherit CreateCSharpManifestResourceName()`

- `member val UseStandardResourceNames = false with get, set` — when true, resource names are generated exactly as C# does (with `RootNamespace` and folder names — the doc-XML comment on the property says exactly that); when false, the default F# behavior (C#-style is applied) — effectively this task is a marker task so F# projects can opt into legacy C#-compatible names.
- `override _.IsSourceFile(fileName: string)` — files of type `.fs`, `.fsx`, `.fsi` (and source-linked extensions) are treated as source; the base `CreateCSharpManifestResourceName` uses this to decide which inputs pass through unchanged vs. get the root-namespace treatment.
- `CreateManifestNameCore`-style overrides map the `LogicalName`/`DependentUpon` metadata into the final resource name using the `rootNamespace` argument and the source-file folde path.

---

## Related

- Builds on `Microsoft.Build.Tasks.CreateCSharpManifestResourceName`; used by the F# core targets (`Microsoft.FSharp.Targets`) for the default F# manifest-name strategy.
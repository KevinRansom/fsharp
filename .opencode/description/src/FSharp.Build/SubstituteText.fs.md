# SubstituteText.fs

> Pipeline role: MSBuild helper task that rewrites text files during build — copies an embedded-resource-shaped file to the intermediate/resources directory and performs simple `Pattern1/Replacement1`→`Pattern2/Replacement2` textual substitutions, producing `CopiedFiles` for the build graph (used to rewrite FSharp.Core resource `.txt` inputs or provider `.fsi` template text such as `ILLink` input).
> Namespace: `FSharp.Build` (line 2).

---

## `type SubstituteText() = inherit Task()`

State: `copiedFiles = ResizeArray<ITaskItem>()`, `embeddedResources: ITaskItem[]`.

**Inputs/outputs**: `EmbeddedResources: ITaskItem[]` (items with `FullPath`/`Identity` metadata), `CopiedFiles: ITaskItem[]` (`CopiedFiles = copiedFiles.ToArray()`).

**`Execute()`** (line ~30) — per embedded resource item:

- `sourcePath = item.GetMetadata("FullPath")`.
- If the item carries additional metadata (`SourceLib`-ish `Identity`, `IntermediateTargetPath`) it computes a target name:
  - `getTargetPathFrom "Identity"` → `Path.Combine(Path.GetDirectoryName(identity), @"..\resources", fileName)` (drop the item into a sibling `resources` folder);
  - else `target = Path.Combine(intermediateTargetPath, fileName)`.
- Reads `File.ReadAllText(sourcePath)`, then does the `Pattern1/Replacement1`/`Pattern2/Replacement2` substitutions over the content; writes the result to `target`; records a `TaskItem` in `CopiedFiles` with the source → target mapping.
- Returns `true` when all copies succeed.

---

## Related

- Used in `FSharp.Core`'s build to transpile resource/`fsi` templates containing file-path tokens and in provider SDK targets. Sibling tasks: `SubstituteText` runs before `FSharpEmbedResourceText` in the chain.
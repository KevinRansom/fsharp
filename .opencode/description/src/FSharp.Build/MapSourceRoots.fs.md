# MapSourceRoots.fs

> Pipeline role: MSBuild task (a port of Roslyn's `MapSourceRoots`) that maps `SourceRoot` items into paths suitable for deterministic PDB **Source Link** — it assigns each source root a `MappedPath` (the same path when `Deterministic=false`, else a path relative to the containing root), validates well-known metadata (`SourceControl`, `NestedRoot`, `ContainingRoot`, `RevisionId`, `SourceLinkUrl`), and (in later `-targets` integration) feeds `--pathmap`. File header: "Copied from msbuild. ItemSpecs are normalized using this method."
> Namespace: `FSharp.Build` (line 2).

---

## `module Utilities` — file/path helpers

- `FixFilePath (path: string)` — normalizes directory separators for the platform.
- The module mirrors Roslyn's path handling so F# and Roslyn deterministic builds produce identical SourceLink paths.

---

## `type MapSourceRoots() = inherit Task()`

**Well-known metadata names** (`static let`): `MappedPath`, `SourceControl`, `NestedRoot`, `ContainingRoot`, `RevisionId`, `SourceLinkUrl`; `knownMetadataNames` = the set used for validation.

**Helpers**:

- `(|NullOrEmpty|HasValue|)` active pattern for `string | null`.
- `ensureEndsWithSlash`, `endsWithDirectorySeparator`.
- `reportConflictingWellKnownMetadata (log) (l) (r)` — warns when the same well-known metadata is set to different values on `ContainingRoot` and its `NestedRoot`s.

**`static member PerformMapping (log: TaskLoggingHelper) (sourceRoots: ITaskItem[]) deterministic`** (line ~90):

- Groups roots by `ContainingRoot`, enforcing that each `NestedRoot`'s `ContainingRoot` is itself a source root; computes `MappedPath`:
  - **Deterministic=false**: `MappedPath = ItemSpec` (identity) — every root stays where it is.
  - **Deterministic=true**: the *containing root's `ContainingRoot` (or itself)* becomes the base and nested roots get paths relative to it (e.g. `src/project` with `ContainingRoot=<repo root>` maps to a relative location). Applies `ensureEndsWithSlash` semantics and drops path garbage (`..`).
- Writes `MappedPath` metadata back onto each `SourceRoot` item; reports `MapSourceRootsInvalidPath`-style errors for malformed combos (task fails when a `ContainingRoot` refers to a non-root item).
- Public `SourceRoots` (`[<Required>]`) input, `Deterministic` bool input, `Execute()` orchestrator.

---

## Related

- Ported from Roslyn (`src/Compilers/Core/Portable/Iteration/MapSourceRoots.cs`); consumed by `FSharp.Targets` SourceLink targets; output feeds the compiler's `--pathmap`/PDB embedded-source data.
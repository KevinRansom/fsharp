# SemanticClassificationKey.fsi

**Purpose**: Internal/public contract for `SemanticClassificationKey.fs`. Declares the public `SemanticClassificationView` (a read-only iterator over stored semantic-classification items) plus the internal store and builder that back it in a memory-mapped file.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## TypeDefs / Classes declared

- **`SemanticClassificationView`** (sealed, public)
  - `member ForEach: (SemanticClassificationItem -> unit) -> unit` — iterates every stored `SemanticClassificationItem` and applies the function.
- **`SemanticClassificationKeyStore`** (sealed, `internal`)
  - `interface IDisposable`
  - `member GetView: unit -> SemanticClassificationView` — get a read-only view over the store's contents.
- **`SemanticClassificationKeyStoreBuilder`** (sealed, `internal`)
  - `new: unit -> SemanticClassificationKeyStoreBuilder`
  - `member WriteAll: SemanticClassificationItem[] -> unit` — write a whole array of items.
  - `member TryBuildAndReset: unit -> SemanticClassificationKeyStore option` — finalize into a store (or `None`) and reset.

## Public API surface

- Only `SemanticClassificationView.ForEach`; `SemanticClassificationItem` itself is declared elsewhere (`SemanticClassification.fsi`).
- Store/builder are internal — the store is created by the background compiler and a view handed to the caller (see `FSharpChecker.GetBackgroundSemanticClassificationForFile`, which returns `SemanticClassificationView option`).

## Internal helpers / active patterns

- None exposed; implementation details (mmf ownership, `BlobReader` walking, pinning the item array) live in the `.fs`.

## Significant internal logic

- The fsi documents the store as holding a list of "semantic classification key strings and their ranges"; in practice (per the .fs) the payload is a packed sequence of fixed-size `SemanticClassificationItem` structs in a `MemoryMappedFile`.
- `TryBuildAndReset` returning `option` lets callers distinguish "no classification data produced" from an error, matching the `GetSemanticClassificationForFile ... option` shape in `BackgroundCompiler.fsi`.

## Cross-references

- `SemanticClassificationItem` / `SemanticClassificationType` — `SemanticClassification.fs`/`.fsi`.
- Consumed by `service.fsi` (`FSharpChecker.GetBackgroundSemanticClassificationForFile`) and `FSharpWorkspaceQuery.fs` (`GetSemanticClassification`).
- Sibling design to `ItemKey.fsi` (`ItemKeyStore`/`ItemKeyStoreBuilder`).

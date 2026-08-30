# SemanticClassificationKey.fs

**Purpose**: Stores per-file semantic classification items (text range + `SemanticClassificationType`) in a memory-mapped file so that the background compiler can publish classification results without copying them into the foreground. Provides a read-only `SemanticClassificationView` for iteration and a builder that serializes a `SemanticClassificationItem[]` into the store.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## TypeDefs / Classes declared

- **`SemanticClassificationView`** (sealed class) — read-only iteration over stored items.
  - `ReadItem(reader: byref<BlobReader>)` — binary-reads one fixed-size `SemanticClassificationItem` (cast from a byte buffer via `MemoryMarshal.Cast`).
  - `ForEach(f: SemanticClassificationItem -> unit)` — opens a view accessor on the `MemoryMappedFile` and walks all stored items in order.
- **`SemanticClassificationKeyStore`** (sealed class, `internal`) — owns the `MemoryMappedFile`; `GetView() : SemanticClassificationView`; `interface IDisposable` (disposes the mmf, checks `ObjectDisposedException`).
- **`SemanticClassificationKeyStoreBuilder`** (sealed class, `internal`) — `WriteAll(semanticClassification: SemanticClassificationItem[])` writes the whole pinned array in one blob (`sizeof<SemanticClassificationItem>` per item); `TryBuildAndReset()` flushes into an anonymous `MemoryMappedFile` via `BlobBuilder` and returns an `SemanticClassificationKeyStore` (or `None` if empty), clearing the builder.

## Public API surface

- `SemanticClassificationView.ForEach` is the only public member; the store and builder are `internal` per the fsi.

## Internal helpers / active patterns

- `BlobReader`/`BlobBuilder` (from `System.Reflection.Metadata`) plus `System.MemoryMappedFiles` for the shared-memory transport.
- `#nowarn "9"` to suppress warning 9 in this file.

## Significant internal logic

- `SemanticClassificationItem` is a fixed-size struct (a `range` + an enum), so the store layout is a simple sequence of packed items with no length prefixes — unlike `ItemKeyStore`, where keys are variable-length strings.
- `WriteAll` pins the array (`fixed`) and copies the raw bytes in one `WriteBytes` call for speed.
- `TryBuildAndReset` uses `MemoryMappedFile.CreateNew` (no file name) so the payload lives purely in memory but can still be memory-mapped/shared; the builder clears itself for subsequent files.
- Disposal semantics mirror `ItemKeyStore`: the store is the sole owner of the `MemoryMappedFile` handle.

## Cross-references

- `SemanticClassificationItem`/`SemanticClassificationType` are declared in `SemanticClassification.fs`.
- The store is populated by the background type-check pipeline (see `BackgroundCompiler.fs` `GetSemanticClassificationForFile`) and consumed by `FSharpChecker.GetBackgroundSemanticClassificationForFile` (see `service.fsi`) and `FSharpWorkspaceQuery.GetSemanticClassification` (see `FSharpWorkspaceQuery.fs`).
- Structurally parallel to `ItemKey.fs` (`ItemKeyStore`/`ItemKeyStoreBuilder`).

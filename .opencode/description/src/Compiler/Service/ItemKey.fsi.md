# ItemKey.fsi

**Purpose**: Internal contract for `ItemKey.fs`. Exposes to the rest of the service only two sealed types — the binary store of item-key/range pairs (`ItemKeyStore`) and the builder that writes into it (`ItemKeyStoreBuilder`) — so that "find all references of a given `Item`" can be performed over a shared memory-mapped file without copying data.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## TypeDefs / Classes / Structs declared

- **`ItemKeyStore`** (sealed, `internal`) — a read-side handle over a `MemoryMappedFile`; `interface IDisposable`.
  - `member FindAll: Item -> seq<range>` — given an `Item`, return every stored text range whose encoded key matches.
- **`ItemKeyStoreBuilder`** (sealed, `internal`) — a write-side handle.
  - `new: TcGlobals -> ItemKeyStoreBuilder` — needs the `TcGlobals` to decode/encode the `Item`'s types.
  - `member Write: range * Item -> unit` — append one `(range, Item)` pair to the buffer.
  - `member TryBuildAndReset: unit -> ItemKeyStore option` — finalize the buffered contents into a fresh memory-mapped `ItemKeyStore` (or `None` if nothing was written), and reset the builder for reuse.

## Public API surface

- Nothing — the fsi marks both types `internal`. The only consumers are other modules in the service (notably the background compiler and the semantic-classification pipeline).

## Internal helpers / active patterns

- None re-exported; the encoding helpers (`writeType`, `writeValRef`, `writeILType`, `writeActivePatternCase`, the `ItemKeyTags` literals, and the `DebugKeyStore`/`_DebugKeyStoreNoop` pair) are all implementation details of the `.fs`.

## Significant internal logic

- The fsi is deliberately minimal: it hides the whole tag-string/structural encoding scheme and the debug-key-store infrastructure, leaving only the "build a store / query a store" surface.
- `ItemKeyStoreBuilder` requiring `TcGlobals` in its constructor reflects that key construction must be able to inspect the typed structure of `Item` values.
- The `MemoryMappedFile`-backed design implies the store is meant to be shared (e.g., between the background checking thread and the foreground query), hence the `IDisposable` on the store but not on the builder.

## Cross-references

- Implements the backing store for "find all references of a symbol" used by `FSharpChecker.FindBackgroundReferencesInFile` (see `service.fsi`) and by `FSharpWorkspaceQuery` (see `FSharpWorkspaceQuery.fs`).
- See `SemanticClassificationKey.fs`/`.fsi` for the closely related store of semantic-classification items.
- Depends on `FSharp.Compiler.NameResolution.Item`, `FSharp.Compiler.Text.range`, `FSharp.Compiler.TcGlobals.TcGlobals`.

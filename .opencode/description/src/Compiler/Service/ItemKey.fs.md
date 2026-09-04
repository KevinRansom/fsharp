# ItemKey.fs

**Purpose**: Implements a compact, collision-resistant binary "item key" encoding of compiler `Item` values (values, types, union cases, record fields, etc.) so that the same symbol used at different text locations can be matched for "find all references". The encoded keys are stored in a memory-mapped file, letting the background compiler share them with the foreground without copying large F# data structures.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## TypeDefs / Unions / Structs / Modules declared

- **`type ItemKeyStore`** (sealed class, internal) — read side: owns a `MemoryMappedFile`, exposes `FindAll(item: Item) : range seq` which scans the stored (range, key-string) pairs and returns all ranges whose key string equals the freshly built key for `item` (applying `#line` directives for generated code, see #9928). Also `interface IDisposable`.
- **`type ItemKeyStoreBuilder`** (sealed class, internal) — write side: serializes one `(range, Item)` pair into a `BlobBuilder` using tag strings + structural encodings of types, val refs, IL types, typars, measures; `TryBuildAndReset()` flushes into a fresh anonymous `MemoryMappedFile` and returns an `ItemKeyStore` (or `None` when nothing was written).
- **`module ItemKeyTags`** — the literal tag strings used to disambiguate structurally similar items: `#E#` entityRef, `#T#` tuple, `#F#` function, `#U#` union case, `m$`/`v$`/`u$`/`r$`/`d$`/`a$`/`n$`/`l$`/`t$`/`p$`/`T$`/`y$`/`o$`/`g$` item kinds, `p$p$` parameters, measure tags, etc.
- **`module DebugKeyStore`** — `[<AutoOpen>]` debugging aid: `DebugKeyStore` (records every write as a human-readable list) and `_DebugKeyStoreNoop` (all members `inline` no-ops, returned by `DebugKeyStoreNoop`); the builder currently uses the noop variant and the comment explains how to swap in the real one.

## Public API surface

- None — the fsi marks both `ItemKeyStore` and `ItemKeyStoreBuilder` as `internal`; only `FindAll` and `Write`/`TryBuildAndReset` matter to callers inside the service.

## Internal helpers / active patterns

- `writeILType`, `writeType`, `writeMeasure`, `writeTypar`, `writeValRef`, `writeValue`, `writeActivePatternCase` — recursive structural encoders (see below).
- `DebugKeyStore.WriteRange/WriteEntityRef/WriteType/...` — parallel debug logging mirroring every write.
- `BlobReader`/`BlobBuilder` + `MemoryMappedFile` — cross-process-safe binary blob plumbing (from `System.IO.MemoryMappedFiles`, `System.Reflection.Metadata`).

## Significant internal logic

- **Key = tag string + structural payload.** Each `Item` kind is prefixed by a unique tag (e.g. `m$` for a member value, `v$` for a plain value) so that, e.g., a record field and a union case of the same name cannot collide.
- **`writeType`** strips `forall`s and type abbreviations (when not standalone), then encodes tuples/anon records/functions/measure/typar/union-case references; a standalone typar writes its `Stamp` (int64) — this is how type variables are matched across use sites.
- **`writeValRef`** distinguishes members (`m$` + enclosing entity + logical name + parameters + type, skipping the `this` type for instance members since it differs between a definition and an override) from plain values (`v$` + name + params + type + optional deref display range + declaring entity).
- **`writeValue`** special-cases property getters/setters → `p$` + property name + declaring entity.
- **`writeActivePatternCase`** encodes the AP's source file (name without extension) + all tags + case index — disambiguates active-pattern cases with the same arity.
- **`TryBuildAndReset`** uses `MemoryMappedFile.CreateNew` with a `BlobBuilder` so the key can be handed to a read side without serialization cost; the builder resets itself for the next item.
- **`FindAll`** rebuilds the item's key with the same builder, then linearly scans the mmf comparing key strings — linear but cheap since the mmf is page-cached.

## Cross-references

- `BlobBuilder`/`BlobReader` and `MemoryMappedFile` come from `System.IO.MemoryMappedFiles` / `System.Reflection.Metadata` (shared with `SemanticClassificationKey.fs`).
- `Item`/`ValRef`/`TType`/`Typar`/`Measure`/`EntityRef` come from `FSharp.Compiler.NameResolution`, `FSharp.Compiler.TcGlobals`, `FSharp.Compiler.TypedTree`.
- Used by `FSharpChecker.GetBackgroundSemanticClassificationForFile` and the background find-references paths (see `BackgroundCompiler.fs`, `SemanticClassificationKey.fs`, `FSharpWorkspaceQuery.fs`).
- `DebugKeyStore` pairs conceptually with `FSharpChecker`'s diagnostics plumbing (see `service.fs`).

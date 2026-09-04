# FSharpSource.fs

**Purpose**: Defines `FSharpSource`, the abstract storage container for an F# source item that may be on-disk or in-memory, plus private concrete implementations (from file, memory-mapped/copy, byte array, custom callback). Used by the incremental build pipeline to fetch file contents without each caller knowing how the content is stored.

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## Types declared

- **`TextContainer`** (union, internal, `RequireQualifiedAccess`) — `OnDisk`, `Stream of Stream`, `SourceText of ISourceText`; implements `IDisposable` (only the `Stream` case disposes).
- **`FSharpSource`** (abstract class, internal) — `FilePath: string`, `TimeStamp: DateTime`, `GetTextContainer: unit -> Async<TextContainer>`.
- **`FSharpSourceMemoryMappedFile`** (private) — wraps a deferred `openStream()` factory; `GetTextContainer` returns `TextContainer.Stream`.
- **`FSharpSourceByteArray`** (private) — holds a `byte[]` exposed as a non-writable `MemoryStream`.
- **`FSharpSourceFromFile`** (private) — `TimeStamp` from `FileSystem.GetLastWriteTimeShim`; `GetTextContainer` → `TextContainer.OnDisk`.
- **`FSharpSourceCustom`** (private) — custom `getTimeStamp` and async `getSourceText: unit -> Async<ISourceText option>`; falls back to `OnDisk` when the custom source yields `None`.

## Public API surface

- `FSharpSource.Create(filePath, getTimeStamp, getSourceText)` — custom in-memory source.
- `FSharpSource.CreateCopyFromFile(filePath)` — shadow-copy open via `FileSystem.OpenFileForReadShim(useMemoryMappedFile = true, shouldShadowCopy = true)`.
- (`CreateFromFile` exists in the `.fs` but is internal per the fsi.)

## Internal helpers

- `FileSystem.GetLastWriteTimeShim` / `OpenFileForReadShim` (from `FSharp.Compiler.IO`) for portable timestamp/shadow-copy reads.

## Significant internal logic

- The abstraction separates "when does my file change?" (`TimeStamp`) from "how do I read it?" (`GetTextContainer`), letting the build graph decide staleness while the reader decides disk vs memory.
- `CreateCopyFromFile` captures the timestamp eagerly (before the stream is opened) so the staleness check is stable against later file edits.

## Cross-references

- Consumed by `IncrementalBuild.fs` (`FSharpFile` record has a `Source: FSharpSource` field) to read file content during builds.
- Internal contract in `FSharpSource.fsi`.
- Related (newer) source model: `FSharpFileSnapshot` in `FSharpProjectSnapshot.fs` and `DocumentSource` in `FSharpCheckerResults.fs`.

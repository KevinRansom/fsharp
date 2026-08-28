# FSharpSource.fsi

**Purpose**: Internal contract for `FSharpSource.fs` — the storage container abstraction for an F# source item that can be either on-disk or in-memory, plus the `TextContainer` discriminating how the text is actually materialized. (The file contains a TODO to make `FSharpSource` public.)

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis`

## Types declared

- **`TextContainer`** (union, internal, `RequireQualifiedAccess`) — `OnDisk`, `Stream of Stream`, `SourceText of ISourceText`; `interface IDisposable`.
- **`FSharpSource`** (abstract class, internal)
  - `abstract FilePath: string`
  - `abstract TimeStamp: DateTime`
  - `abstract GetTextContainer: unit -> Async<TextContainer>` — text may be on-disk, in a stream, or a source text.
  - `static member internal CreateFromFile: filePath -> FSharpSource` — "only used internally".
  - `static member CreateCopyFromFile: filePath -> FSharpSource` — creates a `FSharpSource` by shadow-copying the file.
  - `static member Create: filePath * getTimeStamp * getSourceText -> FSharpSource` — custom source with async text provider.

## Public API surface

- None — both types are `internal` in this fsi; consumers are other modules in the service (notably `IncrementalBuild.fs`).

## Internal helpers / active patterns

- None declared here; `IDisposable` on `TextContainer` is the only interface obligation (to release stream-backed containers).

## Significant internal logic

- The fsi fixes the three-way distinction (disk / stream / in-memory text) and the async accessor signature, which lets callers unify disk and editor-buffered documents without checking `FSharpChecker` configuration.
- `CreateCopyFromFile` documents shadow-copying semantics at the contract level (file can be locked/replaced by the compiler output while being read).

## Cross-references

- Implemented in `FSharpSource.fs` (four private subclasses).
- Used by `IncrementalBuild.fs` for `FSharpFile.Source`.
- Contrast with the newer `FSharpFileSnapshot` (in `FSharpProjectSnapshot.fs`) and `DocumentSource` (`FSharpCheckerResults.fsi`).

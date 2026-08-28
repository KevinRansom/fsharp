# FSharpProjectSnapshot.fs

**Purpose**: Defines the immutable project-snapshot data model used by the workspace/transparent-compiler path: an `FSharpProjectSnapshot` is a fully-specified, hash-versioned, immutable description of a project (config + referenced projects + source file snapshots) that can be checked repeatedly without ambiguity, and is shared across cache layers (`ParsingVersion`, `SignatureVersion`, `FullVersion`, per-file keys).

**Namespace(s)**: `FSharp.Compiler.CodeAnalysis.ProjectSnapshot`

## Types declared

- **`ProjectIdentifier`** (internal typedef) — `string * string` (project file, output file).
- **`IFileSnapshot`** (internal interface) — `FileName`, `Version: byte array`, `IsSignatureFile`; the common denominator for file snapshots at all compilation stages.
- **`module Helpers`** (internal, AutoOpen) — `isSignatureFile` (filename ends with `i`), `addFileName(AndVersion)` MD5 hash additions, `signatureHash` (hash over the public surface: signature files by name+version, otherwise the impl file, tracking the last file), `findOutputFileName` (`-o:` argv scan).
- **`FSharpFileSnapshot`** (experimental, public) — a lazy source file snapshot: `Create`, `CreateFromString` (MD5 of content as version), `CreateFromFileSystem` (last-write-time ticks as version), `CreateFromDocumentSource`; members `FileName`, `Version`, `GetSource: unit -> Task<ISourceTextNew>`, `IsSignatureFile`; `Equals`/`GetHashCode` on (FileName, Version); implements `IFileSnapshot`.
- **`FSharpFileSnapshotWithSource`** (internal) — snapshot with loaded `ISourceTextNew`; version = hash of source.
- **`FSharpParsedFile`** (internal) — snapshot with `ParsedInput` + parse diagnostics; version = syntax tree hash.
- **`ReferenceOnDisk`** (experimental, record) — `{ Path; LastModified }`.
- **`ProjectSnapshotBase<'T when 'T :> IFileSnapshot>`** (internal) — the core: `projectConfig * referencedProjects + 'T list sourceFiles`. Computes (lazily) `baseVersion`, `noFileVersionsHash`, `fullHash`, `signatureHash`/`lastFileHash` and matching `ICacheKey`s (`noFileVersionsKey`, `fullKey`, `signatureKey`, `lastFileKey`, `BaseCacheKeyWith`). Members: all the flat project properties, `SourceFiles`, `SourceFileNames`, `IndexOf`, `Replace(changed)`, `UpTo(index|file)`, `OnlyWith(indexes)`, `GetLastModifiedTimeOnDisk` (skips `.AssemblyInfo.fs`/`.AssemblyAttributes.fs`), version/key accessors (`FullVersion`, `SignatureVersion`, `LastFileVersion`, `ParsingVersion`, `NoFileVersionsKey`, `FullKey`, `SignatureKey`, `LastFileKey`, `FileKey`, `FileKeyWithExtraFileSnapshotVersion`).
- **`ProjectSnapshot`** — `ProjectSnapshotBase<FSharpFileSnapshot>`; **`ProjectSnapshotWithSources`** — with loaded sources.
- **`ProjectConfig`** (experimental, public data) — project info without files/referenced-project snapshots; lazily computes `hashForParsing`, `fullHash` (refs + last-modified), `commandLineOptions` (reconstructs `-r:` args), `outputFileNameValue`, `Identifier` (→ `FSharpProjectIdentifier`); `With(newReferencesOnDisk)` copy.
- **`FSharpReferencedProjectSnapshot`** (experimental, union) — `FSharpReference of output * snapshot`, `PEReference of getStamp * DelayedILModuleReader`, `ILModuleReference of output * getStamp * getReader`; `CreateFSharp`, `Version` (signature version or stamp hash), custom `Equals`/`GetHashCode`.
- **`FSharpProjectIdentifier`** (experimental) — `projectFileName * outputFileName`; `OutputFileName`, `ProjectFileName`, friendly `ToString` with `🡒`.
- **`FSharpProjectSnapshot`** (experimental, public wrapper) — `Create(...)` (13-arg), `FromOptions(options, getFileSnapshot, ?snapshotAccumulator)` (recursive, memoized per options; parallel source-load via `MultipleDiagnosticsLoggers.Parallel`), `FromOptions(options, documentSource)`, `FromOptions(options, fileName, fileVersion, sourceText, documentSource)` (inline source for one file), `FromResponseFile(responseFile, projectFileName)`, `FromCommandLineArgs(compilerArgs, directoryPath, projectFileName)` (splits `.fs/.fsi/.fsx` files, `-r:` refs, other options); forwards all `ProjectSnapshotBase` members; `Replace`.
- Internal: `snapshotTable: ConditionalWeakTable<ProjectSnapshot, FSharpProjectOptions>`, `snapshotToOptions`, `Extensions` (`ToOptions` on both snapshot kinds, `GetProjectIdentifier`).

## Public API surface

- `FSharpFileSnapshot` family of ctors + members, `ReferenceOnDisk`, `ProjectConfig`, `FSharpReferencedProjectSnapshot` (+ `CreateFSharp`), `FSharpProjectIdentifier`, and `FSharpProjectSnapshot` with its `Create`/`From*` constructors and member forwards.
- Versioning surface: `ParsingVersion`, `SignatureVersion`/`FullVersion`/`LastFileVersion`, `NoFileVersionsKey`/`FullKey`/`SignatureKey`/`LastFileKey`/`FileKey` — these are what caches (notably `TransparentCompiler`'s `CompilerCaches`) key on.

## Internal helpers / active patterns

- Lazily-evaluated MD5 hash chains; `ICacheKey` implementations for each layer of caching.
- `Md5Hasher` (from `Internal.Utilities.Hashing`), `MultipleDiagnosticsLoggers` for parallel snapshot construction.
- `snapshotTable`/`snapshotToOptions` — bridge back to legacy `FSharpProjectOptions` for code paths that still need them.

## Significant internal logic

- **Versioning scheme**: `baseVersion` hashes config + referenced projects; `fullHash` adds each file's name+version; `signatureHash` models each impl file by its signature file when present (public surface), falling back to the impl file and remembering the "last file". This gives fine-grained invalidation: in-file edits only bump `LastFileVersion`/`FileKey`, signature changes bump `SignatureVersion`, reference changes bump everything.
- `UpTo`/`OnlyWith` produce prefix/restricted snapshots — the mechanism by which "check file N" is well-defined and cacheable.
- `FromOptions` is recursive over `ReferencedProjects`, memoized in a shared `snapshotAccumulator` dictionary keyed by options (avoids re-loading shared transitive projects).
- `GetLastModifiedTimeOnDisk` treats generated `AssemblyInfo`/`AssemblyAttributes` files as excluded from the staleness max.

## Cross-references

- The snapshot type is the argument type of the experimental overloads in `service.fsi` (`ParseFile`, `ParseAndCheckFileInProject`, `ParseAndCheckProject`, `TryGetRecentCheckResultsForFile`, `GetBackgroundSemanticClassificationForFile`, `FindBackgroundReferencesInFile`, `InvalidateConfiguration`, `ClearCache`).
- Constructed by `FSharpWorkspaceProjects.AddOrUpdate` (see `FSharpWorkspaceState.fs`).
- Consumed/checked by `TransparentCompiler.fs` and `BackgroundCompiler.fs`; `FSharpReferencedProjectSnapshot` mirrors `FSharpReferencedProject` from `FSharpCheckerResults.fs`.
- `DelayedILModuleReader` comes from `FSharpCheckerResults.fs`.

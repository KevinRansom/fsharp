# range.fs

**Purpose**: Implements the core source-location model of the F# compiler: the `Position` (line/column) and `Range` types, backed by compact 64-bit integer encodings of file index, line, and column. `Range` (aliased `range`) is the fundamental annotation attached to every compiler tree node, and this module also owns the global filename-to-index table, line-directive (`#line`) support, and helpers for zero- vs one-based line counting used by Visual Studio services. It is central to error reporting, diagnostics, and the compiler's public surface via FSharp.Compiler.Service.

**Namespace(s)**: `FSharp.Compiler.Text`

**Modules / Types declared**:

- `type FileIndex = int32` — index into the global filename table.
- `[<AutoOpen>] module PosImpl` — bit-layout constants for the `Position` encoding (`columnBitCount = 22`, `lineBitCount = 31`, masks).
- `type Position(code: int64)` (alias `pos`) — `[<Struct; CustomEquality; NoComparison>]`; a position (1-based line, 1-based column) packed into a single `int64`.
- `[<RequireQualifiedAccess>] type NotedSourceConstruct` — UDT marking which construct a range's debug point relates to in computation expressions (`None`, `While`, `For`, `InOrTo`, `Try`, `Binding`, `Finally`, `With`, `Combine`, `DelayOrQuoteOrRun`).
- `[<AutoOpen>] module RangeImpl` — bit-layout constants/masks/shifts for the packed `Range` (fileIndex, startColumn, endColumn in `code1`; startLine, height, isSynthetic, debugPointKind in `code2`), with `#if DEBUG` asserts validating the layout.
- `type FileIndexTable()` — thread-safe bidirectional map between file names and `FileIndex` (using `ResizeArray` + `ConcurrentDictionary`).
- `[<AutoOpen>] module FileIndex` — exposes global mutable `fileIndexTable` and the well-known dummy file names.
- `[<RequireQualifiedAccess>] module internal LineDirectives` — global store of `#line` directive data per file, used by `ApplyLineDirectives`.
- `type Range(code1: int64, code2: int64)` (alias `range`) — `[<Struct; CustomEquality; NoComparison>]`; the compiler's location type.
- `type Line0` (`int`, or `int<ZeroBasedLineAnnotation>` under `CHECK_LINE0_TYPES`), `type Position01`, `type Range01` — zero-based (VS-oriented) position/range aliases.
- `module Line` — conversions between zero- and one-based line numbers.
- `[<AutoOpen>] module Position` — position constructors, comparisons, output.
- `module Range` — range constructors, orderings, transformations, and misc helpers.

**Public API surface** (significant members):

`Position`: `Line`, `Column` (int, decoded from the packed code), `Encoding` (internal `int64`), `IsAdjacentTo` (internal), `static Decode(code : int64)` (internal), `static EncodingSize`, `new(line, column)`.

`Range`: `StartLine`, `StartColumn`, `EndLine` (startLine + height), `EndColumn`, `Start`, `End`, `StartRange`, `EndRange`, `FileIndex` (internal), `FileName`, `ShortFileName` (internal), `IsSynthetic`, `MakeSynthetic()` (internal), `NotedSourceConstruct`, `NoteSourceConstruct(kind)` (internal), `ApplyLineDirectives()`, `IsAdjacentTo(other)` (internal), `DebugCode` (internal — extracts the actual source substring for the range, or a diagnostic name such as "nonexistent file: ..."), `Code1`/`Code2` (internal), `Equals/GetHashCode` (equality ignores synthetic/debug-kind bits), `static member Zero` (obsolete; use `Range.range0`).

`module Position`: `mkPos line column`, `posLt/posGt/posEq/posGeq`, `fromZ (line:Line0) column`, `toZ`, `outputPos`, `stringOfPos`, `pos0`.

`module Range`: `mkRange filePath startPos endPos`, `mkFileIndexRange`, `equals`, `posOrder` (IComparer<pos> by (line,col)) and `rangeOrder` (IComparer<range> by (file,start,end)), `unionRanges` (allocation-free; preserves NotedSourceConstruct when inputs are identical; returns m2 for cross-file), `withStartEnd/withStart/withEnd`, `shiftStart/shiftEnd`, `rangeContainsRange`, `rangeContainsPos`, `rangeBeforePos`, `rangeN fileName line`, `range0`, `rangeStartup`, `rangeCmdArgs`, `trimRangeToLine`, `stringOfRange`, `toZ`, `toFileZ`, `comparer` (IEqualityComparer), `mkFirstLineOfFile` (reads the file to locate the first non-whitespace line), `setTestSource` (internal; injects test sources).

`module FileIndex`: `fileIndexOfFile`, `fileOfFileIndex`, `unknownFileName` ("unknown"), `startupFileName` ("startup"), `commandLineArgsFileName` ("commandLineArgs"), `testSources` (internal `ConcurrentDictionary`).

**Internal helpers / active patterns**:

- `FileIndexTable.FileToIndex normalize filePath` — lock-protected, normalization-tolerant lookup: tries the raw name, then the normalized one, and back-fills aliases.
- `DebugCode.substring` reading logic (`getRangeSubstring`) uses `FileSystem.OpenFileForReadShim` and string slicing.
- `RangeImpl` mask/shift constants (documented as literals) and `mask64` usage.

**Significant internal logic**:

- **Packed encodings**: `Position` packs column in low 22 bits and line in the next 31 bits of a single `int64`; `Range` uses two `int64`s: `code1` = fileIndex (20 bits) | startColumn (22) | endColumn (22); `code2` = startLine (31) | height = endLine-startLine (27) | isSynthetic (1) | debugPointKind (4). This keeps the compiler's hot data structures compact — every tree node carries one `range` — while `Equals`/`GetHashCode` mask out the synthetic and debug-point bits so those annotations don't affect structural identity.
- **LineDirectives**: `Range.ApplyLineDirectives()` consults the per-file `LineDirectives.store` (a `Map<FileIndex, (int * (FileIndex * int)) list>`) and rewrites start/end lines (and file index) according to the last `#line` directive before the range's start line; used when displaying ranges to users so mapped (e.g. F#-script or generated) files show source-correct positions.
- **File-index table caveat** (documented in-code): names going through `mkRange` are normalized, while `fileIndexOfFile` is not, and a `NormalizedFileName` type is a candidate future cleanup; exceeding the 20-bit max silently wraps (`% maxFileIndex`) with a comment that incorrect file names would then be reported.
- **`mkFirstLineOfFile`**: reads the file, finds the first non-whitespace line (or non-empty line) to produce a "whole line 1" range; falls back to `(1,0)-(1,80)` on any failure.

**Cross-references**: `range.fsi` is the public contract and is part of the public API of FSharp.Compiler.Service. Consumed pervasively by `TypedTree` annotations (`range` fields on syntax/typed trees), diagnostic reporting (`sr.fs` message construction), `illib.fs`, and language-service projections. The `Position01`/`Range01`/`Line0` zero-based types interoperate with Visual Studio services; `FileSystem` shims come from `FSharp.Compiler.IO`; `Internal.Utilities.Library.Extras.Bits` provides `mask64`/`pown32`.

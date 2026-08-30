# range.fsi

**Purpose**: Signature file for `range.fs`. Declares the public contract of the `Position`/`Range` types (and related helpers) in `FSharp.Compiler.Text`. These types form part of the public API of FSharp.Compiler.Service — they are the location annotations surfaced in diagnostics and language-service results, so the .fsi is carefully curated (notably with detailed doc comments for `NotedSourceConstruct` and for the zero-based line-counting conversions used by Visual Studio).

**Namespace(s)**: `FSharp.Compiler.Text`

**Modules / Types declared** (as declared in the signature):

- `type internal FileIndex = int32` — "An index into a global tables of filenames".
- `[<RequireQualifiedAccess>] type internal NotedSourceConstruct` — UDT (`None`, `While`, `For`, `InOrTo`, `Try`, `Binding`, `Finally`, `With`, `Combine`, `DelayOrQuoteOrRun`) with per-case doc comments explaining which computation-expression construct a debug point relates to (e.g. `Combine` covers a sequential `a; b` translated to a Combine call, but not side-effecting simple-statement sequentials; `DelayOrQuoteOrRun` covers the implied entry to a computation expression).
- `type Position` (alias `pos`) — `[<Struct; CustomEquality; NoComparison>]`; `Line`, `Column`, plus internal `Encoding`, `IsAdjacentTo`, `Decode`, `EncodingSize`.
- `type Range` (alias `range`) — `[<Struct; CustomEquality; NoComparison>]`; start/end line/column, `Start`/`End` positions, `StartRange`/`EndRange`, `FileName`, public `ApplyLineDirectives` and `IsSynthetic`, plus internal `FileIndex`, `ShortFileName`, `MakeSynthetic`, `NotedSourceConstruct`, `NoteSourceConstruct`, `IsAdjacentTo`, `DebugCode`; obsolete `static member Zero` ("Use Range.range0 instead").
- `type Line0` — zero-based line number (`int`, or `int<ZeroBasedLineAnnotation>` under `#if CHECK_LINE0_TYPES`), plus `type Position01 = Line0 * int` and `type Range01 = Position01 * Position01`.
- `module Position` — `mkPos`, comparisons (`posLt/posGt/posEq/posGeq`), `fromZ`/`toZ` (VS zero-based <-> F# one-based), `outputPos`, `stringOfPos`, `pos0`.
- `module internal FileIndex` — `fileIndexOfFile`, `fileOfFileIndex`, `startupFileName`.
- `[<RequireQualifiedAccess>] module internal LineDirectives` — `add: FileIndex -> (int * (FileIndex * int)) list -> unit`, with doc comment describing the per-directive representation.
- `module Range` — `posOrder`, `mkFileIndexRange`, `mkRange`, `mkFirstLineOfFile`, `equals`, `trimRangeToLine`, `rangeOrder`, `outputRange`, `unionRanges`, `withStartEnd/withStart/withEnd`, `shiftStart/shiftEnd`, `rangeContainsRange`, `rangeContainsPos`, `rangeBeforePos`, `rangeN`, `range0`, `rangeStartup`, `rangeCmdArgs`, `stringOfRange`, `toZ`, `toFileZ`, `comparer`, `setTestSource` (internal).
- `module Line` — `fromZ: Line0 -> int`, `toZ: int -> Line0`.

**Public API surface**: See the module/type lists above; the .fsi intentionally hides implementation details — the packed `int64` codes (`Code1`/`Code2`), bit-layout constants (`PosImpl`, `RangeImpl`), `FileIndexTable`, and the global `testSources` dictionary — none of which appear in the signature.

**Internal helpers**: `val internal setTestSource: path -> source -> unit` — injected to let tests supply file sources for `DebugCode`; `val internal Decode`, `member internal IsAdjacentTo`, etc.

**Significant internal logic**: None in the signature itself; it pins the contract of the bit-packed encodings implemented in `range.fs` (e.g. `EncodingSize` documents the 64-bit budget) and the semantics of the 0/1-based line conversions that interoperate with Visual Studio.

**Cross-references**: Companion implementation `range.fs` (same directory, `src/Compiler/Utilities/`). Types are public API of FSharp.Compiler.Service and are referenced by diagnostics (`sr.fs`), `illib.fs`, and language-service code.

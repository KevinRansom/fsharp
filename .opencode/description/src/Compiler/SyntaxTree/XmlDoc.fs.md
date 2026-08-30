# XmlDoc.fs

**Purpose**: Core implementation of F#'s XML documentation pipeline on the syntax side: it defines the value types `XmlDoc` (collected + elaborated doc text) and `PreXmlDoc` (the lazy/mergeable form carried through `SyntaxTree` nodes), a stateful `XmlDocCollector` that accumulates `///` lines during lexing (keyed by "grab points" set by the parser at construct boundaries), and `XmlDocumentationInfo`, a cached loader for `.xml` documentation files of referenced assemblies (used to *include* existing doc entries via `<include>` tags, see `XmlDocIncludeExpander.fs`). The `Check` method implements the FS390x validation family (parameter-name consistency, duplicate params, malformed XML).

**Namespace(s)**: `FSharp.Compiler.Xml` (public)

**Modules / Types declared**:
- `XmlDoc` — public class wrapping `unprocessedLines: string[]` + `range`; the "done" doc
- `XmlDocStatics` — private helper class only to host the `Empty` static let
- `XmlDocCollector` — internal mutable state for the lexer; accumulates (line, range) pairs and "grab points"
- `PreXmlDoc` — public union: `PreXmlDirect | PreXmlMerge | PreXmlDoc(pos, collector) | PreXmlDocEmpty | PreXmlDocPairedWith`
- `XmlDocumentationInfo` — internal sealed class; lazy `unit -> XmlDocument option` + an `AgedLookup` cache (`cacheStrongSize = 2`, `cacheMaxSize = 4`)
- `IXmlDocumentationInfoLoader` — internal interface with `TryLoad`

**Public API surface**:
- **`XmlDoc`**:
  - `new : unprocessedLines: string[] * range: range -> XmlDoc`
  - `static member Merge : XmlDoc -> XmlDoc -> XmlDoc`
  - `member GetElaboratedXmlLines : unit -> string[]` (inserts `<summary>` for non-tagged lines)
  - `member GetXmlText : unit -> string`
  - `member internal GetExpandedXmlText : emit: bool -> string` and `(emit, env: XmlDocIncludeExpander.ExpansionEnv) -> string` (delegates to `XmlDocIncludeExpander.expandIncludeLines`)
  - `member internal Check : paramNamesOpt: string list option -> unit`
  - `member IsEmpty : bool`, `member NonEmpty : bool`, `member Range : range`, `member UnprocessedLines : string[]`
  - `static member Empty : XmlDoc`
- **`PreXmlDoc`**:
  - `static member internal CreateFromGrabPoint : XmlDocCollector * pos -> PreXmlDoc`
  - `static member Merge : PreXmlDoc -> PreXmlDoc -> PreXmlDoc`
  - `static member WithExtraParamsForCheck : PreXmlDoc * string list -> PreXmlDoc`
  - `static member Create : string[] * range -> PreXmlDoc`
  - `member ToXmlDoc : check: bool * paramNamesOpt: string list option -> XmlDoc`
  - `member Range : range`, `member IsEmpty : bool`
  - `member internal MarkAsInvalid : unit -> unit`
  - `static member Empty : PreXmlDoc`
- **`XmlDocCollector`** (internal; all the members listed in .fsi)
- **`XmlDocumentationInfo`**:
  - `member TryGetXmlDocBySig : string -> XmlDoc option`
  - `static member TryCreateFromFile : string -> XmlDocumentationInfo option`
- **`IXmlDocumentationInfoLoader`**: `abstract TryLoad : string -> XmlDocumentationInfo option`

**Internal helpers**:
- `processLines` inside `XmlDoc` — recursively locates first line starting with `<`; if none, wraps the body in `<summary>…</summary>` (with `escape` per line)
- `XmlDocCollector.savedLines`, `savedGrabPoints : Dictionary<pos, struct(int*int*bool)>`, `delayedGrabPoint : voption<pos>`, `lastNonCommentTokenLine`
- `tryGetSummaryNode` — XPath `doc/members/member[@name=…]` lookup, with special casing when the sig contains a quote (must not contain both `'` and `"`)
- `cache` — `AgedLookup<unit, string*DateTime, XmlDocument>` keyed by (filename, lastWriteTime), case-insensitive filename

**Significant internal logic**:
- **Summary elision**: `GetElaboratedXmlLines` is the step that turns a bare `/// some text` comment block into a well-formed `<summary>` fragment; `range` is always the source range of the block.
- **Grab-point protocol**: the parser calls `CreateFromGrabPoint(collector, markerPos)` at the position of the keyword that starts a new construct (e.g. `let`, `type`, `member`, `val …`); the collector has recorded every XML-doc line + its range up to that point, so `LinesBefore` slices out exactly the lines preceding that marker. `MarkAsInvalid` is used when the parser decides the doc must be discarded (e.g. invalid attach); `CheckInvalidXmlDocPositions` later reports `FS0137`/family and collects the offending ranges for conversion to trivia.
- **Delayed grab points** (`AddGrabPointDelayed`): allow patterns where a doc block is interleaved with a regular comment before the next construct, then "commit" on the next XML-doc line.
- **`PreXmlDoc.ToXmlDoc(check, paramNamesOpt)`**: the central conversion from a lazy doc to a concrete one, merging via `XmlDoc.Merge` when `PreXmlMerge`. The `paramNamesOpt` drives `Check`.
- **`Check` validation**:
  - Parse with `XDocument.Parse("<doc>…</doc>")` with `SetLineInfo | PreserveWhitespace` to keep ranges.
  - Validate each `<param name="x">`: `x` must be in `paramNames` (else `FS0190`-style, `xmlDocInvalidParameterName`); any parameter with doc ⇒ all parameters must have doc (`xmlDocMissingParameter`); report duplicates (`xmlDocDuplicateParameter`); validate `<paramref name="…">` same way.
  - On `XmlException`, emit `xmlDocBadlyFormed` warning.
- **Merge order**: `PreXmlMerge(a, b)` and `XmlDoc.Merge` both *concatenate* `UnprocessedLines` (doc1 then doc2); the combined range is the union of the two (or the non-empty one's range if one is empty). This supports `and`-chained declarations sharing a doc block and property `get`/`set` pairing via `WithExtraParamsForCheck`.
- **Doc-file caching**: `CacheKey = (fileName, lastWriteTime)`, compared case-insensitively; size 2 strong / 4 max. The loader is used by `XmlDocIncludeExpander` when it resolves `<include file=…>` against a referenced DLL.

**Cross-references**: `XmlDoc.fsi` (public contract), `XmlDocIncludeExpander.fs` (resolves `<include>`, called by `GetExpandedXmlText` / `Check`), `LexerStore.fs` (drives `XmlDocCollector` via `SaveXmlDocLine`/`AddGrabPoint`…), `ParseHelpers.fs` (`grabXmlDoc`/`grabXmlDocAtRangeStart` call `CreateFromGrabPoint`), `SyntaxTree.fs` (each `SynDefn`/`SynVal`/`SynBinding` carries a `PreXmlDoc`), `SyntaxTrivia.fs` (consumes the ranges `CheckInvalidXmlDocPositions` returns).

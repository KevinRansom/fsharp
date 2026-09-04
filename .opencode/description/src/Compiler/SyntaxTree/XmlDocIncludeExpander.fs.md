# XmlDocIncludeExpander.fs

**Purpose**: Internal module that implements F#'s `/// <include file="..." path="..."/>` directive. Given a block of elaborated XML doc lines (the output of `XmlDoc.GetElaboratedXmlLines`), it finds every unqualified `<include>` element, loads the target `.xml` file (relative to the source file, falling back to the working directory — Roslyn `XmlFileResolver` parity), evaluates the XPath, and splices the matched elements back in. It guards against cycles, runaway depth, and runaway expansion-count, and emits `FS3908` family warnings when `emit` is true (suppressed when used by `XmlDoc.Check` to validate).

**Namespace(s)**: `FSharp.Compiler.Xml` (module `internal FSharp.Compiler.Xml.XmlDocIncludeExpander`)

**Modules / Types declared**:
- `ExpansionEnv` — record `{ FileCache: Dictionary<string, Result<XDocument, string>> }`, a per-pass file cache
- `mkExpansionEnv : unit -> ExpansionEnv`
- `expandIncludeLines : ExpansionEnv -> emit: bool -> baseFileName: string -> range: range -> lines: string[] -> string[]`
- Private: `maxIncludeDepth = 64`, `maxIncludeExpansions = 10000`
- Private `IncludeInfo` record `{ FilePath: string; XPath: string }`
- Private `ExpansionContext` record threaded through the recursion: `Env`, `InProgressIncludes: Set<struct (string * string)>`, `Depth: int`, `Budget: int ref`, `BudgetExhaustedWarned: bool ref`, `Range`, `Emit`
- Private `IncludeOutcome` union: `IncludeResolved of XNode seq | IncludeNoMatch | IncludeError of string | IncludeBudgetExceeded of string`
- Private closures: `loadXmlFile`, `resolveFilePath`, `evaluateXPath`, `mayContainInclude`, `classifyInclude`, `warnIncludeError`, `warnFramedIncludeError`, `resolveSingleInclude`, `expandAllIncludeNodes`

**Public API surface** (contract as seen by `XmlDoc.fs`):
- `mkExpansionEnv : unit -> ExpansionEnv`
- `expandIncludeLines : ExpansionEnv -> emit: bool -> baseFileName: string -> range: range -> lines: string[] -> string[]`
  - Returns input unchanged when there are no `<include>` tags, when parsing fails, or when nothing was expanded.
  - `emit` = true ⇒ warnings are reported (FS3908 / `xmlDocIncludeError` / `xmlDocIncludeError2`); `emit` = false ⇒ silent (used by `XmlDoc.Check`).

**Internal helpers**:
- `mayContainInclude` — cheap `text.Contains "<include"` pre-filter
- `classifyInclude` — only an *unqualified* `<include>` (no XML namespace) is an include tag; a same-named element in a foreign namespace is left untouched (Roslyn `ElementNameIs` parity). Extracts required `file` and `path` attributes; error message per attribute shape.
- `resolveFilePath` — rooted paths are taken as-is; otherwise `GetFullFilePathInDirectoryShim(GetDirectoryNameShim baseFileName, includePath)` is tried first (source-relative), then the working directory — matching C#/Roslyn `XmlFileResolver` behavior.
- `loadXmlFile` — caches `Result<XDocument, string>` keyed by the resolved path (case-sensitive `Ordinal`). Uses `XmlReaderSettings(DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null)` so DTDs and entity expansion from the file cannot be abused.
- `evaluateXPath` — `doc.XPathSelectElements(xpath) |> List.ofSeq` — *materializes* the result inside the try so that the lazy-enumeration `InvalidOperationException` (e.g. XPath that selects text nodes) is reported as a clean error rather than leaking out.
- `noMatchCommentText` — the comment text inserted when the XPath is valid but matches zero elements ("No matching elements were found for the following include tag").

**Significant internal logic**:
- **Recursion & budgeting**: `expandAllIncludeNodes` walks the node set; for each `<include>` it calls `resolveSingleInclude`, which:
  1. Resolves the file path; on failure yields `IncludeError "the file path is invalid"`.
  2. Cycle check via `InProgressIncludes: Set<struct (resolvedPath, xpath)>`; `IncludeError "a circular include was detected"`.
  3. Depth check (`maxIncludeDepth = 64`): `IncludeError` with the depth bound in the message.
  4. Budget check (`maxIncludeExpansions = 10000` per doc): `IncludeBudgetExceeded` with the bound in the message. The `BudgetExhaustedWarned` ref-cell ensures the warning is emitted **at most once** per documentation comment.
  5. `loadXmlFile` (cached) then `evaluateXPath`.
  6. On success, decrements the budget and recurses with `InProgressIncludes.Add(key)` and `Depth + 1`, so the same (file, xpath) pair cannot appear twice on any path, and nested includes of the same shape at deeper levels are blocked.
- **NoMatch behavior**: a valid XPath with zero matches is handled differently from an error — a `XComment(noMatchCommentText)` is emitted *before* the original tag, and the tag itself is **kept** (not removed), no warning. This is the C#/Roslyn parity behavior.
- **Error behavior**: real failures (missing file, invalid/empty XPath, cycle, depth, budget) emit one of the framed warnings (`xmlDocIncludeError2` carries file + xpath + short reason) and keep the original tag in the output.
- **Round-trip**: after expansion, the node set is serialized per node with `SaveOptions.DisableFormatting`, concatenated, and split with `String.getLines`. If the result is line-for-line identical to the input, the input is returned unchanged (avoids spurious re-emission / range drift); otherwise the expanded lines are returned.
- **`emit`-gated diagnostics**: `warnIncludeError` / `warnFramedIncludeError` no-op when `ctx.Emit` is false. This lets `XmlDoc.Check` run the same expansion pass silently while still populating the *text* that gets validated (`XmlDoc.Check` calls `GetExpandedXmlText false`).
- **Diagnostics**: `xmlDocIncludeError` (short message) and `xmlDocIncludeError2` (file + xpath + reason) are the two SR keys used; `range` is the range of the original doc comment (passed in by `XmlDoc.GetExpandedXmlText`), so the warning anchors at the `///` block, not inside the included file.

**Cross-references**: `XmlDocIncludeExpander.fsi` (public contract), `XmlDoc.fs` (`GetExpandedXmlText` is the sole caller; `Check` calls it with `emit=false`), `FileSystem` shims (`FileExistsShim`, `OpenFileForReadShim`, `IsPathRootedShim`, `GetFullPathShim`, `GetDirectoryNameShim`, `GetFullFilePathInDirectoryShim` — from `FSharp.Compiler.IO`), `DiagnosticsLogger` (via `warning`), `SyntaxTree.fs` (doc-comment lines originate from the syntax tree).

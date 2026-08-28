# XmlDocIncludeExpander.fsi

**Purpose**: Public (module-level internal) contract for `FSharp.Compiler.Xml.XmlDocIncludeExpander`, the module that expands F#'s `/// <include file="..." path="..."/>` directive in XML doc comments. Declares only the `ExpansionEnv` type, the `mkExpansionEnv` constructor, and the single `expandIncludeLines` entry point.

**Namespace(s)**: `FSharp.Compiler.Xml` (module `internal FSharp.Compiler.Xml.XmlDocIncludeExpander`)

**Modules / Types declared** (public surface):
- `ExpansionEnv` — per-pass shared state (opaque record; holds `Dictionary<string, Result<XDocument, string>>`)
- `mkExpansionEnv : unit -> ExpansionEnv`
- `expandIncludeLines : env: ExpansionEnv -> emit: bool -> baseFileName: string -> range: range -> lines: string[] -> string[]`

**Public API surface**: see the three declarations above; `expandIncludeLines` is the only entry point. The .fsi documents:
- `emit` true ⇒ include errors are reported as warnings (`FS3908` family); `emit` false ⇒ errors are suppressed (used by `XmlDoc.Check` for quiet validation)
- Returns the input unchanged when there are no includes, when parsing fails, or when nothing expanded

**Internal helpers / active patterns / extension members**: not in the .fsi. The .fs holds the private machinery: `maxIncludeDepth = 64`, `maxIncludeExpansions = 10000`, `IncludeInfo`, `ExpansionContext`, `IncludeOutcome`, and the closures `loadXmlFile`, `resolveFilePath`, `evaluateXPath`, `mayContainInclude`, `classifyInclude`, `warnIncludeError`, `warnFramedIncludeError`, `resolveSingleInclude`, `expandAllIncludeNodes`.

**Significant internal logic**:
- The .fsi fixes the *public* contract that `XmlDoc.GetExpandedXmlText` depends on — it does not expose the budget/depth limits or the `IncludeOutcome` shape, so those can be tuned without a surface change.
- The `baseFileName` + `range` parameters pin the *source* context (the .fs resolves relative includes relative to the source file, then falls back to the working directory, mirroring C#/Roslyn `XmlFileResolver` semantics), and supply the anchor range for the `FS3908`-family warnings.

**Cross-references**: `XmlDocIncludeExpander.fs` (implementation), `XmlDoc.fs` (sole caller: `XmlDoc.GetExpandedXmlText(emit)` and `XmlDoc.GetExpandedXmlText(emit, env)`), `FSharp.Compiler.IO` (`FileSystem.Get*Shim` / `FileExistsShim` / `OpenFileForReadShim`), `DiagnosticsLogger` (consumed for the warnings).

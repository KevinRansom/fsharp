# XmlDocInheritance.fs

**Purpose**
Implements `<inheritdoc>` expansion for XML doc comments (contract in `XmlDocInheritance.fsi`).
`expandInheritDocFromXmlText` walks the doc XML, finds `<inheritdoc cref="..."/>` (and bare
`<inheritdoc/>`) directives, resolves them via a caller-supplied `resolveCref`, optionally
extracts a subtree via `path="x-path-expression"`, and splices the inherited markup back in. It
guards against inheritance cycles and deep chains, and is strictly best-effort — any failure
degrades to the original text so a tooltip never crashes.

**Namespace / module**
`module internal FSharp.Compiler.XmlDocInheritance` (no `namespace` declaration in the file).

**Types / values declared**
- `maxInheritDocDepth = 100` (`[<Literal>]`) — bounds the (non-tail-recursive) expansion of deep
  acyclic explicit-cref chains that would otherwise raise an uncatchable
  `StackOverflowException`; real inheritance chains are only a few levels deep.
- `InheritDocDirective` (record) — `Cref: string option`, `Path: string option`,
  `Element: XElement`; one per `<inheritdoc>` found in the document.
- `expandInheritDocFromXmlText` (public per .fsi) / `expandInheritedDoc` (private recursive
  wrapper adding the visited-set and depth logic).
- Private helpers: `hasInheritDoc`, `extractInheritDocDirectives`, `nodesToString`,
  `applyXPathFilter`, `selectDefaultInheritedContent`.

**Behavior notes**
- `hasInheritDoc` — cheap `IndexOf("<inheritdoc")` short-circuit before parsing XML.
- `extractInheritDocDirectives` — `XDocument.Descendants("inheritdoc")`; captures
  `cref`/`path` attributes.
- `applyXPathFilter` — parses doc text into a `XDocument` (wrapped in `<doc>`), adjusts absolute
  XPaths (`/...` → `/doc/...`), and serializes matched elements; returns `""` on
  `XPathException`/`XmlException`/`InvalidOperationException` (XPath selections of non-element
  nodes like `text()`/`node()` are unsupported for inheritance and degrade gracefully).
- `selectDefaultInheritedContent` — selects the target's *whole* top-level content, excluding
  `<overloads>`; a nested bare `<inheritdoc/>` inside inherited content is *not* re-resolved
  against the caller's implicit target (it is dropped) — only explicit-cref chains propagate.
- Cycle/depth guard — `visited: Set<string>` of crefs; a repeated cref's directive is removed;
  total chain length is capped at `maxInheritDocDepth`.
- Newline normalization — `node.ToString` re-introduces `\r\n`; output is normalized to `\n`
  because downstream `XmlDoc.processLines` would otherwise re-wrap the spliced markup in an
  implicit `<summary>` and XML-escape it.
- All-`with` fallback — XML parse errors or a throwing `resolveCref` (e.g. `invalidOp` walking an
  unresolved CCU) leave the original text (with the verbatim `<inheritdoc/>`) in place.

**Cross-references**
- `XmlDocInheritance.fsi` — contract.
- `Symbols.fs` (`Impl.buildCrefResolver`, `makeExpandedXmlDoc`, `getImplicitTargetCrefFor*`) —
  constructs `resolveCref`/`implicitTargetCrefOpt` and feeds doc text from `FSharpEntity`/
  member XmlDoc pipelines.
- `XmlDocSigParser.fs` — sibling module for parsing cref-style doc IDs.

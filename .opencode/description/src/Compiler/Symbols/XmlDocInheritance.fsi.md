# XmlDocInheritance.fsi

**Purpose**
Contract for `<inheritdoc>` expansion in XML documentation text. When a symbol's doc comment
contains `<inheritdoc cref="..."/>` (or a bare `<inheritdoc/>` inheriting from an implicit
override/base target), the compiler replaces the directive with the referenced symbol's
documentation before exposing it through `FSharpSymbol.XmlDoc`. The module is internal: callers
supply a `resolveCref` lookup so the expansion stays decoupled from CCU/assembly resolution.

**Namespace(s)**
The file declares a single internal module `FSharp.Compiler.XmlDocInheritance` (dotted internal
module name; the file carries no `namespace` declaration of its own).

**Declared surface**
- `val expandInheritDocFromXmlText :
    resolveCref: (string -> string option) ->
    implicitTargetCrefOpt: string option ->
    visited: Set<string> ->
    xmlText: string ->
    string`

**API notes**
- `resolveCref` — maps a cref string to the referenced symbol's raw XML doc text (or `None` when
  the target cannot be resolved; the directive is then removed).
- `implicitTargetCrefOpt` — the default target for `<inheritdoc/>` elements that carry no `cref`
  attribute (typically the closest base override or base type, computed by the caller — see
  `getImplicitTargetCrefFor*` in `Symbols.fs`).
- `visited` — set of already-visited crefs used to break inheritance cycles.
- Input is a *precomputed* XML text string, avoiding an extra `XmlDoc.GetXmlText()` round trip.

**Internal helpers**
The .fsi exposes only this one function; all machinery (directive extraction, XPath filtering,
cycle guarding) is private in the .fs.

**Cross-references**
- `XmlDocInheritance.fs` — implementation.
- `SymbolHelpers.fs` / `Symbols.fs` — build the `resolveCref` closure and implicit target, then
  invoke this function from the `XmlDoc` member pipeline.
- `XmlDocSigParser.fs` — sibling module for parsing documentation comment IDs (crefs).

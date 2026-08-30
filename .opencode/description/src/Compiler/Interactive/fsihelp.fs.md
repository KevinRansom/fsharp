# fsihelp.fs

## Pipeline role

This file belongs to `FSharp.Compiler.Interactive` (the `fsi` REPL) and implements `fsihelp.fsi`'s `FsiHelp` module — turning a quoted F# expression (e.g. `List.map`, `typeof<List<int>>`) into a rendered help page pulled from the assembly's XML documentation file. The pipeline is: (1) inspect the quotation with `Microsoft.FSharp.Quotations.Patterns` to find the underlying method/member/type and its declaring assembly, (2) map that to the on-disk `*.xml` doc file, (3) locate the `<member name="…">` node containing the xml-doc entry, (4) extract Summary/Remarks/Parameters/Returns/Exceptions/Examples, and (5) format via `Help.ToDisplayString`. Used by fsi to show docs, e.g. for the current or named expression. Note `#nowarn "3261"` (nullness) because the `System.Xml` DOM API is null-heavy and not a good fit for the compiler's nullness checking.

## Opens

`module FSharp.Compiler.Interactive.FsiHelp` opens `System`, `System.IO`, `System.Text`, `System.Reflection`, `FSharp.Compiler.IO`.

## `module Parser`

Opens `System.Xml`, `System.Collections.Concurrent`, `Internal.Utilities.Library`.

### `type Help`

Record of doc-model fields (Summary, Remarks, Parameters, Returns, Exceptions, Examples, FullName, Assembly) — identical to the signature, plus the implementation:

- `member this.ToDisplayString()` — builds the display string with a `StringBuilder`:
  - blank line + `Description:` + Summary.
  - `Remarks:` section when present.
  - `Parameters:` section rendered as `- name: description` lines.
  - `Returns:` section when present.
  - `Exceptions:` section as `exType: description` lines.
  - `Examples:` section — renders each example's code block, then its description re-indented as `// …` comment lines (newlines converted to `\n// `).
  - Trailer `Full name: …` and `Assembly: …` lines.

### XML doc helpers

- `cleanupXmlContent (s: string)` — `s.Replace("\n ", "\n").Trim()` to strip stray whitespace from the XML.
- `trimDotNet (s: string)` — removes a leading `X:` cref-style prefix (when `s[1] = ':'`, e.g. `M:`, `T:`) and anything from a backtick `` ` `` onwards (generic arity), yielding the plain dotted name.
- `xmlDocCache = ConcurrentDictionary<string, Lazy<XmlDocument>>()` — memoization of parsed XML docs per path.
- `tryGetXmlDocument xmlPath` — `FileSystem.OpenFileForReadShim` + `ReadAllText` + `XmlDocument.LoadXml`, cached lazily via `xmlDocCache.GetOrAddLazy`; any failure → `None`.
- `getTexts (node: XmlNode)` — concatenates the free text, `<c>` inline-code text, and `<see … cref="…"/>` reference texts (cref values run through `trimDotNet`) of the node's children.
- `tryMkHelp (xmlDocument: XmlDocument option) (assembly: string) (modName: string) (implName: string) (sourceName: string)` — the central cell extraction:
  - Normalizes ctor dots: `sourceName` and `implName` get `.` → `#`.
  - Tries XPath queries in order, each `contains(@name, ":{modName}.{implName}...")` with suffixes `` ` ``, `(`, and bare — first hit wins:
    - `"/doc/members/member[contains(@name, ':{xmlName}`')]"` (generic/method with backtick arity),
    - `"/doc/members/member[contains(@name, ':{xmlName}(')]"` (parameter list),
    - `"/doc/members/member[contains(@name, ':{xmlName}')]"` (bare).
  - On no match → `ValueNone`; on match extracts:
    - `summary`/`remarks` — first child via `SelectSingleNode`, texts via `getTexts`, normalized with `cleanupXmlContent`.
    - `parameters` — all `<param>` nodes → `(name attr .Value, inner text)` pairs.
    - `returns` — text trimmed.
    - `exceptions` — `<exception cref="T:…">` → type name past the `:` + trimmed inner text.
    - `examples` — `<example>` → the `<code>` child text (removed from the example node first via `RemoveChild`, `cleanupXmlContent`d), paired with the remaining example text.
  - If no summary → `ValueNone`; else builds the `Help` record with `Summary`, `Remarks`, `Parameters`, `Returns`, `Exceptions`, `Examples`, `FullName = "{modName}.{sourceName}"` (the long ident users see), `Assembly`.

## `module Expr`

Opens `Microsoft.FSharp.Quotations.Patterns`.

- `tryGetSourceName (methodInfo: MethodInfo)` — reads the `CompilationSourceNameAttribute`'s `SourceName` (the F#-source name of a method); `None` on failure.
- `getInfos (declaringType: Type) (sourceName: string option) (implName: string)` — derives everything needed for the lookup: `xmlPath = Path.ChangeExtension(declaringType.Assembly.Location, ".xml")`, the parsed `xmlDoc` (`Parser.tryGetXmlDocument`), the assembly file name, the desired `modName`/`fullName` (trimmed at `[` for generic instantiations and with `+` → `.` for nested e.g. `ArrayModule+Parallel`). Returns the tuple `(xmlDoc, assembly, fullName, implName, sourceName |- error : implName)`.
- `exprNames expr` (recursive) — inspects the quotation and returns the info tuple for the targeted member/type:
  - `Call(Some _, _, _)` — instance call with value → `None` (no static name).
  - `Call(None, methodInfo, _)` — static call; source name via `tryGetSourceName`; info for `methodInfo.DeclaringType`, `methodInfo.Name`.
  - `Lambda(_, body)` / `Let(_, _, body)` — unwrap to the body.
  - `Value(_, t)` / `DefaultValue t` — type name info.
  - `PropertyGet(_, info, _)` — declaring type + property name.
  - `NewUnionCase(info, _)` — union case info name.
  - `NewObject(ctorInfo, _)` — constructor name.
  - `NewArray(t, _)` — element type name.
  - `NewTuple _` / `NewStructTuple _` — defines a `2`-tuple type (`typeof<_ * _>` / `typeof<struct (_ * _)>`) and returns info for it.
  - Anything else → `None`.

## `module Logic`

Opens `Expr` and `Parser`.

- `module Quoted`:
  - `tryGetHelp (expr: Quotations.Expr)` — `exprNames expr`, then `Parser.tryMkHelp` over the extracted tuple → `Help voption`.
  - `h (expr)` — `tryGetHelp` → `ValueNone` gives the fallback `"unable to get documentation\n"`, `ValueSome d` gives `d.ToDisplayString()`.
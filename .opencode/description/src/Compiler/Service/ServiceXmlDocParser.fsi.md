# ServiceXmlDocParser.fsi

**Signature for `ServiceXmlDocParser.fs`.** Declares the XML-doc generation helpers of the FSharp.Compiler.Service: finding the places where the user could type an XML documentation comment.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. `XmlDocParser.GetXmlDocables (sourceText, input)` walks the untyped parse tree and returns `XmlDocable`s — insertion marker positions (line + indent) plus the parameter names to scaffold (`/// <param name="...">`) for bindings, type definitions, and members that do not yet have an XML doc. `XmlDocComment.IsBlank` is a tiny parser used to detect an empty `/// <` comment so the editor can offer completing the opening tag.

## Namespaces

- `FSharp.Compiler.EditorServices` with `open FSharp.Compiler.Syntax`, `FSharp.Compiler.Text`.

## Public surface (declared)

- `type XmlDocable = XmlDocable of line: int * indent: int * paramNames: string list` — position + `<param>` names to generate.
- `module XmlDocComment` (public):
  - `val inline IsBlank: string -> int option` — for a blank XML comment with a trailing `<` returns `Some(index of "<")`, otherwise `None`.
- `module XmlDocParser` (public):
  - `val GetXmlDocables: ISourceText * input: ParsedInput -> XmlDocable list`.

## Relation to .fs

The `.fs` implements the machinery in the internal module `XmlDocParsing`: `ConstructorPats` active pattern, `digNamesFrom` (parameter-name extraction from head patterns), `getParamNames` (from `SynValData` curried arg infos, falling back to pattern digging), `indentOf` (0-based line indentation from the source text), `isEmptyXmlDoc` (via `PreXmlDoc.ToXmlDoc(false, None)`), and the recursive `getXmlDocables*` walkers for module declarations, module/namespace nodes, type defns, and member defns (incl. `GetSetMember`/`AbstractSlot`/`Interface`/`NestedType`/`AutoProperty`). The `.fsi` exposes only the three public items.
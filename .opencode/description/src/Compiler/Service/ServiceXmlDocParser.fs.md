# ServiceXmlDocParser.fs

Full implementation of XML-doc insertion-point detection.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. Given the current source text and untyped `ParsedInput`, produce "docable" positions: the line + indentation where an `///` doc comment would go, plus the parameter names to scaffold, for every binding/type/member that currently lacks an XML doc. The editor can then offer a "generate XML doc" action.

## Namespaces / opens

- `FSharp.Compiler.EditorServices` with `open Internal.Utilities.Library`, `FSharp.Compiler.Syntax`, `FSharp.Compiler.Text`, `Text.Range`, `FSharp.Compiler.Xml`.

## Public type

- `type XmlDocable = XmlDocable of line: int * indent: int * paramNames: string list`.

## Module `XmlDocParsing` (internal)

- `(|ConstructorPats|)` — flattens `SynArgPats.Pats`/`NamePatPairs` to patterns (active pattern).
- `digNamesFrom pat` — extracts idents from a head pattern, handling `Named` (also `As … Named`), `OptionalVal`, `Typed`/`Attrib` (recurse), `LongIdent` constructor pats (via `ConstructorPats`), `ListCons`, `Tuple`, `Paren`. Cases never used in declarations (`As`/`Or`/`Ands`/`ArrayOrList`/`Record`/`Null`/`Const`/`Wild`/`IsInst`/`QuoteExpr`/`InstanceMember`/`FromParseError`) → `[]`.
- `getParamNames binding` — from `SynValData`'s `SynValInfo.curriedArgInfos` collect the ident texts of every `SynArgInfo`; if the curried args are empty (or produce no names), fall back to `digNamesFrom headPat`; else `[]`.
- `getXmlDocablesImpl (sourceText, input)`:
  - `indentOf lineNum` — leading-space count of the 1-based line (`GetLineString (lineNum - 1)`).
  - `isEmptyXmlDoc preXmlDoc` — `preXmlDoc.ToXmlDoc(false, None).IsEmpty`.
  - `getXmlDocablesSynModuleDecl` — `NestedModule` → recurse; `Let` bindings → if **none** carry an XML doc, compute `fullRange` = union of the bindings' attribute ranges folded onto the decl range, then `XmlDocable(line, indent, paramNames)` where `paramNames = all getParamNames` (so multiple binds in one `let` produce one docable with all params); `Types` → recurse per type defn; `NamespaceFragment` → recurse; other decls → nothing.
  - `getXmlDocablesSynModuleOrNamespace` — collect decls.
  - `getXmlDocablesSynTypeDefn` — `ObjectModel` extra member defns, then (if the component-info has no doc) the type defn itself (`XmlDocable(…, [])` from component-info range ∪ its attribute ranges ∪ type range), then all member defns.
  - `getXmlDocablesSynMemberDefn` — `Member` → if no doc: `XmlDocable(line, indent, digNamesFrom headPat)` (attributes folded onto member range); `GetSetMember` → each accessor re-wrapped as `Member` and recursed; `AbstractSlot` → if no doc: names from `synValInfo.ArgNames`; `Interface` → member docs; `NestedType` → recurse; `AutoProperty` → always `XmlDocable(…, [])`; `Open`/`ImplicitCtor`/`ImplicitInherit`/`Inherit`/`ValField`/`LetBindings` → nothing.
  - `getXmlDocablesInput` — `ImplFile` → contents; `SigFile` → `[]` (docs only for implementation files).

## Module `XmlDocComment` (public)

A small combinator parser over `(string, pos)`:
- combinators `ws` (TrimStart, advancing pos), `str prefix`, `eol`, and infix `(>=>)` (fish operator, `f >> Option.bind g`, marked `InlineIfLambda`).
- `IsBlank s` — parses `ws`, literal `///`, `ws`, `<`, `eol` (after `s.TrimEnd()`), returning `Some(index of "<")` (position minus 1) or `None`. Used to detect a blank `/// <` comment awaiting the tag name.

## Module `XmlDocParser` (public)

- `GetXmlDocables (sourceText, input)` — delegates to `XmlDocParsing.getXmlDocablesImpl`.
# XmlDoc.fsi

**Purpose**: Public contract for the XML-documentation types in the front-end. Declares the *value* type `XmlDoc` (the collected + elaborated doc text plus range), the *lazy* form `PreXmlDoc` (the union carried by every `SynDefn`/`SynVal`/`SynBinding` in the `SyntaxTree`), the internal stateful `XmlDocCollector` (the lexer's accumulator), and the `XmlDocumentationInfo` / `IXmlDocumentationInfoLoader` surface for loading `<include>`-able `.xml` files of referenced assemblies.

**Namespace(s)**: `FSharp.Compiler.Xml`

**Modules / Types declared** (public contract):
- `XmlDoc` (`[<Class>]`, public) — collected + elaborated doc
- `XmlDocCollector` (internal) — lexer accumulator with grab-points
- `PreXmlDoc` (`[<Sealed>]`, public) — the lazy doc carried in the syntax tree
- `XmlDocumentationInfo` (`[<Sealed>]`, internal) — cached loader of an `.xml` doc file
- `IXmlDocumentationInfoLoader` (internal) — capability interface

**Public API surface**:
- `XmlDoc`:
  - `new : unprocessedLines: string[] * range: range -> XmlDoc`
  - `static member Merge : XmlDoc -> XmlDoc -> XmlDoc`
  - `member internal Check : paramNamesOpt: string list option -> unit`
  - `member GetElaboratedXmlLines : unit -> string[]` (after inserting `<summary>` and escaping)
  - `member GetXmlText : unit -> string`
  - `member internal GetExpandedXmlText : emit: bool -> string`
  - `member internal GetExpandedXmlText : emit: bool * env: XmlDocIncludeExpander.ExpansionEnv -> string`
  - `member IsEmpty / NonEmpty : bool`, `member Range : range`, `member UnprocessedLines : string[]`
  - `static member Empty : XmlDoc`
- `XmlDocCollector` (internal):
  - `new : unit -> XmlDocCollector`
  - `member AddGrabPoint : pos -> unit`
  - `member AddGrabPointDelayed : pos -> unit`
  - `member AddXmlDocLine : string * range -> unit`
  - `member LinesBefore : pos -> (string * range)[]`
  - `member HasComments : pos -> bool`
  - `member CheckInvalidXmlDocPositions : unit -> range list`
  - `member SetLastNonCommentTokenLine : int -> unit`
  - `member LastNonCommentTokenLine : int`
- `PreXmlDoc`:
  - `static member internal CreateFromGrabPoint : XmlDocCollector * pos -> PreXmlDoc`
  - `static member Merge : PreXmlDoc -> PreXmlDoc -> PreXmlDoc`
  - `static member WithExtraParamsForCheck : PreXmlDoc * string list -> PreXmlDoc`
  - `static member Create : string[] * range -> PreXmlDoc`
  - `member ToXmlDoc : check: bool * paramNamesOpt: string list option -> XmlDoc`
  - `member Range : range`, `member IsEmpty : bool`
  - `member internal MarkAsInvalid : unit -> unit`
  - `static member Empty : PreXmlDoc`
- `XmlDocumentationInfo`:
  - `member TryGetXmlDocBySig : string -> XmlDoc option`
  - `static member TryCreateFromFile : xmlFileName: string -> XmlDocumentationInfo option`
- `IXmlDocumentationInfoLoader`:
  - `abstract TryLoad : assemblyFileName: string -> XmlDocumentationInfo option`

**Internal helpers / active patterns / extension members**: none in the .fsi (the .fs holds `XmlDocStatics`, the `processLines` closure, `tryGetSummaryNode`, and the `AgedLookup` cache).

**Significant internal logic** (declared by the contract):
- `XmlDoc.GetExpandedXmlText(emit, env)` *expands* `<include file=…/>` tags via `XmlDocIncludeExpander` (see sibling file) — this is how `/// <include file="MyDoc.xml" path="doc/members[@name='M2']/para/*"/>` works.
- `XmlDoc.Check` performs the parameter/paramref/duplicate validation and malformed-XML reporting — the .fsi documents `paramNamesOpt` as the "expected" names against which `<param name=…>` is checked.
- `PreXmlDoc.WithExtraParamsForCheck` documents its purpose: property `get`/`set` pairs so each accessor's check sees the union of both accessors' parameter names.
- `PreXmlDoc.ToXmlDoc(check, paramNamesOpt)` is the single conversion point from "tree-carrying doc" to a concrete `XmlDoc`; setting `check = true` runs the validation.
- `XmlDocumentationInfo.TryCreateFromFile` gates on `.xml` extension + file existence; `TryGetXmlDocBySig` is the lookup used by `XmlDocIncludeExpander` when the include `file="assemblyname.xml"` references a referenced assembly.

**Cross-references**: `XmlDoc.fs` (implementation), `XmlDocIncludeExpander.fs` (the include-resolution algorithm), `LexerStore.fs` (drives `XmlDocCollector`), `ParseHelpers.fs` (`grabXmlDoc`/`grabXmlDocAtRangeStart` call `CreateFromGrabPoint`), `SyntaxTree.fs` (the AST carries `PreXmlDoc` fields on `SynDefn`/`SynVal`/`SynBinding`), `SyntaxTrivia.fs` (the ranges from `CheckInvalidXmlDocPositions` become trivia).

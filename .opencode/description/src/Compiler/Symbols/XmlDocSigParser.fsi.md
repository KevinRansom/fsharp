# XmlDocSigParser.fsi

**Purpose**
Internal contract for parsing .NET XML documentation comment IDs (cref format, e.g.
`M:Namespace.Type.Method(System.String)`, `T:Namespace.Type`, `F:Namespace.Type.field`) into a
structured value that the documentation pipeline can match against symbols. This powers
`<see cref="..."/>` / `<inheritdoc cref="..."/>` target resolution and doc-comment lookup by ID.

**Namespace(s)**
`namespace FSharp.Compiler.Symbols`

**Modules / Types declared (internal)**
- `DocCommentIdKind` (union, `[RequireQualifiedAccess]`) — the kind of *member* element in a doc
  ID: `Method` | `Property` | `Event` | `Unknown`. Types, fields, and namespaces have their own
  `ParsedDocCommentId` cases, so they do not appear here.
- `ParsedDocCommentId` (union, `[RequireQualifiedAccess]`) —
  - `Type of path: string list` — type reference (`T:`).
  - `Member of typePath: string list * memberName: string * genericArity: int * kind:
    DocCommentIdKind` — member reference (`M:`/`P:`/`E:`).
  - `Field of typePath: string list * fieldName: string` — field reference (`F:`).
  - `None` — invalid or unparseable ID.
- `module XmlDocSigParser` (internal) —
  - `val parseDocCommentId : docCommentId: string -> ParsedDocCommentId`.

**API surface**
- `parseDocCommentId` — the single entry point; takes a cref string and returns the structured
  `ParsedDocCommentId`.

**Cross-references**
- `XmlDocSigParser.fs` — implementation.
- `Symbols.fs` / `SymbolHelpers.fs` — doc-comment ID resolution feeds cref lookup
  (`parseCref`/`tryGetDocByCref`) and `<inheritdoc>` target resolution.
- `XmlDocInheritance.fs` — related doc pipeline (expansion rather than ID parsing).

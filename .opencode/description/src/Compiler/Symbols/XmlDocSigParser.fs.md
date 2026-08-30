# XmlDocSigParser.fs

**Purpose**
Internal implementation of the XmlDoc comment-ID parser (contract in `XmlDocSigParser.fsi`).
`parseDocCommentId` turns a cref string into a `ParsedDocCommentId`, handling the `M:`/`P:`/`E:`
(member), `T:` (type), and `F:` (field) prefixes, generic-arity ```N` suffixes, and the `#ctor`
→ `.ctor` constructor-name normalization the documentation pipeline needs.

**Namespace**
`namespace FSharp.Compiler.Symbols`

**Types / modules declared**
- `DocCommentIdKind` (union) — `Method | Property | Event | Unknown`.
- `ParsedDocCommentId` (union) —
  `Type of path: string list` | `Member of typePath * memberName * genericArity: int * kind:
  DocCommentIdKind` | `Field of typePath * fieldName` | `None`.
- `module XmlDocSigParser` (internal) — `parseDocCommentId` plus two hoisted, compiled regexes
  (module-level so they are not recompiled per call).

**Implementation notes**
- `docCommentIdRx` — captures kind, entity path, optional parenthesized args, and an optional
  `~suffix` (e.g. trailing generic/overload marker).
- `fnGenericArgsRx` — strips a trailing `` ``<n> `` generic-arity from a member name.
- Member parsing — splits the entity on `.`; requires at least two parts (else `None`); takes the
  last segment as the member name and the rest as the type path; maps `M`→Method, `P`→Property,
  `E`→Event, other→Unknown; rewrites `#ctor` to `.ctor` (F# constructor naming).
- Type/field parsing — straightforward path split; a single-segment `F:` ID yields `None`.
- Any unmatched kind (e.g. unrecognized prefix) falls through to `ParsedDocCommentId.None`.

**Cross-references**
- `XmlDocSigParser.fsi` — contract (union cases and `parseDocCommentId`).
- `Symbols.fs` (`Impl.parseCref`/`tryFindMemberXmlDoc`) and `SymbolHelpers.fs`
  (`GetXmlDocHelpSigOfItemForLookup`, `GetXmlCommentForItem`) — consumers that need to match or
  construct documentation signature strings.
- `XmlDocInheritance.fs` — sibling doc pipeline (inherits content by resolved cref).

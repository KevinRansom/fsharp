# sformat.fsi

**Purpose**: Signature file for `sformat.fs`. Declares the public-internal contract of the compiler's structured-formatting engine: the `Layout`/`Joint`/`TaggedText`/`TextTag` model, the `TaggedText` and `Layout` combinator modules, `FormatOptions`, the `IEnvironment` (FSI print-intercept) interface, and the `Display` entry points. The header comment documents that this file is compiled twice: as the internal implementation of `printf "%A"` (with `COMPILER` defined, namespace `FSharp.Compiler.Text`) and as the structured-formatting implementation in FSharp.Compiler.Service/Private.dll (used by fsi.exe), with no layout objects transferred between the two implementations.

**Namespace(s)**: `FSharp.Compiler.Text` when `COMPILER`, else `Microsoft.FSharp.Text.StructuredPrintfImpl` (conditional).

**Modules / Types declared** (as in the signature):

- `[<StructuralEquality; NoComparison>] type internal Joint` = `Unbreakable | Breakable of int | Broken of int`.
- `[<StructuralEquality; NoComparison; RequireQualifiedAccess>] type TextTag` — the full tag enumeration (35+ cases including `ActivePatternCase/Result`, `Alias`, `Class`, `Union(Case)`, `Delegate`, `Enum`, `Event`, `Field`, `Interface`, `Keyword`, `LineBreak`, `Local`, `Record(Field)`, `Method`, `Member`, `Module(Binding)`, `Function`, `Namespace`, `NumericLiteral`, `Operator`, `Parameter`, `Property`, `Space`, `StringLiteral`, `Struct`, `TypeParameter`, `Text`, `Punctuation`, `UnknownType/Entity`, `UnresolvedName`).
- `type public TaggedText` (COMPILER) — `new: TextTag * string -> TaggedText`, `member Tag`, `member Text`; in the non-COMPILER branch it is `type internal TaggedText` class with `Tag`/`Text` (and `type internal Layout`, `type internal TextTag` opaque).
- `type internal TaggedTextWriter` — `Write: TaggedText -> unit`, `WriteLine`.
- `[<NoEquality; NoComparison>] type internal Layout` (COMPILER) — `ObjLeaf | Leaf | Node | Attr` with `static member internal JuxtapositionMiddle`.
- `module public TaggedText` (COMPILER) / `module internal TaggedText` — public: `tagText`, `tagClass`, `comma`; plus a large set of tagged-literal helpers (`tagField`, `tagKeyword`, `tagLocal`, `tagProperty`, `tagMethod`, `tagUnionCase`, `tagNamespace`, `tagParameter`, `tagSpace`, `dot/colon/minus/lineBreak/space`, and ~50 `internal` keyword/punctuation helpers like `keywordTrue/False`, `leftParen/rightParen`, `bar`, `structUnit`, etc.).
- `[<NoEquality; NoComparison>] type internal IEnvironment` (COMPILER-only) — `GetLayout: obj -> Layout`, `MaxColumns`, `MaxRows` (doc: the maximum size of list-like/table-like layouts, -1 for unlimited).
- `module internal Layout` — `emptyL`, `isEmptyL`, `endsWithL` (COMPILER), `objL`, `wordL`, `sepL`, `rightL`, `leftL`, joins `^^ ++ -- --- ---- ----- @@ @@- @@-- @@--- @@----`, `commaListL`, `spaceListL`, `semiListL`, `sepListL`, `bracketL`, `squareBracketL`, `braceL`, `tupleL`, `aboveL`, `aboveListL`, `optionL`, `listL`, `tagAttrL`, `unfoldL`.
- `type internal FormatOptions` — record with `FloatingPointFormat`, `AttributeProcessor`, `FormatProvider`, `BindingFlags`, `PrintWidth`, `PrintDepth`, `PrintLength`, `PrintSize`, `ShowProperties`, `ShowIEnumerable`, plus COMPILER-only `PrintIntercepts: (IEnvironment -> objnull -> Layout option) list` and `StringLimit: int`; `static member Default`. Doc comments record the F# Interactive semantics (ShowProperties may cause computation, ShowIEnumerable forces evaluation to finite depth).
- `module internal Display` — COMPILER: `asTaggedTextWriter`, `any_to_layout options (value, typValue)`, `squashTo width layout`, `squash_layout options layout`, `output_layout_tagged options writer layout`, `fsi_any_to_layout`; shared: `layout_to_string options layout`; non-COMPILER: `anyToStringForPrintf`.

**Public API surface**: See lists above. `TaggedText` is `public` in the COMPILER build (so FSharp.Compiler.Service consumers can pass tagged text to editors), everything else is internal.

**Internal helpers**: The numerous `internal` tagged-literal values in `module TaggedText` (e.g. `leftAngle/rightAngle`, `keywordStatic/Member/Val/...`, `structUnit`, `punctuationUnit`) are compiler-side conveniences not visible in the non-COMPILER build.

**Significant internal logic**: None in the signature; it fixes the two-namespace conditional surface and guarantees layout objects never cross between the compiler and FSharp.Core builds (per the header note).

**Cross-references**: Companion implementation `sformat.fs` (same directory). Used by fsi.exe (`fsi_any_to_layout`), FSharp.Compiler.Service, and `printf "%A"` support; related to `TaggedCollections.fs` for tagged output consumers.

# TextLayoutRender.fs

**Purpose**: Renders F# `Layout` objects (the structured layout AST with leaves, breaks, and attributes used by type display, FSI printing, and diagnostic message rendering) into concrete output. Provides a `LayoutRenderer<'a,'b>` abstraction with built-in renderers (string, `TextWriter` channel, `StringBuilder` buffer, tagged-text collector) and convenience entry points including `toRichText`, which turns a layout into classified `RichText` for tooling.

**Namespace(s)**: `FSharp.Compiler.Text`

**TypeDefs / Modules declared**:
- `type NavigableTaggedText(taggedText, range)` — `TaggedText` subclass carrying a `range` (source location) for navigation
- `module SepL`: separator leaves (`dot`, `star`, `colon`, `questionMark`, `leftParen`, `comma`, `space`, `leftBracket`, `leftAngle`, `lineBreak`, `rightParen`)
- `module WordL`: keyword leaves (`arrow`, `keywordNew/Val/Static/Member/...`, `bar`, `structUnit`, ~35 leaves incl. `keywordBegin/End`, `keywordTypeof`-adjacent keywords)
- `module LeftL`: left-delimiter leaves (`leftParen`, `questionMark`, `colon`, `leftBracketAngle`, `leftBracketBar`, `keywordTypeof`, `keywordTypedefof`)
- `module RightL`: right-delimiter leaves (`comma`, `rightParen`, `colon`, `rightBracket`, `rightAngle`, `rightBracketAngle`, `rightBracketBar`, `semicolon`)
- `type LayoutRenderer<'a,'b>`: abstract `Start`, `AddText`, `AddBreak`, `AddTag`, `Finish`
- `type NoState` / `type NoResult`: unit-like type tags
- `[<AutoOpen>] module LayoutRender`: `mkNav`, `spaces n`, `renderL`, and renderer instances `stringR`, `taggedTextListR`, `channelR`, `bufferR`, `showL`, `outL`, `bufferL`, `toArray`, `toRichText`

**Public API surface**:
- `LayoutRender.renderL renderer layout` — the core walker (continuation-style `addL`)
- `showL: Layout -> string`; `outL: TextWriter -> Layout -> unit`; `bufferL: StringBuilder -> Layout -> unit`
- `toArray: Layout -> TaggedText[]`; `toRichText: Layout -> RichText`
- `mkNav: range -> TaggedText -> TaggedText`
- Note: `ObjLeaf` is asserted unreachable — `failwith "ObjLeaf should never appear here"`

**Significant internal logic**:
- `renderL` is a continuation-passing walk: leaves emit text and track column offset; `Broken indent` nodes emit `AddBreak(pos + indent)` and bump the position; juxtaposition uses `Layout.JuxtapositionMiddle` to decide whether to insert a space
- `Attr(tag, attrs, l)` wraps rendering in `AddTag` begin/end for markup consumers (e.g. XML/HTML output)
- Renderers share the `addL` logic: `stringR` builds via a list of fragments joined at the end (with `List.rev`), `channelR`/`bufferR` stream via `chan.WriteLine`/`bprintf`, `taggedTextListR` pushes each `TaggedText` to a collector — making it trivial to produce classified parts
- Breaks render as newline + spaces(`n`), so output is terminal-friendly with correct indentation for deeply nested types
- Tag attributes are a no-op in the string/channel/buffer renderers (only used by markup-oriented renderers)

**Cross-references**: Layout DSL (`FSharp.Compiler.Text.Layout`: `Leaf/Node/Broken/ObjLeaf/Attr`, `sepL/wordL/leftL/rightL`, `JuxtapositionMiddle`), RichText (`toRichText` output), FSI's type/exception display and QuickInfo; DiagnosticsLogger messages rendered through layouts.

# RichText.fs

**Purpose**: Implements the compiler's classified-text model: `RichText` is an array of `TaggedText` parts so diagnostic messages can carry per-token classification (types, names, punctuation, literals, ...) that IDE tooling maps to colors. Includes constructors for every classification tag, concatenation helpers, and two notable facilities: splicing classified arguments through resource-file message holes (`RichMessage`) and a `RichTextBuilder` that merges adjacent same-tag parts.

**Namespace(s)**: `FSharp.Compiler.Text`

**TypeDefs / Modules declared**:
- `[<Sealed>] type RichText(parts: TaggedText[])` (public): `Parts`, `Text` (precomputed concatenation), `IsEmpty`; text-based `Equals`/`GetHashCode` (classification deliberately excluded from equality)
- `module RichText` (internal): `empty`, `ofParts`, `ofTaggedText`, `ofTag`, `mkText/mkClass/mkFunction/mkRecord/...` (one helper per `TextTag`, ~35 of them; empty text yields `empty` with no parts), `append`, `concat`, `concatWith`, `collectParts`, `ofQualifiedName`, `ofQualifiedTypeName`
- `module RichMessage` (internal): `text` and `numbered` — splice classified arguments into resource-formatted messages
- `[<Sealed>] type RichTextBuilder` (internal): accumulating builder with `Append` overloads (string / TaggedText / RichText / 1–4-arg resource messages / `format` function), `IsEmpty`, `ToRichText()`

**Significant internal logic**:
- `RichText.Text` is built once in the constructor with an up-front `StringBuilder` sized to total length
- `RichMessage` splice: resource accessors return an *already-formatted* string, so the message is formatted twice — once with real argument texts, once with control-char markers (e.g. `\u0001<idx>\u0001`); splice then substitutes the classified parts. This survives translation reordering/repeating of holes. If plain and spliced texts disagree (marker collision), plain text wins and classification is dropped
- `ofQualifiedName` splits a dotted name on the last `.`, tags each segment `Namespace`, joins with `.`-punctuation leaves; `ofQualifiedTypeName` = `ofQualifiedName mkUnknownType` (documented caveat: don't use for assembly-qualified names since versions contain dots)
- `mergeAdjacentParts` in the builder combines consecutive plain `TaggedText` parts of the same tag (non-plain subclasses like `NavigableTaggedText` are never merged, to preserve their data)
- `TextTag` classification names come from `FSharp.Compiler.Text` (TaggedText)

**Cross-references**: DiagnosticsLogger (`DiagnosticWithText`/`DiagnosticWithSuggestions` messages are `RichText`; `NormalizeErrorRichText` walks parts), TextLayoutRender (`toArray` emits `TaggedText[]` into `RichText`), Checker message generation, F# tooling rendering.

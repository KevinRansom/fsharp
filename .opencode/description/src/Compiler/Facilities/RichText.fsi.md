# RichText.fsi

**Purpose**: The contract for `RichText.fs`. Publicly exposes `RichText`; internally declares the construction helpers, per-tag `mk*` constructors, the `RichMessage` splicing facility, and the internal `RichTextBuilder`.

**Namespace(s)**: `FSharp.Compiler.Text`

**Declarations**:
- `type public RichText` — "text made of tagged parts, e.g. a diagnostic message in which types, identifiers and punctuation are classified, so that tooling is able to render them with colors." Equality = "read the same"; no-classification text is a single `TextTag.Text` part
  - `Parts: TaggedText[]`, `Text: string`, `IsEmpty: bool`
- `module internal RichText`: `empty`, `ofParts`, `ofTaggedText`, `ofTag` (empty text ⇒ no parts, boundaries never visible), `mkText` … `mkUnresolvedName` (35+ per-tag helpers; doc advises computing classification via `richTextOfEntityRefName`/`richTextOfValName` over hand-picking), `append`, `concat`, `concatWith`, `collectParts`, `ofQualifiedName` (dotted name ⇒ namespace + punctuation + classified leaf; not for assembly-qualified names), `ofQualifiedTypeName`
- `module internal RichMessage` — "Splices classified arguments into the holes of a message that comes from a resource file" (message is formatted with a sentinel per classified arg, then parts spliced back in; keeps resource keys compile-checked, allows translations to reorder/repeat/drop holes):
  - `text: ((RichText -> string) -> string) -> RichText`
  - `numbered: ((RichText -> string) -> int * RichText) -> int * RichText`
- `type internal RichTextBuilder` — "Accumulates rich text. Adjacent parts with the same classification are merged" (its `Append` string overload mirrors the lib.fs `StringBuilder` extension so existing formatting code can be migrated incrementally):
  - `Append: string -> unit`, `Append: TaggedText -> unit`, `Append: RichText -> unit`
  - `Append: ResourceString<...> * a0..a3: RichText -> unit` (1–4-arg overloads for FSStrings messages)
  - `Append: ((RichText -> string) -> string) -> unit` (mixed classified/plain args via `RichMessage`)
  - `IsEmpty: bool`, `ToRichText: unit -> RichText`

**Cross-references**: Implements RichText.fs; consumed by DiagnosticsLogger (messages), TextLayoutRender (layout → `TaggedText[]`), checker error-message construction.

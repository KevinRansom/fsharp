# ServiceConstants

**Purpose:** Shared constants for the F# editor service: the glyph classification model used by tools to draw an icon next to symbols in outline/navigable lists. There is no public `.fsi`; the type is part of the FSharp.Compiler.Service assembly surface.

**Namespace(s):** `FSharp.Compiler.EditorServices`

## Declared types / modules
- `FSharpGlyph` (enum union, `RequireQualifiedAccess`): one case per symbol class a consumer might want to distinguish.

## Public API surface / union cases
Cases: `Class`, `Constant`, `Delegate`, `Enum`, `EnumMember`, `Event`, `Exception`, `Field`, `Interface`, `Method`, `OverridenMethod` (sic), `Module`, `NameSpace` (camel-case spelling as in source), `Property`, `Struct`, `TypeDef`, `Type`, `Union`, `Variable`, `ExtensionMethod`, `Error`, `TypeParameter`.

## Internal helpers / notable details
- No functions, records, or classes — a pure discriminated union of glyph kinds.
- Used by service code that builds declaration lists / symbol classification (e.g. `FSharpCheckerResults.fs` in the same directory) to tag each `FSharpSymbolUse`-like entry with a display glyph.

## Significant internal logic
- Note the spelling quirks that are part of the public API and cannot be changed: `OverridenMethod`, `NameSpace`.
- `TypeDef` corresponds to C#-style typedef/class interop classification; `Error` marks entries whose symbol could not be resolved.

## Cross-references
- `src/Compiler/Service/FSharpCheckerResults.fs` (consumers that assign glyphs)
- `src/Compiler/Service/ServiceDeclarationLists.fs` (declaration-list consumers)
- `src/Compiler/SyntaxTree/LexClassifier`-related classification in `SemanticClassification.fs`

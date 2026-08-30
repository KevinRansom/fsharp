# ServiceConstants.fs

Single-purpose source file in the FSharp.Compiler.Service defining the `FSharpGlyph` enumeration used to tag symbols for icon display in editors.

## Pipeline role

`FSharpChecker` service-layer constant for F# IDE/tooling. `FSharpGlyph` maps the semantic category of a symbol to an icon identifier so IDEs (VS, Ionide, etc.) can show the appropriate glyph in completion lists, tooltips, and navigation bars. Defined in `FSharp.Compiler.EditorServices`.

## Namespace

- `FSharp.Compiler.EditorServices`

## Type

- `type FSharpGlyph` (`[<RequireQualifiedAccess>]` union) with cases:
  - `Class`, `Constant`, `Delegate`, `Enum`, `EnumMember`, `Event`, `Exception`, `Field`, `Interface`, `Method`, `OverridenMethod` (sic), `Module`, `NameSpace`, `Property`, `Struct`, `Typedef`, `Type`, `Union`, `Variable`, `ExtensionMethod`, `Error`, `TypeParameter`.

## Notes

- Pure data file: no functions or other logic; consumed by public services such as `SymbolHelpers`/tooltip providers that compute a glyph per `FSharpSymbol`.
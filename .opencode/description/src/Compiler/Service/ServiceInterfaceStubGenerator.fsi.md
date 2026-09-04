# ServiceInterfaceStubGenerator.fsi

**Signature for `ServiceInterfaceStubGenerator.fs`.** Declares the "implement interface" / "generate object expression" quick-fix API of the FSharp.Compiler.Service: given the AST location of an interface, produce the F# source text of a stub implementation.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling (editors implement "Generate member stubs for interface"). It captures interface information from untyped ASTs (`InterfaceData`), finds which members are still missing (by reconstructing member signatures from symbol uses located by range), and renders a correctly indented skeleton with `...` bodies or an arbitrary user-provided method body.

## Namespaces

- `FSharp.Compiler.EditorServices` with opens of `FSharp.Compiler.CodeAnalysis`, `Symbols`, `Syntax`, `Text`, `Tokenization`.

## Public types / module

- `type InterfaceData` (`[<RequireQualifiedAccess; NoEquality; NoComparison>]` union) — captures an interface as it appears in an AST:
  - `Interface of interfaceType: SynType * memberDefns: SynMemberDefns option`
  - `ObjExpr of objType: SynType * bindings: SynBinding list`
  - `member Range: range` — the range of the interface type.
  - `member TypeParameters: string[]` — the textual type parameters, from `SynType.Var/'T`, long idents, applications `T<...>`, arrays, measures, etc.
- `module InterfaceStubGenerator`:
  - `val GetInterfaceMembers: entity: FSharpEntity -> seq<FSharpMemberOrFunctionOrValue * seq<FSharpGenericParameter * FSharpType>>` — members across the inheritance chain in decreasing specificity (base-first), each paired with the generic-parameter→type instantiation for that interface.
  - `val HasNoInterfaceMember: entity: FSharpEntity -> bool`.
  - `val GetMemberNameAndRanges: interfaceData: InterfaceData -> (string * range) list` — names+ranges of existing member implementations (properties prefixed `get_`/`set_` where needed).
  - `val GetImplementedMemberSignatures: getMemberByLocation: (string * range -> FSharpSymbolUse option) -> FSharpDisplayContext -> InterfaceData -> Async<Set<string>>` — the set of signatures already implemented (used to skip them when generating).
  - `val IsInterface: entity: FSharpEntity -> bool` — interface or type abbreviation of one (recursively).
  - `val FormatInterface: startColumn: int -> indentation: int -> typeInstances: string[] -> objectIdent: string -> methodBody: string -> displayContext: FSharpDisplayContext -> excludedMemberSignatures: Set<string> -> FSharpEntity -> verboseMode: bool -> string` — generates the stub text.
  - `val TryFindInterfaceDeclaration: pos: pos -> parsedInput: ParsedInput -> InterfaceData option` — AST search for the interface at a caret position.

## Relation to .fs

The signature exposes the seven public entry points; the matching `.fs` implements them, plus internal helpers: `CodeGenerationUtils` (`ColumnIndentedTextWriter`, name normalization avoiding keyword/duplicate collisions), the `Context` record, `MemberInfo` (`PropertyGetSet` merging), signature builder, `[<AutoOpen>]`-like active patterns, and the AST-walking `walkExpr`/`walkBinding`/`walkSynMemberDefn` machinery backing `TryFindInterfaceDeclaration`.
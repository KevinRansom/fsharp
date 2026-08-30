# SymbolPatterns.fsi

**Purpose**
Declares `FSharpSymbolPatterns`, a module of active patterns for discriminating `FSharpSymbol` and
its subtypes (`FSharpEntity`, `FSharpType`, `FSharpSymbol`) at the *language* level — a
convenience layer over the many `Is*` predicates on the symbol classes. It exists so tooling can
`match` on symbol shape without repeating boilerplate, but is marked
`[<Experimental>]` — future redesign suggests checking properties directly (e.g.
`entity.IsFSharpRecord`, `entity.IsFSharpUnion`).

**Namespace(s)**
`namespace FSharp.Compiler.Symbols` (module is `[<RequireQualifiedAccess>]`)

**Modules / Types declared**
- `module FSharpSymbolPatterns` — ~35 active patterns (all `(... |_) : symbol -> ... -> 'a option`):
  - Entity shapes: `AbbreviatedType`, `TypeWithDefinition`, `Attribute`, `ValueType`, `Class`
    (parameterized by original/abbreviated entity triple), `Record`, `UnionType`, `Delegate`,
    `FSharpException`, `Interface`, `AbstractClass`, `FSharpType`, `ProvidedType`
    (`#if !NO_TYPEPROVIDERS`), `ByRef`, `Array`, `FSharpModule`, `Namespace`,
    `ProvidedAndErasedType` (`#if !NO_TYPEPROVIDERS`), `Enum`.
  - Type shapes: `Tuple`, `RefCell` (detects `FSharpRef`1`), `FunctionType`.
  - Symbol shapes: `Pattern` (union case or active pattern case), `Field` (returns
    `FSharpField * stripped FSharpType`), `MutableVar`, `FSharpEntity` (returns the
    `(originalEntity, abbreviatedEntity, abbreviatedType option)` triple), `Parameter`,
    `UnionCase`, `RecordField`, `ActivePatternCase`, `MemberFunctionOrValue`.
  - Member shapes: `Constructor` (detects `.ctor`/`.cctor` `CompiledName`), `Function`
    (parameterized by an `excluded: bool`), `ExtensionMember`, `Event`.
  - `internal hasModuleSuffixAttribute : FSharpEntity -> bool`.

**Public API surface**
All bindings are `val ...` active patterns as listed above. Notable signatures:
- `(|Class|_|) : original:FSharpEntity * abbreviated:FSharpEntity * 'a -> unit option` — note the
  odd `'a` parameter (must be supplied when the pattern is used).
- `(|FSharpEntity|_|) : FSharpSymbol -> (FSharpEntity * FSharpEntity * FSharpType option) option`
  — matches any entity and deconstructs abbreviation chains.
- `(|Function|_|) : excluded:bool -> ...` / constructor pattern usage: `Function false`.

**Internal helpers**
- `hasModuleSuffixAttribute` (internal; checks `CompilationRepresentationAttribute` with
  `ModuleSuffix` flag).
- `Option.attempt`-style try helpers in the .fs.

**Significant notes**
- The .fsi is the public contract; the .fs implements each pattern as a one-liner over symbol
  `Is*` properties plus small type-hierarchy walks (`Attribute` checks the base-type chain for
  `System.Attribute`; `RefCell` strips abbreviations and matches
  `Microsoft.FSharp.Core.FSharpRef`1`).
- Because the module is `Experimental` + `RequireQualifiedAccess`, it is opt-in for external
  tooling.

**Cross-references**
- `SymbolPatterns.fs` — implementations.
- `Symbols.fsi` — every predicate delegates to members there (`IsFSharpRecord`, `IsClass`,
  `StripAbbreviations`, `IsFunctionType`, `IsExtensionMember`, ...).
- `Exprs.fsi` — complementary patterns, but over expressions rather than symbols.

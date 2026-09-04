# SymbolPatterns.fs

**Purpose**
Implements `FSharpSymbolPatterns` (declared in `SymbolPatterns.fsi`): a library of active
patterns for discriminating F# symbols and types by language shape, used by tooling to match on
entities, types, fields, and members without spelling out `Is*` checks. Each pattern is a thin
adaptation of the corresponding `Is*` predicate or type inspection on the symbol API.

**Namespace(s)**
`namespace FSharp.Compiler.Symbols` (module is `[<RequireQualifiedAccess>]`)

**Modules / Types declared**
- `module FSharpSymbolPatterns`
  - Nested `module Option` — `attempt` helper (`try Some f() with _ -> None`).

**Patterns and helpers (implementation notes)**
- `hasModuleSuffixAttribute : FSharpEntity -> bool` (internal) — true if the entity carries a
  `CompilationRepresentationAttribute` with the `ModuleSuffix` flag (checked both as `int32` and
  as the enum, since pickled metadata can store either).
- `AbbreviatedType` — `entity.IsFSharpAbbreviation → entity.AbbreviatedType`.
- `TypeWithDefinition` — `ty.HasTypeDefinition → ty.TypeDefinition`.
- `getEntityAbbreviatedType` (private recursion) — follows an abbreviation chain to the first
  defining entity; used by `(|FSharpEntity|_|)` to return
  `(entity, abbreviatedEntity, abbreviatedType option)`.
- `Attribute` — walks the base-type chain looking for `System.Attribute` as
  `FullName` (defensive `try/with` against unresolved assemblies).
- `ValueType`, `Record`, `UnionType`, `Delegate`, `FSharpException`, `Interface`, `Enum`, `ByRef`,
  `Array`, `FSharpModule`, `Namespace` — single-property checks.
- `Class` — depends on `#if !NO_TYPEPROVIDERS`: with type providers, a non-static-instantiation
  class matches; without, only abbreviation-wrapped classes match. Note it takes the
  `(original, abbreviated, _)` triple.
- `AbstractClass` — `HasAttribute<AbstractClassAttribute>()`.
- `FSharpType` — matches delegate/exception/record/union/interface/measure entities, or any F#
  opaque entity that is not a module/namespace.
- `ProvidedType`, `ProvidedAndErasedType` — compiled only when type providers are enabled
  (`#if !NO_TYPEPROVIDERS`).
- Type patterns: `Tuple` (`IsTupleType`), `RefCell` (strip abbreviations, require defining entity
  `Microsoft.FSharp.Core.FSharpRef'1`), `FunctionType` (`IsFunctionType`).
- Symbol patterns: `Pattern` (`:? FSharpUnionCase` or `:? FSharpActivePatternCase`), `Field`
  (returns `FSharpField` + `FieldType.StripAbbreviations()`), `MutableVar` (mutable field or
  member/value), `Parameter`, `UnionCase`, `RecordField` (field whose declaring entity is a record),
  `ActivePatternCase`, `MemberFunctionOrValue`.
- Member patterns: `Constructor` (matches `CompiledName` of `.ctor`/`.cctor`, returns declaring
  entity), `Function` (takes `excluded: bool`; excludes property accessors, operator display names;
  checks `FullType` is a function type), `ExtensionMember`, `Event`.

**Internal helpers / active patterns**
- `Option.attempt` and the recursive `getEntityAbbreviatedType` are the only non-pattern helpers.
- All pattern bodies are single-expression guards over the public symbol API; no compiler-internal
  types are referenced here (except attribute types from `FSharp.Core`).

**Significant notes**
- `Function` is deliberately conservative: it fails (via `try/with`) if the underlying
  `FullType`/`DisplayName` computation throws for an unresolved symbol.
- The patterns exist primarily for FCS/IntelliSense display logic and external analyzers; the
  `[<Experimental>]` attribute on the module in the .fsi signals they may be redesigned (e.g. to
  direct `entity.IsFSharpRecord` checks instead).
- Some patterns intentionally duplicate `FSharpSymbol.IsEffectivelySameAs`-style distinctions:
  `RecordField` vs `Field` (record-specific), `Function` vs `MemberFunctionOrValue`.

**Cross-references**
- `SymbolPatterns.fsi` — the public contract (identical val signatures; .fs must stay in sync).
- `Symbols.fsi` — all `Is*` predicates, `AbbreviatedType`, `TypeDefinition`, `FieldType`,
  `StripAbbreviations` used here live on `FSharpEntity`/`FSharpType`/`FSharpField`/
  `FSharpMemberOrFunctionOrValue`.
- `Exprs.fsi` / `Exprs.fs` — the expression-level pattern module; this file is the
  symbol-level counterpart.

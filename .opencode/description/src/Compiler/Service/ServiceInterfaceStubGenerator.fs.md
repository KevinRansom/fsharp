# ServiceInterfaceStubGenerator.fs

Full implementation of the interface-stub generator (implement-interface quick fix) for the FSharp.Compiler.Service.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. Usage flow:
1. `TryFindInterfaceDeclaration pos parsedInput` — locate the `SynType` + existing member definitions at the caret by walking the untyped `ParsedInput` AST.
2. `GetInterfaceMembers entity` — enumerate all members the interface (and its inherited interfaces) demands, with generic instantiations.
3. `GetImplementedMemberSignatures` — crack existing member bindings (names + ranges), resolve each to an `FSharpSymbolUse` via `getMemberByLocation`, and format `DisplayName:type` signatures to build the excluded set.
4. `FormatInterface` — emit, into a `ColumnIndentedTextWriter`, one `member ... = ...` line per missing member (getters/setters merged when they clearly match), with an object identifier (`x`/`this`/`__`), verbose vs. brief syntax, type substitutions for specialized interface instantiations, and per-line skeleton bodies. Empty result if nothing is missing.

## Namespaces / opens

- `FSharp.Compiler.EditorServices` — with `open System`, `System.Diagnostics`, `Internal.Utilities.Library`, `FSharp.Compiler.CodeAnalysis`, `EditorServices.ParsedInput`, `Symbols`, `Syntax`, `SyntaxTreeOps`, `Text`, `Text.Range`, `Tokenization`.

## Module `CodeGenerationUtils` (internal, `[<AutoOpen>]`)

- `type ColumnIndentedTextWriter()` — a `StringWriter` + `System.CodeDom.Compiler.IndentedTextWriter` pair abstracting a "column+indent" text buffer for code generation.
  - `Write`, `WriteLine`, `WriteBlankLines count`, `Indent i`, `Unindent i` (never below 0), `Dump()` → final string (with `!!` for null-forgiving on platforms where `ToString` may be nullable), `IDisposable` disposal of both writers.
- `type NamesWithIndices = Map<string, Set<int>>` — tracks each captured identifier and the trailing indices already used.
- `keywordSet = set FSharpKeywords.KeywordNames`.
- `normalizeArgName (namesWithIndices) nm`:
  - `"()"` passes through unchanged.
  - lower-cases first char, extracts trailing numeric index, finds next free index for a name already seen, re-appends the index (`arg1`, `arg2`, ...), and wraps in backticks (`` `name` ``) if it collides with an F# keyword. Returns the name and an updated `NamesWithIndices`.

## `InterfaceData` (public union)

`Interface of interfaceType: SynType * memberDefns: SynMemberDefns option` and `ObjExpr of objType: SynType * bindings: SynBinding list`.
- `member Range` = range of the type.
- `member TypeParameters` — textual generic parameter names extracted from the stripped type:
  - Active pattern `RationalConst` prints integer/rational/negated/parenthesized values (`- %s`, `(%s)`).
  - Active pattern `TypeIdent` matches `SynType.Var` (with `'` or `^` static-requirement prefix), `LongIdent` (dot-joined), `App` (generic `T<...>`/postfix notation), `Anon` (`_`), `AnonRecd`, `Array` (`T [,,]`), `MeasurePower` (`T^2`), `Paren`.
  - For top-level `SynType.App`/`LongIdentApp`, collects the type args into `string[]`; otherwise `[||]`.

## `InterfaceStubGenerator` module

### Internal types & helpers

- `type Context` (`[<NoComparison>]` record; internal) — `Writer: ColumnIndentedTextWriter`, `TypeInstantiations: Map<string,string>` (generic name → concrete instance), `ArgInstantiations: (FSharpGenericParameter * FSharpType) seq`, `Indentation: int` (inside method bodies), `ObjectIdent: string`, `MethodBody: string[]`, `DisplayContext: FSharpDisplayContext`.
- Active pattern `|AllAndLast|_|` — splits a list into (all-but-last, last).
- `getTypeParameterName typar` — `^` for compile-time-solved (statically resolved type parameter), `'` otherwise.
- `bracket str` — wraps in parens if it contains a space.
- `formatType ctx ty` — `ty.Instantiate(ctx.ArgInstantiations).Format(ctx.DisplayContext)` then replaces mapped name→instance text.
- `formatArgUsage ctx hasTypeAnnotation namesWithIndices arg` —
  - anonymous `unit` arg → `"()"`; other unnamed args → `argN` (counter is sum of used name counts, min 1).
  - `normalizeArgName`; optional args prefixed `?`; when `hasTypeAnnotation` (verbose mode) adds `name: type` unless the arg is `()`.
  - Returns (text, updated names map).
- `formatArgsUsage ctx hasTypeAnnotation v args` — folds all curried groups; initializes `namesWithIndices` with `{objectIdent -> Set.empty}` (so the object ident is never reused). Joins:
  - no args → `()`;
  - single `unit` → `()`;
  - single arg for non-members / indexers (`Item`) → bare `arg`;
  - indexer args joined by `, ` (tuple);
  - otherwise joined (or bracketed) args.
- `type MemberInfo` (internal, `[<RequireQualifiedAccess; NoComparison>]`) — `PropertyGetSet of (FSharpMemberOrFunctionOrValue * FSharpMemberOrFunctionOrValue)` | `Member of FSharpMemberOrFunctionOrValue`.
- `getArgTypes ctx v` — converts `CurriedParameterGroups` to a list-of-lists; for property setters drops the trailing implicit `unit` arg and keeps `last.Type` as the value type; getters without args → no args, `Some retType`; `None` → `"unit"`. Return type special-cased: `IEvent<_, _>` wrapping when the setter's type derives from `System.MulticastDelegate` (event-handler detection); otherwise the formatted core type.
- `normalizePropertyName v` — strips `get_`/`set_` prefixes from property getter/setter method display names.
- `isEventMember m` — `m.IsEvent || m.HasAttribute<CLIEventAttribute>`.
- `formatMember ctx m verboseMode`:
  - `getParamArgs` — computes the argument usage text; drops a synthetic `unit` arg for getters; parenthesizes multi-arg groups or (for curried >1 groups in brief mode) space-separates like F# function application.
  - `preprocess ctx v` → `(usage, modifiers, argInfos, retType)`:
    - usage: `.ctor` → `new<args>`; property getter/setter → property display name; instance member → `name(parArgs)`; plain member of non-`RequireQualifiedAccess` module → `name parArgs`; else `name(parArgs)`.
    - modifiers: `inline` (if `AlwaysInline`), `internal` (if internal accessibility).
  - Emits `member <modifiers> <objectIdent>.name ...` lines.
  - `closeDeclaration returnType` — in verbose mode writes `: returnType`; always writes `= `; newline in verbose mode.
  - `writeImplementation` — no-body (verbose multi-line mode) indents and writes `ctx.MethodBody` lines; brief single-line mode writes the line inline.
  - `PropertyGetSet` case merges getter+setter into `with get ... / and set ...` (value arg normalized as `v`), emitting `[<CLIEvent>]`? (no — that's the Member case) — merging only when the pair matches (see `formatMembers`).
  - `Member` case: emits `[<CLIEvent>]` for event members; handles events (bare add accessor), setters (`with set (v: type): unit =` with verbose typing), getters (short-hand `= body` when no args; `with get args` otherwise), and ordinary members.
- `getNonAbbreviatedType ty` — follows `AbbreviatedType` chains.
- Active pattern `|MemberFunctionType|_|` — matches function types with 2 generic args, returning the 2nd (interface member symbolic type sometimes stored as `I<'T> -> memberType`).
- Active pattern `|TypeOfMember|_|` — `m.FullTypeSafe` → `MemberFunctionType` for F# property members on `DeclaringEntity`, else the plain type.
- `removeWhitespace str`.
- `getInterfaces e` — `e.AllInterfaces`, non-abbreviated; returns distinct `(typeDefinition, genericParameter*genericArgument zips)` (lazy args).
- `GetInterfaceMembers entity` — for each (iface, instantiations): `TryGetMembersFunctionsAndValues`, **excluding** properties and `add_`/`remove_` event methods (FCS metadata quirk workaround).
- `HasNoInterfaceMember entity` — `GetInterfaceMembers |> Seq.isEmpty`.
- Active pattern `|LongIdentPattern|_|` on `SynPat.LongIdent` → (last ident text, its range).
- Active pattern `|MemberNameAndRange|_|` on `SynBinding`:
  - PropertyGet members get `get_` prefix if the pattern name doesn't already carry it; PropertySet members likewise `set_`; ordinary bindings just the name + range (merging `get`/`set` on the same logical property needs disambiguation because both share ranges).
- `GetMemberNameAndRanges interfaceData` — from `InterfaceData.Interface(_, Some members)` collects `SynMemberDefn.Member` and `GetSetMember` bindings; from `ObjExpr` walks the bindings; selects via `|MemberNameAndRange|_|`.
- `normalizeEventName m` — strips `add_`/`remove_` prefixes.
- `GetImplementedMemberSignatures getMemberByLocation displayContext interfaceData : Async<Set<string>>`:
  - For each (name, range): `getMemberByLocation(name, range)`. Explain: resolves the symbol; if it's an `FSharpMemberOrFunctionOrValue`:
    - event members → signature = `normalizeEventName`.
    - others → `DisplayName+":"+ FullType.Format(displayContext)` (whitespace removed).
  - Non-member symbols → member-signature not recorded.
  - Returns the deduped signature set.
  - Note the crude-vs-FCS comment: signatures aren't exposed on error symbols, so names+ranges crack the AST and symbols are re-resolved by location.
- `IsInterface entity` — `entity.IsInterface` or (F# abbreviation whose abbr'd `TypeDefinition` is itself an interface).
- `FormatInterface startColumn indentation (typeInstances: string[]) objectIdent (methodBody: string) displayContext excludedMemberSignatures (e: FSharpEntity) verboseMode : string`:
  - `Debug.Assert(IsInterface e)`.
  - Split method body into lines (`String.getLines`).
  - Build `TypeInstantiations` map from `getTypeParameterName e.GenericParameters` zipped with `typeInstances`, keeping only entries where `t1 <> t2 && t2 <> "_"`; for abbreviations, additionally fold the abbrev's underlying generic params/args.
  - Construct `Context`.
  - `missingMembers` — `GetInterfaceMembers e |> groupBy signature`:
    - events → `normalizeEventName` as the key;
    - `TypeOfMember` → `removeWhitespace (sprintf "%s:%s" m.DisplayName (formatType {ctx with ArgInstantiations=insts} ty))`;
    - failures → group (kept, unfiltered).
    - If a group's signature is not in `excludedMemberSignatures`, keep only its first member (one stub per signature).
  - All implemented → `String.Empty`.
  - Else: indent `startColumn`, blank line, detect duplicated member display names (same name+arity) to force verbose declarations for them, then `formatMembers` recursively:
    - getter+setter pairs adjacent in sorted order with equal `normalizePropertyName` and equal return type → merge into `MemberInfo.PropertyGetSet` (verbose forced if duplicated).
    - otherwise single `MemberInfo.Member`.
    - Order is `Seq.sortBy (normalizePropertyName m, getReturnType m)` so getter/setter pairs are contiguous for merging.
  - Returns `writer.Dump()`.
- `TryFindInterfaceDeclaration (pos: pos) (parsedInput: ParsedInput) : InterfaceData option`:
  - Recursive AST walk: `walkImplFileInput` → `walkSynModuleOrNamespace` → `walkSynModuleDecl` → `walkSynTypeDefn`/`walkSynTypeDefnRepr` → `walkSynMemberDefn` → `walkBinding` → `walkExpr`, every step range-checked against `pos`.
  - Yields `InterfaceData.Interface(interfaceType, members)`: `SynMemberDefn.Interface` — when `pos` is within the interface type range; otherwise continues into the member defns.
  - `SynExpr.ObjExpr`: when no base-call: if pos in object type → `InterfaceData.ObjExpr(ty, unionBindingAndMembers binds ms)`; else checks each `SynInterfaceImpl` range. With a base-call present (plain object creation) → `None`.
  - Full `SynExpr` case coverage (quotes, parens, tuples, arrays, records, `new`, while/for loops, lambdas, matches, apps, let/use, try, sequentials, conditionals, dot/get/set forms, indexers, casts, address-of, trait calls, CE keywords, `LibraryOnly*`, `FromParseError`/`DiscardAfterMissingQualificationAfterDot`), returning `None` at leaves (`Ident`, `LongIdent`, `Const`, `Null`, `ImplicitZero`, etc.).
  - `ParsedInput.SigFile` → `None`; only `ImplFile` is searched.

## Key notes

- The stub text is generated without a checker round-trip: everything derives from `FSharpEntity`, `FSharpDisplayContext`, and AST ranges.
- Signature comparison is deliberately whitespace-tolerant (`removeWhitespace`) and uses `DisplayName`/`FullType` formatting, so already-implemented members with slightly different spacing still count as done.
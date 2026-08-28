# ServiceStructure

**Purpose:** Computes the "structure" (block outline) of a source file from its **untyped** parse tree, producing the ranges used by IDE code-folding/outlining and the structure (outline) API. Each scope (module, type, member, `let`, `match`, `for`, record/union/enumeration definition, attributes, XML doc comments, etc.) is tagged with a `Scope`, a `Collapse` style, an overall `Range`, and a `CollapseRange` (the span that would be hidden when collapsed).

**Namespace(s):** `FSharp.Compiler.EditorServices`

## Declared types / modules
- `Structure` (module, public): the whole feature entry point.
- `Structure.Range` (module, `RequireQualifiedAccess`): range-composition helpers — `endToEnd`, `endToStart`, `startToEnd`, `startToStart`, `modStart`, `modEnd`, `modBoth` (shift start/end columns, used to shrink/expand collapse ranges around tokens like `=` or `type`).
- `Collapse` (union, `RequireQualifiedAccess`): `Below` (collapse under the line — e.g. RHS of a `let`) vs `Same` (collapse alongside, e.g. `[| ... |]` list literals, record/union definitions).
- `Scope` (union, `RequireQualifiedAccess`): one case per outlineable construct — `Open`, `Namespace`, `Module`, `Type`, `Member`, `LetOrUse`, `Val`, `ComputationExpr`, `IfThenElse` (+`ThenIn`/`ElseIn`), `TryWith` (+`TryIn`/`WithIn`), `TryFinally` (+sub-scopes), `ArrayOrList`, `ObjExpr`, `For`, `While`, `Match`, `MatchBang`, `MatchLambda`, `MatchClause`, `Lambda`, `Quote`, `Record`, `SpecialFunc`, `Do`, `New`, `Attribute`, `Interface`, `HashDirective`, `LetOrUseBang`, `TypeExtension`, `YieldOrReturn`, `YieldOrReturnBang`, `Tuple`, `UnionCase`, `EnumCase`, `RecordField`, `RecordDefn`, `UnionDefn`, `Comment`, `XmlDocComment`; has `ToString`.
- `ScopeRange` (record, `NoComparison`): `Scope`, `Collapse`, `Range` (HintSpan/BlockSpan), `CollapseRange` (TextSpan).
- `LineNumber` / `LineStr` (typedefs): `int` / `string`.
- `CommentType` (union): `SingleLine | XmlDoc`.
- `CommentList` (record, `NoComparison`): accumulated comment lines + type; static `New`.
- `getOutliningRanges: sourceLines: string[] -> ParsedInput -> seq<ScopeRange>` — the public API.

## Public API surface
- `Structure.getOutliningRanges (sourceLines, parsedInput)` — returns the full set of outline scopes for a file; `sourceLines` is required because some scopes (e.g. comment-based) need raw line text as well as ranges.

## Internal helpers (notable)
- `longIdentRange` — span from first to last ident of a long id.
- `rangeOfTypeArgsElse other typeArgs` — union range of `SynTyparDecl` ranges, or a fallback.
- `rcheck scope collapse fullRange collapseRange` — the central accumulator: only records the scope when it spans 2+ lines (single-line scopes are not worth collapsing).
- Recursive parsers (defined mutually inside `getOutliningRanges`): `parseExpr`, `parsePat`, `parseTypeDefn`, `parseSimpleRepr` (record/union/enum case scopes), `parseSynMemberDefn`, `parseAttributes`, `parseSynModuleDecl`, etc. — each emits `rcheck` calls for the constructs it covers, handling object-model types (classes, interfaces, augmentations) and simple types (records, unions, enums) differently.
- `getConsecutiveModuleDecls` — groups consecutive `let`/`val` bindings into a single outline scope (so a block of top-level bindings folds as one).

## Significant internal logic
- Collapse-style choice follows the rule "delimiters ⇒ `Same`, statements ⇒ `Below`" (see `Scope`/`Collapse` comments).
- Type parameters contribute to the collapse start (`Range.modEnd 1 typeArgsRange`) so generics stay visible when collapsed.
- XML doc comments and regular comments are captured as scopes (`Comment`/`XmlDocComment`) using `CommentList`/`CommentType`, combined with trivia info from the parse tree.
- Output is a flat `seq<ScopeRange>` (no nested tree) — the consumer (IDE outline) infers nesting from range containment.

## Cross-references
- `src/Compiler/SyntaxTree` (`SynModuleOrNamespace`, `SynTypeDefn`, `SynMemberDefn`, `SynBinding`, `SynExpr`) — the tree being walked
- `ServiceParseTreeWalk.fs` (generic traversal alternative; this module does a bespoke one for outlining)
- `FSharpCheckerResults.fs` (exposes `GetOutliningRanges`/structure to the service)
- `src/Compiler/SyntaxTrivia` (comment trivia consumed for the doc-comment scopes)

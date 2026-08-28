# ServiceParamInfoLocations

**Purpose:** Computes, purely from the **untyped** parse tree, the positions relevant to activating "parameter info" (signature help) in an IDE — where the call's open-paren is, where each argument begins/ends, where commas/close-paren sit, and which arguments are named — so editors can light up the correct parameter slot as the user types inside a call.

**Namespace(s):** `FSharp.Compiler.EditorServices`

## Declared types / modules
- `TupledArgumentLocation` (record): `IsNamedArgument: bool` + `ArgumentRange: range`.
- `ParameterLocations` (sealed class, public): one result — `LongId` (path parts), `LongIdStartLocation`/`LongIdEndLocation`, `OpenParenLocation`, `TupleEndLocations: pos[]`, `IsThereACloseParen: bool`, `NamedParamNames: string option[]` (`None` for positional, `Some name` for `a=...`/`?b=...`), `ArgumentLocations: TupledArgumentLocation[]`. Public entry: `static member Find: pos * ParsedInput -> ParameterLocations option`.
- `ParameterLocationsImpl` (internal AutoOpen module): the analysis logic.
- `SynExprAppLocationsImpl` (internal module, per .fsi): exposes `getAllCurriedArgsAtPosition: pos -> ParsedInput -> range list option` — the ranges of all curried argument expressions at a position.

## Public API surface
- `ParameterLocations.Find (pos, parsedInput)` — the only public entry; returns locations for the call enclosing `pos`, or `None` when not inside a call expression.

## Internal helpers (notable, `ParameterLocationsImpl`)
- `isStaticArg` — recognizes static-argument positions (`TP<42, ...>`), accepting `SynType.LongIdent` as a "prefix of incomplete code".
- `digOutIdentFromFuncExpr` — extracts the callable identifier (and its range) from the function expression of an application (handles `Ident`, `LongIdent`, `DotGet`, `TypeApp`, `Paren`).
- `digOutIdentFromStaticArg` — extracts a named static argument identifier.
- `getNamedParamName` — big pattern matcher recognizing named-argument desugaring `op_Equality` applications for both `x=4` and `?x=4` optional-argument forms.
- `getTypeName` — gets a long-ident type name (for `typeApp`/static-arg contexts).
- `handleSingleArg` — processes one parenthesized argument group, detecting if the cursor falls inside that argument and building the `Found` record.
- `FindResult` (internal union): `Found of openParen * argRanges * commasAndCloseParen * hasClosedParen | NotFound`.

## Significant internal logic
- Walks outward from the position over `SynExpr.App` / `ParenthesizedApp` / `TypeApp` shapes, reconstructing argument boundaries from the parser's comma/paren ranges rather than re-tokenizing.
- Handles curried calls, optional arguments (`?x`), named arguments, static arguments (`<...>`), and constructor calls (record/union) — see unit-test reference in comments (e.g. "CallConstructorViaLongId.Bug94333") for edge-case coverage expectations.
- Result invariants: `TupleEndLocations.Length == NamedParamNames.Length` (a trailing `None` is synthesized when the argument list is incomplete, mirroring how the parser injects a fake `AbrExpr`).

## Cross-references
- `src/Compiler/SyntaxTree` (`SynExpr`, `SynType`, `SynIdent`, `SynLongIdent`, `ExprAtomicFlag`)
- `ServiceParseTreeWalk.fs` (`SyntaxTraversal.rangeContainsPosLeftEdgeExclusiveAndRightEdgeInclusive` used to test cursor containment)
- `FSharpCheckerResults.fs` (calls `ParameterLocations.Find` from the service entry point)
- Language-server "signatureHelp" handler (consumer)

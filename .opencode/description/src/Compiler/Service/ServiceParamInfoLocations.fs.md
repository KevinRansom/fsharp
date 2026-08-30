# ServiceParamInfoLocations.fs

Full implementation of parameter-info location discovery in the FSharp.Compiler.Service.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. The core function is `ParameterLocations.Find(pos, parseTree)`: using `SyntaxTraversal.Traverse` with a custom `SyntaxVisitorBase<_>`, it locates the application containing the caret and then refines where the caret sits within the argument list. The result powers parameter-help windows: which overload, which parameter is highlighted (`TupleEndLocations`/`NamedParamNames`/`ArgumentLocations`), and whether a completion trigger (the open paren) is active. It is deliberately tolerant of incomplete code — error-recovery AST nodes (`ArbitraryAfterError`, `TypeApp` with a `<` only, tuple-syntax with missing args) are all handled.

## Namespaces / opens

- `FSharp.Compiler.EditorServices` with `open FSharp.Compiler.Text`, `Text.Position`, `Text.Range`, `FSharp.Compiler.Syntax`, `FSharp.Compiler.SyntaxTreeOps`.

## Public data type

`TupledArgumentLocation = { IsNamedArgument: bool; ArgumentRange: range }`.

## `ParameterLocations` (sealed class)

Internal constructor `(longId, longIdRange, openParenLocation, argRanges: TupledArgumentLocation list, tupleEndLocations: pos list, isThereACloseParen, namedParamNames: string option list)`.

- Arrays `tupleEndLocations`, `namedParamNames` built from the lists. The named-param array is **normalized**: if lengths differ (exactly when `tupleEndLocations.Length = namedParamNames.Length + 1` — the missing trailing static argument case in `TP<` / `TP<42,`, where the parser does not inject the fake missing arg it does for `f(`/`f(42,`), a trailing `None` is appended. An `assert` guards the invariant.
- Public members: `LongId`, `LongIdStartLocation`/`LongIdEndLocation` (from `longIdRange`), `OpenParenLocation`, `TupleEndLocations`, `IsThereACloseParen`, `NamedParamNames`, `ArgumentLocations` (array of the arg ranges).

## Module `ParameterLocationsImpl` (`[<AutoOpen>]`, internal)

- `isStaticArg (StripParenTypes ty)` — `true` for `SynType.StaticConstant*` and (deliberately) `SynType.LongIdent` (prefix of an in-progress named static arg like `TP<42, Arg3`).
- `digOutIdentFromFuncExpr synExpr` (recursive) — extracts `(path, range)` from `SynExpr.Ident`, `LongIdent` (dotted long id, with special case for a single ident + `arity`), `DotGet`, digging through `TypeApp` and `Paren`. Used to name the function/id being applied.
- `type FindResult = Found of openParen: pos * argRanges: TupledArgumentLocation list * commasAndCloseParen: (pos * string option) list * hasClosedParen: bool | NotFound`.
- `digOutIdentFromStaticArg (StripParenTypes ty)` — name of a (possibly `Named`) static argument's long ident.
- `getNamedParamName e` — detects `f(x=4)` / `f(?x=4)`: an application of the built-in `op_Equality` to an `Ident` (or long ident) — returns the argument name.
- `getTypeName synType` — `SynType.LongIdent` → path; else `[ "" ]` (TODO noted with the `Bug94333` unit test reference).
- `handleSingleArg traverseSynExpr (pos, synExpr, parenRange, rpRangeOpt)` — single-argument paren: if the inner expression contains no further application of interest and the caret is in `parenRange` (left-edge-exclusive/right-edge-inclusive), produce `Found` with a one-element arg list and `( parenRange.End, name )` as the comma/close entry.
- `searchSynArgExpr traverseSynExpr pos expr` — the heart of argument scanning. It returns a tuple `(result, cacheOption)` where `cacheOption = Some(cache)` records when it already invoked `traverseSynExpr` (avoiding recomputation — perf, bug 345385):
  - `SynExprParen(Tuple(false, exprs, commaRanges, _))` — **tuple argument**: maps each element to an arg range+namedness, and pairs each element with a comma position (`commaRanges @ [parenRange]`) for `commasAndCloseParen`; `hasClosedParen = rpRangeOpt.IsSome`.
  - `Paren(Paren(Tuple …))` and nested `Paren(Paren …)` — special single-tuple-arg / multiline-paren cases → `handleSingleArg` or recursive descent.
  - `Paren(e, …, rpRangeOpt, parenRange)` — single (possibly named) argument via `handleSingleArg`.
  - `ArbitraryAfterError` — caret in the pseudo-arg range (hitting EOF after open paren): `Found(…, [], [ (range.End, None) ], false)`.
  - `Const Unit` — `f()` → empty args, closed paren.
  - any other expression — treat as a paren-less single argument (`f x`): cache the inner traverse result.
- Active pattern `StaticParameters pos (StripParenTypes ty)` — matches `SynType.App(LongIdent, Some mLess, args, commas, mGreaterOpt, …)`: if the caret is within the `<…>` range and **all** args are static constants, builds `ParameterLocations(pathOfLid lid, lidm, mLess.Start, [], commaEnds@[wholem.End], mGreaterOpt.IsSome, staticArgNames)`. This drives type-provider static-argument parameter info (`T<42,...>`).
- `traverseInput (pos, parseTree)` — `SyntaxTraversal.Traverse(pos, parseTree, visitor)` where the visitor handles:
  - `SynExpr.New(_, synType, synExpr, _)` — constructor call: `searchSynArgExpr` over the argument expression; on `Found` builds a `ParameterLocations` (using `getTypeName synType` and the cached close-paren data); on `NotFound, Some cache` uses the inner cache; otherwise tries `StaticParameters` on the constructor type (error-recovery for `new TP<42>(` prefix) then falls back to traversing the argument.
  - `SynExpr.App(…, SynExpr.App(_, true, LongIdent op_LessThan, synExpr, _), ArbitraryAfterError _, wholem)` — **`EXPR<` recovery**: after the function-expression search fails, if the caret is inside `<…end` it digs out the ident and returns `ParameterLocations(lid, mLongId, op.idRange.Start, [], [wholem.End], false, [])`.
  - `SynExpr.App(_, isInfix, synExpr, synExpr2, _)` — ordinary application: first the function expression; then `searchSynArgExpr` over the argument; on `Found` digs out the ident; asserts `isInfix = (posLt parenLoc mLongId.End)` and rejects actual infix operators (unsupported); otherwise recurses into the argument expression.
  - `SynExpr.TypeApp(synExpr, mLess, tyArgs, commas, mGreaterOpt, _, wholem)` — **`ID<tyarg1,…>`**: if inside `<…>`, all args static — returns `ParameterLocations([ "dummy" ], synExpr.Range, mLess.Start, argRanges, …, mGreaterOpt.IsSome, staticArgNames)` (the `dummy` id is the historical API shape). Also covers the error-recovery forms.
  - `VisitTypeAbbrev` — `StaticParameters` on the abbreviation RHS (type-provider abbreviations).
  - `VisitImplicitInherit` — `inherit DbContext(...)`: after default traversal, if the caret is inside the inherit statement, `searchSynArgExpr` over the constructor args → `ParameterLocations(typeName, ty.Range, …)` treating the inherited ctor call as an application.
  - `defaultTraverse` for all other expressions.

## `ParameterLocations.Find` (static, extension member on `ParameterLocations`)

- Runs `traverseInput (pos, parseTree)`; in `DEBUG` builds the list of all reported positions and **asserts they are sorted** (`posOrder`), ensuring monotonic locations for the UI; otherwise returns the result.

## Module `SynExprAppLocationsImpl` (internal)

`getAllCurriedArgsAtPosition pos parseTree : range list option`:
- `searchSynArgExpr` (private, different signature than the one above): collects the **ranges of all curried arguments** (`f a b c` → `[a;b;c]`) rather than paren/comma locations:
  - `Const Unit` → nothing.
  - `Paren(Tuple …)` → all element ranges.
  - nested parens → recurse.
  - `Paren(App …)` → the whole paren range.
  - any other expr → its range (with cache propagation).
- The visitor matches `SynExpr.App` only when `posEq pos range.Start`; skips infix applications; otherwise gathers functional ranges + argument ranges. Result `RangeOption.map List.rev` (used by the "match expressions across arguments" feature like `Printf`/text-template tooling).
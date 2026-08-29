# ServiceParamInfoLocations.fsi

**Signature for `ServiceParamInfoLocations.fs`.** Declares the parameter-info activation API of the FSharp.Compiler.Service: given a caret position and the untyped `ParsedInput`, find the exact locations that describe the application whose argument is currently being typed, so the IDE can show a parameter-help/tooltip window and highlight the active argument.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. `ParameterLocations.Find(pos, parseTree)` (a static member) walks the syntax tree from the caret outward and, when the caret is inside a call's argument list, returns:
- the long identifier of the function being called (plus its start/end positions),
- the opening paren position,
- the positions of every comma and of the closing paren (or last arg char when there is no close paren),
- whether a close paren exists,
- the names of named parameters (`f(0,a=4,?b=None)` → `[None; Some "a"; Some "b"]`),
- the per-argument ranges and named-ness (`TupledArgumentLocation[]`).

This covers ordinary function applications (`f(x,y)`), indexers/type applications (`T<42,"foo">` static parameters), constructors (`new C(...)`), inherited-constructor calls (`inherit DbContext(...)`), and error-recovery cases (half-typed `f(x,y` or `TP<`).

## Namespaces

- `FSharp.Compiler.EditorServices` with `open FSharp.Compiler.Syntax`, `FSharp.Compiler.Text`.

## Public types (declared)

- `type TupledArgumentLocation` (record): `IsNamedArgument: bool`, `ArgumentRange: range`.
- `type ParameterLocations` (`[<Sealed>]`):
  - `member LongId: string list` — text of the long identifier before the parens.
  - `member LongIdStartLocation: pos`; `member LongIdEndLocation: pos`.
  - `member OpenParenLocation: pos`.
  - `member TupleEndLocations: pos[]` — commas and close paren (or last char of the last arg if no final close paren).
  - `member IsThereACloseParen: bool` — false either for paren-less calls (`f x`) or recovered cases (`f(x,y`).
  - `member NamedParamNames: string option[]` — per-argument names (empty/None for non-named).
  - `member ArgumentLocations: TupledArgumentLocation[]` — per-argument range + named flag.
  - `static member Find: pos * ParsedInput -> ParameterLocations option`.
- `module internal SynExprAppLocationsImpl`:
  - `val getAllCurriedArgsAtPosition: pos: pos -> parseTree: ParsedInput -> range list option` — all curried argument ranges at the caret (perf-shared helper).

## Relation to .fs

The `.fs` implements `ParameterLocations` with an internal constructor plus the primary walker `ParameterLocationsImpl.traverseInput` (a `SyntaxTraversal`/`SyntaxVisitorBase` visitor), argument-location search `searchSynArgExpr`, static-argument parsing (`StaticParameters` active pattern, `isStaticArg`, `digOutIdentFromStaticArg`), named-parameter detection (`getNamedParamName`), and identifier digging (`digOutIdentFromFuncExpr`). The `.fsi` exposes only the four public data members and `Find`; all machinery and the second module's helper are internal.
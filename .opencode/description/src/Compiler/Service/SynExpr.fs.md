# SynExpr.fs

## Pipeline role

This file belongs to the Service folder of the F# compiler. It implements `SynExpr.fsi`'s `shouldBeParenthesizedInContext` decision procedure, plus the internal helper types and active patterns it relies on. The module answers "can this `SynExpr` be written without its surrounding parentheses without changing the program's meaning?" by comparing operator precedences and associativity, checking raw source-line indentation and trivia, and walking the ancestor path to detect ambiguous, dangling, shadowing, and undentation-sensitive constructs. Nothing in this file produces a library/API surface; everything exists to support the formatting/AST-edit pipeline.

## Namespaces, opens

- Namespace `FSharp.Compiler.Syntax`.
- Opens `System`, `FSharp.Compiler.SyntaxTrivia`, `FSharp.Compiler.Text`.
- `module SynExpr`, marked `[<RequireQualifiedAccess>]` and `[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`.

## Private active patterns

- `let (|Last|) = List.last` — extracts the last element of a list (used to inspect the trailing nested expression of tuples, app arguments, match clauses, etc.).
- `let inline (|Is|_|) (inner1: 'a) (inner2: 'a)` (returns `ValueSome Is` / `ValueNone`) — matches when two values are the *same object* (`obj.ReferenceEquals`), used to detect that the current `expr` is literally a sub-expression of the outer node.

## Types

### `MulDivMod` — symbolic infix operator with `*`, `/`, `%` precedence

- Cases: `Mul`, `Div`, `Mod`.
- `[<CustomComparison; CustomEquality>]`.
- `CompareTo` always returns `0`; `Equals` returns `this.CompareTo(unbox obj) = 0`; `GetHashCode()` returns `0`. All instances of this type are considered equal, so precedence comparison never depends on which of `*`, `/`, `%` the operator is.
- Implements `IComparable`.

### `AddSub` — symbolic infix operator with `+`, `-` precedence

- Cases: `Add`, `Sub`.
- Same `[<CustomComparison; CustomEquality>]` arrangement: all instances equal (`CompareTo` is 0, hash is 0), implements `IComparable`.

### `OriginalNotation`

- Single case `OriginalNotation of string` — holds a symbolic operator's original written text (e.g. `"+":`), so equality is content-based (`String.Equals(this, other, StringComparison.Ordinal)`) while `CompareTo` always returns 0 and hash is the string hash. Implements `IComparable`.

### `Precedence` — expression precedence

- Cases (with doc comments): `Low` (yield/yield!/return/return!), `Set` (`<-`), `ColonEquals` (`:=`), `Comma` (`,`), `BarBar of OriginalNotation` (`or`, `||`), `AmpAmp of OriginalNotation` (`&`, `&&`), `UpcastDowncast` (`:>`, `:?>`), `Relational of OriginalNotation` (`=`, `|`, `&`, `$`, `>`, `<`, `!=`, …), `HatAt` (`^`, `@`), `Cons` (`::`), `TypeTest` (`:?`), `AddSub of AddSub * OriginalNotation` (`+`, `-`), `MulDivMod of MulDivMod * OriginalNotation` (`*`, `/`, `%`), `Exp` (`**`), `UnaryPrefix` (`- x`), `Apply` (`f x`), `High` (`-x`, `!… x`, `~~… x`), `Dot` (`x.y`).
- Comparison is based only on the precedence case; equality additionally considers the embedded `OriginalNotation` (e.g. `compare (AddSub (Add, OriginalNotation "+")) (AddSub (Add, OriginalNotation "++")) = 0` but the two are not `=`).

### `Assoc` — associativity

- Cases: `Non` (non-associative / no association), `Left` (left-associative / left-hand association), `Right` (right-associative / right-hand association).
- `module Assoc` — `let ofPrecedence precedence` maps each `Precedence` case to its associativity:
  - `Non`: `Low`, `Set`, `Comma`, `TypeTest`.
  - `Right`: `ColonEquals`, `UpcastDowncast`, `HatAt`, `Cons`, `Exp`.
  - `Left`: `BarBar _`, `AmpAmp _`, `Relational _`, `AddSub _`, `MulDivMod _`, `UnaryPrefix`, `Apply`, `High`, `Dot`.
- `Dot` is `Left` (note: `OuterBinaryExpr` may return `Non` or `Left` for dot-style nodes).

## Internal active patterns and helpers

- `(|AtomicExprAfterType|_|)` (`[<return: Struct>]`, returns `ValueSome AtomicExprAfterType`) — matches expressions that may follow a type after `inherit T(…)` or `new T(…)` without parens: `Paren`, `Quote`, `Const`, struct `Tuple`, `Record`, `AnonRecd`, `InterpolatedString`, `Null`, array `ArrayOrList(isArray = true)`, `ArrayOrListComputed(isArray = true)`. Mirrors `atomicExprAfterType` in `pars.fsy`.
- `(|HighPrecedenceApp|_|)` — matches a high-precedence function application like `f x` or `(+) x y`: a non-infix `App` whose `funcExpr` is an `Ident`/`LongIdent`, or a nested non-infix `App`.
- `module FuncExpr` — `(|SymbolicOperator|_|)` matches a `LongIdent` whose `SynLongIdent` trivia holds a symbolic operator; `tryPick` scans the trivia list for the first `IdentTrivia.OriginalNotation op` and returns that notation string.
- `(|PrefixApp|_|)` returns a `Precedence voption` — matches `-x`, `~~~x`, `!x` etc.: a non-infix `App` with a symbolic-operator `funcExpr`; if `funcExpr`'s range is adjacent to the argument's, precedence is `High`, else `!`/`~`-first operators give `High` and others give `UnaryPrefix`. Also matches `SynExpr.AddressOf` (adjacent → `High`, else `UnaryPrefix`).
- `(|SymbolPrec|_|)` — parses an original-notation string into its `Precedence`: trims leading `.`/`?` chars, then dispatches on the first character (with exact-string checks for `:=`, `||`, `&&`, `::`; `!`-followed-by-`=` and `*`-followed-by-`*` require the second char). Returns `ColonEquals`, `BarBar`, `AmpAmp`, `Relational`, `HatAt`, `Cons`, `AddSub(Add|Sub, …)`, `MulDivMod(Div|Mod|Mul, …)`, `Exp`, or `ValueNone`.
- `(|Contains|_|)` — `let (|Contains|_|) (c: char) (s: string)` matches if `s` contains char `c`; used by `ConfusableWithTypeApp` for `<`, `>`.
- `(|ConfusableWithTypeApp|_|)` (`rec`) — matches expressions where removing parens would produce `x<y>z` / `x<y,y>z` (parsed as a type application): parens wrapping a confusable, app chains, a right-nested infix `>` operator application, an infix `<` operator app whose argument range is adjacent to the operator, or any-but-last tuple elements (a trailing element is fine since `x, y<z>` is unambiguous).
- `(|InfixApp|_|)` returns `struct (Precedence * Assoc) voption` — matches `(x λ y) ρ z` / `x λ (y ρ z)`: an `App` of a symbolic-operator-`funcExpr`; a *right*-nested infix app yields `(prec, Right)`, a simple infix app `(prec, Left)`; `Upcast`/`Downcast` yield `(UpcastDowncast, Left)`; `TypeTest` → `(TypeTest, Left)`.
- `(|OuterBinaryExpr|_| inner outer)` returns `struct (Precedence * Assoc) voption` — derives the containing binary context of `outer` around `inner`:
  - `YieldOrReturn`/`YieldOrReturnFrom` → `(Low, Right)`; a tuple whose *first* element is the parenthesized `inner` → `(Comma, Left)`, otherwise `(Comma, Right)`.
  - `InfixApp(Cons, side)` → `(Cons, side)`; other `InfixApp(prec, side)` → `(prec, side)`.
  - `Assert`, `Lazy`, `InferredUpcast`, `InferredDowncast` → `(Apply, Non)`; `PrefixApp prec` → `(prec, Non)`.
  - `App` with a `ComputationExpr` argument → `(UnaryPrefix, Left)`; `App` whose parenthesized argument is `inner` → `(Apply, Right)`; `App` whose `funcExpr` is a parenthesized app → `(Apply, Left)`; `App(flag = Atomic)` → `(Dot, Non)`; plain `App` → `(Apply, Non)`.
  - Dot assignments/setters: `DotSet`/`DotIndexedSet`/`DotNamedIndexedPropertySet` with `targetExpr`/`objectExpr` parenthesized-as-`inner` → `(Dot, Left)`; with the *rhs/value* parenthesized → `(Set, Right)`; `LongIdentSet` rhs → `(Set, Right)`; `Set` → `(Set, Non)`; `DotGet` → `(Dot, Left)`; `DotIndexedGet` with `objectExpr` → `(Dot, Left)`.
  - Otherwise `ValueNone`.
- `(|NestedApp|_|)` — matches a `SynExpr.App` nested in a chain of dot-gets (`x.M.N().O`): recursively unwraps `DotGet`/`DotIndexedGet`, matches an `App` at the base.
- `(|InnerBinaryExpr|_|)` returns a `Precedence voption` — the inner expression's precedence: non-struct `Tuple` → `Comma`; `DotGet`/`DotIndexedGet` over a `NestedApp` → `Apply`, otherwise → `Dot`; `PrefixApp prec` → `prec`; `InfixApp(prec, _)` → `prec`; `App`, `Assert`, `Lazy`, `For`, `ForEach`, `While`, `Do`, `New`, `InferredUpcast`, `InferredDowncast` → `Apply`; `DotIndexedSet`/`DotNamedIndexedPropertySet`/`DotSet` → `Set`; `TypeTest` → `TypeTest`.

### `module Dangling` — dangling (trailing) construct detection

- `let private dangling (target: SynExpr -> SynExpr option)` — returns the first nested right-hand "target" expression. `loop` walks through the last/trailing child of tuple(expression `exprs` via `Last`), app arguments, `IfThenElse` (`elseExpr`/`ifExpr`), `Sequential(expr2)`, `YieldOrReturn(expr)`/`YieldOrReturnFrom(expr)`, `Set(rhsExpr)`, `DotSet(rhsExpr)`, `DotNamedIndexedPropertySet(rhsExpr)`, `DotIndexedSet(valueExpr)`, `LongIdentSet(expr)`, `LetOrUse` body, `Lambda(body)`, last `SynMatchClause(resultExpr)` in `Match`/`MatchLambda`/`MatchBang`/`TryWith(withCases)`, `TryFinally(finallyExpr)`, `Do(expr)`, `DoBang(expr)`.
- Active patterns (all `[<return: Struct>]`, each a `dangling` instance with a specific target predicate):
  - `(|IfThen|_|)` — dangling `IfThenElse`.
  - `(|LetOrUse|_|)` — dangling `LetOrUse`.
  - `(|Sequential|_|)` — dangling `Sequential`.
  - `(|Try|_|)` — dangling `TryWith`/`TryFinally`.
  - `(|Match|_|)` — dangling `Match`/`MatchBang`/`MatchLambda`/`TryWith`/`Lambda`.
  - `(|ArrowSensitive|_|)` — dangling `Match`/`MatchBang`/`MatchLambda`/`TryWith`/`Lambda`/`Typed`/`TypeTest`/`Upcast`/`Downcast` (constructs whose domination would be wrong near `->`).
  - `(|Problematic|_|)` — dangling `Lambda`/`MatchLambda`/`Match`/`MatchBang`/`TryWith`/`TryFinally`/`IfThenElse`/`Sequential`/`LetOrUse`/`Set`/`LongIdentSet`/`DotIndexedSet`/`DotNamedIndexedPropertySet`/`DotSet`/`NamedIndexedPropertySet`.
- `containsSensitiveIndentation (getSourceLineStr: int -> string) outerOffsidesColumn (range: range)` — reports whether the expression's text includes indentation that would be invalid in the outer context if not wrapped in parens. Single-line expressions just compare start column to the outer offsides column; multi-line expressions track the offsides column line-by-line, computing the first non-`')'`/space index per line and whether it lands at or before the outer offsides column (with a special allowance for symbolic-operator characters `*/%-+:^@><=!|$.?`).
- `(|UndentationSensitive|_|)` — matches `TryWith`, `TryFinally`, `For`, `ForEach`, `IfThenElse`, `Match`, `While`, `Do` (constructs whose parse inside a sequential expression is sensitive to indentation).

## Public implementation of the `.fsi`

- `let rec shouldBeParenthesizedInContext (getSourceLineStr: int -> string) path expr : bool` — the core decision procedure (recursive over the ancestor `path`). Its logic, in rough order:
  1. **Named-argument / tuple double-paren cases**: parens must stay around `x = y` binary equals and around tuples (and `()`) in argument position of a method call (`LongIdent`/`DotGet`/`Ident` function), including the nested-paren/tuple variants, since they could otherwise parse as named arguments or as a 2-arg method call.
  2. **Already parenthesized** (outer is `SynExpr.Paren`) → `false`.
  3. **Sensitive indentation**: expression is parenthesized inside a `SynBinding` (checked against `trivia.LeadingKeyword.Range.StartColumn`) or inside one of a long list of control-flow/construct ancestors (`YieldOrReturn(From)`, `Assert`, `Lazy`, `App` with parenthesized arg, `LetOrUse`, `TryWith`, `TryFinally`, `For`, `ForEach`, `IfThenElse`, `New`, `Set`/`DotIndexedSet`/`DotNamedIndexedPropertySet`/`DotSet`/`LibraryOnlyUnionCaseFieldSet`/`LongIdentSet`/`NamedIndexedPropertySet` rhs parenthesized, `InferredUpcast`/`InferredDowncast`, `Match`, `MatchBang`, `While`, `WhileBang`, `Do`, `DoBang`, `Fixed`, `Record`, `AnonRecd`, `InterpolatedString`) → `true` when `containsSensitiveIndentation outer.Range.StartColumn expr.Range`.
  4. **Hanging tuples**: a non-struct tuple spanning multiple lines with any element less indented than the tuple → `true`.
  5. **Undentation-sensitive parents** (an `UndentationSensitive` expr inside sequential/list/array/computation parents, where removing parens in place would re-parse the surrounding sequence) → `true` when the wrapped expr and neighbor start on different lines with the expr's column ≤ the neighbor's.
  6. **Match clauses**: when the immediate path is `SynMatchClause`, recurse without the clause in the path (the "trailing arrow" case).
  7. **Always-keep cases**: `TraitCall`; `LibraryOnlyILAssembly`/`LibraryOnlyStaticOptimization`/`LibraryOnlyUnionCaseFieldGet`/`LibraryOnlyUnionCaseFieldSet` → `true`.
  8. **Binding bodies / top-level** (`SynBinding`/`SynModule` path) → `false` (parens never required there).
  9. **Prefix-operator interaction**: a `PrefixApp`/`StartsWithSymbol` expression inside an `App` whose funcExpr is a high-precedence app/`Assert`/inferred up/downcast → `true` (`id -(-x)`, `id -($"")`, …). An expression inside `App` of a `PrefixApp High` → `true` (`!x.M(y)`).
  10. **Join conditions** (`App` inside `App` of `JoinIn`) → `true`.
  11. **Inherit**: after `ImplicitInherit`, `AtomicExprAfterType` → `false`, everything else → `true`.
  12. **Fluent call chains**: an `App` argument that is a non-array `ArrayOrListComputed` → `true`; and an expression inside an app whose enclosing path "depends on dot or pseudo-dot precedence" (`appChainDependsOnDotOrPseudoDotPrecedence` walks the path through `DotGet`, `DotLambda`, `DotIndexedGet`, `Set`, `DotSet`, `DotIndexedSet`, `DotNamedIndexedPropertySet`, and app-list arguments) → `true`.
  13. **Numeric literals**: `DotSafeNumericLiteral` → `false` (safe to dot into, e.g. `(1l).ToString()`, including base/`e` notation and suffixed literals via `TextContainsLetter`/`TextEndsWithNumber` over the source text); a bare `Int32`/`Double` const being dotted into (`DotGet`) → `true` (e.g. `(1).ToString()`, `(1.).ToString()`).
  14. **`::` (Cons) special-casing**: for `x :: xs`-shaped expressions the function recurses with a synthetic path: a `[Paren; _]`-tuple first element in an infix app recurses through the app path; for the second element it re-packages the outer infix app as a synthetic non-infix `App(outer, argExpr)` and recurses (so the precedence of `::` (a right-nested arg) is handled).
  15. **Ordinary nested expressions** (`inner` inside `SynExpr outer` with `outerPath`):
      - `ConfusableWithTypeApp` inner → `true`.
      - `IfThenElse` with both parenthesized inner and a dangling `LetOrUse` whose start precedes the `then` keyword → `true`.
      - `IfThenElse` with a dangling `IfThen`/`Match` that is "problematic" relative to the `then`/`else` keyword ranges → `true`.
      - `IfThenElse(ifExpr)`/`While(whileExpr)`/`ForEach(enumExpr)` with a dangling construct fully inside those ranges → `true`.
      - `TryFinally` with a dangling `Try` running past the `finally` keyword → `true`.
      - `Match`/`MatchBang` (via `WithKeyword` + `anyProblematic` over clause `BarRange`/`ArrowRange`) and `MatchLambda`/`TryWith` with dangling arrow-sensitive constructs → `true`.
      - **Trailing-arrow**: a dangling `ArrowSensitive` construct whose ancestral path (`ancestralTrailingArrow`) passes through match clauses/apps/tuples/if/sequence/yield/set/let/lambda/match/try/do constructs back to a `SynMatchClause` → `true`.
      - `Sequential` with a dangling `Sequential` → `true`; `Sequential(expr1 = Paren inner, expr2)` with a problematic inner → `true`; and **shadowing**: `Sequential(expr1 = Paren inner)` where `innerBindingsWouldShadowOuter` finds that names bound by patterns in `inner` are referenced in `expr2` → `true` (would shadow the outer binding).
      - **Interpolated strings**: `$"{({ A = 3 })}"`-style record/anon-record/computation/sequence/tuple holes → `true`; a hole whose trailing node is `Dangling.Problematic` when any fill expression has a `DotNet` alignment or format (a trailing `,-3` would otherwise be parsed into the hole) → `true`.
      - **Record/anon-record fields**: `Record`/`AnonRecd` hole that is a `Sequential` → `true` (semicolon would become a field separator); `!x`/`~…` copy-info holes → `false`; other prefix/infix/problematic copy-info holes → `true`; a problematic value in a record field that would collide with the next field's name/anonymous field → `true`.
      - **Typed expressions**: `Paren`/`Quote`/`While`/`WhileBang`/`For`/`ForEach`/`Match`/`Do`/`LetOrUse`/`TryWith`/`TryFinally` with a `Typed` inner → `false`, otherwise `Typed` inner → `true`.
      - **Binary precedence comparison** (the core rule, `OuterBinaryExpr inner (outerPrecedence, side)` vs `InnerBinaryExpr innerPrecedence`):
        - `compare outerPrecedence innerPrecedence < 0` → `true` (outer binds looser, e.g. an `+` inside a `*`).
        - Equal precedence: `ambiguous = dangling||dangling inner` cases — `Non`-side or right-inside-left is `true`; same-side is `false`; `Right`-outside-`Left` (odd case) requires unequal precedence *or* the specific `Div`/`Mod`/`Sub`/`Relational`/`Apply` marks → `true`.
        - `> 0` → `false`.
  16. **Right-nested binary / dangling inner** (`OuterBinaryExpr (_, Right)` around `Sequential` or a `LetOrUse` without `InKeyword`) → `true`; (`_, Right)` around any inner component → `true` if inner is dangling.
  17. **`new T(expr)`**: `AtomicExprAfterType` → `false`, else `true`.
  18. **Record inheriting (`inherit T(expr)` in the `baseInfo`)**: parenthesized `AtomicExprAfterType` → `false`, else `true`.
  19. **Never-required pairs**: extensive lists of expression kinds where parens are never required — inner kinds `Paren`, `Quote`, `Const`, struct `Tuple`, `AnonRecd`, `ArrayOrList`, `Record`, `ObjExpr`, `ArrayOrListComputed`, `ComputationExpr`, `TypeApp`, `Ident`, `LongIdent`, `DotGet`, `DotLambda`, `DotIndexedGet`, `Null`, `InterpolatedString`; and outer kinds `Paren`, `Quote`, `Typed`, `AnonRecd`, `Record`, `ObjExpr`, `While`, `WhileBang`, `For`, `ForEach`, `Lambda`, `MatchLambda`, `Match`, `MatchBang`, `LetOrUse`, `Sequential`, `Do`, `DoBang`, `IfThenElse`, `TryWith`, `TryFinally`, `ComputationExpr`, `InterpolatedString` → `false`.
  20. Fallback: anything not matched → `true` (keep the parens).

  Local helper patterns used inside the implementation: `(|StartsWith|)` (first char of a string), `(|StartsWithSymbol|_|)` (quotes, interpolated strings, verbatim strings, and signed numeric constants that start with `+`/`-`), and `(|DotSafeNumericLiteral|_|)` (byte/int/float/measure/user-num literals that are safe to dot into, refined by `TextContainsLetter` and `TextEndsWithNumber`).
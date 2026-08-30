# SynPat.fs

## Pipeline role

This file belongs to the Service folder of the F# compiler. It implements `SynPat.fsi`'s `shouldBeParenthesizedInContext` decision procedure for F# patterns, plus the internal active patterns it relies on. The module answers "can this `SynPat` be written without its surrounding parentheses without changing the program's meaning?" by examining the ancestor path (`SynBinding`, match clauses, lambdas, `let!`/`and!`/`use!`, `new` constructor signatures, signatures files, RHS offsides lines, etc.) and the nested pattern structure (typing, tuples, or/as/and/cons chains, named-argument patterns). Unlike its `SynExpr` sibling it has no `getSourceLineStr` — everything is decided from the AST and the ancestor path.

## Namespaces, opens, module

- Namespace `FSharp.Compiler.Syntax`.
- `open FSharp.Compiler` (brings in `SyntaxTreeOps`, used for the `LetOrUse` match, and `Ident`).
- `module SynPat`, marked `[<RequireQualifiedAccess>]` and `[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`.

## Internal active patterns and helpers

- `let (|Last|) = List.last` — extracts the last element of a list (used to reach the trailing element of `Ands` and tuples).
- `let inline (|Is|_|) (inner1: 'a) (inner2: 'a)` (`[<return: Struct>]`, `ValueSome Is`/`ValueNone`) — identity match (`obj.ReferenceEquals`), used to confirm the current `pat` is literally a sub-pattern of the outer node.
- `let (|Ident|) (ident: Ident) = ident.idText` — unwraps `Ident` to its text (used to match the special `new` constructor ident).
- `let (|AnyTyped|_|) pats` (`[<return: Struct>]`) — matches if any pattern in the given list is a `SynPat.Typed`.
- `let rec (|Rightmost|) pat` — returns the rightmost potentially dangling nested pattern: unwraps the `rhsPat` of `Or`/`ListCons`/`As`, the last element of `Ands`/non-struct `Tuple`, recursing until a leaf pattern; the leaf itself is returned for any other pattern.
- `let rec (|DanglingAs|_|)` (`[<return: Struct>]`, matches with `ValueSome()`) — matches a pattern that has an `As` anywhere trailing/reachable through the rightmost nesting: direct `SynPat.As`, either side of `Or`, either side of `ListCons`, any element of `Ands`, any element of a non-struct `Tuple` (via `AnyDanglingAs` = `List.tryPick`).
- `let (|Atomic|_| pat)` (`[<return: Struct>]`) — matches atomic patterns: `Named`, `Wild`, `Paren`, struct `Tuple`, `Record`, `ArrayOrList`, `Const`, `LongIdent` with zero argument patterns, `Null`, `QuoteExpr`.

## Public implementation of the `.fsi`

- `let shouldBeParenthesizedInContext path pat : bool` — the core decision procedure (not recursive; single pass over `pat, path`). Its rules, in order:
  1. **Types and tuples need distinct parens** — matching `SynPat.Typed`/tuples-with-typed-elements inside match clauses (`(Pattern …)`, `(x: …) -> …`), inside `let!`/`and!`/`use!` bindings (`SyntaxTreeOps.LetOrUse(_, true, _)`, the `true` marking it as a let-bang), inside `SynBinding`, and `let! (_ : obj) = …` directly → `true`.
  2. **`let! (A _) = …` style patterns** — a `LongIdent` directly under a binding whose enclosing expression is a let-bang → `false` (parens never required); but a `LongIdent` with arguments under a binding or lambda, a non-struct tuple under a %lambda with `parsedData`, a `Typed` under such a lambda, and property-get/set member typed tuples → `true`.
  3. **RHS offsides guard** — `wouldMoveRhsOffsides n pat path` (bounded backtracking up to `maxBacktracking = 10`; deliberately approximate, producing some false positives): walks up through outer `SynPat` nodes, then matches the first enclosing `SynExpr.Lambda(body)`, `LetOrUse` body, `SynBinding(expr)`, or `SynMatchClause(resultExpr)`; if that RHS expression spans multiple lines and `pat`'s last line equals the RHS's first line → `true` (removing the parens would shift the RHS offsides line; e.g. `` match ... with | Some(x) -> let y = x * 2\n let z = 99 ...`` or ``let (x) = printfn "…"\n printfn "…"``).
  4. **`()` unit pattern** — `SynPat.Const(SynConst.Unit, _)` anywhere → `true` (this shape is *how* unit is represented when parenthesized).
  5. **Double parens for generic overrides** — `(())` required when overriding a generic member whose type argument is unit or a tuple: parenthesized unit/tuple under a `LongIdent` (e.g. `override _.M (())`), a tuple under a `Paren` under a `LongIdent`, within a binding and member definition → `true` (single vs double parens compile to different method signatures).
  6. **Multiline tuple bindings** — a non-struct tuple binding whose range spans its own lines but whose body starts on a later line at ≤ the tuple's start column → `true` (required for `let (a,\nb,\nc) =\n    _`-style, not required when the tuple closes on the same line as the body).
  7. **`new` constructor signature compat** — parens required around a tuple pattern whose `new` signature in a signature file is written as `new: (range * …) -> …`: a `Paren` of a tuple (or a bare non-struct tuple) under `SynPat.LongIdent [ Ident "new" ]` inside a binding/member/type definition → `true`.
  8. **Non-last `new` constructors** — an `Atomic` argument of any `new` constructor that is *not* the last `new` member in an `ObjectModel` type representation → `true` (`new (x) = …`; `new (x, y) = …`); the last one, when it is itself a parenthesized pattern, → `false`. (The last-`new` is found by `List.fold` over the `members`, tracking the last member whose head pattern is a `LongIdent [ Ident "new" ]`.)
  9. **Never-required contexts** — parens never needed inside `SynBinding`, `SynExpr.ForEach`, let-bang, `SynMatchClause`, or `%lambda` with `parsedData` when the pattern is atomic → `false`.
  10. **Nested patterns** (current `inner` inside `SynPat outer`):
      - `(x :: xs) :: ys` / `(x, xs) :: ys` — `ListCons` whose *left-hand* pattern is a paren of the inner, when inner is a `ListCons` or tuple → `true`.
      - `A as (B | C)` / `A as (B & C)` / `x as (y, z)` / `xs as (y :: zs)` — `As` whose `rhsPat` is a paren of the inner, when inner is `Or`/`Ands`/tuple/`ListCons` → `true`.
      - `(A | B) :: xs` / `(A & B) :: xs` / `(x as y) :: xs` — `ListCons` around `Or`/`Ands`/`As` → `true`.
      - `Pattern (x = (…))` — a `LongIdent` with `NamePatPairs` argument → `false`.
      - `Pattern (x : int)`, `Pattern ([<Attr>] x)`, `Pattern (:? int)`, `Pattern (A :: _)`, `Pattern (A | B)`, `Pattern (A & B)`, `Pattern (A as B)`, `Pattern (A, B)`, `Pattern1 (Pattern2 (x = A))`, `Pattern1 (Pattern2 x y)` — `LongIdent` with any typed/attributed/isinst/cons/or/ands/as/tuple/named-pair/arg-bearing inner → `true`.
      - `A | (B as C)` / `A & (B as C)` / `A, (B as C)` — `Or`/`Ands`/tuple around `As`/`DanglingAs` → `true`.
      - `x, (y, z)` / `x & (y, z)` / `(x, y) & z` — tuple/`Ands` around a tuple; `A , (B | C)` / `A & (B | C)` — tuple/`Ands` around `Or` → `true`.
      - `(x : int) & y` / `x & (y : int) & z` — `Ands` whose *last* element is a paren of the inner typed pattern → `false`; otherwise `Ands` around `Typed` → `true`.
      - **No-parens pairs** (blanket `false`): inner `Const`/`Wild`/`Named`/`Typed`/empty-arg `LongIdent`/struct `Tuple`/`Paren`/`ArrayOrList`/`Record`/`Null`/`OptionalVal`/`IsInst`/`QuoteExpr`; outer `Or`/`ListCons`/`Ands`/`As`/`LongIdent`/`Tuple`/`Paren`/`ArrayOrList`/`Record`.
  11. Fallback for nested patterns → `true`; anything not matched at the top level → `true`. (Note: no explicit `getSourceLineStr` parameter exists here, unlike `SynExpr`.)
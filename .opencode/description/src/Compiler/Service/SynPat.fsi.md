# SynPat.fsi

## Pipeline role

This file belongs to the Service folder of the F# compiler. It is the public signature of `SynPat.fs`, the `FSharp.Compiler.Syntax` helper module that decides whether a `SynPat` (pattern) must keep its surrounding parentheses in a given context. It is used together with `SynExpr` by the F# formatting / AST-editing pipeline to decide when parens can be removed from a pattern without changing the meaning of the enclosing construct (bindings, match clauses, lambdas, `let!`/`and!`/`use!` patterns, `new` constructors, signatures, etc.). Note that, unlike `SynExpr`, this signature does *not* take a `getSourceLineStr` source-line function.

## Namespaces and modules

- `FSharp.Compiler.Syntax` namespace.
- `SynPat` module (the extension module for the `SynPat` union), declared `module public SynPat =`.
  - Marked `[<RequireQualifiedAccess>]` and `[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`, mirroring the implementation module in `SynPat.fs`.

## Public API

- `val shouldBeParenthesizedInContext: path: SyntaxVisitorPath -> pat: SynPat -> bool`
  - Returns `true` if the given pattern should be parenthesized in the given context, otherwise `false`.
  - `path` — the pattern's ancestor nodes (`SyntaxVisitorPath`), used to determine the surrounding context.
  - `pat` — the pattern to check.
  - No source-line access: unlike `SynExpr.shouldBeParenthesizedInContext`, the pattern decision relies only on the AST and the ancestor path.
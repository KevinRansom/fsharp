# SynExpr.fsi

## Pipeline role

This file belongs to the Service folder of the F# compiler. It is the public signature of `SynExpr.fs`, the `FSharp.Compiler.Syntax` helper module that decides whether a `SynExpr` must keep (or would otherwise benefit from) surrounding parentheses when rendered into source text after an AST edit or formatting step. The exposed entry point `shouldBeParenthesizedInContext` is consumed by the F# validation / formatting pipeline (used e.g. by IDE formatting and by expression-editing operations) to decide if a parenthesized expression can have its parens removed without changing the meaning, precedence, associativity, or parse of the enclosing program.

## Namespaces and modules

- `FSharp.Compiler.Syntax` namespace.
- `SynExpr` module (the extension module for the `SynExpr` union), declared `module public SynExpr =`.
  - Marked `[<RequireQualifiedAccess>]` and `[<CompilationRepresentation(CompilationRepresentationFlags.ModuleSuffix)>]`, mirroring the implementation module in `SynExpr.fs`.

## Public API

- `val shouldBeParenthesizedInContext : getSourceLineStr: (int -> string) -> path: SyntaxVisitorPath -> expr: SynExpr -> bool`
  - Returns `true` if the given expression should be parenthesized in the given context, otherwise `false`.
  - `getSourceLineStr` — a function for retrieving the text of a given source line (used to inspect raw trivia/indentation and operator source text).
  - `path` — the expression's ancestor nodes (`SyntaxVisitorPath`), used to determine the surrounding context.
  - `expr` — the expression to check.
# ServiceStructure.fsi

**Signature for `ServiceStructure.fs`.** Declares the outlining/block-structure API of the FSharp.Compiler.Service: `Structure.getOutliningRanges` returns the ranges an editor can collapse as fold regions ("hint span" = full construct range, "collapse span" = the sub-range that collapses) for both implementation and signature files.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. Using the given source lines and the untyped `ParsedInput` (including parse trivia — code comments and preprocessor `#if`/`#else` conditional directives), it computes a sequence of `ScopeRange`s: modules/namespaces, types, members, bindings, expressions (`match`, `try`, `if`, `for/while`, records, tuples, arrays, lambdas, quotes, object expressions, …), opens, hash directives, union/enum/record definitions, and comments. Editors map these onto their outlining "block spans".

## Namespaces

- `FSharp.Compiler.EditorServices` with `open FSharp.Compiler.Syntax`, `FSharp.Compiler.Text`.

## Module `Structure` (public)

- `type Collapse` (`[<RequireQualifiedAccess>]`) — `Below` (expression following a binding / RHS of a pattern) | `Same` (scope inside scope delimiters like `{ ... }`, `[| ... |]`).
- `type Scope` (`[<RequireQualifiedAccess>]`) — the tag identifying the construct:
  `Open | Namespace | Module | Type | Member | LetOrUse | Val | ComputationExpr | IfThenElse | ThenInIfThenElse | ElseInIfThenElse | TryWith | TryInTryWith | WithInTryWith | TryFinally | TryInTryFinally | FinallyInTryFinally | ArrayOrList | ObjExpr | For | While | Match | MatchBang | MatchLambda | MatchClause | Lambda | Quote | Record | SpecialFunc | Do | New | Attribute | Interface | HashDirective | LetOrUseBang | TypeExtension | YieldOrReturn | YieldOrReturnBang | Tuple | UnionCase | EnumCase | RecordField | RecordDefn | UnionDefn | Comment | XmlDocComment`.
- `type ScopeRange` (`[<NoComparison>]` record) — `Scope: Scope`, `Collapse: Collapse`, `Range: range` (HintSpan), `CollapseRange: range` (TextSpan).
- `val getOutliningRanges: sourceLines: string[] -> parsedInput: ParsedInput -> seq<ScopeRange>`.

## Relation to .fs

The `.fs` adds a large amount of internal machinery: a `Range` utility submodule (range combinator helpers `endToEnd`/`endToStart`/`startToEnd`/`startToStart`/`modStart`/`modEnd`/`modBoth`), `longIdentRange`, `rangeOfTypeArgsElse`, a `ToString` override on `Scope`, `LineNumber`/`LineStr`/`CommentType`/`CommentList` comment helpers, the recursive expression/module/signature walkers (`parseExpr`, `parseMatchClause`, `parseAttributes`, `parseBinding`, `parseTypeDefn`, `parseSynMemberDefn`, the signature mirrors, `getConsecutiveModuleDecls`/`getConsecutiveSigModuleDecls` grouping opens & hash directives, `collectConditionalDirectives`, `getCommentRanges`), the `rcheck` validation (already in the signature's contract: multi-line ranges only), and the `#if/#else/#elif/#endif`/comment trivia handling driven by `file.Trivia`. The public surface is just `getOutliningRanges` plus the three declared types.
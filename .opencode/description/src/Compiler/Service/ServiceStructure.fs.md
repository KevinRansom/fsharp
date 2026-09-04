# ServiceStructure.fs

Full implementation of outlining/block-structure range extraction from the untyped parse tree.

## Pipeline role

`FSharpChecker` service-layer file for F# IDE/tooling. `Structure.getOutliningRanges sourceLines parsedInput` walks an implementation or signature file and emits one `ScopeRange` per collapsible construct. The single acceptance filter is `rcheck`: **only ranges spanning 2+ lines are yielded** (single-line constructs don't outline). Collapse style says *how* to fold (`Below` = collapse the trailing body of a header line such as `let x =`, `Same` = collapse inside matching delimiters), `Range` is the hint span and `CollapseRange` the text span.

## Namespaces / opens

- `FSharp.Compiler.EditorServices` with `open Internal.Utilities.Library`, `FSharp.Compiler.Syntax`, `SyntaxTreeOps`, `SyntaxTrivia`, `Text`, `Text.Position`, `Text.Range`.

## Module `Range` (RequireQualifiedAccess submodule)

Range combinators over two ranges (same file index): `endToEnd`, `endToStart`, `startToEnd`, `startToStart`; column shifters `modStart m`, `modEnd m` (minus in modBoth), and `modBoth modStart modEnd`.

## Helpers

- `longIdentRange longId` — `range0` for empty; else `startToEnd head.last`.
- `rangeOfTypeArgsElse other typeArgs` — union of typar ranges, or `other` for `[]`.
- `type Collapse` / `type Scope` — as in the signature, plus `ToString` overrides (e.g. `"Open"`, `"Namespace"`, …, `"XmlDocComment"`).
- `type ScopeRange` — the record.
- `type LineNumber = int`; `type LineStr = string`; `type CommentType = SingleLine | XmlDoc`; `type CommentList = { Lines: ResizeArray<LineNumber * LineStr>; Type: CommentType }` with `static member New ty lineStr`.

## `getOutliningRanges (sourceLines: string[]) parsedInput`

Accumulator `acc`; inner `rcheck scope collapse fullRange collapseRange` validates and adds.

### Implementation-file expression walker `parseExpr`

- Unary wrappers (`Upcast/Downcast/AddressOf/InferredUpcast/InferredDowncast/DotGet/Do/Typed/DotIndexedGet`) → recurse; binary forms of those → recurse both.
- `New(_,_,e,r)` → `Scope.New, Below, r/e.Range`.
- `YieldOrReturn`/`YieldOrReturnFrom` → `YieldOrReturn`/`YieldOrReturnBang, Below, r/r`.
- `DoBang` → `Do, Below, modStart 3`.
- `For`/`ForEach` → `For, Below`.
- `LetOrUse` → bindings + body.
- `Match`/`MatchBang` — when a seqpoint `DebugPointAtBinding.Yes sr` exists, `Match, Same` collapsing from `sr` end to `r` end; then clauses.
- `MatchLambda` → `MatchLambda, Same` (seq-point start or case range).
- `App` (non-atomic, non-infix):
  - func = plain `Ident` and arg not a computation expr → `SpecialFunc, Below` from func-end to `r` (op-call outlining).
  - arg = computation expr → `ComputationExpr, Same` collapsing the braces (`modBoth 1 1`); comments explain afunction value application.
  - Then recurses arg and func.
- `Sequential` → both. `ArrayOrListComputed isArray` → `ArrayOrList, Same` with `modBoth 2/1` for `[| |]` vs `[ ]`.
- `ComputationExpr` → recurse inner.
- `ObjExpr` — bindings via `unionBindingAndMembers`; `ObjExpr, Below` after either the ctor args or the `new` range; then bindings + interface impls.
- `TryWith` — using `try`/`with` debug-points: `TryWith` (Below), `TryInTryWith` (Below, try-range), `WithInTryWith` (Below, with-range); then expr + clauses.
- `TryFinally` — `TryFinally`, `FinallyInTryFinally` (Below); then both exprs.
- `IfThenElse` — uses `spIfToThen` seqpoint: `IfThenElse, Below` (whole); `ThenInIfThenElse, Below` via `trivia.IfToThenRange` (and `modEnd -4`); elifs (`IfThenElse` as else) are recursed to prevent double-collapse; AST doesn't expose the `else` keyword position so `ElseInIfThenElse` is never emitted (comment explains this).
- `While`/`WhileBang` → `While, Below`; `Lambda` → `Lambda, Below` (collapse from pats end); `Lazy` → `SpecialFunc, Below`; `Quote` → `Quote, Same` with `modBoth` for `@@>`/`@>`; `Tuple` → `Tuple, Same`; `Paren` → recurse.
- `Record` — ctor args, copy expr, field/spread value exprs, then `Record, Same` with braces excluded (`modBoth 1 1`).
- Anything else → nothing.

`parseMatchClause` — `MatchClause, Same` spanning from pattern end (`->` onwards) to clause end, yielded whenever pattern-end line ≠ result-end line (resultExpr and pattern on different lines even if single-line); then the result expr.

`parseAttributes` — first attribute's whole list range → `Attribute, Same`; remaining attributes each get their own range (avoid double-collapsing); each attribute's arg expr recursed.

`parseBinding` — by `SynBinding.Kind`:
- `Normal`: collapse = `endToEnd RangeOfBindingWithoutRhs RangeOfBindingWithRhs`; `New` (Constructor member flags) | `Member` (other member flags) | `LetOrUse` (plain) — all `Below`.
- `Do`: `Do, Below` from `modStart 2`.
- Attributes + expr recursed.

`parseSynMemberDefn` — `Member`: constructor → `New, Below`; property get/set → `Member, Below` (extended start column to object-model column); else `Member, Below`; `GetSetMember` → re-wraps each as `Member` and recurses; `LetBindings` → bindings; `Interface` → `Interface, Below` (+ member recurses); `NestedType` → parseTypeDefn; `AbstractSlot` → `Member, Below` (from slot type start); `AutoProperty` → `Member, Below` + expr.

`parseSimpleRepr` (used for sig & impl): `Enum` → per-case `EnumCase, Below` (+ attrs); `Record` → `RecordDefn, Same` on braces + per-field `RecordField, Below` (+ attrs); `Union` → `UnionDefn, Same` on braces + per-case `UnionCase, Below` (+ attrs).

`parseTypeDefn` — `Type, Below` or `TypeExtension, Below` (for `SynTypeDefnKind.Augmentation`), collapse from type-args end; members recursed.

### Grouping helpers (impl)

`getConsecutiveModuleDecls scope predicate decls` — collects ranges from decls matching the predicate, groups **consecutive** decls (adjacent lines, or intervening blank lines per `sourceLines`), and for multi-line groups yields a single `Same`-style range spanning the group. Used by:
- `collectOpens` — `SynModuleDecl.Open` (→ `Scope.Open`).
- `collectHashDirectives` — parses each `#directive` line, trimming the `#directive ` prefix (→ `Scope.HashDirective`).

`collectConditionalDirectives directives sourceLines` — folds `#if/#elif/#else/#endif` regions: `addSectionFold` between directives (up to the line above the next), `addEndpointFold` from `#if` to `#endif`; uses a stack of `ConditionalDirectiveTrivia`.

### Module walker (impl)

`parseDeclaration` — `Let` bindings → `LetOrUse, Below` per binding; `Types` → parseTypeDefn; `NestedModule` → `Module, Below` (from component-info end; folds attributes, opens, decls); `Expr`; `Attributes`.

`parseModuleOrNamespace` — attributes; `longIdentRange`; only `NamedModule` gets `Module, Below` (top-level script implicit modules excluded); hash directives, opens, and decls.

### Comments

`(|Comment|_|)` line classifier (`///` → XmlDoc, `//` → SingleLine). `getCommentRanges trivia lines` groups consecutive comment lines (same type, adjacent line numbers) with `CommentList`; multi-line groups → `Scope.Comment`/`Scope.XmlDocComment` (Range = from first `//` start to last trimmed-line end); block comments (`CommentTrivia.BlockComment`) spanning 2+ lines → `Scope.Comment`.

### Signature-file walker

Because of dotnet/fsharp issue #2094 (sig-file ranges over-extend into the next construct), end ranges are pinned to the last child:
- `lastMemberSigRangeElse r memberSigs`, `lastTypeDefnSigRangeElse`, `lastModuleSigDeclRangeElse`.
- `parseSynMemberDefnSig` — `Member` → `Member, Below` (collapse from `RangeOfId`); `ValField` → `Val, Below`; `Interface` → `Interface, Below`; `NestedType` → recurse.
- `parseTypeDefnSig` — component-info attrs; `Type`/`TypeExtension`/`Type` by kind (Unspecified with ObjectModel, Augmentation, other ObjectModel, Simple); collapse range pinned to `lastMemberSigRangeElse`.
- `getConsecutiveSigModuleDecls` (adjacency only, no blank-line tolerance) → `collectSigHashDirectives`, `collectSigOpens`.
- `parseModuleSigDeclaration` — `Val` → `Val, Below`; `Types`; `NestedModule` → `Module, Below` pinned to `lastModuleSigDeclRangeElse`.
- `parseModuleOrNamespaceSigs` — like impl but drops longId module check (`kind.IsModule`), end pinned by last decl range.

### Dispatch

`ParsedInput.ImplFile` → contents walk + `collectConditionalDirectives file.Trivia.ConditionalDirectives` + `getCommentRanges file.Trivia.CodeComments`. `ParsedInput.SigFile` → same with the sig walker. Returns `acc` as `seq`.
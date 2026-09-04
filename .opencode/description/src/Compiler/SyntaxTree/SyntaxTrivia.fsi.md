# SyntaxTrivia.fsi

**Purpose**: Public (module-level internal) contract for `FSharp.Compiler.SyntaxTrivia` — the record types the F# syntax tree nodes carry to preserve source-faithful positions of keywords/punctuation the core AST drops, plus the *file-level* trivia (`ParsedInputTrivia`) that bundles `ConditionalDirectiveTrivia`, `WarnDirectiveTrivia`, and `CommentTrivia`. This is the single public surface through which tooling (formatting, highlighting, refactoring, go-to-def) reads source positions back out of the AST.

**Namespace(s)**: `FSharp.Compiler.SyntaxTrivia` (recursive)

**Modules / Types declared** (public surface; all `[<NoEquality; NoComparison>]`):
- **Identifiers & directives**
  - `IdentTrivia` — `OriginalNotation | OriginalNotationWithParen | HasParenthesis` (display name + paren ranges)
  - `ConditionalDirectiveTrivia` — `If | Elif | Else | EndIf`
  - `IfDirectiveExpression` — `And | Or | Not | Ident`
  - `WarnDirectiveTrivia` — `Nowarn | Warnon`
  - `CommentTrivia` — `LineComment | BlockComment`
  - **`ParsedInputTrivia`** (record: `ConditionalDirectives`, `WarnDirectives`, `CodeComments`; `static member internal Empty`) — the file-level trivia attached to `ParsedInput`
- **Expression trivia**
  - `SynExprTryWithTrivia`, `SynExprTryFinallyTrivia`, `SynExprIfThenElseTrivia`, `SynExprLambdaTrivia`(`+Zero`), `SynExprDotLambdaTrivia`, `SynLetOrUseTrivia`(`+Zero`), `SynExprMatchTrivia`, `SynExprMatchBangTrivia`, `SynExprDoBangTrivia`, `SynExprYieldOrReturnTrivia`(`+Zero`), `SynExprYieldOrReturnFromTrivia`(`+Zero`), `SynExprAnonRecdTrivia`, `SynExprSequentialTrivia`(`+Zero`)
- **Pattern / union-case trivia**
  - `SynMatchClauseTrivia`(`+Zero`), `SynEnumCaseTrivia`, `SynUnionCaseTrivia`, `SynPatOrTrivia`, `SynPatListConsTrivia`
- **Leading-keyword records** (the master tables)
  - `SynTypeDefnLeadingKeyword` (`Type | And | StaticType | Synthetic` + `Range`)
  - `SynTypeDefnTrivia` (`+Zero`), `SynTypeDefnSigTrivia` (`+Zero`)
  - `SynLeadingKeyword` (the ~30-case union of every binding/member leading keyword + `Range`)
  - `SynModuleOrNamespaceLeadingKeyword` (`Module | Namespace | None`)
- **Binding / module trivia**
  - `SynBindingTrivia` (`+Zero`), `SynModuleDeclNestedModuleTrivia` (`+Zero`), `SynModuleSigDeclNestedModuleTrivia` (`+Zero`), `SynModuleDeclLetTrivia` (`+Zero`), `SynModuleOrNamespaceTrivia`, `SynModuleOrNamespaceSigTrivia`
- **Val / type / member trivia**
  - `SynValSigTrivia` (`+Zero`), `SynTypeFunTrivia`, `SynMemberGetSetTrivia`, `SynMemberDefnImplicitCtorTrivia`, `SynArgPatsNamePatPairsTrivia`, `GetSetKeywords`, `SynMemberDefnAutoPropertyTrivia`, `SynMemberDefnLetBindingsTrivia` (`+Zero`), `SynMemberDefnAbstractSlotTrivia` (`+Zero`), `SynMemberDefnInheritTrivia`, `SynFieldTrivia` (`+Zero`), `SynTypeOrTrivia`, `SynTypeWithNullTrivia`, `SynBindingReturnInfoTrivia`, `SynMemberSigMemberTrivia` (`+Zero`), `SynTyparDeclTrivia` (`+Zero`), `SynMeasureConstantTrivia`, `SynTypeConstraintWhereTyparNotSupportsNullTrivia`

**Public API surface**: each type is a record (or union with `RequireQualifiedAccess`) with named fields; the `Range` members and `Zero` static members are the canonical "empty" values. There are no functions in this module — it is a pure type surface.

**Internal helpers / active patterns / extension members**: none (the .fs is a mirror of the .fsi).

**Significant internal logic** (contract-level):
- **`Zero` records** are the "no-source" trivia records used when the compiler synthesizes a node (desugaring, `LibraryOnly*` lowering, signature emission). Downstream consumers must be ready to see `Zero` and fall back to a synthetic range.
- **`SynLeadingKeyword`** is the *master table* of every leading keyword the compiler recognizes (let/and/or/bang/use/rec/static/abstract/member/override/default/new/val/do) — each case stores the precise range(s) of the keyword(s), including multi-token forms.
- **`IdentTrivia.OriginalNotation` / `OriginalNotationWithParen` / `HasParenthesis`** is the single channel between the *mangled* name (e.g. `op_Addition`) and the *display* name (e.g. `+`, `(>=>)`); the inverse direction is handled by `PrettyNaming.ConvertValLogicalNameToDisplayName*`.
- **`ParsedInputTrivia`** is the *file-level* trivia bundle: the parser sets it from the outputs of `LexerStore.IfdefStore` (`ConditionalDirectiveTrivia`), `WarnScopes.getDirectiveTrivia` (`WarnDirectiveTrivia`), and `LexerStore.CommentStore` (`CommentTrivia`). It is the only public surface that carries file-level `#if`/`#nowarn`/comment information.
- **`RequireQualifiedAccess`** on most records avoids opening the trivia namespaces implicitly and keeps the AST surface stable.

**Cross-references**:
- `SyntaxTrivia.fs` (implementation; structurally identical to the .fsi)
- `SyntaxTree.fs` (the AST nodes that carry these records)
- `SyntaxTreeOps.fs` (operators that read/write trivia)
- `PrettyNaming.fs` (inverse of `IdentTrivia.OriginalNotation` → display name)
- `LexerStore.fs`, `WarnScopes.fs` (producers of the file-level trivia)
- `XmlDoc.fs` (`PreXmlDoc` — the parallel channel for XML-doc text)

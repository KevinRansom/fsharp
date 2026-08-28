# CheckRecordSyntaxHelpers.fsi

**Purpose**: Public contract for record copy-and-update / nested-update syntactic helpers used during Checking. Declares the nested-update AST transformation, the `bind@` binding marker and its active pattern, and the two helpers that bind a complex original record expression (or spread source) exactly once.

**Namespace(s)**: `module internal FSharp.Compiler.CheckRecordSyntaxHelpers`

**Public API surface** (val contracts):
- `TransformAstForNestedUpdates<'a> : cenv: TcFileState -> env: TcEnv -> overallTy: TType -> lid: LongIdent -> exprBeingAssigned: SynExpr -> withExpr: SynExpr * (range * 'a) -> (Ident list * Ident) * SynExpr` — expands a nested long identifier (e.g. `A.B`) in copy-and-update syntax into nested copy-and-update expressions.
- `BindIdText : string` — the name (`"bind@"`) used when a complex expression is bound for use as the base of a copy-and-update expression (e.g. `{ f () with ... }` → `let bind@ = f () in ...`).
- `inline (|IsSimpleOrBoundExpr|_|) : withExpr: SynExpr -> bool` — active pattern: detecting the `bind@` identifier is the only way to know an expression has already been bound.
- `BindOriginalRecdExpr : withExpr: SynExpr * BlockSeparator -> mkRecdExpr: ((SynExpr * BlockSeparator) option -> SynExpr) -> SynExpr` — binds the original record expression (when more complex than `{ x with ... }`) so it is not evaluated multiple times during a nested update.
- `bindSrcIn : spreadSrcExpr: SynExpr -> ((SynExpr -> SynExpr) -> SynExpr)` — same single-binding trick applied to record spread source expressions.

**Implementation-only** (in the `.fs`, not the .fsi): the inner recursive builders `buildLid`, `recdExprCopyInfo`, `synExprRecd`, `totalRange`, `rangeOfBlockSeparator`, `calcLidSeparatorRanges`, and the thread-safe fresh-id counter `bindId`/`newBindId`.

**Cross-references**: `CheckRecordSyntaxHelpers.fs` (implementation), `CheckBasics.fsi` (`TcFileState`, `TcEnv`), `NameResolution.fs` (`ResolveNestedField`), `Features` (`LanguageFeature.NestedCopyAndUpdate`).

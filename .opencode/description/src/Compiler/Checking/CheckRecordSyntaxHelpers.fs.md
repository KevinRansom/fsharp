# CheckRecordSyntaxHelpers.fs

**Purpose**: Syntactic (pre-checking) helpers for record copy-and-update expressions (`{ expr with a.b = ... }`) and record spreads/nested updates in the Checking phase. Implements the "nested copy-and-update" feature (LanguageFeature.NestedCopyAndUpdate) by rewriting nested `with`-syntax long identifiers into a tree of record-update expressions, and binds complex original expressions once (`let bind@ = ...`) so they are not re-evaluated for each nested update.

**Namespace(s)**: `module internal FSharp.Compiler.CheckRecordSyntaxHelpers`

**Notable declarations**:
- `TransformAstForNestedUpdates (cenv : TcFileState) (env : TcEnv) overallTy (lid: LongIdent) exprBeingAssigned withExpr -> (Ident list * Ident) * SynExpr` (line 21) — expands a long identifier into nested copy-and-update expressions: `{ x with A.B = 0; A.C = "" }` becomes `{ x with A = { x.A with B = 0 }; A = { x.A with C = "" } }`. Uses `ResolveNestedField` (NameResolution), marks qualifier idents synthetic (`idRange.MakeSynthetic()`) so the name-resolution sink doesn't double-report them, and gates the feature with `checkLanguageFeatureAndRecover ... LanguageFeature.NestedCopyAndUpdate`.
  - Nested helper `recdExprCopyInfo` builds the "copy" side of each `SynExpr.Record` / `SynExpr.AnonRecd` (for anonymous records: `SynExprAnonRecordField` with `TupInfo.Const isStruct`) and computes `calcLidSeparatorRanges` (separator ranges between dots, for accurate error spans) and `rangeOfBlockSeparator`.
- `BindIdText = "bind@"` (line 134) — the marker identifier used when a complex original expression is bound for use in a copy-and-update (e.g. `{ f () with ... }` becomes `let bind@ = f () in { bind@ with ... }`).
- Active pattern `(|IsSimpleOrBoundExpr|_|)` (line 137, `inline`) — returns `true` when `withExpr` is a simple `SynExpr.Ident` or a `SynExpr.LongIdent` whose id already starts with `bind@` (i.e. an expression we previously bound ourselves). The doc comment notes this is the only way to detect an already-bound expression.
- `BindOriginalRecdExpr (withExpr: SynExpr * BlockSeparator) (mkRecdExpr: ((SynExpr * BlockSeparator) option -> SynExpr)) -> SynExpr` (line 147) — wraps the original (complex) record expression in `let bind@ = <expr> in <mkRecdExpr (Some (bind@ ident, blockSep))>`; generates the binding with `mkSynBinding`, compiler-generated trivia (`IsFromSource = false`).
- `bindSrcIn (spreadSrcExpr: SynExpr) -> ((SynExpr -> SynExpr) -> SynExpr)` (line 186) — same binding trick for record *spread* source expressions, generating fresh unique ids `bind@-N` via a module-level counter.
  - Helpers: `let mutable private bindId = 0` and `newBindId ()` (lines 181-184) using `System.Threading.Interlocked.Increment` for thread-safe fresh ids.

**Internal helpers**:
- `buildLid` (inner `let rec`, line 24) — walk the identifier path up to a given id, preserving original ranges for idents matched by range equality (needed to find the "current" identifier among same-named fields at different nesting levels) and building `LongIdentWithDots`.
- `totalRange` (line 49), `rangeOfBlockSeparator` (line 52) — source-range bookkeeping for diagnostics.
- `synExprRecd` (line 67, `let rec`) — recursive construction of the nested `SynExpr.Record` / `SynExpr.AnonRecd` tree from the resolved nested-field path, choosing `Item.AnonRecdField` handling when the field item is an anonymous record type.

**Significant internal logic**:
- Resolution of `A.B.C` against the overall type's record shape uses `ResolveNestedField` from NameResolution; each resolved step becomes one level of nested `with`-syntax desugaring.
- Synthesized idents (`MakeSynthetic()`) prevent the synthetic field accesses (both the implicit "copy side" `x.A` reads and the outer-identifier reads inside the nested update) from surfacing in the name-resolution sink / IntelliSense.
- Feature-gating: nested copy-and-update only compiles on language versions supporting `LanguageFeature.NestedCopyAndUpdate`; otherwise `checkLanguageFeatureAndRecover` reports.
- `BindOriginalRecdExpr`/`bindSrcIn` guarantee single evaluation of the original (possibly impure) expression in `{ f () with a = ... ; b = ... }`, which would otherwise be computed once per field update.

**Cross-references**: `CheckRecordSyntaxHelpers.fsi` (contract), `NameResolution.fs` (`ResolveNestedField`), `CheckBasics.fsi` (`TcFileState`, `TcEnv`), the record-expression checking code in CheckExpressions that consumes the transformed AST, `SyntaxTreeOps` (`LongIdentWithDots`, `mkSynBinding`, `mkSynId`).

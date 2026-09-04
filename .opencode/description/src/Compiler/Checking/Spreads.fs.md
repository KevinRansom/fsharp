# Spreads.fs

**Purpose**
Implements typechecking of F# *spread* syntax in the Checking phase: record type spreads (e.g.
`type Rec = { field1; field2; ... }` with `<@ src @>`-style spread sources in type position, gated by the
spreads language feature) and record/anonymous-record value spreads (`{ x with A.B = ...; ... }` with
spread-of-another-record sources). It computes the list of fields (name, type, expression) that make up
the result, handling ambiguous-shadowing diagnostics (`errorAmbiguousShadowing`), explicit-shadowing
info (warning that a later explicit field overrides a spread field), and combining of nested record
updates (`{ x with A = { x.A with B = ... }; A = { x.A with C = ... } }` merged into a single nested
update).

**Namespace(s)**
`module internal FSharp.Compiler.Spreads` (marked `[<RequireQualifiedAccess>]`)

**Modules declared**
- `Patterns` (private, `AutoOpen`) — literals `LeftwardExplicit = true` / `NoLeftwardExplicit = false` used as the shadowing-state tag in the field map.
- `Types` → `Types.Records` — `check : checkSpreadsLanguageFeature -> tcField -> tcSpread -> SynFieldOrSpread list -> _ list`. Typechecks type-level record fields and spreads; builds a `Map<fieldId, (shadowState, (index*field) list)>`, reporting ambiguous shadowing and explicit-over-spread shadowing, then returns the final ordered field list.
- `Values` → `Values.Records` — record *value* spread checking. Contains `establishFields` (computes field list plus the ordered list of spread source types/expressions and any intervening spread sources, raising `ReportedError` for malformed fields) and `check` (the public entry: `TcExprFlex * g * env * cenv * tpenv * ad * mWholeExpr * withExprOpt * overallTy * SynExprRecordFieldOrSpread list -> ...` — typechecks a record expression or copy-and-update with spreads, including the type-directed conversion adjustment of spread source fields and the "spread used with `with`" error).
- `Values` → `Values.AnonymousRecords` — analogous checking for anonymous record expressions with spreads: `check : TcExprFlex * TcAdjustExprForTypeDirectedConversions * MustConvertTo * UnifyOverallType * errorRIfSpreadUsedWithWith * g * env * cenv * tpenv * ad * mWholeExpr * maybeAnonRecdTargetTy * origExprOpt * origExprTyOrOverallTy * SynExprAnonRecordFieldOrSpread list -> ...`.

**Active patterns / helpers**
- `(|NestedUpdate|_|) expr2 expr1` (private) — merges two successive record / anonymous-record copy-and-update expressions that update the same record: `Record(base, copy, fields1) + Record(fields2) → Record(base, copy, fields1 @ fields2)`. Used to combine nested updates produced by `CheckRecordSyntaxHelpers.TransformAstForNestedUpdates`.
- Per-field thunks `tcField` / `tcSpread` are passed in by the caller (`CheckExpressions.fs`), so this module stays decoupled from the rest of the checker.

**Significant internal logic**
- Field collection is a left-to-right fold over `SynFieldOrSpread` / `SynExprRecordFieldOrSpread` keeping,
  per field name, a shadowing state (`LeftwardExplicit` vs `NoLeftwardExplicit`) and an indexed list of
  candidate fields. Rules: an explicit field following an explicit field → *ambiguous shadowing error*;
  an explicit field following a spread field → *info: explicit overrides spread*; a spread field following
  an explicit field → *ambiguous shadowing warning* (later explicit field wins).
- Value spreads also carry the ordered list of spread-source expressions/types (`spreadSrcExprs` /
  `spreadSrcTys`), and `check` arranges the evaluation order so sources are captured into temporary
  bindings in the right order (the "intervening spread sources" handling in `establishFields`).
- `checkSpreadsLanguageFeature m` raises/dispatches the language-feature gate diagnostics at the spread's
  range (the spreads feature flag lives in `Features`/`TcGlobals`).
- The anonymous-record version additionally computes `targetAnonRecordTy` /
  `targetAnonRecordTyContainsField` to decide field types when a target anonymous-record type is known.

**Cross-references**
- `CheckExpressions.fs` (Expressions dir) — calls `Spreads.Types.Records.check`,
  `Spreads.Values.Records.check`, `Spreads.Values.AnonymousRecords.check` for record/anonymous-record
  expressions with spreads.
- `CheckRecordSyntaxHelpers.fs` (sibling) — `TransformAstForNestedUpdates` produces the nested update
  shape that `(|NestedUpdate|_|)` merges.
- `NameResolution.fsi` — `ExplicitOrSpread<'E,'S>` mirrors the same "explicit vs spread field" duality in
  field resolution.
- `CheckBasics.fs` (sibling) — `TcFileState`, `TcEnv`, `UnscopedTyparEnv` parameter types.
- `DiagnosticsLogger.fs` (Text dir) — `ReportedError` for error-recovery hand-off on malformed spread
  fields.

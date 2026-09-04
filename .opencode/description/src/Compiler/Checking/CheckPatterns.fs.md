# CheckPatterns.fs

**Purpose**: Pattern checking for the F# type-checker (part of the Checking phase linking parsed trees to the typed tree). Performs left-to-right, type-directed pattern checking: binds pattern variables into a linear environment (`TcPatLinearEnv`), resolves pattern long identifiers (union cases, record fields, IL fields, new defs, literals), checks attribute patterns, `and`/`or` patterns, `is` instance patterns, `as` aliases, and builds the phase-2 function `(TcPatPhase2Input -> Pattern)` that materializes the final `Pattern` once the bound values exist.

**Namespace(s)**: `module internal FSharp.Compiler.CheckPatterns`

**Type alias**: `cenv = TcFileState` (CheckBasics).

**Public API surface** (per the .fsi):
- `TcPat` — check one pattern (for a binding or match clause):
  `(warnOnUpper, cenv, env, valReprInfo, patEnv, ty, synPat) -> (TcPatPhase2Input -> Pattern) * TcPatLinearEnv` (CheckPatterns.fs:284).
- `TcSimplePats` — check a list of simple patterns for function/ctor arguments (CheckPatterns.fs:150).
- `TcSimplePatsOfUnknownType` — check simple patterns of unknown type (for implicit-constructor parameters) (CheckPatterns.fs:221).

**Internal recursive pattern checkers** (the `and` chain, CheckPatterns.fs:78-880):
- `TcSimplePat` (line 78) — single simple `Id` pattern; handles optional arguments (`mkOptionalParamTyBasedOnAttribute`), alternative id cells, `isMemberThis`, and the `WarnOnUpperFlag` behavior for uppercase idents.
- `TcPatBindingName` (line 229) — bind a name into `TcPatLinearEnv`, computing `PrelimVal1` via `TcPatValFlags`.
- `TcPatNamed` (line 420) — `as`-alias handling; `TcPatNamedAs` (line 397), `TcPatUnnamedAs` (line 405).
- `TcPatAnds` (line 470) and `TcPatOr` (line 447) — `and` / `|` pattern composition (or-patterns require re-checking of both patterns with fresh envs).
- `TcPatTuple` (line 475) — tuple pattern, using `UnifyRefTupleType` for ref-tuple optimization.
- `TcPatArrayOrList` (line 490) — list patterns: `[]`, `x::xs` (via `mkNilListPat` / `mkConsListPat`, lines 38-40), `|>`/arrays; `head`/`tail` pattern generation.
- `TcRecordPat` (line 501) — record pattern checking with named/positional field binding and type-directed field resolution.
- `TcNullPat` (line 544) — `null` pattern (type must be nullable/reference type).
- `TcPatIsInstance` (line 428) — `is T` instance test pattern, unifying against `obj`/target type with accessibility checks.
- `TcConstPat` (line 377) — constant patterns.
- `TcPatAttributed` (line 441) — attributed patterns.
- `TcArgPats` (line 564) — check constructor/case argument patterns.
- `TcPatLongIdent` (line 579) — dispatch on the resolved `Item` (union/exn case, new def, record/IL field, literal); delegates to:
  - `TcPatLongIdentNewDef` (line 623) — `new C(...)` constructor pattern;
  - `TcPatLongIdentUnionCaseOrExnCase` (line 682) — union-case / exception-case patterns (largest single case, lines 682-815), including exhaustiveness-related diagnostics and null-relevance of cases;
  - `TcPatLongIdentILField` (line 816);
  - `TcPatLongIdentRecdField` (line 840);
  - `TcPatLongIdentLiteral` (line 860) — F# constant pattern from an external value.
- `TcPatterns` (line 878) — top-level check of an argument pattern list against types.
- `TcPatAndRecover` (line 265) — wrapper recovering from certain errors to produce better diagnostics.

**Internal helpers / active patterns**:
- `mkNilListPat` / `mkConsListPat` (lines 38-40) — build the `TPat_unioncase` shapes for `[]` and `head::tail` list patterns against `g.nil_ucref` / `g.cons_ucref`.
- `UnifyRefTupleType` (line 44) — optimized unification for ref-tuple types that avoids creating new inference variables when the target is already a ref tuple; refines `ContextInfo.RecordFields` into `ContextInfo.TupleInRecordFields`.
- `TryAdjustHiddenVarNameToCompGenName` (line 61) — resolves a pattern `Id` to a compgen name / alternative id (used by computation expressions and `match` with alternative patterns), gated on `LanguageFeature.DontWarnOnUppercaseIdentifiersInBindingPatterns` and `WarnOnUpperVariablePatterns`.
- `collectBoundIdTextsFromPat` (line 152), `getPats`, `isOptArg` — pattern-list helpers for `SynSimplePats`.

**Significant internal logic**:
- Two-phase pattern checking: phase 1 (here) checks the shape, binds names, and returns a *function* `TcPatPhase2Input -> Pattern` plus an updated `TcPatLinearEnv`; phase 2 (run by the caller after `val_specs` are created and inference variables resolved, per the `TcPatPhase2Input` doc in `CheckBasics.fsi`) materializes the `Pattern` node with the actual `Val`s.
- `TcPatLinearEnv` flows left-to-right: `tpenv` (unscoped type parameters introduced inside the pattern), `names : NameMap<PrelimVal1>`, `takenNames : Set<string>` for shadowing/duplication diagnostics.
- Name resolution inside patterns (e.g. a union case vs. a new-binding vs. an IL field) is performed via `ResolvePatternLongIdent` using `env.eAccessRights`; uppercase/lowercase diagnostics are controlled by the `WarnOnUpperFlag` threaded through every `Tc*` function.
- The pattern for a union case produces `TPat_unioncase` together with argument pattern checks against the case's `UnionCaseInfo`.

**Cross-references**: `CheckPatterns.fsi` (contract), `CheckBasics.fs` (`TcPatLinearEnv`, `TcPatPhase2Input`, `TcPatValFlags`, `PrelimVal1`, `TcFileState`), `NameResolution.fs` (`ResolvePatternLongIdent`, `Item`), `ConstraintSolver.fs` (`AddCxTypeEqualsType`, `ContextInfo`), `PatternMatchCompilation.fs` (downstream pattern-to-code translation), `AttributeChecking.fs` (attributed patterns), `CheckDeclarations.fs` (consumes `TcSimplePatsOfUnknownType` for implicit constructors).

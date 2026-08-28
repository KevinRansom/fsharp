# CheckPatterns.fsi

**Purpose**: Public contract for pattern checking in the F# type-checker. Exposes exactly three entry points — check one pattern, check a list of simple patterns (function/ctor arguments), and check simple patterns of unknown type (implicit-constructor parameters) — all of which thread the linear pattern environment and the phase-2 materializer from `CheckBasics`.

**Namespace(s)**: `module internal FSharp.Compiler.CheckPatterns`

**Public API surface** (val contracts):
- `TcSimplePatsOfUnknownType : cenv: TcFileState -> optionalArgsOK: bool -> checkConstraints: CheckConstraints -> env: TcEnv -> tpenv: UnscopedTyparEnv -> pat: SynPat -> string list * TcPatLinearEnv * SynSimplePats`
  — check a set of simple patterns whose type is not yet known (e.g. the declarations of parameters for an implicit constructor); returns the bound id names, the updated linear env, and the normalized `SynSimplePats`.
- `TcPat : warnOnUpper: WarnOnUpperFlag -> cenv: TcFileState -> env: TcEnv -> valReprInfo: PrelimValReprInfo option -> vFlags: TcPatValFlags -> patEnv: TcPatLinearEnv -> ty: TType -> synPat: SynPat -> (TcPatPhase2Input -> Pattern) * TcPatLinearEnv`
  — check a pattern, e.g. for a binding or a match clause; returns a phase-2 function that materializes the `Pattern` plus the updated `TcPatLinearEnv`.
- `TcSimplePats : cenv: TcFileState -> optionalArgsOK: bool -> checkConstraints: CheckConstraints -> ty: TType -> env: TcEnv -> patEnv: TcPatLinearEnv -> synSimplePats: SynSimplePats -> parsedPatterns: SynPat list * bool -> string list * TcPatLinearEnv`
  — check a list of simple patterns, e.g. the arguments of a function or a class constructor, against a known function type; the `bool` in `parsedPatterns` indicates whether this is the first pattern in a sequence.

**Not in the .fsi** (implementation-only, in the `.fs`): `TcSimplePat`, `TcPatBindingName`, `TcPatAnds`, `TcPatOr`, `TcPatTuple`, `TcPatArrayOrList`, `TcRecordPat`, `TcNullPat`, `TcArgPats`, `TcPatLongIdent` and its case-specific dispatchers (`TcPatLongIdentNewDef`, `TcPatLongIdentUnionCaseOrExnCase`, `TcPatLongIdentILField`, `TcPatLongIdentRecdField`, `TcPatLongIdentLiteral`), `TcConstPat`, `TcPatNamedAs`/`TcPatUnnamedAs`, `TcPatIsInstance`, `TcPatAttributed`, `TcPatAndRecover`, `TcPatterns`, plus helpers `mkNilListPat`, `mkConsListPat`, `UnifyRefTupleType`, `TryAdjustHiddenVarNameToCompGenName`, `collectBoundIdTextsFromPat`.

**Cross-references**: `CheckPatterns.fs` (implementation), `CheckBasics.fsi` (`TcFileState`, `TcEnv`, `TcPatLinearEnv`, `TcPatPhase2Input`, `TcPatValFlags`, `PrelimVal1`, `ExplicitTyparInfo`, `UnscopedTyparEnv`, `CheckConstraints`), `NameResolution.fsi`, `PatternMatchCompilation.fsi`, `ConstraintSolver.fsi`, `CheckDeclarations.fs` (calls `TcSimplePats*` for ctor arguments and for binding patterns).

# QuickParse.fs

**Purpose**: Very cheap, deliberately inaccurate lexical scanning of raw F# source lines, historically used to extract "long identifier islands" (`A.B.C`) for intellisense-style operations (decl-items-at-position, goto-definition) before the language service had parsed ASTs. The header comment notes this code is largely obsolete now that ASTs are available, but long identifiers are still passed to `GetDeclarations` and friends, so it remains.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## TypeDefs / Records / Modules declared

- **`type PartialLongName`** (record) — a qualified long name fragment: `QualifyingIdents: string list`, `PartialIdent: string`, `EndColumn: int`, `LastDotPos: int option`; static `Empty` constructor.
- **`module QuickParse`** — the scanning functions:
  - `MagicalAdjustmentConstant` — `= 1`, "puts us after the last character".
  - `CorrectIdentifierToken` — retags a token as an identifier if it's inside an active-pattern name (ends with `|`).
  - `GetCompleteIdentifierIsland` (plus `GetCompleteIdentifierIslandImplAux`) — given a line string and index, find the identifier (with special cases for active patterns `|x|`, optional parameters `?x`, backquoted identifiers, and the `|[` array boundary); returns `(name, dotPos, isEnd)`.
  - `GetPartialLongName` — the list of partial qualified name to the left of index plus the residue.
  - `GetPartialLongNameEx` — same, but as a `PartialLongName` including `EndColumn` and `LastDotPos`.
  - `TestMemberOrOverrideDeclaration` — true when the user is typing `member x.` / `override (*comment*) x.` (a list of `FSharpTokenInfo`).
  - private helpers: `isValidStrippedName`, `isValidActivePatternName`, local active patterns (`|Char|_|`, `|IsLongIdentifierPartChar|_|`, `|IsIdentifierPartChar|_|`) and the `searchLeft`/`searchRight` recursion.

## Public API surface

- All six module values above are public per the fsi; `PartialLongName` is public.
- Note the fsi documents the known inaccuracy (e.g., long identifier chains with `` ``...`` `` and active-pattern special cases).

## Internal helpers / active patterns

- `|Char|_|`, `|IsLongIdentifierPartChar|_|`, `|IsIdentifierPartChar|_|` — line-based scanning active patterns.
- `isValidActivePatternName`/`isValidStrippedName` — heuristic active-pattern recognition good enough to distinguish `|_|` names from operators like `||`.
- `FSharp.Compiler.Parser.tagOfToken`/`token` used by `CorrectIdentifierToken`; `PrettyNaming` `IsIdentifierPartCharacter`/`IsLongIdentifierPartCharacter`.

## Significant internal logic

- The scan is pure string manipulation over one line — no lexer state, no AST — which is why it is "magical" (`MagicalAdjustmentConstant`) and error-tolerant; it must work even on incomplete lines mid-edit.
- `GetCompleteIdentifierIsland` handles: cursor before/inside/after the identifier, `tolerateJustAfter` for goto-definition, `?` optional-argument positions, `|`-bound active patterns, and backtick-quoted identifiers.
- The module explicitly documents itself as legacy; newer code should prefer AST-based lookups (see `FSharpParseFileResults.fs` position queries).

## Cross-references

- Feeds `FSharpCheckFileResults.GetDeclarationListInfo`/`GetDeclarationListSymbols`/`GetToolTip`/`GetMethods` (see `FSharpCheckerResults.fs/.fsi`), which take a `PartialLongName`.
- Superseded in most scenarios by `FSharpParseFileResults` position-based members (see `FSharpParseFileResults.fs`).
- Token info types come from `FSharp.Compiler.Tokenization`.

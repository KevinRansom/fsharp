# QuickParse.fsi

**Purpose**: Public contract for `QuickParse.fs` — the cheap, inexact line-scanning functions that extract partial long names ("identifier islands" like `A.B.C`) from raw source text for intellisense-position queries. The fsi carries the long header comment explaining this is very old code, kept because long identifiers are still passed to `GetDeclaration*` entry points.

**Namespace(s)**: `FSharp.Compiler.EditorServices`

## TypeDefs / Records / Modules declared

- **`type PartialLongName`** (record, public)
  - `QualifyingIdents: string list` — idents before the last dot
  - `PartialIdent: string` — last part
  - `EndColumn: int`
  - `LastDotPos: int option`
  - `static member Empty: endColumn: int -> PartialLongName`
- **`module QuickParse`** (public)
  - `MagicalAdjustmentConstant: int` — "puts us after the last character".
  - `CorrectIdentifierToken: tokenText * tokenTag -> int` — fixes the token tag when inside an active-pattern name (at the bar).
  - `GetCompleteIdentifierIsland: tolerateJustAfter -> lineStr * index -> (string * int * bool) option` — find the identifier at a position; documents special handling of active patterns (letters + `|`), backticked identifiers, and that operators are not supported.
  - `GetPartialLongName: lineStr * index -> string list * string` — partial long name to the left of index.
  - `GetPartialLongNameEx: lineStr * index -> PartialLongName` — e.g. for `System.DateTime.Now` returns `([|"System";"DateTime"|], "Now", Some 32)`.
  - `TestMemberOrOverrideDeclaration: FSharpTokenInfo[] -> bool` — detect `member x.` / `override (*comment*) x.` while typing.

## Public API surface

- Exactly the module values above plus `PartialLongName`; consumers pass these into `FSharpCheckFileResults` "list info / tooltip / methods / declaration location" members.

## Internal helpers / active patterns

- None exposed in the fsi; the `.fs` active patterns (`|Char|_|` etc.) and recursive `searchLeft`/`searchRight` scans are private.

## Significant internal logic

- Documented caveats: inaccurate for `` ``...`` `` long identifier chains, special-cases active-pattern names; `tolerateJustAfter` exists specifically so goto-definition works one character past the identifier.
- `TestMemberOrOverrideDeclaration` operates on already-tokenized lines (`FSharpTokenInfo[]`), i.e. it bridges the raw-text scanner and the lexer.

## Cross-references

- `PartialLongName` is an input to `FSharpCheckFileResults.GetDeclarationListInfo`, `GetDeclarationListSymbols`, `GetDescription`, `GetF1Keyword`, `GetMethods` (see `FSharpCheckerResults.fsi`).
- `FSharpTokenInfo`/`FSharpTokenTag` — `FSharp.Compiler.Tokenization` (see also `ServiceLexing.fs`).
- Superseded for many scenarios by the AST-based position queries in `FSharpParseFileResults.fs`/`.fsi`.

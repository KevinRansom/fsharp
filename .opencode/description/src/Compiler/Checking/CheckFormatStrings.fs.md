# CheckFormatStrings.fs

**Purpose**: Compile-time parsing of "printf-style" format specifiers (`%d`, `%i`, `%f`, `%s`, `%b`, `%A`, indexed `%N` specifiers, width/precision, etc.) used by `Printf` and the newer `$` string interpolation / formattable strings. It produces the list of types for the arguments the format string expects, plus the "printer" residue type, so that `printf`-like functions can be type-checked at compile time. It must stay in sync with the Printf runtime component.

**Namespace(s)**: `module internal FSharp.Compiler.CheckFormatStrings`

**Types declared**:
- `FormatItem` (internal) — `Simple of TType` | `FuncAndVal`: either a plain argument type or a printer function + value pair (used for `%A`-style specifiers).
- `FormatInfoRegister` (internal) — mutable register accumulating per-specifier flags while parsing: `leftJustify : bool`, `numPrefixIfPos : char option`, `addZeros : bool`, `precision : bool`; `newInfo ()` creates a fresh one.
- `module Parse` (internal) — tokenizing/scanning sub-module with `go`, `digitsPrecision`, `digitsWidthAndPrecision`, `digitsPosition`, `parseFormatStringInternal`, `parseLoop` and `parseSpecifier` (recursive pair, ~lines 119-509).

**Public API surface**:
- `mkFlexibleIntFormatTypar : TcGlobals -> TType` — flexible type variable constrained to the integer types accepted by `%d`/`%i`/`%u` (sbyte..unativeint, default `int` via `TyparConstraint.DefaultsTo` at `lowestDefaultPriority = 0`; see `mkFlexibleFormatTypar` at CheckFormatStrings.fs:26-32).
- `mkFlexibleDecimalFormatTypar` — constrained to `decimal` for `%M`. (Also unexported `mkFlexibleFloatFormatTypar` for `%f`/`%F`.)
- `stringFormatTy : TcGlobals -> TType` — the type accepted by `%s`; `string_ty_ambivalent` when nullness checking is on.
- `ParseFormatString : range * range list * TcGlobals * bool * bool * FormatStringCheckContext option * string * TType * TType * TType -> TType list * TType * TType * TType[] * (range * int) list * string` — the main entry: given the literal format string, the per-fragment source ranges (for interpolated `$"... {expr} ..."` forms), and the printer arg/residue/result types, returns the list of expected argument types, the residue type, the printer result type, per-fragment arrays, `(range*size)` index info, and any error string.
- `TryCountFormatStringArguments : range * TcGlobals * bool * string * TType * TType -> int option` — lightweight count of arguments (used for early diagnostics without full resolution).

**Internal helpers / active patterns**:
- `copyAndFixupFormatTypar` — freshens a typar via `FreshenAndFixupTypars` (CheckBasics/TcGlobals machinery).
- `escapeDotnetFormatString` — doubles `{`/`}` since the F# lexer strips braces (CheckFormatStrings.fs:55-61).
- Active pattern `PrefixedBy` (CheckFormatStrings.fs:63) — string prefix match returning the prefix length.
- `makeFmts` (CheckFormatStrings.fs:69-112) — splits a string on interpolation holes using `fragRanges`; computes `delimLen` (number of `$` at the start of a triple-quoted string) and `nQuotes` (1 vs 3) to correctly reconstruct per-fragment source text for diagnostics.
- `Parse.parseSpecifier` — per-specifier type construction (drives `%` codes to `FormatItem`s, builds width/precision argument types, resolves `*` width specifiers).

**Significant internal logic**:
- Type variable rigidity is `Rigid` for the format typar with `SimpleChoice` constraint enumerating allowed concrete types and a `DefaultsTo` constraint providing a default (e.g. `int` for integer formats), matching the behavior of `TyparConstraint.DefaultsTo` lowest-priority semantics.
- Interpolated strings (`isInterpolated`, `isFormattableString`) and `FormatStringCheckContext` support the modern `$"..."` / `"$@..."` / `"""` triple-quoted forms; the fragment splitting depends on `context.SourceText` and `context.LineStartPositions` to extract the original fragment text for accurate error reporting.

**Cross-references**: `CheckFormatStrings.fsi` (contract), `TcGlobals` (format typars, `checkNullness`), TypedTree `TyparConstraint` (`SimpleChoice`, `DefaultsTo`), CheckExpressions (caller for `printf`/`sprintf`/`$`-interpolated strings), `PatternMatchCompilation.fs` (same Checking phase, unrelated).

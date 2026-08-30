# CheckFormatStrings.fsi

**Purpose**: Public contract for `printf`-style / `$`-interpolated format-string checking. States the two entry points (`ParseFormatString`, `TryCountFormatStringArguments`) and the small set of helpers for constructing the flexible type variables used for integer/decimal/string format specifiers.

**Namespace(s)**: `module internal FSharp.Compiler.CheckFormatStrings`

**Header notes**: The module doc comments note it must be updated whenever the Printf runtime component is updated.

**Public API surface** (val contracts):
- `mkFlexibleIntFormatTypar : g: TcGlobals -> m: range -> TType` — flexible type variable constrained to the integer types accepted by `%d`/`%i`/`%u`.
- `mkFlexibleDecimalFormatTypar : g: TcGlobals -> m: range -> TType` — flexible type variable constrained to `decimal`, as accepted by `%M`.
- `stringFormatTy : g: TcGlobals -> TType` — the type accepted by `%s`; ambivalent about nullness when nullness checking is active.
- `ParseFormatString : m: range -> fragmentRanges: range list -> g: TcGlobals -> isInterpolated: bool -> isFormattableString: bool -> formatStringCheckContext: FormatStringCheckContext option -> fmt: string -> printerArgTy: TType -> printerResidueTy: TType -> printerResultTy: TType -> TType list * TType * TType * TType[] * (range * int) list * string` — parses the format string at compile time and produces the argument type list, residue type, printer result type, per-fragment type arrays, and `range * int` index info, plus a final `string` (diagnostic/result summary).
- `TryCountFormatStringArguments : m: range -> g: TcGlobals -> isInterpolated: bool -> fmt: string -> printerArgTy: TType -> printerResidueTy: TType -> int option` — cheap count of expected arguments (returns `None` when the format can't be pre-counted, e.g. `*` width specifiers or function arguments).

**Not in the .fsi** (implementation-only, see the `.fs`): the `FormatItem`/`FormatInfoRegister` types, the internal `Parse` sub-module (scanning, `parseLoop`/`parseSpecifier`), `mkFlexibleFormatTypar`, `mkFlexibleFloatFormatTypar`, `escapeDotnetFormatString`, the `PrefixedBy` active pattern, and `makeFmts`.

**Cross-references**: `CheckFormatStrings.fs` (implementation), `TcGlobals` (built-in type references, `checkNullness`), TypedTree `TyparConstraint` (`SimpleChoice`/`DefaultsTo`), CheckExpressions (primary caller of `ParseFormatString`).

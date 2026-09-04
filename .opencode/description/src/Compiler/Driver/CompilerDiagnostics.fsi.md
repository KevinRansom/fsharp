# CompilerDiagnostics.fsi

**Purpose** Signature for the diagnostics pipeline. Declares the `PhasedDiagnostic` contract (rich-text + plain formatting, severity adjustment, and terminal/console output) together with the "old-style" exception types that historically carried diagnostics, and the few module-level entry points that filter by scoped `#nowarn`/pragmas.

**Pipeline role** Terminal of the diagnostic flow: every `warning`/`error` raised across the driver and checkers ends up either as an `exn` or as a `PhasedDiagnostic`; this module is where they are normalized (`AdjustSeverity`), formatted (`FormatCore`/`FormatRichCore`), filtered (the nowarn logger), and rendered to a `StringBuilder` or `TextWriter`.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.CompilerDiagnostics`, declared `internal`.

**Exceptions (old-style diagnostics)**
- `HashIncludeNotAllowedInNonScript of range` — `#load` in a non-script.
- `HashReferenceNotAllowedInNonScript of range` — `#r` in a non-script.
- `HashLoadedSourceHasIssues of informationals * warnings * errors * range`.
- `HashLoadedScriptConsideredSource of range`.
- `HashDirectiveNotAllowedInNonScript of range`.
- `DeprecatedCommandLineOptionFull of string * range`.
- `DeprecatedCommandLineOptionForHtmlDoc of string * range`.
- `DeprecatedCommandLineOptionSuggestAlternative of string * string * range`.
- `DeprecatedCommandLineOptionNoDescription of string * range`.
- `InternalCommandLineOption of string * range`.

**Types declared (contract)**
- **`PhasedDiagnostic`** (extension `with` block) — the unified diagnostic type. Members:
  - `Range: range option`.
  - `Number: int`.
  - `EagerlyFormatCore suggestNames: bool -> PhasedDiagnostic` — pre-format so it no longer needs type formatting.
  - `FormatRichCore (flattenErrors, suggestNames) -> RichText`.
  - `FormatCore (flattenErrors, suggestNames) -> string`.
  - `AdjustSeverity FSharpDiagnosticOptions -> FSharpDiagnosticSeverity` — central place for `WarnOn`/`WarnOff`/`WarnAsErrors`/`CheckNullness`/`CheckOverflow`/severity demotion to `Hidden`.
  - `Output (buf: StringBuilder, tcConfig, severity)` — append the full diagnostic (range + canonical + message + context) in the requested order.
  - `WriteWithContext (os: TextWriter, prefix, fileLineFunction, tcConfig, severity)` — same, but to a `TextWriter`, used for interactive contexts.

- **`FormattedDiagnosticLocation`** (`RequireQualifiedAccess`) — `{ Range; File; TextRepresentation; IsEmpty }`.
- **`FormattedDiagnosticCanonicalInformation`** — `{ ErrorNumber; Subcategory; TextRepresentation }`.
- **`FormattedDiagnosticDetailedInfo`** — `{ Location: FormattedDiagnosticLocation option; Canonical; Message; Context: string option; DiagnosticStyle }`.
- **`FormattedDiagnostic`** — `Short of FSharpDiagnosticSeverity * string | Long of FSharpDiagnosticSeverity * FormattedDiagnosticDetailedInfo`.

**Public API surface (per signature)**
- `GetDiagnosticsLoggerFilteringByScopedNowarn (diagnosticOptions, diagnosticsLogger) -> DiagnosticsLogger` — a logger that delegates to another but first filters warnings per scoped pragmas / `#nowarn` ranges.
- `SanitizeFileName (fileName, implicitIncludeDir) -> string` — strips the include-dir prefix for display.
- `CollectFormattedDiagnostics (tcConfig, severity, diagnostic, suggestNames) -> FormattedDiagnostic[]` — the function consumed by `PhasedDiagnostic.Output` / `WriteWithContext` to produce the formatted pieces.
- Debug-only (inside `#if DEBUG`): `showAssertForUnexpectedException: bool ref` and `mutable showParserStackOnParseError: bool`.

**Internal helpers / active patterns** The heavy formatting logic (per-exception rendering, suggestion output, caret / code-context lines) is implemented in the .fs — see `CompilerDiagnostics.fs.md`. The signature only exposes the `PhasedDiagnostic` contract and the three module-level helpers.

**Significant internal logic** `PhasedDiagnostic` unifies two diagnostic sources — the modern `DiagnosticMessage`-based value and the legacy `exn`-based errors — behind the same formatting members, so fsc/fsi and the language service render identical output. Severity adjustment is centralized in `AdjustSeverity` so that no other module ever implements its own warn-on/warn-off semantics.

**Cross-refs** `FSharp.Compiler.Diagnostics` (base `PhasedDiagnostic`, `FSharpDiagnosticOptions`, `FSharpDiagnosticSeverity`), `FSharp.Compiler.DiagnosticsLogger`, `FSharp.Compiler.CompilerConfig.TcConfig`, `FSharp.Compiler.Text` (`RichText`, `range`, `Position`), and the large family of checker/lexer modules whose exceptions it renders (e.g. `FSharp.Compiler.ConstraintSolver`, `FSharp.Compiler.NameResolution`, `FSharp.Compiler.CheckExpressions`, …). Installed as the thread logger from `FSharp.Compiler.Driver` (fsc.fs).

# FSharpDiagnostic.fsi

**Purpose**
Public contract for compiler diagnostics as seen by the F# language and consumed by FCS/tooling.
It defines `FSharpDiagnostic` (position + severity + message + error number + optional
contextual `ExtendedData`), the `ExtendedData` module carrying type-mismatch, signature-vs-
implementation mismatch, obsolete/experimental attribute and other diagnostic context, and the
internal diagnostic-capture scopes used by the compiler during type checking. Diagnostics embed
symbols from `FSharp.Compiler.Symbols`, tying messages to semantic entities.

**Namespace(s)**
`namespace FSharp.Compiler.Diagnostics` (references `FSharp.Compiler.Symbols`,
`FSharp.Compiler.Text`, `FSharp.Compiler.DiagnosticsLogger`)

**Modules / Types declared**
- `module ExtendedData`
  - `DiagnosticContextInfo` (union, `[RequireQualifiedAccess]`) — the context of a type equation
    in type-mismatch diagnostics: `NoContext`, `IfExpression`, `OmittedElseBranch`,
    `ElseBranchResult`, `RecordFields`, `TupleInRecordFields`, `CollectionElement`,
    `ReturnInComputationExpression`, `YieldInComputationExpression`, `RuntimeTypeTest`,
    `DowncastUsedInsteadOfUpcast`, `FollowingPatternMatchClause`, `PatternMatchGuard`,
    `SequenceExpression`.
  - `IFSharpDiagnosticExtendedData` (interface) — marker for diagnostic payload.
  - `ObsoleteDiagnosticExtendedData` — `DiagnosticId`, `UrlFormat`.
  - `ExperimentalExtendedData` — `DiagnosticId`, `UrlFormat`.
  - `TypeMismatchDiagnosticExtendedData` — `ExpectedType: FSharpType`, `ActualType: FSharpType`,
    `ContextInfo: DiagnosticContextInfo`, `DisplayContext: FSharpDisplayContext`.
  - `TypeExtendedData` — `Type: FSharpType`, `DisplayContext`.
  - `ExpressionIsAFunctionExtendedData` — `ActualType`.
  - `FieldNotContainedDiagnosticExtendedData` — `SignatureField`/`ImplementationField: FSharpField`.
  - `ValueNotContainedDiagnosticExtendedData` — `SignatureValue`/`ImplementationValue: FSharpMemberOrFunctionOrValue`.
  - `ArgumentsInSigAndImplMismatchExtendedData` — `SignatureName`/`ImplementationName`/`SignatureRange`/`ImplementationRange`.
  - `DefinitionsInSigAndImplNotCompatibleAbbreviationsDifferExtendedData` — `SignatureRange`/`ImplementationRange`.
- `FSharpDiagnostic` (`[<Class>]`) — the diagnostic record (see API).
- `DiagnosticsScope` (`[Sealed]`, internal) — `IDisposable` scope that resets error/warning
  handlers, collects diagnostics, and `Protect<'T>`s a thunk against compiler-internal failures.
- `CompilationDiagnosticLogger` (internal, inherits `DiagnosticsLogger`) — capture logger with
  severity adjustment per `FSharpDiagnosticOptions`; `GetDiagnostics: unit -> PhasedDiagnostic[]`.
- `module DiagnosticHelpers` (internal) — `ReportDiagnostic`, `CreateDiagnostics` turning
  `PhasedDiagnostic`s into `FSharpDiagnostic`s (with file-filtering by `allErrors`/
  `mainInputFileName`).

**Public API surface — `FSharpDiagnostic`**
- Members: `FileName`, `Start`, `End`, `StartColumn`, `EndColumn`, `StartLine`, `EndLine`,
  `Range: range`, `Severity: FSharpDiagnosticSeverity`, `DefaultSeverity`
  ("original severity prior to adjustments via compiler flags, #nowarn and other features"),
  `Message: string`, `RichMessage: RichText`, `Subcategory: string`, `ErrorNumber: int`,
  `ErrorNumberPrefix: string`, `ErrorNumberText: string` (e.g. "FS0031"), and
  `ExtendedData: IFSharpDiagnosticExtendedData option` (marked `[<Experimental>]`).
- `static member Create` — two overloads (string message or `RichText` message; `?numberPrefix`,
  `?subcategory`) for e.g. analyzer-emitted diagnostics.
- `internal static member CreateFromException : PhasedDiagnostic * suggestNames * flatErrors *
  symbolEnv option -> FSharpDiagnostic` — decomposes a warning/error into parts.
- `static member NewlineifyErrorString`, `static member NormalizeErrorString` — newline ↔
  ASCII 29 (group separator) conversion so multi-line errors survive QuickInfo transport.

**Internal helpers**
- `DiagnosticsScope.Protect<'T> (range) (f) (err)` — runs `f` under a fresh diagnostic
  scope; on `RecoverableException`, re-runs through `errorRecovery` and maps the first captured
  error text via `err`, so FCS entry points fail gracefully instead of crashing.
- `DiagnosticsScope.Diagnostics` / `Errors` (filter by severity) / `TryGetFirstErrorText`.
- `DiagnosticHelpers.ReportDiagnostic` — applies `diagnostic.AdjustSeverity(options)`; drops
  `Hidden` and non-main-file diagnostics unless `allErrors`.

**Significant internal logic**
- `DefaultSeverity` vs `Severity`: the compiler may downgrade/upgrade (e.g. #nowarn, `-w` flags);
  tools can tell whether a warning was originally an error.
- `ExtendedData` is the extensibility hook "for things like code fixes"; it is produced by
  `CreateFromException` when a `SymbolEnv` is supplied (see .fs) — type mismatches yield expected/
  actual `FSharpType`s plus the `DiagnosticContextInfo`.
- The `PhasedDiagnostic` → `FSharpDiagnostic` boundary is the point where compiler-internal
  exception payloads (from `CheckExpressions`, `ConstraintSolver`, `SignatureConformance`) are
  flattened into a public shape.

**Cross-references**
- `FSharpDiagnostic.fs` — implementation (ExtendedData construction from exception payloads,
  `DiagnosticsScope`/`CompilationDiagnosticLogger` logic, `DiagnosticHelpers`).
- `Symbols.fsi` — `FSharpType`, `FSharpField`, `FSharpMemberOrFunctionOrValue`,
  `FSharpDisplayContext`, `SymbolEnv` used in ExtendedData.
- `XmlDocInheritance`/`SymbolHelpers` — unrelated diagnostic-wise, but same directory.

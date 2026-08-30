# DiagnosticOptions.fsi

**Purpose**: The contract for `DiagnosticOptions.fs`. Exposes the two shared diagnostics types — `FSharpDiagnosticSeverity` and the `FSharpDiagnosticOptions` record — which are part of the public FSharp.Compiler.Service API surface.

**Namespace(s)**: `FSharp.Compiler.Diagnostics`

**TypeDefs declared**:
- `[<RequireQualifiedAccess>] type FSharpDiagnosticSeverity`: `Hidden | Info | Warning | Error`
- `type FSharpDiagnosticOptions`: record with `WarnLevel: int`, `GlobalWarnAsError: bool`, `WarnOff/WarnOn/WarnAsError/WarnAsWarn: int list`, `mutable WarnScopeData: obj option`

**Contract (API surface)**:
- `FSharpDiagnosticOptions.Default: FSharpDiagnosticOptions`
- `member CheckXmlDocs: bool`

**Notes**: This is one of the few Facilities files whose types are intentionally part of the FSharp.Compiler.Service public API (per the file header comment: "made public in the FSharp.Compiler.Service API but which are also used throughout the F# compiler"). The mutable `WarnScopeData` field is the mechanism for stowing pragma-scope data.

**Cross-references**: Implements DiagnosticOptions.fs; consumed by DiagnosticsLogger.fsi (logger takes diagnostic options) and the driver's warning-option parsing.

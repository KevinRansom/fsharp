# DiagnosticOptions.fs

**Purpose**: Defines the simple, shared diagnostics option types that are public in the FSharp.Compiler.Service API and also used throughout the compiler: the severity enumeration and the per-compilation `FSharpDiagnosticOptions` record (warn level, warn-as-error/on/off lists).

**Namespace(s)**: `FSharp.Compiler.Diagnostics`

**TypeDefs / Records / Unions declared**:
- `[<RequireQualifiedAccess>] type FSharpDiagnosticSeverity`: `Hidden | Info | Warning | Error`
- `type FSharpDiagnosticOptions`: record `{ WarnLevel:int; GlobalWarnAsError:bool; WarnOff:int list; WarnOn:int list; WarnAsError:int list; WarnAsWarn:int list; mutable WarnScopeData: obj option }`

**Public API surface**:
- `FSharpDiagnosticOptions.Default` — static member: `WarnLevel=3`, all warning lists empty, `GlobalWarnAsError=false`
- `member CheckXmlDocs: bool` — true iff warning 3390 is in `WarnOn` and not in `WarnOff`
- Minor helper: the `mutable WarnScopeData` slot is used by `#nowarn`-scope bookkeeping at runtime

**Significant internal logic**:
- `WarnScopeData` is a mutable `obj option` carrier so scoping pragmas (`#nowarn "3390"`) can stow compiler-internal state alongside the options record without the Service API knowing about it
- `CheckXmlDocs` special-cases code 3390 (missing XML doc), which is treated as an optional "on by request" warning rather than being driven by `WarnLevel`

**Cross-references**: Consumed by DiagnosticsLogger.fs (severity/warn-level decisions), Driver command-line parsing, and the F# `CheckOptions`; severity values flow into RichText/TextLayoutRender output formatting.

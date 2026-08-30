# FSharpDiagnostic.fs

**Purpose**
Implementation of the `FSharpDiagnostic` API. In this codebase the class *implementations* (member
bodies, constructor, static members) live here, while public type signatures are mirrored in
`FSharpDiagnostic.fsi`. It also hosts the compiler-internal diagnostic machinery: the
`ExtendedData` payload types, `DiagnosticsScope` (exception-safe wrapper for FCS entry points),
`CompilationDiagnosticLogger` (severity-filtering capture logger), and the `DiagnosticHelpers`
module that turns compiler-internal `PhasedDiagnostic`s into public `FSharpDiagnostic`s.

**Namespace(s)**
`namespace FSharp.Compiler.Diagnostics` (opens `FSharp.Compiler.CheckExpressions`,
`ConstraintSolver`, `NameResolution`, `SignatureConformance`, `Symbols`, `Syntax`, `TypedTree`,
`CompilerDiagnostics`, `DiagnosticsLogger`, `FSharp.Core.Printf`, `FSharp.Compiler.Text`)

**Modules / Types declared (with implementation)**
- `module ExtendedData`
  - `DiagnosticContextInfo` — union of type-equation contexts; `static member From(contextInfo:
    ContextInfo)` maps the internal `ContextInfo` (which carries ranges/typar data) onto the
    public, range-free shape; `NullnessCheckOfCapturedArg` and
    `MemberAccessOnNullable` map to `NoContext`.
  - `IFSharpDiagnosticExtendedData` — marker interface.
  - `ObsoleteDiagnosticExtendedData`/`ExperimentalExtendedData` (internal ctors) — expose
    `DiagnosticId`, `UrlFormat`.
  - `TypeMismatchDiagnosticExtendedData` — wraps `TType`s in `FSharpType(cenv, ...)`; exposes
    `ExpectedType`, `ActualType`, `ContextInfo`, `DisplayContext = FSharpDisplayContext(fun _
    -> dispEnv)`.
  - `TypeExtendedData`, `ExpressionIsAFunctionExtendedData`,
    `FieldNotContainedDiagnosticExtendedData` (wraps sig/impl `RecdField`s as `FSharpField` via
    `mkLocalTyconRef`), `ValueNotContainedDiagnosticExtendedData` (sig/impl `Val`s as
    `FSharpMemberOrFunctionOrValue` via `mkLocalValRef`),
    `ArgumentsInSigAndImplMismatchExtendedData` (identifiers + ranges),
    `DefinitionsInSigAndImplNotCompatibleAbbreviationsDifferExtendedData` (tycon ranges).
- `FSharpDiagnostic` — constructor `(m: range, severity, defaultSeverity, message: RichText,
  subcategory, errorNum, numberPrefix, extendedData)`. All .fsi members are trivial projections
  (`ErrorNumberText = numberPrefix + errorNum.ToString("0000")`, etc.).
  - `WithStart`/`WithEnd` copy members with adjusted range endpoints (internal use).
  - `ToString` — "file (line,col)-(line,col) subcategory severity message".
- `DiagnosticsScope` (`[Sealed]`) — `IDisposable`; pushes `UseBuildPhase BuildPhase.TypeCheck`
  and a `DiagnosticsLogger` whose sink converts via `CreateFromException` and accumulates into
  `diags`; `Errors`, `Diagnostics`, `TryGetFirstErrorText`; `Dispose` unwinds both bindings.
- `CompilationDiagnosticLogger` (internal) — inherits `DiagnosticsLogger`; optional `preprocess`
  pass on each `PhasedDiagnostic`; `AdjustSeverity(options)` then stores with adjusted severity
  (drops `Hidden`, counts `Error`); `GetDiagnostics: unit -> PhasedDiagnostic[]`.
- `module DiagnosticHelpers` — `ReportDiagnostic` (applies severity adjustment, filters by
  `allErrors` / `mainInputFileName` / `TcGlobals.DummyFileNameForRangesWithoutASpecificLocation`),
  `CreateDiagnostics` (array fold over diagnostics).

**Public API surface**
See `FSharpDiagnostic.fsi.md` for the full contract. Implementation notes:
- `CreateFromException` — the only path with a switch over compiler-internal exception payloads:
  `ErrorFromAddingConstraint` / `ErrorFromAddingTypeEquation` (several shapes — picks the best
  expected/actual pair via `typeEquiv` comparisons) / `ErrorsFromAddingSubsumptionConstraint` →
  `TypeMismatchDiagnosticExtendedData`; `FunctionValueUnexpected` →
  `ExpressionIsAFunctionExtendedData`; `FieldNotContained`/`ValueNotContained`/
  `ArgumentsInSigAndImplMismatch`/`DefinitionsInSigAndImpl...` → conformance extended data;
  `ObsoleteDiagnostic`/`Experimental` → id/URL data; `NoConstructorsAvailableForType` →
  `TypeExtendedData`. Message formatting prefers a cached `RichText` under
  `diagnostic.Exception.Data["CachedFormatCore"]`, else `FormatRichCore` (which honors
  `flatErrors`/`suggestNames`). Range comes from `diagnostic.Range` with `ApplyLineDirectives()`,
  defaulting to `range0`.
- `DiagnosticsScope.Protect` — try `f()`; on failure run `errorRecovery e m` (catching
  `RecoverableException`) purely to populate the scope, then map
  `TryGetFirstErrorText()` through the caller's `err` — so e.g. autocomplete formatting turns a
  "missing assembly" into an error string in the tooltip rather than crashing.

**Internal helpers**
- `ExtendedData.DiagnosticContextInfo.From` — the internal→public context mapping (a few internal
  context kinds intentionally collapse to `NoContext` so they never leak).
- `DiagnosticsScope`'s anonymous `DiagnosticsLogger` — sink closure building `FSharpDiagnostic`s.

**Significant internal logic**
- Two-severity model (`Severity` vs `DefaultSeverity`) set at `CreateFromException` from
  `PhasedDiagnostic.Severity`/`.DefaultSeverity`.
- `CompilationDiagnosticLogger` enforces `FSharpDiagnosticOptions` (warn-as-error, hidden
  removal) at collection time, so downstream lists are already filtered.
- `DiagnosticHelpers.CreateDiagnostics` is the batch path used at the end of a compilation.

**Cross-references**
- `FSharpDiagnostic.fsi` — contract.
- `Symbols.fsi`/`.fs` — `FSharpType`, `FSharpField`, `FSharpMemberOrFunctionOrValue`,
  `FSharpDisplayContext`, `SymbolEnv` are constructed in the ExtendedData payloads.
- `DiagnosticHelpers` is consumed by compiler entry points (e.g. `fscomp`/`FSharp.Compiler.Service`)
  to emit final diagnostics.

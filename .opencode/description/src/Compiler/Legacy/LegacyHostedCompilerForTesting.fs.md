# LegacyHostedCompilerForTesting.fs — In-Process "fsc.exe" for Tests

**Purpose**: A test-only helper in the `FSharp.Compiler.CodeAnalysis.Hosted` namespace that
hosts a full, real F# compiler run *in-process* (same as `fsc.exe` would behave) so that
compiler tests can compare against actual compiler output without spawning a process or
depending on the full compiler service API. The file's own header comment (lines 3-4) is
explicit about this: *"This component is used for faster in-memory compilation in some
tests. It should be removed and the proper compiler service API used instead."* — i.e.
it is a **legacy shim**, slated for removal once tests are ported to the real
`FSharp.Compiler.CodeAnalysis` API.

All types and the helper module are `internal`, so this file is not part of the public
API surface — it exists purely to ease test harness wiring.

## Types & members

- **`InProcDiagnosticsLoggerProvider`** (lines 22-50)
  - Internal class implementing `IDiagnosticsLoggerProvider`.
  - `Provider` produces a `DiagnosticsLoggerUpToMaxErrors` named
    `"InProcCompilerDiagnosticsLoggerUpToMaxErrors"` that:
    - `HandleTooManyErrors text` — records "too many errors elided" notice as a warning.
    - `HandleIssue tcConfig err severity` — collects formatted diagnostics (via
      `CollectFormattedDiagnostics` with `suggestNames = true`) into `errors`
      or `warnings` `ResizeArray`s depending on severity.
  - `CapturedErrors` / `CapturedWarnings` — expose collected `FormattedDiagnostic[]`
    arrays to the caller.
- **`Location`** (lines 53-59) — small record: `{ StartLine; StartColumn; EndLine;
  EndColumn : int }`, a 2-D span in a source file for an issue.
- **`CompilationIssueType`** (lines 61-63) — `Warning | Error` discriminated union.
- **`CompilationIssue`** (lines 66-74) — record bundling one issue:
  `{ Location: Location; Subcategory: string; Code: string; File: string; Text: string;
    Type: CompilationIssueType }`.
- **`FailureDetails`** (lines 77-81) — `{ Warnings: CompilationIssue list; Errors:
  CompilationIssue list }`, used on `Success`-adjacent cases where there is no single
  failure "primary" but a list of each kind.
- **`CompilationResult`** (lines 83-85) — `Success of CompilationIssue list | Failure
  of FailureDetails`, a convenience union the *consumer* of this module can match on.
- **`CompilationOutput`** (lines 87-92) — `RequireQualifiedAccess` record of
  `FormattedDiagnostic[]` for `Errors` and `Warnings`, the *raw* output of one in-proc
  compile (before `CompilationIssue` shaping).

- **`InProcCompiler(legacyReferenceResolver)`** (lines 94-129)
  - The actual in-process driver. A single member:
  - **`Compile(argv: string[]): bool * CompilationOutput`** —
    1. Calls `AssumeCompilationThreadWithoutEvidence()` to get a compile-thread token
       `ctok` (the comment at line 97 explains that compilation happens on the calling
       thread).
    2. Builds an `InProcDiagnosticsLoggerProvider` and a `StopProcessingExiter()`.
    3. Calls the real F# compiler entry:
       ```fsharp
       CompileFromCommandLineArguments(
           ctok, argv, legacyReferenceResolver, false,
           ReduceMemoryFlag.Yes, CopyFSharpCoreFlag.Yes,
           exiter, loggerProvider.Provider, None, None)
       ```
       (note `ReduceMemoryFlag.Yes` and `CopyFSharpCoreFlag.Yes` are forced — in-proc
       mode prefers less memory and avoids copying FSharp.Core; `legacyReferenceResolver`
       is injected by tests for reference resolution).
    4. Catches `StopProcessing` and `ReportedError`/`WrappedError(ReportedError _, _)` to
       set `exiter.ExitCode <- 1`.
    5. Returns `(exiter.ExitCode = 0, { Warnings = …; Errors = … })` — i.e. a success
       boolean plus the captured diagnostic arrays.

- **`FscCompiler(legacyReferenceResolver)`** (lines 132-263)
  - A thin wrapper over `InProcCompiler` that mimics the **command-line UX of
    `fsc.exe`** so existing test harnesses that pass an `argv[]` and check exit codes
    keep working.
  - Holds an inner `InProcCompiler` instance and an `emptyLocation` record used for
    issues without location info.
  - Local helpers:
    - **`convert (issue: FormattedDiagnostic): CompilationIssue`** (lines 144-183) —
      normalizes `FormattedDiagnostic.Short` or `.Long` into a `CompilationIssue`:
      fills in `Location` (from `details.Location` if present, else empty),
      `Code = sprintf "FS%04d" details.Canonical.ErrorNumber`,
      `Subcategory = details.Canonical.Subcategory`, `File = l.File`, `Text =
      details.Message`, and maps severity to `CompilationIssueType`.
    - **`errorRangesArg`** (lines 186-190) — compiled regex
      `^(/|--)test:ErrorRanges$` (case-insensitive) to detect that flag.
    - **`vsErrorsArg`** (lines 193-197) — same regex for `--vserrors`.
    - **`fscExeArg`** (lines 200-204) — regex `fsc(\.exe)?$` used to detect whether
      `args[0]` already looks like the fsc path.
  - **`Compile(args: string[]): int * string[]`** (lines 207-263)
    1. **Args normalization** (lines 210-217): if `args` is `null` or empty, uses
       `| "fsc" |`; if `args[0]` does *not* already look like `fsc(.exe)`, *prepends*
       `"fsc"` (so the inner compiler can drop it — the comment at line 208 explains the
       convention).
    2. Reads `errorRanges` and `vsErrors` flags from `args`.
    3. Calls `compiler.Compile(args)` to get `(ok, result)`.
    4. Builds output lines — one per issue, using:
       - `issueTypeStr` — `"error"` or `"warning"` by default; if `--vserrors` is set,
         prefixes the subcategory (`"%s error"/"%s warning"`).
       - `locationStr` — three formats:
         - `--vserrors` → `"(L1,C1,L2,C2)"` (StartLine,StartCol,EndLine,EndCol)
         - `--test:ErrorRanges` → `"(L1,C1-L2,C2)"` (range form)
         - otherwise → `"(L1,C1)"` (standard fsc-style "file(line,col)" form, minus the
           file — the file name is not in this in-proc output shape).
       - `sprintf "%s: %s %s: %s" locationStr issueTypeStr issue.Code issue.Text`
         produces a line of the form
         `"<loc>: <type> <code>: <text>"` that matches the fsc.exe console format the
         tests compare against.
    5. Returns `(if ok then 0 else 1, lines)` — the exit code and an array of output
       lines, mimicking `fsc.exe`'s `(exitCode, stdout)` contract.

## Module: `CompilerHelpers` (lines 265-320)

- **`parseCommandLine (commandLine: string): string[]`** (lines 269-287)
  - Splits a command-line string into an `argv` array.
  - The doc comment is honest about the limitation: *"currently handles quotes, but not
    escaped quotes"* — a stateful `fold` walks the string, toggling `inQuote` on `"` and
    breaking on spaces when not in a quote; appends a trailing space to the character
    input before folding to guarantee the last arg is flushed.
  - Returns `string[]` (the `List.rev |> Array.ofList` pipeline at 285-286).

- **`fscCompile legacyReferenceResolver directory args`** (lines 290-319)
  - The top-level test entrypoint. Returns a 3-tuple
    `(exitCode : int, output : string[], consoleError : string[])`.
  - **Captures the console** — the in-proc compiler still prints its banner to
    `Console.Out`/`Console.Error`, so the function:
    - Saves `origOut`/`origError` (lines 292-293).
    - Redirects `Console.SetOut(sw)` and `Console.SetError(ew)` (lines 295-296) to new
      `StringWriter`s.
    - In a `try` block, sets `Directory.SetCurrentDirectory directory` (important so
      relative `@response.files` files and `fsc` paths resolve from `directory`), calls
      `FscCompiler(legacyReferenceResolver).Compile(args)`, then splits both writers'
      buffers into arrays of lines (`StringSplitOptions.RemoveEmptyEntries`), and
      concatenates the console output lines in front of the *compiler* output lines —
      `(exitCode, [| yield! consoleOut; yield! result |], consoleError)`.
    - In a `with e ->` block, on *any* exception reports `1`, a single "Internal
      compiler error" line plus a one-line `e.ToString()` (newlines flattened to spaces),
      and an empty error array.
    - In a `finally` block, restores the original console streams (`Console.SetOut
      origOut; Console.SetError origError`) — this is critical so that the test host's
      own console is not silently redirected forever.

## Test-only entrypoints (what the test harness calls)

- **`FscCompiler(legacyReferenceResolver).Compile(args: string[]) : int * string[]`**
  — the main "run fsc in-proc with these argv args" entry; returns an exit code and a
  `string[]` of lines formatted like fsc.exe's stderr/stdout.
- **`InProcCompiler(legacyReferenceResolver).Compile(argv : string[]) : bool *
  CompilationOutput`** — same compile, but lower-level: returns a success boolean and the
  raw `FormattedDiagnostic` arrays (no string formatting).
- **`CompilerHelpers.parseCommandLine commandLine`** — turn a single command-line string
  into an `argv` array (useful when tests store a command line as one string).
- **`CompilerHelpers.fscCompile legacyReferenceResolver directory args`** — the all-
  in-one test harness helper that returns `(exitCode, output, consoleError)` and
  restores `Console.*`. This is probably the *most* common entrypoint from test code
  because it bundles the directory switch, the console capture, the exception wrap, and
  the output formatting in one call.

## Cross-references / dependencies

- **`FSharp.Compiler.Driver`** — the home of `CompileFromCommandLineArguments`,
  `AssumeCompilationThreadWithoutEvidence`, `StopProcessingExiter`, `ReportedError`,
  `WrappedError`, and the `ReduceMemoryFlag` / `CopyFSharpCoreFlag` enums, all of which
  this file opens and calls.
- **`FSharp.Compiler.CodeAnalysis.Hosted`** namespace — the file declares itself under
  this namespace (`namespace FSharp.Compiler.CodeAnalysis.Hosted`) even though the types
  are `internal`; tests that use it live in the same assembly and reference it unqualified
  or via `open`.
- **`FSharp.Compiler.Diagnostics` / `.DiagnosticsLogger`** — `FormattedDiagnostic`,
  `IDiagnosticsLoggerProvider`, `DiagnosticsLoggerUpToMaxErrors`,
  `CollectFormattedDiagnostics`, `FSharpDiagnosticSeverity` all come from these modules.
- **`FSharp.Compiler.CompilerConfig` / `.CompilerDiagnostics`** — `tcConfig`/
  `tcConfigB` parameters and severity plumbing.
- **`FSharp.Compiler.AbstractIL.ILBinaryReader`** — opened but used transitively by
  `CollectFormattedDiagnostics`/`FormattedDiagnostic` shaping.
- **`Internal.Utilities.Library`** — `StopProcessing` exception type and general utilities.
- **`System.Text.RegularExpressions`** — the three compiled regexes
  (ErrorRanges / VS-errors / fsc-path) used to interpret `argv`.

## Notes

- The file is explicitly **test-only** (see the header comment and the all-`internal`
  declaration). Do not treat this as a public API or call it from production code paths.
- The three format variations in `FscCompiler.Compile` (`--vserrors`,
  `--test:ErrorRanges`, and the default) exist so that the same in-proc run can be
  compared byte-for-byte against the *three* different reference outputs that historical
  F# test suites expect from `fsc.exe`:
  - default: `"(line,col)"` (classic) format
  - `--test:ErrorRanges`: the "start..end" line-range form used by some test baselines
  - `--vserrors`: the 4-component `(startLine,startCol,endLine,endCol)` form +
    subcategory-prefixed type, used when comparing against Visual Studio-integrated
    compiler output.

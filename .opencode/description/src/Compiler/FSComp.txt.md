# FSComp.txt

## Pipeline role
Master F# compiler diagnostics string table. Defines every user-facing compiler message:
2,000+ entries across 1,849 lines (~237 KB), using classic F# resource-string syntax.

## Format
- One entry per line: `id,messageName,"format string with %s/%d placeholders"`.
- Lines with an integer id (e.g. `201,tcNamespaceCannotContainValues,"..."`) are
  error/warning-numbered diagnostics. Lines without an integer prefix (e.g.
  `undefinedNameNamespace,"..."`) are named, unnumbered messages.
- `#` and whitespace-only leading prefixes are ignored; several diagnostics share a
  number (e.g. `222` has two messages; `438` has `chkDuplicateMethod` +
  `chkDuplicateMethodWithSuffix`), and several unnumbered entries interleave the numbered
  ranges (e.g. `tcNamespaceCannotContainValues` group around 200).
- Error numbers below 200 map to legacy-structured messages whose numbers come from
  `src/Compiler/Driver/CompilerDiagnostics.fs` (the `exn.DiagnosticNumber` switch).

## Role of the strings
Messages span the whole pipeline: syntax/parse (`ast...`, `lex...`), name resolution
(`undefinedName...`), type checking (`tc...`, `typrel...`, `chk...`), signatures
(`DefinitionsInSigAndImplNotCompatible...`, `ValueNotContained...`), constraint solver
(`constraintSolver...`), quotations (`cref...`), format strings (`for...`), and driver
options (`build...`, `opts...`). Current tail entries include `3908,xmlDocIncludeError`
and `3909,lexColonDirectiveMustBeFirst`.

## Build-time consumption
- Compiled as an `EmbeddedText` item in `FSharp.Compiler.Service.fsproj` (RichText-flagged).
  The F# build's `FSharpEmbedResourceText` task (see `Microsoft.FSharp.Targets`) generates
  an `FSComp.resources` satellite resource plus a generated F# module of typed accessors
  (`SR`-style) into the intermediate folder; accessors are consumed via `sr.fs` /
  `FSharp.Compiler.DiagnosticsLogger` etc.
- `FSCompCheck.fsx` is a repo CI script verifying that numbered ids appear in strictly
  ascending order within their groups.
- xlf: localized satellites are produced from the .resources via the XLIFF pipeline
  (`.xlf` translation files), giving `FSComp.resources.dll` culture satellites.
# printf.fs

## Overview

This file (namespace `Microsoft.FSharp.Core`) implements F#'s **extensible printf-style formatting** family. It defines the `PrintfFormat`/`Format` types and the `Microsoft.FSharp.Core.Printf` module (`printf`, `printfn`, `sprintf`, `fprintf`, `eprintf`, `bprintf`, and their continuation variants). The implementation is performance-oriented: format strings are parsed once, cached, and turned into pre-built curried printing functions so that repeated calls with the same format string avoid repeated parsing.

## Format types

- `PrintfFormat<'Printer, 'State, 'Residue, 'Result>` — the basic format value. It holds the raw format string `value`, an optional `captures` array (for interpolated strings, when a `%d{expr}` style hole is present) and `captureTys` (the types used for `%A` expression gaps). Two constructors: one taking only `value`, and one taking `(value, captures, captureTys)`. `ToString()` returns the raw `value`.
- `PrintfFormat<'Printer, 'State, 'Residue, 'Result, 'Tuple>` — the 5-parameter (typed/tuple) variant used for `scanf`/`match`-style operations; inherits the 4-parameter type.
- Abbreviations: `Format<...>` = `PrintfFormat<...>` (both arities).

## `module internal PrintfImpl`

Contains the core engine (marked `[<AutoOpen>]` internal). Its design principle, explained in the header comment, is to **compose curried printer functions from prebuilt "pieces"**: instead of building functions argument-by-argument at runtime, it predefines "final pieces" (1–5 arguments, which produce the final result) and "chained pieces" (which don't produce the result but tail into another piece). Simple specifiers (`%d`, `%s`) map onto one argument; more complex ones (`%a`, `%t`, or `*` width/precision) consume multiple arguments. This lets many formats be compiled with as little as one reflection call, and makes parsed/specialized formats cacheable and shareable across calls.

Key internals:

- `FormatFlags` — `[<Flags>]` enum: `LeftJustify`, `PadWithZeros`, `PlusForPositives`, `SpaceForPositives`; with `hasFlag`/`isLeftJustify`/... `inlines`.
- Sentinels `StarValue = -1` and `NotSpecifiedValue = -2` for `*` (user-supplied) and omitted width/precision.
- `FormatSpecifier` record — `TypeChar`, `Precision`, `Width`, `Flags`, and `InteropHoleDotNetFormat` (for interpolated `%P(...)` holes). Members expose `IsStarPrecision`/`IsPrecisionSpecified`/`IsStarWidth`/`IsWidthSpecified`, `ArgCount`, `IsDecimalFormat`, `GetPadAndPrefix`, `IsGFormat`, and a diagnostic `ToString`.
- `module FormatString` — the hand-written format **parser**: `intFromString`, `parseFlags` (`0/+/-/space`), `parseWidth`/`parsePrecision` (handling `*`), `parseTypeChar`, `parseInterpolatedHoleDotNetFormat` (for `%P(...)`), `skipInterpolationHole`, and `findNextFormatSpecifier` which scans a format string into literal text plus a specifier.
- `type Step` — the internal "execution step" representation of a format, e.g. `StepWithArg` (literal prefix + converter), `StepWithTypedArg`, `StepString`, `StepLittleT`, `StepLittleA` (for `%t`/`%a`), `StepStar1`/`StepPercentStar1` (dynamic width/precision from a signed argument). A `Cache` (built with `ConcurrentDictionary`) maps parsed format strings to cached parser results, and provides `GetCurriedPrinterFactory`, `GetCurriedStringPrinter`, `GetStepsForCapturedFormat`, `BlockCount`, etc.
- Env abstractions for the different output targets and printer specializations for each format type character, plus modules `Padding`, `Basic`, `GenericNumber`, `Integer`, `FloatAndDecimal` — these implement padding, sign, decimal/general (`G`/`g`/`M`), integer (signed/unsigned, hex/octal/binary) and float/double formatting, largely by building .NET `NumberFormatInfo`/format strings and calling into `double.ToString`/`decimal` formatting.

## `module Printf`

The public API (compiled with `ModuleSuffix`). It defines the format type abbreviations used in signatures:

- `BuilderFormat<'T, 'Result> = Format<'T, StringBuilder, unit, 'Result>` and `BuilderFormat<'T>`.
- `StringFormat<'T, 'Result> = Format<'T, unit, string, 'Result>` and `StringFormat<'T>`.
- `TextWriterFormat<'T, 'Result> = Format<'T, TextWriter, unit, 'Result>` and `TextWriterFormat<'T>`.

Public functions (all driven by the shared `gprintf` helper that selects between the curried-factory path and the interpolated-captures path):

- `ksprintf continuation format` — `sprintf` into a string then apply a continuation (returns `'T = string -> 'Result`).
- `sprintf format` — format to a string via `StringPrintfEnv`.
- `kprintf continuation format` — alias of `ksprintf` (continuation `string -> 'Result`).
- `kbprintf continuation builder format` — into a `StringBuilder` via `StringBuilderPrintfEnv`.
- `kfprintf continuation textWriter format` — into a `TextWriter` via `TextWriterPrintfEnv`.
- `bprintf builder format` — `kbprintf ignore` (into a `StringBuilder`).
- `fprintf textWriter format`, `fprintfn textWriter format` (adds newline) — into a `TextWriter`.
- `failwithf format` — `ksprintf failwith` (raises `Exception` with the formatted message).
- `printf format` / `printfn format` — to `Console.Out` (with newline for `printfn`).
- `eprintf format` / `eprintfn format` — to `Console.Error`.

Each carries a `[<CompiledName(...)>]` attribute for the CLI name (e.g. `PrintFormat`, `PrintFormatLine`, `PrintFormatToTextWriter`), and the source uses `gprintf` inlining for `sprintf` to reduce allocations.

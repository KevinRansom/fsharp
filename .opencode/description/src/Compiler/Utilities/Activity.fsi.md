# Activity.fsi

**Purpose**: Public signature file for `Activity.fs` (same directory, namespace `FSharp.Compiler.Diagnostics`). Exposes the contract for the compiler's activity tracing utilities: source names, the shared `Metrics.Meter`, and the `internal Activity` module for starting tagged activities, attaching events, profiling environment stats, and exporting to CSV.

**Namespace(s)** declared: `FSharp.Compiler.Diagnostics`

**Declared items** (public contract):
- `[<RequireQualifiedAccess>] module ActivityNames` — `FscSourceName` (literal "fsc"), `ProfiledSourceName` (literal "fsc_with_env_stats"), `AllRelevantNames : string[]`.
- `module internal Metrics` — `Meter : Meter` (from `System.Diagnostics.Metrics`), `printTable : headers: string list * rows: string list list -> string` (table used for stats display).
- `[<RequireQualifiedAccess>] module internal Activity` — with submodules:
  - `Activity.Tags` — string tag-key values (`fileName`, `qualifiedNameOfFile`, `project`, `userOpName`, `length`, `cache`, `buildPhase`, `version`, `stackGuard*`, `caller*`) for use with `start`/`addEventWithTags`.
  - `Activity.Events` — `cacheHit`.
  - `Activity` itself — `startNoTags`, `start`, `addEvent`, `addEventWithTags` (signatures in the .fsi).
  - `Activity.Profiling` — `startAndMeasureEnvironmentStats : name -> System.IDisposable | null`; `addConsoleListener : unit -> IDisposable`.
  - `Activity.CsvExport` — `addCsvFileListener : pathToFile: string -> IDisposable`.

**Relationship to .fs**: The .fs additionally contains private helpers (activity source instances, GC stats collection, CSV escaping/formatting, `Activity.RootId`/`Depth` extensions) which are not part of the .fsi; the .fsi omits the `Tags` constants `cpuDelta`/`realDelta` (they exist in the .fs) and documents only the API intended for compiler code. Doc comments reference the .NET distributed-tracing concept.

**Cross-references**: `Caches.fsi`/`Caches.fs` consume `FSharp.Compiler.Diagnostics.Metrics.Meter`; see sibling `Caches.md`.

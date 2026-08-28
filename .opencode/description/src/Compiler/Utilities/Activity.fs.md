# Activity.fs

**Purpose**: Provides the compiler's activity-based diagnostics/telemetry infrastructure built on .NET's `System.Diagnostics` distributed tracing (`Activity`, `ActivitySource`, `ActivityListener`). Compilers and other compiler components start named activities to record build phases, file-level work, cache activity, and GC/perf stats; listeners can export these as console tables or CSV. Its .fsi (Activity.fsi) is the exposed contract.

**Namespace(s)** declared: `FSharp.Compiler.Diagnostics`

**Modules / Types declared**:
- `module ActivityNames` — literal names for the activity sources: `FscSourceName` ("fsc"), `ProfiledSourceName` ("fsc_with_env_stats"), and `AllRelevantNames`.
- `module Metrics` (internal) — a shared `Metrics.Meter` named "fsc" used by cache/other instrumentation, plus `printTable`/`formatTable` for rendering statistics tables.
- `module Activity` (internal, `RequireQualifiedAccess`) — the core API for starting/storing instrumented activities.
  - `module Activity.Tags` — conventional tag keys (fileName, project, length, cache, buildPhase, gc0-2, stack-guard info, caller info, etc.) and `AllKnownTags`.
  - `module Activity.Events` — event names (e.g. `cacheHit`).
  - `module Activity.Profiling` — GC/process stats capture and a console listener.
  - `module Activity.CsvExport` — CSV file export of activity traces.

**Public API surface** (per Activity.fsi; most functions are `internal`):
- `ActivityNames.FscSourceName : string`, `ProfiledSourceName : string`, `AllRelevantNames : string[]`
- `Metrics.Meter : Meter` — global meter.
- `Metrics.printTable : headers * rows -> string`
- `Activity.start : name * tags seq -> System.IDisposable | null` — start an activity on the "fsc" source with tags.
- `Activity.startNoTags : name -> System.IDisposable | null`
- `Activity.addEvent : name -> unit` and `Activity.addEventWithTags : name * (string*objnull) seq -> unit` — attach events to the current activity.
- `Activity.Tags.*` — tag key constants; `Activity.Events.cacheHit`.
- `Activity.Profiling.startAndMeasureEnvironmentStats : name -> IDisposable | null`, `Activity.Profiling.addConsoleListener : unit -> IDisposable`.
- `Activity.CsvExport.addCsvFileListener : pathToFile -> IDisposable`.

**Internal helpers / extension members**:
- Extensions on `Diagnostics.Activity`: `RootId` (walks `Parent` chain to root activity id) and `Depth` (depth in parent chain) — used for CSV export and console indented display.
- Private `activitySource` / `profiledSource` instances of `ActivitySource`.
- `Profiling.collectGCStats` (GC generation counts, stored as `int[]`), `addStatsMeasurementListener` — adds tags for working set MB, handle count, thread count, and per-generation GC count *deltas* on activity stop.
- `CsvExport.escapeStringForCsv`, `createCsvRow` — row layout is `Name,StartTime,EndTime,Duration(s),Id,ParentId,RootId,<each known tag...>`.

**Significant internal logic**:
- `addConsoleListener` prints a live table row per stopped activity: name (indented by depth), elapsed, duration, working set, GC0-2, handles, threads.
- `addCsvFileListener` creates the CSV with a header, then serializes writes through a `MailboxProcessor` queue into a `StreamWriter`; on `Dispose` it unregisters the listener first, drains the queue, then closes the file — order matters to avoid losing final rows.
- `Metrics.formatTable` computes column widths and center-aligned headers; `printTable` wraps it in a try/with that returns an error string on failure.

**Cross-references**: `Caches.fs` uses `FSharp.Compiler.Diagnostics.Metrics.Meter` from this file for cache telemetry; see sibling `Caches.md`.

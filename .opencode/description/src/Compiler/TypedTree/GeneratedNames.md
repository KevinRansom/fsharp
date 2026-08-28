# GeneratedNames.fs

**Purpose**: Parsing/normalization helpers for compiler-generated (synthesized) names, supporting hot reload (Edit-and-Continue) name matching. Recognizes the occurrence-keyed generation-suffixed closure class name format `{base}@hotreload#g{generation}_o{occurrenceChain}`, line-ordinal names `{base}@{line}[-{ordinal}]`, and debug-pipe names (`Pipe #n input/stage #n at line L`), and reduces them to normalized basic names / positional ordinals used to pair synthesized types across compiles.

**Namespace(s)**: `FSharp.Compiler` (module `internal FSharp.Compiler.GeneratedNames`).

**Declared types**:
- `SynthesizedPositionalName` — record `{ NormalizedBasicName: string; Ordinal: int list }`.
- `HotReloadReplayName` — record `{ NormalizedBasicName: string; ReplayOrdinal: int }`.
- `HotReloadGenerationName` — record `{ NormalizedBasicName: string; Generation: int; OccurrenceOrdinal: int list }`.

**Public/used API surface** (module internal):
- `HotReloadGenerationSuffixedNameInfix = "@hotreload#g"` — `[<Literal>]` marker for occurrence-keyed hot-reload closure names; its suffix space is disjoint from the replayable `-{ordinal}` space of FSharpSynthesizedTypeMaps.
- `TryNormalizeHotReloadGenerationName: string -> HotReloadGenerationName option`
- `IsHotReloadGenerationSuffixedName: string -> bool`
- `TryGetHotReloadNameGeneration: string -> int option` — e.g. `f@hotreload#g2_o3` -> `Some 2`.
- `TryNormalizeHotReloadReplayName: string -> HotReloadReplayName option` — parses `{base}@hotreload[-n]` (replay ordinal 0 if no suffix).
- `tryNormalizeSynthesizedTypeNameForPositionalPairing: string -> SynthesizedPositionalName option`
- `SynthesizedNameMapKey: basicName: string -> string` — normalized basic name map key (falls back to the raw name).

**Internal helpers**: `tryParseNonNegativeInt`, `tryParsePositiveInt`, `tryParseLineOrdinalSuffix` (`{line}` or `{line}-{ordinal}`), `tryParseOccurrenceOrdinal` (`_`-separated chain), `tryNormalizeDebugPipeBasicName` (regex `Pipe #[1-9][0-9]* (?:input|stage #[1-9][0-9]*) at line L`), `tryNormalizeDebugPipeName`, `tryNormalizeHotReloadOrdinalName`, `tryNormalizeLineOrdinalName`.

**Significant internal logic**: Base names must not be empty and must not contain `@`; occurrence ordinals are `_`-separated non-negative ints. Normalization order for pairing: hot-reload ordinal (`@hotreload...`) first, then line-ordinal (`@line[-ordinal]`), then the debug-pipe name form; each may rewrite the basic name via `tryNormalizeDebugPipeBasicName`.

**Cross-references**: `CompilerGeneratedNameMapState.fs` (replay map that consumes normalized names), `WellKnownAttribs.fs` (no), `TcGlobals.fs`/`TypeDefinition` consumers; used with `FSharpSynthesizedTypeMaps` (typed tree synthesize info).

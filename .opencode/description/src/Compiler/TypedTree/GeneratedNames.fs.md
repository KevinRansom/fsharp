# GeneratedNames.fs

## Pipeline role

This file belongs to the TypedTree folder of the F# compiler. It is an internal helper module (`FSharp.Compiler.GeneratedNames`) providing the name-mangling vocabulary and parsing/recognition helpers for compiler-generated names, used in two places: the ordinary generated-name scheme and the hot-reload synthesized-name scheme. It (a) defines the marker infix for "occurrence-keyed, generation-suffixed closure class names" produced by hot-reload closure name allocation (`{base}@hotreload#g{generation}_o{occurrenceChain}`), (b) parses the various generated-name shapes (hot-reload generation names, hot-reload replay names, line/ordinal-suffixed names, debug `Pipe #N … at line L` names), and (c) normalizes them into a small positional key (`SynthesizedPositionalName`) used by `FSharpSynthesizedTypeMaps` to pair generated names with stable replay slots.

## Module and contents

- `module internal FSharp.Compiler.GeneratedNames` — internal module.
- Opens `System`, `System.Text.RegularExpressions`.

### Literal and data types

- `[<Literal>] let HotReloadGenerationSuffixedNameInfix = "@hotreload#g"` — marker of occurrence-keyed closure class names: `{base}@hotreload#g{gen}_o{chain}`. Generation-0 names come from (flag-on) baseline compiles; generations ≥ 1 are minted by delta compiles of session generation N for occurrences first allocated there. The `#g…_o…` suffix space is disjoint from the replayable `-{ordinal}` space of `FSharpSynthesizedTypeMaps`, so these names never parse as replay ordinals and are never produced by sequence replay.
- `type SynthesizedPositionalName = { NormalizedBasicName: string; Ordinal: int list }` — normalized basic name + positional slot chain.
- `type HotReloadReplayName = { NormalizedBasicName: string; ReplayOrdinal: int }`.
- `type HotReloadGenerationName = { NormalizedBasicName: string; Generation: int; OccurrenceOrdinal: int list }`.

### Parsing helpers

- `debugPipeNameRegex` (lazy `Regex`) — matches `Pipe #[1-9][0-9]* (?:input|stage #[1-9][0-9]*) at line ([1-9][0-9]*)$`.
- `tryParseNonNegativeInt`, `tryParsePositiveInt` — validated `Int32.TryParse` wrappers.
- `tryParseLineOrdinalSuffix suffix` — parses `line` or `line-ordinal` (`-`-separated, ordinal ≥ 0); used for `@<line>`/`@<line>-<ordinal>` suffixes.
- `tryNormalizeDebugPipeBasicName (name)` — if the name matches the debug-pipe regex, returns `(name-without-" at line N", line)`.
- `tryParseOccurrenceOrdinal (text)` — parses an `_`-separated chain of non-negative ints into `int list` (`_o0_1_2`-style).
- `positionalName normalizedBasicName ordinal` — small builder.

### Name normalization API

- `TryNormalizeHotReloadGenerationName (name)` — parses `{base}@hotreload#g{gen}_o{chain}`: extracts base name (no `@` allowed in base), generation (non-negative int), occurrence chain; normalizes pipe names if the base looks like a debug-pipe name; returns `HotReloadGenerationName option` (or `None` when malformed/`markerIndex <= 0`).
- `IsHotReloadGenerationSuffixedName (name)` — recognizer for well-formed `{base}@hotreload#g{N}_o{chain}` names, any generation.
- `TryGetHotReloadNameGeneration (name) : int option` — the generation of a well-formed generation-suffixed name (`f@hotreload#g2_o3` → `Some 2`); `None` when not generation-suffixed or malformed.
- `TryNormalizeHotReloadReplayName (name)` — parses `{base}@hotreload` (ordinal 0) or `{base}@hotreload-{ordinal}` (positive ordinal), base without `@`; normalizes debug-pipe base names; returns `HotReloadReplayName option`.
- `tryNormalizeHotReloadOrdinalName (name)` — maps a replay name to a positional name: for pipe bases, ordinal `[line; replayOrdinal]`; otherwise `[replayOrdinal]`.
- `tryNormalizeLineOrdinalName (name)` — parses `base@<line>` / `base@<line>-<ordinal>`: for debug-pipe bases the parsed line must match the pipe's line (else `None`); non-pipe bases must be non-empty, contain no `@`, and not start with `Pipe #`; yields a positional name `[line; ordinal]`.
- `tryNormalizeSynthesizedTypeNameForPositionalPairing (name)` — the overall normalizer: tries hot-reload ordinal, then line-ordinal, then debug-pipe-name parsing.
- `SynthesizedNameMapKey (basicName)` — the normalized map key: the normalized positional name's `NormalizedBasicName`, or the raw name when nothing parses.

There is no `.fsi` for this module.
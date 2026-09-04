# CompilerGeneratedNameMapState.fs

## Pipeline role

This file belongs to the TypedTree folder of the F# compiler. It is a tiny, self-contained module (`FSharp.Compiler.CompilerGeneratedNameMapState`) that decouples compiler-generated-name generation from whatever concrete implementation replays those names. It provides a side-channel (associated with an arbitrary owner object via a `ConditionalWeakTable`) through which a "name map" — something that can replay or assign compiler-generated names deterministically — can be installed for a compilation. This is the seam the Edit-and-Continue / hot-reload emit path uses: `CompilerGlobalState` (and through it `NiceNameGenerator`/`StableNiceNameGenerator`) reads the installed map while emitting, so serialization passes replay the baseline's stable names instead of re-deriving volatile line-based names. There is no `.fsi` for this file (it is compiled as an internal implementation unit).

## Module and contents

- `module internal FSharp.Compiler.CompilerGeneratedNameMapState` — internal module.
- Opens `System.Runtime.CompilerServices` (for `ConditionalWeakTable`, `VolatileField`).

### `type ICompilerGeneratedNameMap`

Minimal abstraction for compiler-generated name replay/state (hot-reload-aware implementations plug in here without coupling core compiler paths to a concrete synthesized-name-map type):

- `abstract BeginSession: unit -> unit` — resets allocation cursors so the next serialized code-generation pass replays the snapshot from its first slot.
- `abstract GetOrAddName: basicName: string -> string` — returns the next name in deterministic encounter order for a given basic name (callers must serialize codegen while a map is installed — synchronization prevents data races but cannot make encounter order scheduling-independent).
- `abstract Snapshot: seq<struct (string * string[])>` — captures names in allocation order, grouped by normalized basic name.
- `abstract LoadSnapshot: snapshot: seq<struct (string * string[])> -> unit` — replaces replay state with a previously captured allocation-order snapshot.

### Query/update plumbing (per-owner slot)

- `type private NameMapHolder` — a single `[<VolatileField>]`-guarded `ICompilerGeneratedNameMap option` slot (reads vastly outnumber writes; installs happen a handful of times per compile, so one volatile field suffices — reference reads/writes are atomic and volatile preserves the ordering a lock would provide). `TryGet()` / `Set(value)`.
- `let private holders = ConditionalWeakTable<obj, NameMapHolder>()` — maps each owner object to its holder.
- `let private getOrCreateHolder (owner: obj)` — `holders.GetValue(...)`.
- `let private tryGetHolder (owner: obj)` — pure read; never inserts, so a compile that never installs a map pays one failed weak-table lookup.
- `let tryGetCompilerGeneratedNameMap (owner: obj)` — reads the owner's slot (via `tryGetHolder`): `Some map`/`None`.
- `let getCompilerGeneratedNameMapAccessor (owner: obj) : unit -> ICompilerGeneratedNameMap option` — resolves the holder exactly once and captures it in the returned closure, so each generated name costs a single volatile field read rather than a weak-table probe + lock. The holder is created eagerly on purpose: the emit hook installs the map later in the compile, through the same owner, and pre-creating the holder lets that install mutate the captured object so the map is observed.
- `let setCompilerGeneratedNameMap (owner: obj) (map)` — installs a map (`Set(Some map)`).
- `let setCompilerGeneratedNameMapOpt (owner: obj) (map: option)` — installs or clears.
- `let clearCompilerGeneratedNameMap (owner: obj)` — `Set(None)`.
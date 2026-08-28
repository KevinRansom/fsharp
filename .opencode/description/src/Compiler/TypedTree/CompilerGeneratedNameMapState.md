# CompilerGeneratedNameMapState.fs

**Purpose**: Minimal abstraction for compiler-generated name replay/state used by hot reload (Edit-and-Continue). Defines an `ICompilerGeneratedNameMap` interface plus a side-channel slot (a `ConditionalWeakTable` keyed by an owner object) so the map can be attached to a `CompilerGlobalState` without coupling core compiler signatures to a concrete synthesized-name map type. Enables a code-generation pass to replay a previously captured name allocation to get stable names across delta compiles.

**Namespace(s)**: `FSharp.Compiler` (module `FSharp.Compiler.CompilerGeneratedNameMapState`, marked `internal`).

**Declared types**:
- `ICompilerGeneratedNameMap` (abstract class) — replay/state interface: `BeginSession` (reset allocation cursors to replay a snapshot), `GetOrAddName: string -> string` (next name in deterministic encounter order), `Snapshot: seq<struct (string * string[])>`, `LoadSnapshot` (restore a captured snapshot).
- `NameMapHolder` (private class) — holds a single `[<VolatileField>]` optional map; `TryGet`/`Set` for cheap reads.

**Public/used API surface** (module is internal; these are the entry points):
- `tryGetCompilerGeneratedNameMap: owner -> ICompilerGeneratedNameMap option` — pure read, never inserts (compiles that never install a map pay one failed weak-table lookup).
- `getCompilerGeneratedNameMapAccessor: owner -> (unit -> ICompilerGeneratedNameMap option)` — resolves the holder once up front so each generated name costs a single volatile read; holder is eagerly created so a later install by the emit hook is observed through the captured closure.
- `setCompilerGeneratedNameMap : owner -> ICompilerGeneratedNameMap -> unit`
- `setCompilerGeneratedNameMapOpt : owner -> ICompilerGeneratedNameMap option -> unit`
- `clearCompilerCompilerGeneratedNameMap` — actually `clearCompilerGeneratedNameMap : owner -> unit`

**Internal helpers**:
- `holders : ConditionalWeakTable<obj, NameMapHolder>` — per-owner storage.
- `getOrCreateHolder` / `tryGetHolder` — weak-table accessors.

**Significant internal logic**: The design separates *reads* (vastly outnumber writes) from *installs* (a handful per compile); the volatile field keeps hot reads lock-free. The accessor pre-creates the `NameMapHolder` deliberately so that a map installed later in the compile (by the emit hook) through the same owner is observed by already-constructed accessors.

**Cross-references**: `CompilerGlobalState.fs` (consumes `ICompilerGeneratedNameMap` via `NiceNameGenerator`), `GeneratedNames.fs` (name normalization/replay formats), `TypedTreeOps.Remapping.fs` (FSharpSynthesizedTypeMaps replay context).

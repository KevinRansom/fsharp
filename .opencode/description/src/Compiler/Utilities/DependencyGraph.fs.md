# DependencyGraph.fs

**Purpose**: Implements a generic lazy dependency graph used by the compiler to maintain up-to-date but lazily computed sets of dependent values (e.g. in parser/typed-tree pipeline stages). When nodes or edges change, nothing is recomputed; a value is only computed when requested, cached in the node, and invalidated (set to `None`) on changes to the node or its transitive dependents. No .fsi ships for this file (the module is `internal`).

**Namespace(s)** declared: `Internal.Utilities.DependencyGraph` (module is internal: `module internal Internal.Utilities.DependencyGraph`)

**Modules / Types declared**:
- `type DependencyNode<'Identifier, 'Value>` — record: `Id`, `Value: 'Value option` (cached computed value), `Compute: 'Value seq -> 'Value` (pure function over dependency values).
- `type IDependencyGraph<'Id, 'Val when 'Id: equality>` — abstract interface with the core operations (see API surface).
- `type IThreadSafeDependencyGraph<'Id, 'Val>` — extends `IDependencyGraph`, adds `Transact<'a>` for atomic multi-step access.
- `module Internal` — contains the concrete implementation `DependencyGraph<'Id, 'Val>`.
- `type GraphBuilder<'Id, 'Val, 'T, 'State>` — helper to chain dependent nodes when node values form a type hierarchy ('T is a subset/case of 'Val), carrying state along the chain.
- `type LockOperatedDependencyGraph<'Id, 'Val>` — thread-safe wrapper over `Internal.DependencyGraph` that locks every operation; implements `IThreadSafeDependencyGraph`.
- `type GraphExtensions` (`[<Extension>]`) — extension helpers for unpacking dependency values.

**Public API surface** (per `IDependencyGraph` / `IThreadSafeDependencyGraph`, implemented by `DependencyGraph` and `LockOperatedDependencyGraph`):
- `AddOrUpdateNode: id * value -> unit` — register/replace a node with a fixed value (its `Compute` ignores inputs).
- `AddList: ('Id * 'Val) seq -> 'Id seq` — bulk node registration, returns the ids.
- `AddOrUpdateNode: id * dependsOn: 'Id seq * compute: ('Val seq -> 'Val) -> unit` — register a computed node (re-wires its dependencies, replacing old ones).
- `GetValue: id -> 'Val` — lazily compute (recursively, in dependency order) and cache the value.
- `GetDependenciesOf` / `GetDependentsOf: id -> 'Id seq`
- `AddDependency: node * dependsOn -> unit` (invalidates dependents of `dependsOn`)
- `RemoveDependency: node * noLongerDependsOn -> unit` (invalidates `node` and its transitive dependents)
- `UpdateNode: id * ('Val -> 'Val) -> unit`
- `RemoveNode: id -> unit`
- `OnWarning: (string -> unit) -> unit` — subscribe to a warning callback (subscriber list maintained; note subscribers fire via `warningSubscribers`).
- `Debug_GetNodes: ('Id -> bool) -> DependencyNode seq` and `Debug_RenderMermaid: ?mapping -> string` — dump a Mermaid `graph LR` of dependencies.
- `Transact<'a>: (IDependencyGraph -> 'a) -> 'a` — thread-safe wrapper only; executes `f` under the graph's lock with the inner graph.

**Internal helpers**:
- `insert: key * value -> Dictionary -> unit` — upsert helper for dictionaries.
- `invalidateDependents` / `invalidateNodeAndDependents` — recursive invalidation walking the `dependents` reverse-adjacency map.

**Significant internal logic**:
- Storage: three `Dictionary` maps — `nodes` (id → node), `dependencies` (id → its deps, `HashSet`), `dependents` (reverse edge map). Invalidating a node propagates to all transitive dependents.
- `GetValue` is recursive: it fetches each dependency's value first (computing them lazily), then runs `node.Compute values` and stores the result — a memoized topological evaluation (no explicit topo-sort; recursion enforces order).
- `LockOperatedDependencyGraph` serializes everything with a single mutex; `Transact` exposes the inner (unlocked) graph inside the lock for compound operations.
- `GraphExtensions.Unpack*` helpers validate that dependency values match expectations (exactly one match, all match, or one + many) and `failwith` with diagnostics otherwise.

**Cross-references**: none in-sibling; this module is used by compiler pipeline code (parser/typed tree incremental machinery).

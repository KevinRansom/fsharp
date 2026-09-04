# OverloadResolutionCache.fsi

**Purpose**
Public contract for the overload-resolution result cache. Declares the cache key/result types and the
functions to compute a cache key from a caller's `CalledMeth` group and argument types, and to store/lookup
results in the per-`TcGlobals` cache. The .fsi documents the safety conditions under which a type structure
may be used in a cache key (solved-typar instability is OK, unsolved-typar instability is not).

**Namespace(s)**
`module internal FSharp.Compiler.OverloadResolutionCache`

**Modules / Types declared**
- `OverloadResolutionCacheKey` — record: `MethodGroupHash: int`, `ObjArgTypeStructures: TypeStructure[]`, `ArgTypeStructures: TypeStructure[]`, `ReturnTypeStructure: TypeStructure voption`, `CallerTyArgCount: int`. Combines method-group identity with caller argument/return type structures.
- `OverloadResolutionCacheResult` (`[Struct]`) — `CachedResolved of methodIndex: int`; the index of the resolved method in the original `calledMethGroup` list.

**Public API surface**
- `getOverloadResolutionCache: TcGlobals -> Cache<OverloadResolutionCacheKey, OverloadResolutionCacheResult>` — per-`TcGlobals` cache (via `WeakMap`, per-compilation isolation).
- `computeMethInfoHash: MethInfo -> int` — method identity hash.
- `tryGetTypeStructureForOverloadCache: TcGlobals -> TType -> TypeStructure voption` — type structure for the key. Accepts Unstable structures unstable *only* due to solved typars; rejects structures with Unsolved tokens.
- `tryComputeOverloadCacheKey: TcGlobals -> CalledMeth<'T> list -> CallerArgs<'T> -> TType option -> bool (anyHasOutArgs) -> OverloadResolutionCacheKey voption` — key computation; `ValueNone` when not cacheable (unresolved type variables, named args, ...).
- `computeCacheResult: CalledMeth<'T> list -> CalledMeth<'T> voption -> OverloadResolutionCacheResult option`.
- `storeCacheResult: ... -> unit` — stores a successful resolution (also under an "after-solve" key when types were solved during the resolution); failed resolutions are not cached.

**Significant notes**
- Safety rationale (doc comment on `tryGetTypeStructureForOverloadCache`): the key is computed before
  `FilterEachThenUndo` runs; caller argument types were resolved before overload resolution; solved typars
  in those types are not reverted by `Trace.Undo`. Unsolved flexible typars *are* rejected because they may
  resolve differently in different contexts (wrong cache hits).
- The cache stores only the *index* of the winner, not the method itself, keeping entries small and
  structurally hashable.

**Cross-references**
- `OverloadResolutionCache.fs` — implementation.
- `MethodCalls.fsi` — `CalledMeth`, `CallerArgs` in the key/result signatures.
- `Utilities/Caches.fsi` — the generic `Cache` used for storage.
- `Utilities/TypeHashing` (StructuralUtilities) — `TypeStructure` / `tryGetTypeStructureOfStrippedType`.

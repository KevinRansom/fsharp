# OverloadResolutionCache.fs

**Purpose**
Per-`TcGlobals` caching infrastructure for method overload-resolution results. Computes a stable cache key
from the method group + caller argument type structures + optional return type, and caches the index of the
resolved method within the candidate list, so repeated identical overload resolution calls (common in
large codebases with repeated member calls) can short-circuit the expensive per-candidate constraint solving
in `ResolveOverloadingForCall`.

**Namespace(s)**
`module internal FSharp.Compiler.OverloadResolutionCache`

**Modules / Types declared**
- `OverloadResolutionCacheKey` (record) — hash over the method group (`MethodGroupHash`), type structures of the 'this'/obj args (`ObjArgTypeStructures: TypeStructure[]`), type structures of the caller args (`ArgTypeStructures: TypeStructure[]`), the expected return type structure (`ReturnTypeStructure: TypeStructure voption`), and the count of caller-provided type args (`CallerTyArgCount`).
- `OverloadResolutionCacheResult` (`[Struct]`) — `CachedResolved of methodIndex: int`. Only successful resolutions are cached; failed ones are not.

**Public API surface**
- `getOverloadResolutionCache: TcGlobals -> Cache<OverloadResolutionCacheKey, OverloadResolutionCacheResult>` — obtains (or creates, keyed by `TcGlobals` via `WeakMap`) the cache. One-off compilations use no-eviction; others use a 4096-entry LRU with 50% headroom.
- `computeMethInfoHash: MethInfo -> int` — structural hash of a `MethInfo` used in the key.
- `tryGetTypeStructureForOverloadCache: TcGlobals -> TType -> TypeStructure voption` — extract a usable `TypeStructure` for a type. Accepts `Stable` and `Unstable` structures that are unstable *only because of solved typars* (which can't be reverted by `Trace.Undo`); rejects any structure containing a `TypeToken.Unsolved` (unsolved flexible typar).
- `tryComputeOverloadCacheKey: g -> CalledMeth<'T> list -> CallerArgs<'T> -> TType option (reqdRetTyOpt) -> bool (anyHasOutArgs) -> OverloadResolutionCacheKey voption` — build the key from the caller side; returns `ValueNone` when caching is not possible (e.g. any caller arg type is unstable due to unsolved typars).
- `computeCacheResult: CalledMeth<'T> list -> CalledMeth<'T> voption -> OverloadResolutionCacheResult option` — store form: resolve the winning `CalledMeth`'s index into the candidate list.
- `storeCacheResult: g -> cache -> keyOpt -> calledMethGroup -> callerArgs -> reqdRetTyOpt -> anyHasOutArgs -> calledMethOpt -> unit` — store the result; when types became solved during resolution, also stores under an "after" key (recomputed on the now-solved types) so subsequent calls with already-solved types hit directly.

**Internal helpers**
- `hasUnsolvedTokens: TypeToken[] -> bool` — detects `TypeToken.Unsolved` entries, used to reject unstable types.
- Cache factory with `Caches.CacheOptions` per compilation mode (`OneOff` -> no eviction; else LRU 4096/50%).

**Significant internal logic and safety rationale**
- The key must not depend on unsolved flexible typars: those could resolve to different types in
  different contexts, producing wrong cache hits. Solved typars are safe to include because (1) the key is
  computed *before* `FilterEachThenUndo`/`Trace.Undo` runs, (2) caller argument types were established
  before overload resolution, and (3) solved typars are not reverted by the undo pass.
- The "double store" (`storeCacheResult` also stores under an "after" key) handles the case where the
  resolution attempt itself solved typars in caller argument types — a later identical call would then
  produce a different (but equivalent) key, and the after-key makes it hit.
- The cache is deliberately keyed off `TcGlobals` (a per-compilation object) using `WeakMap`, so cache
  lifetimes are tied to compilations; no cross-compilation contamination.
- Only `CachedResolved` (successful) results are stored. Failures are not cached because a later attempt
  with a different solver state could succeed.

**Cross-references**
- `OverloadResolutionCache.fsi` — public contract and the safety-rationale doc comments for `tryGetTypeStructureForOverloadCache`.
- `MethodCalls.fs`/`MethodCalls.fsi` — `CalledMeth`, `CallerArgs` types used in the key/result.
- `ConstraintSolver.fs` (sibling) — call site: `ResolveOverloadingForCall` consults/stores the cache around
  the per-candidate loop.
- `Utilities/Caches.fs` (sibling dir) — `Cache` implementation.
- `Utilities/TypeHashing/StructuralUtilities` — `TypeStructure`/`TypeToken` definitions and
  `tryGetTypeStructureOfStrippedType`.

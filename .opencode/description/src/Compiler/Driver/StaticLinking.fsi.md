# StaticLinking.fsi

**Purpose** Signature for the optional static-linking stage. When `--standalone` is on, `extraStaticLinkRoots` is non-empty, or type-provider-generated assemblies must be merged in, `StaticLink` returns a function that grafts the IL of those F# assemblies (and their type forwarders) into the main output module. Otherwise it returns the identity function.

**Pipeline role** fsc `main4`, applied once to the `ILModuleDef` produced by `OptimizeInputs.GenerateIlxCode` and before `CreateILModule.CreateMainModule` runs — i.e. between "IL exists" and "we have the final module to save".

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.StaticLinking`, declared `internal`.

**Function (contract)**

- `StaticLink (ctok: CompilationThreadToken, tcConfig: TcConfig, tcImports: TcImports, tcGlobals: TcGlobals) -> (ILModuleDef -> ILModuleDef)`
  Returns an endo-function over the main `ILModuleDef`. The leading doc comment in the .fsi says: "This only captures `tcImports` (a large data structure) if static linking is enabled. Normally this is not the case, which lets us collect `tcImports` prior to this point." — i.e. the closure is the *only* thing that holds a reference to `TcImports` after this point, so if the condition to skip is met, a simple `id` is returned and the GC can reclaim the big table.

**Public API surface** Just `StaticLink`. It is called exactly once from `FSharp.Compiler.Driver` (fsc.fs `main4`).

**Behavioral contract (from the implementation)**
- Returns `id` when **none** of the following holds:
  - `tcConfig.standalone` is true,
  - `tcConfig.extraStaticLinkRoots` is non-empty,
  - (`#if !NO_TYPEPROVIDERS`) any entry of `tcImports.DllTable` is a provider-generated assembly with a `ProviderGeneratedStaticLinkMap`.
- Otherwise the returned function:
  1. Reports timing via `ReportTime tcConfig "Find assembly references"`.
  2. Calls `FindDependentILModulesForStaticLinking` to compute the set of `(CcuThunk option * ILModuleDef)` to splice in (walking the dependency graph rooted at FSharp.Core and any `extraStaticLinkRoots`).
  3. Reports `"Static link"`.
  4. (typeproviders) Calls `FindProviderGeneratedILModules` to collect provider-generated IL modules and their `ProvidedAssemblyStaticLinkingMap`s.
  5. Re-roots every `ILTypeRef` in every provider-generated module via `Morphs.morphILTypeRefsInILModuleMemoized` + `TcGlobals.IsInEmbeddableKnownSet` so that provider types point at the local scope (with local `ILScopeRef.Local` entries synthesized from each map's `ILTypeMap`).
  6. Splices the foreign type-defs into the main module, adding forwarders so that clients still reference the original assembly identity.
  7. Returns the stitched `ILModuleDef`.

**Internal helpers / active patterns** All the IL-graph and morph machinery is in the .fs — see `StaticLinking.fs.md`. In particular, the `TypeForwarding` lookup class (exact-qualified-name → simple-name cascade against the `CcuThunk`s in `TcImports`), the `Node` record that models the dependency graph (name, `ILModuleDef`, optional `CcuThunk`, `ILReferences`, mutable `edges` and `visited`), the worklist traversal `FindDependentILModulesForStaticLinking` (which also implements the "independent set" of assemblies that are never expanded: mscorlib, System, System.Core, System.Xml, Microsoft.Build.*, netstandard, and anything with the ECMA public key), and the recursive `implantTypeDef` that grafts the type defs into the main module.

**Notes / caveats**
- The return type is a *function*, not the module itself: this is deliberate so that `StaticLink` can be called unconditionally in the driver pipeline and is a no-op when no linking is needed. The driver applies the function once, to the module it has in hand.
- `tcGlobals` is passed in (rather than read from `TcConfig`) because the `ILGlobals` it carries is needed to compute the refs of the main module (`computeILRefs ilGlobals ilxMainModule`) — the `TcConfig` alone is not sufficient.
- The `ctok` (`CompilationThreadToken`) is threaded through to `tcImports.TryFindDllInfo` / `FindCcuFromAssemblyRef` for thread-affinity bookkeeping; a static-link that runs off-thread would be a bug.
- The "no type forwarders / no splicing" identity-shortcut is the *only* case where the result is `id`; every other path (standalone, extra roots, provider-generated assemblies) actually rewrites the module.

**Significant internal logic** Two design points are worth calling out:
1. **Purity of the entry.** `StaticLink` is pure in the sense that it *returns* a function of the module rather than mutating — this is what lets the driver apply `id` or the real transform uniformly, and what lets the GC reclaim `TcImports` when no transform is needed.
2. **Lazy capture of `TcImports`.** `TcImports` is the single largest data structure in a compile (it holds the pickled CCUs for every referenced F# assembly). By only capturing it in a closure under the condition "we have to static-link", the driver keeps it *alive* if and only if static linking will happen — which is the common case for small scripts and the exception for big service graphs.

**Cross-refs**
- Consumed by: `FSharp.Compiler.Driver` (fsc.fs `main4`).
- Depends on: `FSharp.Compiler.CompilerImports` (`TcImports.DllTable`, `ProviderGeneratedTypeRoots`, `ProviderGeneratedStaticLinkMap`, `FindCcuFromAssemblyRef`, `TryFindDllInfo`), `FSharp.Compiler.Optimizer.Morphs` (`morphILTypeRefsInILModuleMemoized`, `enableMorphCustomAttributeData`), `FSharp.Compiler.TcGlobals` (`IsInEmbeddableKnownSet`), `FSharp.Compiler.AbstractIL.IL`, `FSharp.Compiler.IO` (module readers for the linked assemblies).

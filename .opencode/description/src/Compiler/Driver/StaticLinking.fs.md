# StaticLinking.fs

**Purpose** Implements the optional "--standalone" static-linking step, plus the static-linking of **type-provider-generated assemblies**: takes the IL of F# assemblies that the output links against (FSharp.Core and, when requested, any other F# assembly root, plus every provider-generated assembly) and splices their type bodies into the main output module, rewriting `ILTypeRef`s to point at the local scope, and emitting type forwarders so that clients who still reference the original assembly identity keep working. Returns a `ILModuleDef -> ILModuleDef` transform that the driver applies exactly once.

**Pipeline role** fsc `main4` — applies the transform to the `ILModuleDef` produced by `OptimizeInputs.GenerateIlxCode` and before `CreateILModule.CreateMainModule` runs.

**Namespace(s)** `FSharp.Compiler` — module `FSharp.Compiler.StaticLinking`, `internal`.

**Types**

- **`TypeForwarding (tcImports: TcImports)`** (line ~27) — a small class encapsulating the *forwarder lookup* logic. Its internals:
  - `ccuThunksQualifiedName` — a `dict` from `CcuThunk.QualifiedName -> CcuThunk` (the exact-identity map); built once at construction.
  - `ccuThunksSimpleName` — a `dict` from `CcuThunk.AssemblyName -> CcuThunk` (the loose fallback map, used when exact qualified-name lookup fails).
  - `followTypeForwardForILTypeRef (tref: ILTypeRef)` — given a type ref, splits its `FullName` into (enclosing parts, name), and tries (in order): exact-qualified-name lookup in `ccuThunksQualifiedName` → `ccu.TryForward (parts, name)`; loose simple-name lookup in `ccuThunksSimpleName` → `ccu.TryForward (parts, name)`. Returns the `ILScopeRef` of the forwarding target, or the original `Score` if no forwarding applies.
  - `typeForwardILTypeRef tref` — calls the above and rebuilds the ref via `ILTypeRef.Create (scoref2, tref.Enclosing, tref.Name)` only if the scope changed (reference-equality check `scoref1 === scoref2`).
  - `member _.TypeForwardILTypeRef tref` — the public surface used by the code that rewrites type refs.
- **`Node`** (line ~260) — a node in the dependency graph of IL modules to be static-linked: `{ name: string; data: ILModuleDef; ccu: CcuThunk option; refs: ILReferences; mutable edges: Node list; mutable visited: bool }`.

**Top-level functions**

- `debugStaticLinking` (line ~101, `#if !NO_TYPEPROVIDERS`) — reads the `FSHARP_DEBUG_STATIC_LINKING` env var and enables `printfn` traces of each type-ref rewrite decision (used in tests and for diagnosing provider-generated assemblies).

- **`StaticLinkILModules (tcConfig, ilGlobals, tcImports, ilxMainModule, dependentILModules: (CcuThunk option * ILModuleDef) list)`** (line ~104) — the core splicer. Skips (returns `ilxMainModule, id`) when the input list is empty. Otherwise:
  1. Builds a `TypeForwarding` instance, then **asserts no dependent assembly uses F# quotations** by scanning `ccu.UsesFSharp20PlusQuotations` and raising `fscQuotationLiteralsStaticLinking` if any is found — quotation literals in a linked assembly cannot be resolved after the types are localised.
  2. Merges the foreign type defs into `ilxMainModule`, de-duplicating by name and honouring the `ccu` order, while using `TypeForwarding.TypeForwardILTypeRef` to re-root type refs.
  3. Produces the final forwarder list (for use by `CreateILModule` in the `mkILExportedTypes` of the output module).

- **`FindDependentILModulesForStaticLinking (ctok, tcConfig, tcImports, ilGlobals, ilxMainModule)`** (line ~271) — computes the set of `(CcuThunk option * ILModuleDef)` to splice in.
  - Returns `[]` when `not tcConfig.standalone && tcConfig.extraStaticLinkRoots.IsEmpty`.
  - Builds a worklist `remaining` seeded from `computeILRefs ilGlobals ilxMainModule`.
  - Maintains a `depModuleTable: HashMultiMap` of `Node`s.
  - `dummyEntry nm` — a visited placeholder for "independent" assemblies (mscorlib / System / System.Core / System.Xml / Microsoft.Build.* / netstandard, and anything with the ECMA public key — comment: "these we assume we don't need to link").
  - For every non-independent `ilAssemRef`: `tcImports.TryFindDllInfo(..., lookupOnly=false)` to find the imported binary, `FindCcuFromAssemblyRef` to get its CCU (may be `None` — an assembly without F# CCU cannot participate, but may still be linked), `OpenILModuleReader` on the file (with an `ILReaderOptions` that turns `metadataOnly` off because we actually need the IL, and a `pdbDirPath` if `tcConfig.openDebugInformationForLaterStaticLinking` is set so the standalone build *preserves debug info*), then push the new module's own `AssemblyReferences` onto the worklist.
  - Warnings on the way: `fscIgnoringMixedWhenLinking` (a mixed managed/native assembly is present), `fscAssumeStaticLinkContainsNoDependencies` (a referenced assembly could not be resolved — assumed to have no F# dependencies).
  - Edges are built (line ~393): `n2.edges <- n :: n2.edges` for each `aref in n.refs.AssemblyReferences`.
  - Roots: line ~399 — if `standalone` and FSharp.Core is in the table, that node is a root; every `extraStaticLinkRoots` entry must be in the table (else `fscAssemblyNotFoundInDependencySet` error).
  - Final traversal: depth-first from the roots, collecting `(n.ccu, n.data)` for every visited node.

- **`FindProviderGeneratedILModules (ctok, tcImports, providerGeneratedAssemblies)`** (line ~424, `#if !NO_TYPEPROVIDERS`) — for each `(importedBinary, provAssemStaticLinkInfo)`, gets the `ILAssemblyRef` from the `ILScopeRef`, finds the provider's IL module, and builds the per-provider list of `(ccu, ilScopeRef, ilModule)`. These are the *virtual types* that type providers materialized at compile time.

- `trySplitFind p xs` (line ~450) — small list splitter used in the splicer.

- `rec implantTypeDef ilGlobals isNested (tdefs) (enc: string list) (td: ILTypeDef)` (line ~459) — recursively (de)nest and insert a foreign type def (and its nested types) into the main module's type-def list; the `enc` accumulator rebuilds the enclosing chain for nested types.

- **`StaticLink (ctok, tcConfig, tcImports, tcGlobals) -> (ILModuleDef -> ILModuleDef)`** (line ~496) — the public entry. Sequence:
  1. Collects `providerGeneratedAssemblies` from `tcImports.DllTable` (each `ImportedBinary` that is `IsProviderGenerated` with a `Some` `ProviderGeneratedStaticLinkMap`).
  2. Returns `id` when none of `tcConfig.standalone`, `extraStaticLinkRoots.IsEmpty`, (`#if !NO_TYPEPROVIDERS`) `providerGeneratedAssemblies.IsEmpty` is true.
  3. Otherwise, returns `fun ilxMainModule ->`:
     - `ReportTime tcConfig "Find assembly references"`.
     - `dependentILModules = FindDependentILModulesForStaticLinking (...)`.
     - `ReportTime tcConfig "Static link"`.
     - `#if !NO_TYPEPROVIDERS` — `Morphs.enableMorphCustomAttributeData ()` (turns on the morph of custom-attribute *data*, so that attribute argument types pointing at linked assemblies are also rewritten); `providerGeneratedILModules = FindProviderGeneratedILModules (...)`.
     - Builds the cross-provider `ILTypeMap` by unioning every provider's `ILTypeMap` with **local** `ILTypeRef.Create(ILScopeRef.Local, k.Enclosing, k.Name)` entries for the current provider's own map (the key trick: each provider's types get their own local forwarder, so provider A's types don't collide with provider B's).
     - `Morphs.morphILTypeRefsInILModuleMemoized TcGlobals.IsInEmbeddableKnownSet (fun tref -> ...)` — the actual rewrite; the decision predicate `IsInEmbeddableKnownSet` is what decides which type refs are "localizable" (those in the embeddable/known set, e.g. FSharp.Core types) and which must be left alone (e.g. `System.Runtime` types).
     - `StaticLinkILModules (tcConfig, ilGlobals, tcImports, ilxMainModule, dependentILModules @ providerGeneratedILModules)` (the provider-generated modules are *appended* to the dependent set so they get spliced in the same pass).
     - Returns the result of the splicer.

**Public API surface** `StaticLink` (see .fsi) — the only function the driver calls.

**Internal helpers / active patterns** `TypeForwarding` (the forwarder table), `Node` (the work-item in the dependency graph), `dummyEntry`, `implantTypeDef`, `trySplitFind`, and the inline `ILReaderOptions` that turns off `metadataOnly` because we need the real IL (see the inline comment).

**Significant internal logic**
- **Quotation prohibition.** A linked F# assembly that contains F# 20+ quotation literals *cannot* be static-linked (because the quotation's `QuotationGenerator` type will be lost as a local type). `StaticLinkILModules` checks this per dependent CCU and raises `fscQuotationLiteralsStaticLinking` — a real user-facing limitation of `--standalone` that this file enforces.
- **Type-provider path.** Each provider can define multiple "virtual" types that were materialised at compile time; the cross-provider `ILTypeMap` (the union of every provider's map with local `ILTypeRef`s pointing at the *current* provider's types) is what lets two providers that both defined `Foo.Bar` still be distinguishable after the splice.
- **The identity-return shortcut.** Returning `id` when nothing needs to be linked is the key to the GC benefit called out in the .fsi: in that case `TcImports` (the single largest data structure in a compile) is not captured and can be collected right away.
- **`openDebugInformationForLaterStaticLinking`** is a special `--standalone` flag: when set, the module reader is pointed at the `.pdb` next to the linked binary so the resulting standalone assembly preserves its debug info (otherwise the PDB is dropped).

**Cross-refs**
- Consumed by: `FSharp.Compiler.Driver` (fsc.fs `main4`).
- Depends on: `FSharp.Compiler.CompilerImports` (`TcImports.DllTable`, `Finding Ccu`, `ImportedBinary.ImportedBinary`, `ProviderGeneratedStaticLinkMap`, `IsProviderGenerated`), `FSharp.Compiler.Optimizer.Morphs` (`morphILTypeRefsInILModuleMemoized`, `enableMorphCustomAttributeData`), `FSharp.Compiler.TcGlobals` (`IsInEmbeddableKnownSet`, `ilGlobals`), `FSharp.Compiler.AbstractIL.IL` (the `ILTypeDef`/`ILTypeRef`/`ILScopeRef` model), `FSharp.Compiler.AbstractIL.ILBinaryReader` (`OpenILModuleReader`, `ILReaderOptions`), `FSharp.Compiler.IO` (file-system access for the `.pdb` lookup).
- Consumes the `IlxGenResults` pipeline output (`ilxMainModule`) from `FSharp.Compiler.OptimizeInputs`; its result is the input to `FSharp.Compiler.CreateILModule.CreateMainModule`.

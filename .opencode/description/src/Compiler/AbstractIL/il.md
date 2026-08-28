# il.fs

**Purpose**
Implementation of the core abstract-IL algebra (contract in `il.fsi`) — "the 'unlinked' view of .NET metadata and code, central to the Abstract IL library". Provides the F# definitions, equality/comparison, shared-instance pools, and all the helper constructors that the rest of the AbstractIL library (Codegen → binary reader, binary writer, Reflection.Emit writer, pretty printer, morph, ASCII parser, delta metadata writer) builds on top of. The module is `module rec` so that the types can reference each other and the `ILX` (`ilx.fs`) extension types.

**Namespace / module**
- `FSharp.Compiler.AbstractIL` (module `FSharp.Compiler.AbstractIL.IL`)

See `il.fsi.md` for the full type list. The implementation file contains:
- Concrete F# union/record definitions for every type in the contract (with structural equality / no-comparison where appropriate).
- Shared-instance pools for the 18 `ILCallingConv` combinations and `WellKnownILAttributes` constants (no per-call allocation).
- `DelayInitArrayMap<_,_,_>` (from `Internal.Utilities`) instantiation for `ILMethodDefs`, `ILTypeDefs`, `ILNestedExportedTypes`, `ILExportedTypesAndForwarders` — name-keyed, lazily initialized lists.
- `ILAttributesStored` / `ILSecurityDeclsStored` — efficiency-oriented wrappers that cache the computed `WellKnownILAttributes` flags and hold the `ILAttributes` / `ILSecurityDecls` payloads, used by the binary reader to defer work until a member is first inspected.
- All the constructor helpers (`mk*`, `split*`, `rescope*`, `is*Ty`, `inst*Type`, `sha1Hash*`, `computeILEnumInfo`, `computeILRefs`, `getTyOfILEnumInfo`, etc.).
- `PrimaryAssemblyILGlobals` — the singleton `ILGlobals` whose `PrimaryAssembly` is `Mscorlib`.
- `ILReferences` — the aggregated per-module "what does this module reference" summary (assembly refs, etc.).

**Significant internal logic**
- `DelayInitArrayMap` is a `class` with `FindByName`, `AsArray`, `AsList` — built by `mkILTypeDefsOfNamespace` / `mkILTypeDefsGroupedComputed` to give O(1) name-lookup on member tables without materializing a list until requested. The binary reader (`ilread.fs`) uses this to keep "relative metadata" cheap.
- `ILAttributes` / `ILSecurityDecls` are `struct`s whose payloads are allocated lazily; `CreateReader(idx, f)` creates one over a lazy function `int32 -> ILAttribute[]` (`f` is the per-module row fetcher), so the reader can defer parsing of the CustomAttribute/DeclSecurity blobs.
- `rescopeILTypeRef` / `rescopeILType` / `rescopeILMethodRef` / `rescopeILFieldRef` implement the scope-substitution step the .fsi notes require of consumers of "relative" metadata.
- The 18 `ILCallingConv` shared instances (`Instance`, `Static`, and the 16 other (ThisConvention, ArgConvention) pairs) are pre-allocated module-statics so no signature ever allocates one per method.

**Cross-references**
- `il.fsi` (contract), `ilx.fs` (ILX extension types), `Internal.Utilities` (DelayInitArrayMap, HashMultiMap, etc.), `ilbinary.fs` (opcode / table-name constants used by the reader/writer), `ilread.fs` (binary reader — the main consumer), `ilwrite.fs` (binary writer), `ilreflect.fs` (Reflection.Emit writer), `ilmorph.fs` (morphism), `ilascii.fs` (ASCII instruction tables)

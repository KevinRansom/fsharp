# ServiceAssemblyContent

**Purpose:** Reads symbol content (entities, modules, members, functions/values) out of reference assemblies via the TAST signature model, producing flat `AssemblySymbol` lists used for symbol browsing, "open" module discovery, and completion in language service consumers. Supports caching results per assembly file (including provider-generated content) keyed by file write time.

**Namespace(s):** `FSharp.Compiler.EditorServices`

## Declared types / modules
- `Utils` (module): small identifier-massaging helpers (e.g. `replaceLastIdentToDisplayName`).
- `IsAutoOpen` (typedef): boolean flag used in `EntityKind`.
- `LookupType` (enum union, `RequireQualifiedAccess`): `Fuzzy` vs `Precise` classification of an entity's kind.
- `AssemblySymbol` (record): one symbol in an assembly — full name, cleaned idents, namespace, `RequireQualifiedAccess`/`AutoOpen` parent info, the `FSharpSymbol`, a kind function, and a completion-oriented `UnresolvedSymbol`.
- `AssemblyPath` (typedef): `string`.
- `AssemblyContentType` (enum union): `Public` | `Full`.
- `Parent` (record): context for traversing a nested entity — namespace, RQA parents, AutoOpen, module-suffix info, `IsModule`; has static `Empty` and helpers `RewriteParentIdents`, `FormatEntityFullName`.
- `AssemblyContentCacheEntry` (internal record): file write time + content type + cached symbol list.
- `IAssemblyContentCache` (interface): `TryGet`/`Set` cache contract.
- `EntityCache` (class): thread-safe dictionary-backed cache implementing `IAssemblyContentCache`, plus `Clear` and `Locking`.
- `AssemblyContent` (module): the main extraction engine (see API below).

## Public API surface
- `AssemblyContent.GetAssemblySignatureContent : AssemblyContentType -> FSharpAssemblySignature -> AssemblySymbol list` — walk the TAST entities of one assembly signature.
- `AssemblyContent.GetAssemblyContent : withCache -> contentType -> fileName option -> FSharpAssembly list -> AssemblySymbol list` — cached/uncached aggregation across a list of assemblies, respecting public-only filtering and skipping provider-generated assemblies where type providers are enabled.
- `EntityCache` — `Clear`, `Locking f`, `TryGet`, `Set`.
- `Parent.FormatEntityFullName` — strips generic arity suffixes (``Dictionary`2``) and module suffixes from full names to build cleaned display identifiers.

## Internal helpers / notable details (`AssemblyContent` module)
- `UnresolvedSymbol` — normalizes backticks and computes namespace/display-name for completion candidates.
- `createEntity` — converts one `FSharpEntity` into an `AssemblySymbol`, including `EntityKind` (Module with `IsAutoOpen`/`HasModuleSuffix`, Type, Attribute, FunctionOrValue).
- `traverseMemberFunctionAndValues` — yields `AssemblySymbol`s for functions/values; also re-yields an extra entry for compiled operator names (e.g. `M.op_PlusPlus` alongside `++`).
- `traverseEntity` (recursive) — walks nested entities, accumulating `Parent` context (RQA/AutoOpen/module-suffix), skipping private entities in `Public` mode; type-provided entities are excluded under `#if !NO_TYPEPROVIDERS`.

## Significant internal logic
- Runs inside a `DiagnosticsScope(false)` so no diagnostics are emitted while traversing TAST concurrently with other threads (see the CLEANUP comment at `GetAssemblySignatureContent`).
- `GetAssemblyContent` consults the cache only when a file name is supplied; cache validity uses the assembly's last-write time; the `Public` mode post-filters symbols by `Accessibility.IsPublic`.
- `traverseEntity` is intentionally careful to distinguish whether an RQA parent applies to a member/value vs the type itself (`isForMethodOrValue`).

## Cross-references
- `FSharp.Compiler.TAST` / signature (`FSharpAssemblySignature`) for the entity walk
- `FSharp.Compiler.Symbols`, `FSharp.Compiler.SyntaxTree` (`EntityKind`, `UnresolvedSymbol`, `ShortIdents`)
- `FSharpCheckerResults.fs` (service consumer surfacing assembly content)
- `src/Compiler/PrettyNaming` (identifier normalization, backticks)

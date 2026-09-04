# ServiceAssemblyContent.fs

Full implementation of the assembly-content enumeration for the F.Compiler.Service checker layer. Provides the symbol lists used by IntelliSense/completion: for a given `FSharpAssembly`, produce one `AssemblySymbol` per entity/member/function/value, with cleaned display idents and qualification info, optionally cached on disk-write-time.

## Pipeline role

`FSharpChecker` service-layer infrastructure for F# IDE/tooling (part of `FSharp.Compiler.EditorServices`). `AssemblyContent.GetAssemblyContent` walks `FSharpAssemblySignature.Contents` and flattens the entity hierarchy into a flat `AssemblySymbol list` so editors can show every candidate for completion. Diagnostics raised during the walk are suppressed via `DiagnosticsScope(false)`; the walk deliberately skips type-provider-generated entities (`entity.IsProvided`) to avoid triggering provider computation from user threads (see CLEANUP comments).

## Namespaces

- `FSharp.Compiler.EditorServices`
- `open System`, `System.Collections.Generic`, `Internal.Utilities.Library`, `FSharp.Compiler.Diagnostics`, `FSharp.Compiler.IO`, `FSharp.Compiler.Symbols`, `FSharp.Compiler.Syntax`.

## Module `Utils` (internal)

- `replaceLastIdentToDisplayName (idents: string array) (displayName: string) : string array`
  - Finds the last index where `displayName.StartsWith(ident)`. If it is the final element, replaces it; if a prefix matches earlier, truncates the array at that index and installs `displayName`; otherwise returns idents unchanged.

## Type aliases / small types

- `type IsAutoOpen = bool`
- `type LookupType` (`[<RequireQualifiedAccess>]`) — `Fuzzy` | `Precise`.
- `type AssemblySymbol` (`[<NoComparison; NoEquality>]` record; same shape as the .fsi):
  - `FullName: string`, `CleanedIdents: ShortIdents`, `Namespace: ShortIdents option`, `NearestRequireQualifiedAccessParent: ShortIdents option`, `TopRequireQualifiedAccessParent: ShortIdents option`, `AutoOpenParent: ShortIdents option`, `Symbol: FSharpSymbol`, `Kind: LookupType -> EntityKind`, `UnresolvedSymbol: UnresolvedSymbol`.
  - `override ToString() = sprintf "%A" x`.
- `type AssemblyPath = string`
- `type AssemblyContentType = Public | Full` (orthogonal to the RequireQualifiedAccess version used by the API; here declared as a plain union, supported by the pattern match `| Full, _ | Public, true ->`).

## `Parent` (internal record + helpers)

Fields:
- `Namespace: ShortIdents option`
- `ThisRequiresQualifiedAccess: bool (* isForMemberOrValue *) -> ShortIdents option`
- `TopRequiresQualifiedAccess: bool -> ShortIdents option`
- `AutoOpen: ShortIdents option`
- `WithModuleSuffix: ShortIdents option`
- `IsModule: bool`

Members / static functions:
- `static member Empty` — defaults with `Namespace=None`, no RQA, `AutoOpen=None`, `WithModuleSuffix=None`, `IsModule=true`.
- `static member RewriteParentIdents (parentIdents) (idents)` — overwrites the leading elements of `idents` with `parentIdents` (when the parent is a prefix).
- `member FixParentModuleSuffix (idents)` — applies `RewriteParentIdents x.WithModuleSuffix`.
- `member FormatEntityFullName (entity: FSharpEntity) : (string * ShortIdents) option`
  - `removeGenericParamsCount` strips `` `2 ``-style arity suffixes (e.g. `Dictionary`2` → `Dictionary`).
  - `removeModuleSuffix` reinstates the display name for F# modules (`entity.IsFSharpModule`) or backtick-requiring idents, via `Utils.replaceLastIdentToDisplayName`.
  - Combines `TryGetFullName()` and `TryGetFullDisplayName().Split '.'`.

## `AssemblyContentCacheEntry` + `IAssemblyContentCache`

- `AssemblyContentCacheEntry = { FileWriteTime: DateTime; ContentType: AssemblyContentType; Symbols: AssemblySymbol list }`
- `IAssemblyContentCache` (`[<NoComparison; NoEquality>]`) — `abstract TryGet: AssemblyPath -> AssemblyContentCacheEntry option`, `abstract Set: AssemblyPath -> AssemblyContentCacheEntry -> unit`.

## Module `AssemblyContent`

- `UnresolvedSymbol (topRequireQualifiedAccessParent) (cleanedIdents) fullName ns : UnresolvedSymbol`
  - Computes the namespace to open: from the top RQA parent (as namespace/module prefix), falling back to `ns`, defaulting to empty; normalizes backticks. Display name = remaining cleaned idents joined with `.`, backticks normalized.
- `createEntity ns (parent: Parent) (entity: FSharpEntity) : AssemblySymbol option`
  - Runs `parent.FormatEntityFullName`; builds the `AssemblySymbol` with:
    - `NearestRequireQualifiedAccessParent = parent.ThisRequiresQualifiedAccess false`
    - `TopRequireQualifiedAccessParent = parent.TopRequiresQualifiedAccess false`
    - `AutoOpenParent = parent.AutoOpen`
    - `Kind` — `FSharpModule` → `EntityKind.Module { IsAutoOpen = …; HasModuleSuffix = … }`; otherwise `LookupType.Fuzzy` → `EntityKind.Type`, `LookupType.Precise` → `EntityKind.Attribute` (if an attribute) or `EntityKind.Type`.
- `traverseMemberFunctionAndValues ns (parent: Parent) (membersFunctionsAndValues)`
  - Filters out instance members and property getters/setters; for each remaining member/function/value produces two `AssemblySymbol`s (deduped later):
    1. From `TryGetFullDisplayName()` + `func.FullName`, with a backtick-aware final-ident replacement.
    2. From `TryGetFullCompiledOperatorNameIdents()` (also returns the compiled `op_PlusPlus`-style name under `ModuleSuffix`), so operators are findable both by display name and compiled name.
  - `Kind = fun _ -> EntityKind.FunctionOrValue func.IsActivePattern`.
- `traverseEntity contentType (parent: Parent) (entity: FSharpEntity) : seq<AssemblySymbol>`
  - Recursive pre-order walk over `NestedEntities` producing a `seq`.
  - Skips provided entities (`#if !NO_TYPEPROVIDERS`); emits only when `contentType=Full` or the entity is public.
  - Computes nested `Parent`:
    - `thisRequiresQualifierAccess`: RQA parent is the entity itself for methods/vals, else the RQA of the (nested) type.
    - `AutoOpen` propagation: nearest AutoOpen module is kept; if current is AutoOpen but parent wasn’t, the current becomes the AutoOpen parent; otherwise dropped.
    - `WithModuleSuffix`: tracked when a module has a `ModuleSuffix` attribute or `CompiledName <> DisplayName`.
  - Then emits properties, dedupes, and recurses into `entity.TryGetMembersFunctionsAndValues()`.
- `GetAssemblySignatureContent contentType (signature: FSharpAssemblySignature) : AssemblySymbol list`
  - Wraps the traversal in `DiagnosticsScope(false)`; visits `signature.TryGetEntities()`; `distinctBy (FullName, CleanedIdents)`; returns the list.
- `getAssemblySignaturesContent contentType (assemblies)` — `List.collect` over `asm.Contents`.
- `GetAssemblyContent withCache contentType (fileName: string option) (assemblies) : AssemblySymbol list`
  - Skips type-provider-generated assemblies when filtering (unless `NO_TYPEPROVIDERS`).
  - Empty assemblies / no file: compute directly (no cache).
  - `Some fileName`: get `FileSystem.GetLastWriteTimeShim`, then inside `withCache <| fun cache ->`:
    - Cache hit when `entry.FileWriteTime = fileWriteTime` (for `Public`, both content types agree) → return `entry.Symbols`.
    - Else compute via `getAssemblySignaturesContent`, store `{ FileWriteTime; ContentType; Symbols }`, return symbols.
  - Final filter: `Full` keeps everything; `Public` keeps only `entity.Symbol.Accessibility.IsPublic`.

## `EntityCache` (public class)

- `let dic = Dictionary<AssemblyPath, AssemblyContentCacheEntry>()`
- `interface IAssemblyContentCache` — `TryGet`/`Set` implemented over `dic`.
- `member Clear()` — `dic.Clear()`.
- `member x.Locking f` = `lock dic <| fun _ -> f (x :> IAssemblyContentCache)` — thread-safe accessor.

## Key internal logic notes

- Name cleaning happens at build time so completion can group by `CleanedIdents` without re-walking metadata.
- The `Kind` function is lazy/parameterized by `LookupType`, letting the same symbol yield `EntityKind.Module`/`Attribute` vs. `Type` depending on whether completion is fuzzy or precise.
- The cache stores `FileWriteTime` so stale on-disk changes invalidate cached content automatically.
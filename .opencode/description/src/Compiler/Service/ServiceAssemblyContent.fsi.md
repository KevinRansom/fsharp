# ServiceAssemblyContent.fsi

**Signature for `ServiceAssemblyContent.fs`.** This file is part of the `FSharp.Compiler.EditorServices` namespace and belongs to the FSharp.Compiler.Service checker layer. It declares the public API surface used to enumerate the symbols (`FSharpSymbol`) that live in a compiled assembly for IntelliSense / completion scenarios. The matching `.fs` file implements these declarations along with additional internal helpers (`Utils`, `Parent`, `EntityCache` internals).

## Pipeline role

`FSharpChecker` service-layer infrastructure for F# IDE/tooling. `GetAssemblyContent`/`GetAssemblySignatureContent` flatten a set of `FSharpAssembly` values into a list of `AssemblySymbol` records describing every type, module, member, function, and value visible in those assemblies (with cleaned display idents, namespace/module context, and `RequireQualifiedAccess`/`AutoOpen` parents). A cache (`IAssemblyContentCache`/`EntityCache`) keyed by assembly path and file-write-time avoids recomputing this expensive enumeration. This feeds completion dropdowns, where fuzzy vs. precise lookup changes the reported `EntityKind`.

## Namespaces

- `FSharp.Compiler.EditorServices` (with `open System` and `open FSharp.Compiler.Symbols`).

## Public types (declared in signature)

- `type AssemblyContentType` (`[<RequireQualifiedAccess>]`)
  - `Public` — report public assembly content only.
  - `Full` — report all assembly content regardless of accessibility.
- `type LookupType` (`[<RequireQualifiedAccess>]`)
  - `Fuzzy` — used for fuzzy (completion/typing) lookups.
  - `Precise` — used for precise (tooltip/find-all-references) lookups.
- `type AssemblyPath = string` — a file path of an assembly used as a cache key.
- `type AssemblySymbol` (`[<NoComparison; NoEquality>]` record):
  - `FullName: string` — raw `FSharpEntity.FullName` / `FSharpValueOrFunction.FullName` as seen in compiled code.
  - `CleanedIdents: ShortIdents` — display idents with module suffixes removed (`Ns.M1Module.M2Module.M3.entity` → `Ns.M1.M2.M3.entity`) and compiled names replaced by display names (`DisplayName`); all parts are cleaned, not just the last.
  - `Namespace: ShortIdents option` — from `FSharpEntity.Namespace`.
  - `NearestRequireQualifiedAccessParent: ShortIdents option` — most narrative parent module carrying `RequireQualifiedAccess`.
  - `TopRequireQualifiedAccessParent: ShortIdents option` — outermost parent module carrying `RequireQualifiedAccess` (largest scope).
  - `AutoOpenParent: ShortIdents option` — parent module marked `AutoOpen`.
  - `Symbol: FSharpSymbol` — the underlying symbol.
  - `Kind: LookupType -> EntityKind` — function returning the entity kind given the lookup type.
  - `UnresolvedSymbol: UnresolvedSymbol` — cached display name + namespace used for completion.
- `type AssemblyContentCacheEntry` (internal record guards the cache):
  - `FileWriteTime: DateTime` — last write time of the assembly file.
  - `ContentType: AssemblyContentType` — content type used to build the entry.
  - `Symbols: AssemblySymbol list` — the assembly content.
- `type IAssemblyContentCache` (`[<NoComparison; NoEquality>]`) — interface:
  - `abstract TryGet: AssemblyPath -> AssemblyContentCacheEntry option`
  - `abstract Set: AssemblyPath -> AssemblyContentCacheEntry -> unit`
- `type EntityCache` (public class) — thread-safe wrapper over `IAssemblyContentCache`:
  - `interface IAssemblyContentCache`
  - `new: unit -> EntityCache`
  - `member Clear: unit -> unit` — clears the cache.
  - `member Locking: (IAssemblyContentCache -> 'T) -> 'T` — runs an operation on the cache under the lock.

## Public module

- `module AssemblyContent`
  - `val GetAssemblySignatureContent: AssemblyContentType -> FSharpAssemblySignature -> AssemblySymbol list` — enumerate content of one assembly signature (each type, member, function, value).
  - `val GetAssemblyContent: withCache: ((IAssemblyContentCache -> AssemblySymbol list) -> AssemblySymbol list) -> contentType: AssemblyContentType -> fileName: string option -> assemblies: FSharpAssembly list -> AssemblySymbol list` — returns possibly-cached assembly content. When `fileName` is supplied, cache lookup is keyed on file write time.

## Relation to .fs

The signature constrains the corresponding `ServiceAssemblyContent.fs`, exposing only the four-public-API items (`AssemblyContentType`, `LookupType`, `AssemblySymbol`, cache types, `AssemblyContent`) and hiding the internal machinery: `Utils`, the `Parent` record with its parent-ident rewriting, `AssemblyContentCacheEntry` (hidden), and the `createEntity`/`traverseEntity`/`traverseMemberFunctionAndValues` traversal logic.
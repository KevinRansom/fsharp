# FSharp.DependencyManager.fsi

> Pipeline role: Contract for the nuget dependency manager — keeps the class surface (`Name`, `Key`, `HelpMessages`, `ClearResultsCache`, `ResolveDependencies`, ctors) public while hiding the parsing/generation internals.
> Namespace: `FSharp.DependencyManager.Nuget` (line 1).

---

## Contract

- `module FSharpDependencyManager` — the `[<assembly: DependencyManager>]` marking.
- `[<Sealed>] type FSharpDependencyManager =` with:
  - `new: outputDirectory: string option * useResultsCache: bool * additionalParams: IDictionary<string, obj> -> FSharpDependencyManager`
  - `new: outputDirectory: string option * useResultsCache: bool -> ...`
  - `new: outputDirectory: string option -> ...`
  - `member Name: string`, `member Key: string` ("nuget"), `member HelpMessages: string[]`.
  - `member ClearResultsCache: unit -> unit`.
  - `member ResolveDependencies: scriptDirectory: string * scriptName: string * scriptExt: string * packageManagerTextLines: seq<string * string> * targetFrameworkMoniker: string * runtimeIdentifier: string * timeout: int -> obj` — returns a boxed `ResolveDependenciesResult`.
- (Implementation details like `validateAndFormatRestoreSources`, `formatPackageReference`, `parsePackageReference`, `prepareDependencyResolutionFiles`, `computeHashForResolutionInputs`, `tryGetResultsForResolutionHash` are internal to the `.fs`.)

---

## Related

- Implementation in `FSharp.DependencyManager.fs`; the `ResolveDependenciesResult` record and `DependencyManagerAttribute` come from `FSDependencyManager` (`FSharp.Compiler.Service` interface types).
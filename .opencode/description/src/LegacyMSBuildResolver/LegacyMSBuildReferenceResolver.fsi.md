# LegacyMSBuildReferenceResolver.fsi

> Pipeline role: Public contract for the FSharp.Compiler.Service reference resolver that shells out to MSBuild's `ResolveAssemblyReference` for .NET Framework reference resolution — a single function `getResolver` producing a `LegacyReferenceResolver` (boxed `ILegacyReferenceResolver`).
> Namespace: `module public FSharp.Compiler.CodeAnalysis.LegacyMSBuildReferenceResolver`.

---

## Contract

- `[<System.Obsolete("This module is not for external use and may be removed in a future release of FSharp.Compiler.Service")>] module public FSharp.Compiler.CodeAnalysis.LegacyMSBuildReferenceResolver`.
- `val getResolver: unit -> LegacyReferenceResolver` — create a resolver; `LegacyReferenceResolver` is the `union` wrapper defined in the service that carries an `ILegacyReferenceResolver` (see `FSharp.Compiler.SourceCodeServices`/`CodeAnalysis` contract types).

---

## Related

- Implementation in `LegacyMSBuildReferenceResolver.fs`; invoked from `fscmain` (`CompileFromCommandLineArguments`) and the script/fsi resolution path when MSBuild-based resolution is wanted.
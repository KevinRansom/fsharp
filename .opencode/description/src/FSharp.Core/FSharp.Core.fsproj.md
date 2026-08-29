# FSharp.Core.fsproj

## Pipeline role
Builds `FSharp.Core.dll` — the F# standard library shipped as the FSharp.Core NuGet package
and bundled in the dotnet SDK/compiler dist.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Library`.
- Proto: `TargetFrameworks=netstandard2.0`. Otherwise:
  `netstandard2.0;netstandard2.1;$(FSharpCoreShippedNetTargetFramework)`.
- Defines `FSHARP_CORE`; compiler flags `--compiling-fslib --compiling-fslib-40
  --maxerrors:100 --extraoptimizationloops:1`, plus `--warnon:3218/3390/3520`,
  `--nowarn:57` (Experimental) and `--nowarn:3513` (resumable code).
- `Tailcalls=true` and `Optimize=true` (always optimized so IL baselines stay identical
  between Debug/Release; comment notes to disable locally for FSharp.Core debugging).
- Non-DOTNET / non-Proto builds add `--realsig-` (old-style structural equality init needed
  for SQL CLR requirements).
- `PreRelease=true`, `PackageId=FSharp.Core`, `PackageVersionPrefix=$(FSCorePackageVersion)`,
  `IsPackable=true`, `NuspecFile=FSharp.Core.nuspec`.
- `NoOptimizationData=false/NoInterfaceData=false/CompressMetadata=true` (public surface).

## Key items
- `EmbeddedResource` `FSCore.resx` with source generation (SR module
  `Microsoft.FSharp.Core.SR`); `EmbeddedResource` `ILLink.Substitutions.xml` with logical
  name `ILLink.Substitutions.xml` (trimming substitutions for FSharp.Core).
- Sources: `prim-types-prelude.fsi/.fs` (CompileFirst for the SDK build pattern, via
  `CompileBefore` under Proto/BUILDING_USING_DOTNET), then the whole library: primitives,
  collections (`list/array/seq/map/set/option/result/string/seqcore/array2/array3/local/
  collections`), random, reflection, numerics (`math/z`), `sformat` (shared with compiler),
  printf, quotations, nativeptr, control (`event`, `resumable`, `async`, `tasks`,
  `eventmodule`, `observable`, `mailbox`), queries/Linq (`Nullable`, `Linq`,
  `MutableTuple`, `QueryExtensions`, `Query`), `SI` (units), `fslib-extra-pervasives`.
- `CopyToBuiltBin` target registers `FSharp.Core.xml` in the built-output group.

## References
- Non-Package builds use FSharp.Core via... none besides SDK; the C#-accessibility of the
  library is self-contained. `BUILDING_USING_DOTNET` switches output paths to artifacts.

## Output
`FSharp.Core.dll` per TFM (+ xml, satellites, embedded ILLink substitutions).
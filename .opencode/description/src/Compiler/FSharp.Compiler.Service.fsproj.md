# FSharp.Compiler.Service.fsproj

## Pipeline role
The heart of the repository: builds `FSharp.Compiler.Service.dll`, the public,
referencable F# compiler-as-a-library (parsing, type checking, code generation, the
incremental service/model API, and the FSharpChecker-based tooling surface). Its source
files are shared by fsc, fsi, and FSharp.Compiler.LanguageServer.

## Project type / frameworks
- `Microsoft.NET.Sdk`; `OutputType=Library`; default `TargetFrameworks=netstandard2.0`
  (a second `$(FSharpNetCoreProductTargetFramework)` is added for non-official local
  builds when available to get better BCL nullability annotations).
- `AssemblyName=FSharp.Compiler.Service`; `Nullable=enable`; `Tailcalls=true`;
  `--extraoptimizationloops:1`, `--warnon:3218`, `--warnon:3390`,
  `--generate-filter-blocks`; `CompressMetadata`/`NoOptimizationData=false`/
  `NoInterfaceData=false` (public reference surface).
- Defines `COMPILER`, optionally `BUILD_USING_MONO` / `FSHARPCORE_USE_PACKAGE`.

## Key items
- EmbeddedText: `FSComp.txt`, `Interactive\FSIstrings.txt`, `Facilities\UtilsStrings.txt`
  (become `.resources` + typed accessors). `FSStrings.resx` embedded as
  `FSStrings.resources`.
- Static preprocessing: `FsLex`/`FsYacc` for `illex/inlpars`, `pplex/pppars`, `lex/pars`
  into the intermediate output folder; generated `.fsi/.fs` are compiled.
- Full compiler source ordering: Utilities -> Facilities -> AbstractIL -> SyntaxTree
  (lexer/parser) -> TypedTree -> Checking (incl. `Checking\Expressions\*`) -> Optimize
  -> CodeGen (incl. EraseUnions, HotReloadBaseline) -> Driver (incl.
  `Driver\GraphChecking\*` for parallel type-checking) -> Symbols -> Service ->
  Interactive (`fsi.fs`, `FSharpInteractiveServer`).
- `Driver\GraphChecking\Docs.md` included as Content.
- `InternalsVisibleTo`: fsc/fsi/fsiAnyCpu/fsiArm64/fscAnyCpu/fscArm64, VisualFSharp.Salsa,
  test projects, FSharp.Editor, FSharp.Compiler.LanguageServer, FSharp.VisualStudio.Extension.

## References / packaging
- ProjectReferences: `FSharp.DependencyManager.Nuget.fsproj`; `FSharp.Core.fsproj` (or
  FSharp.Core package when `FSHARPCORE_USE_PACKAGE=true`); buildtools fslex/fsyacc/
  AssemblyCheck (ReferenceOutputAssembly=false) for the net-core build; classic
  System.* packages only for non-.NETCoreApp targets.
- `IsPackable`, `NuspecFile=FSharp.Compiler.Service.nuspec`, icon `logo.png`, package
  description/tags/release-notes; NuspecProperty variables pass exact dependency versions
  through NuGet repack.

## Output
`FSharp.Compiler.Service.dll` (+ `.xml`, satellites, `default.win32manifest`) — the
library all editors, LSP, fsc, fsi and the VSIX build upon.
# Microsoft.FSharp.NetSdk.props

## Pipeline role
The .NET SDK F# language props: imported at the top of evaluation for every F#
`Microsoft.NET.Sdk` project. Establishes F#-specific defaults, compiler tool discovery,
implicit FSharp.Core/System.ValueTuple references, and compile-ordering item schemas.

## Key properties / items
- `MSBuildAllProjects` self-registration.
- `Choose` adds `TRACE` to `DefineConstants` when empty.
- `EnableDefaultCompileItems` / `EnableDefaultNoneItems` default to **false** — F#
  projects do not glob; source order is explicit in the .fsproj (globbed None items
  break Solution-Explorer folder ordering).
- Language metadata: `Language=F#`, `DefaultProjectTypeGuid` (the F# project type GUID
  F2A71F9B-...), `Prefer32Bit=false`, `TreatWarningsAsErrors=false`, `WarningLevel=3`,
  `WarningsAsErrors=3239;...`, `UseStandardResourceNames=true`, `FsiExec=true`,
  `ReflectionFree=false`; `SYSLIB0011` (BinaryFormatter) promoted to error to mirror the
  SDK.
- Debug vs Release defaults: `DebugSymbols/Optimize/Tailcalls` combos.
- Auto compiler-tool discovery when `DOTNET_HOST_PATH` is set: `FscToolPath/FscToolExe/
  DotnetFscCompilerPath` (and Fsi equivalents) pointing at the SDK's bundled `fsc.dll`/
  `fsi.dll`.
- Central package management compat: `DisableImplicitSystemValueTupleReference` &
  `DisableImplicitFSharpCoreReference` under `ManagePackageVersionsCentrally`.
- Implicit references: System.ValueTuple package when targeting old netstandard/netframework
  TFMs and `ValueTupleImplicitPackageVersion=4.6.2`; FSharp.Core package reference using
  `FSharpCoreImplicitPackageVersion` or the `FSCorePackageVersion` from the imported
  `Microsoft.FSharp.Core.NetSdk.props` (contentFiles excluded unless a doc file is wanted).
- Preview-SDK language-version auto-set: with a preview SDK >= 11 and no explicit
  `LangVersion`, defaults to `11`.
- `ItemDefinitionGroup`: `PackageReference.GeneratePathProperty` and metadata-driven
  compile ordering (`CompileFirst`, `CompileBefore`, `CompileAfter`, `CompileLast`
  bound to `CompileOrder`).

## Import
Convention: F# SDK projects import this props early; `Microsoft.FSharp.NetSdk.targets`
imports `Microsoft.FSharp.Targets` at the bottom.
# CompilerLocation.fs

**Purpose**: Despite the name, this file (module `FSharpEnvironment`) contains the compiler *environment/location* machinery: product/version strings, discovery of the default F# compiler/FSharp.Core locations, type-provider design-time assembly search paths, and the `dotnet` host probing logic. It is the "where things live" facility used by the compiler driver, F#, and tooling.

**Namespace(s)**: `Internal.Utilities`

**Modules / TypeDefs declared**:
- `module internal FSharpEnvironment`: all logic lives here (no separate types beyond a private marker `TypeInThisAssembly`)

**Public API surface** (internal values):
- Version/product: `FSharpBannerVersion`, `FSharpProductName`, `FSharpCoreLibRunningVersion`, `FSharpBinaryMetadataFormatRevision` ("2.0.0.0"), `isRunningOnCoreClr`, `tryCurrentDomain`
- Compiler location: `BinFolderOfDefaultFSharpCompiler`, `getFSharpCompilerLocation`, `getDefaultFSharpCoreLocation`, `getDefaultFsiLibraryLocation`, `getFSharpCoreLibraryName`, `fsiLibraryName`
- Type providers: `toolingCompatibleTypeProviderProtocolMonikers` (`fsharp41`), `toolingCompatibleVersions` (net45..netstandard2.0 / net5+ list), `toolPaths` (`tools`, `typeproviders`), `toolingCompatiblePaths`, `searchToolPath(s)`, `getTypeProviderAssembly`, `getCompilerToolsDesignTimeAssemblyPaths`
- dotnet host: `isWindows`, `dotnet`, `getDotnetHostPath`, `getDotnetGlobalHostPath`, `getDotnetHostDirectories/Directory/SubDirectories`
- Small helpers: `Option.ofString`, `fileExists`

**Significant internal logic**:
- `BinFolderOfDefaultFSharpCompiler` order: `FSHARP_COMPILER_BIN` env var → probePoint containing `FSharp.Core.dll` → `AppDomain.CurrentDomain.BaseDirectory` → executing assembly's directory
- `getTypeProviderAssembly` searches the parent-directory chain from the runtime assembly for a `.DesignTime.dll` (stops at `packages`), then falls back to `Assembly.Load` for full-name specs (legacy GAC path)
- `toolingCompatibleVersions` branches on whether running on `mscorlib` (full .NET Framework: net45..netstandard2.0) vs `System.Private.CoreLib` (net5+ down to netcoreapp2.0), so type providers can be placed in TFM-specific `tools/fsharp41/<tfm>/` folders
- `getDotnetHostPath` probing order: `DOTNET_HOST_PATH` env var → SDK-install relative location (two `..` above `Int32`'s assembly dir) → `PATH` scan → global `%PROGRAMFILES%\dotnet`
- `getDotnetHostDirectories` dedupes host + global host dirs, honoring `DOTNET_MULTILEVEL_LOOKUP`

**Cross-references**: Used by the compiler driver, F# (`FSharp.CompilerService`), `FSharp.Build` default tool paths; type-provider loading ties into checking; relates to DiagnosticsLogger for error reporting in `getTypeProviderAssembly`.

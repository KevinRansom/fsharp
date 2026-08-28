# CompilerLocation.fsi

**Purpose**: The contract for the `FSharpEnvironment` module: exposes the internal values for product version strings, default compiler/FSharp.Core/dotnet host discovery, and type-provider tooling path computation that `CompilerLocation.fs` implements.

**Namespace(s)**: `Internal.Utilities`

**Modules declared**:
- `module internal FSharpEnvironment`: all declared values (see below)

**Contract (API surface)**:
- `FSharpBannerVersion: string`, `FSharpProductName: string`, `FSharpCoreLibRunningVersion: string option`, `FSharpBinaryMetadataFormatRevision: string`
- `isRunningOnCoreClr: bool`, `tryCurrentDomain: unit -> string option`
- `BinFolderOfDefaultFSharpCompiler: string option -> string option` — documented as the default location basis for script FSharp.Core copies, `FSharp.Build` ToolPath default, `service.fs` binaries dir, and `FSharp.VS.FSI` fsi.exe default
- `toolingCompatiblePaths: unit -> string list`, `searchToolPaths: string option * seq<string> -> seq<string>`
- `getTypeProviderAssembly: runTimeAssemblyFileName * designTimeAssemblyName * compilerToolPaths * raiseError -> Assembly option`
- `getFSharpCompilerLocation/unit->string`, `getDefaultFSharpCoreLocation`, `getDefaultFsiLibraryLocation`, `getCompilerToolsDesignTimeAssemblyPaths`, `fsiLibraryName`, `getFSharpCoreLibraryName`
- `isWindows: bool`, `dotnet: string`, `getDotnetHostPath: string option -> string option`, `getDotnetHostDirectories: unit -> string[]`, `getDotnetHostDirectory: unit -> string option`, `getDotnetHostSubDirectories: string -> DirectoryInfo[]`
- Note: `versionOf`, `toolingCompatibleTypeProviderProtocolMonikers`, `Option.ofString`, `getDotnetGlobalHostPath`, `getFSharpCompilerLocationWithDefaultFromType` are internal to the implementation (not surfaced here)

**Notes**: All bindings are `internal`; the F# file additionally implements the env-var/SDK-install/path probing algorithms behind these values.

**Cross-references**: Implements CompilerLocation.fs; consumed by driver/tooling code for locating `dotnet`, FSharp.Core, and type-provider design-time assemblies.

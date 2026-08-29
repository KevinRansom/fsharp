# LegacyResolver.txt

## Pipeline role
Embedded narrative text (path list) consumed by `LegacyMSBuildReferenceResolver.fsi/.fs` in
the fsc/fsi **.NET Framework** reference-resolution path. Embedded via `EmbeddedText` in
`fsc.targets` and `fsi.targets` under the logical name this file lives at.

## Content (line names)
- `assemblyResolutionFoundByAssemblyFoldersKey`
- `assemblyResolutionFoundByAssemblyFoldersExKey`
- `assemblyResolutionNetFramework`
- `assemblyResolutionGAC`

## How it is read
`LegacyMSBuildReferenceResolver` embeds these as a string resource index so the resolver
can label/name resolution attempts in its trace/debug output — the four resolution
strategies it can use when answering a reference: the Microsoft.NETFramework.ReferenceAssemblies
`AssemblyFoldersEx` keys (`AssemblyFoldersKey`, `AssemblyFoldersExKey`), the plain
.NET Framework directory (`assemblyResolutionNetFramework`), and the GAC lookup
(`assemblyResolutionGAC`). The actual probing logic lives in `FSharp.Compiler.Private` /
`ScriptingHelpers.cs` (this txt marks *which* mechanism produced a hit for diagnostics).